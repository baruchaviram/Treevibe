// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/* ---------- Minimal IERC20 / SafeToken (no OZ imports) ---------- */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address a) external view returns (uint256);
    function allowance(address o, address s) external view returns (uint256);
    function approve(address s, uint256 v) external returns (bool);
    function transfer(address to, uint256 v) external returns (bool);
    function transferFrom(address f, address t, uint256 v) external returns (bool);
}

library SafeToken {
    function safeTransfer(IERC20 t, address to, uint256 v) internal {
        bool ok = t.transfer(to, v);
        require(ok, "TRANSFER_FAILED");
    }
    function safeTransferFrom(IERC20 t, address from, address to, uint256 v) internal {
        bool ok = t.transferFrom(from, to, v);
        require(ok, "TRANSFER_FROM_FAILED");
    }
}

/* ---------------------- Simple Ownable ---------------------- */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ZERO_ADDRESS");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


/* =========================== TreeVibe =========================== */
contract TreeVibe is Ownable {
    using SafeToken for IERC20;

    IERC20 public immutable usdt;
    address public treasuryWallet;

    uint256 public constant USDT_DECIMALS = 6;
    uint256 public constant REG_PRICE = 100 * (10 ** USDT_DECIMALS);
    uint256 public constant WEEKLY_PRICE = 9 * (10 ** USDT_DECIMALS);

    uint16[8] public levelPerc = [uint16(1500), 1800, 1200, 1000, 1000, 1000, 1000, 1000]; // bps = 10000
    uint16 public constant PIONEER_REST_BPS = 5000; // 50% of REST goes to pioneer lottery (the rest to treasury)

    uint32 public constant PIONEER_GROUP_SIZE = 500;
    uint8  public constant PIONEER_WINNERS = 5;

    struct User {
        address account;
        uint32  id;
        uint32  uplineId;
        string  nickname;
        uint32  directs;
        uint32  teamSize;
        uint64  activeUntil;
        uint256 totalEarnings;
    }

    mapping(address => uint32) public idOf;
    mapping(uint32  => User)   public userOf;
    mapping(bytes32 => uint32) private nicknameOwnerId;
    uint32 public totalUsers;

    event Registered(address indexed user, uint32 indexed userId, uint32 indexed uplineId, string nickname);
    event WeeklyPaid(address indexed user, uint32 indexed userId, bool assistUsed, address helper, uint256 totalOut);
    event Payout(address indexed to, uint256 amount, bytes32 tag);
    event PioneerWin(address indexed winner, uint32 indexed groupIndex, uint256 amountEach);
    event TreasuryWalletUpdated(address indexed a);

    constructor(address usdt_, address treasury_, string memory rootNickname) Ownable() {
        require(usdt_ != address(0) && treasury_ != address(0), "ZERO");
        usdt = IERC20(usdt_);
        treasuryWallet = treasury_;
        
        // Validate and create root user
        _validateNickname(rootNickname);
        
        // Create root user with ID 0
        User storage rootUser = userOf[0];
        rootUser.account = msg.sender;
        rootUser.id = 0;
        rootUser.uplineId = 0; // Root has no upline
        rootUser.nickname = rootNickname;
        rootUser.directs = 0;
        rootUser.teamSize = 0;
        rootUser.activeUntil = 0;
        rootUser.totalEarnings = 0;
        
        // Update mappings - store (userID + 1) in nicknameOwnerId to handle root user (ID 0)
        idOf[msg.sender] = 0;
        bytes32 nicknameHash = keccak256(bytes(rootNickname));
        nicknameOwnerId[nicknameHash] = 1; // Store (0 + 1) for root user
        totalUsers = 1;
        
        emit Registered(msg.sender, 0, 0, rootNickname);
    }

    function setTreasuryWallet(address a) external onlyOwner { 
        require(a != address(0), "ZERO");
        treasuryWallet = a;
        emit TreasuryWalletUpdated(a);
    }

    function isRegistered(address a) public view returns (bool) { return idOf[a] != 0 || a == userOf[0].account; }

    function _validateNickname(string memory nickname) internal view {
        bytes memory nickBytes = bytes(nickname);
        require(nickBytes.length >= 3 && nickBytes.length <= 20, "INVALID_NICKNAME_LENGTH");
        
        // Check for alphanumeric characters only
        for (uint256 i = 0; i < nickBytes.length; i++) {
            bytes1 char = nickBytes[i];
            require(
                (char >= 0x30 && char <= 0x39) || // 0-9
                (char >= 0x41 && char <= 0x5A) || // A-Z
                (char >= 0x61 && char <= 0x7A),   // a-z
                "INVALID_NICKNAME_CHARS"
            );
        }
        
        // Check uniqueness - nicknameOwnerId stores (userID + 1) to handle root user (ID 0)
        bytes32 nicknameHash = keccak256(nickBytes);
        require(nicknameOwnerId[nicknameHash] == 0, "NICKNAME_TAKEN");
    }

    function _distributeRegistration(uint32 newId, address account, uint32 uplineId) internal {
        uint256 left = REG_PRICE;

        uint32 cur = uplineId;
        for (uint8 level = 0; level < 8; level++) {
            uint256 share = (REG_PRICE * levelPerc[level]) / 10000;
            // Check if current user exists and is valid
            if (cur < totalUsers && userOf[cur].account != address(0)) {
                address to = userOf[cur].account;
                usdt.safeTransfer(to, share);
                userOf[cur].totalEarnings += share;
                emit Payout(to, share, bytes32(uint256(0x55504C494E455F00) | (uint256(level + 1))));
                left -= share;
                
                // Move to next upline, but stop if we reach root user (has uplineId = 0 and id = 0)
                uint32 nextUpline = userOf[cur].uplineId;
                if (cur == 0) {
                    // We're at root user, stop here since root has no upline
                    break;
                }
                cur = nextUpline;
            } else {
                break;
            }
        }

        if (left > 0) {
            uint256 toPioneer = (left * PIONEER_REST_BPS) / 10000;
            uint256 toTreasury = left - toPioneer;

            if (toPioneer > 0) {
                (uint32 gIndex, uint32 startId, uint32 endId, uint32 count) = _currentPioneerWindow();
                if (count > 0) {
                    uint256 each = toPioneer / PIONEER_WINNERS;
                    
                    // Track winners for this lottery round to prevent duplicate wins
                    uint32[PIONEER_WINNERS] memory roundWinners;
                    uint8 uniqueWinners = 0;
                    
                    for (uint8 i = 0; i < PIONEER_WINNERS; i++) {
                        uint32 winnerId = _randomWinner(newId, account, i, startId, endId);
                        
                        // Check if this user has already won in this round
                        bool alreadyWon = false;
                        for (uint8 j = 0; j < uniqueWinners; j++) {
                            if (roundWinners[j] == winnerId) {
                                alreadyWon = true;
                                break;
                            }
                        }
                        
                        if (!alreadyWon) {
                            // First time winning - award the prize to the user
                            roundWinners[uniqueWinners] = winnerId;
                            uniqueWinners++;
                            
                            address winner = userOf[winnerId].account;
                            usdt.safeTransfer(winner, each);
                            userOf[winnerId].totalEarnings += each;
                            emit PioneerWin(winner, gIndex, each);
                            emit Payout(winner, each, "PIONEER");
                        } else {
                            // User already won in this round - redirect to treasury
                            toTreasury += each;
                        }
                    }
                    
                    uint256 distributed = each * PIONEER_WINNERS;
                    if (toPioneer > distributed) {
                        toTreasury += (toPioneer - distributed);
                    }
                } else {
                    toTreasury += toPioneer;
                }
            }

            if (toTreasury > 0) {
                usdt.safeTransfer(treasuryWallet, toTreasury);
                emit Payout(treasuryWallet, toTreasury, "TREASURY_REST");
            }
        }
    }

    function _currentPioneerWindow() internal view returns (uint32 gIndex, uint32 startId, uint32 endId, uint32 count) {
        if (totalUsers == 0) {
            return (0, 0, 0, 0);
        }
        gIndex = (totalUsers - 1) / PIONEER_GROUP_SIZE;
        startId = gIndex * PIONEER_GROUP_SIZE + 1;
        endId = totalUsers < (startId + PIONEER_GROUP_SIZE - 1) ? totalUsers : (startId + PIONEER_GROUP_SIZE - 1);
        count = endId >= startId ? (endId - startId + 1) : 0;
    }

    function _randomWinner(
        uint32 newId,
        address account,
        uint8 salt,
        uint32 startId,
        uint32 endId
    ) internal view returns (uint32) {
        bytes32 prev = block.number > 0 ? blockhash(block.number - 1) : bytes32(0);
        uint256 seed = uint256(keccak256(abi.encodePacked(newId, account, prev, block.timestamp, salt)));
        uint32 span = endId - startId + 1;
        uint32 offset = uint32(seed % span);
        return startId + offset;
    }

    function _nextRandomId() internal returns (uint32) {
        totalUsers++;
        return totalUsers;
    }

    function _performRegistration(uint32 uplineId, string memory nickname) internal {
        require(idOf[msg.sender] == 0, "ALREADY_REGISTERED");
        require(bytes(nickname).length > 0, "EMPTY_NICKNAME");
        
        bytes32 nickHash = keccak256(bytes(nickname));
        require(nicknameOwnerId[nickHash] == 0, "NICKNAME_TAKEN");
        
        if (uplineId > 0) {
            require(userOf[uplineId].account != address(0), "UPLINE_NOT_EXISTS");
        }
        
        // Transfer registration fee
        usdt.safeTransferFrom(msg.sender, address(this), REG_PRICE);
        
        // Generate new ID
        uint32 newId = _nextRandomId();
        
        // Create user record
        User storage newUser = userOf[newId];
        newUser.account = msg.sender;
        newUser.id = newId;
        newUser.uplineId = uplineId;
        newUser.nickname = nickname;
        newUser.directs = 0;
        newUser.teamSize = 0;
        newUser.activeUntil = 0;
        newUser.totalEarnings = 0;
        
        // Update mappings
        idOf[msg.sender] = newId;
        nicknameOwnerId[nickHash] = newId;
        
        // Update upline stats
        if (uplineId > 0) {
            userOf[uplineId].directs++;
            // Update team size for all uplines
            uint32 cur = uplineId;
            while (cur != 0) {
                userOf[cur].teamSize++;
                cur = userOf[cur].uplineId;
            }
        }
        
        // Distribute registration fees
        _distributeRegistration(newId, msg.sender, uplineId);
        
        // Emit event
        emit Registered(msg.sender, newId, uplineId, nickname);
    }

    function register(uint32 uplineId, string calldata nickname) external {
        _performRegistration(uplineId, nickname);
    }

    function registerByUplineNick(string calldata uplineNick, string calldata nickname) external {
        bytes32 uplineNickHash = keccak256(bytes(uplineNick));
        uint32 uplineId = nicknameOwnerId[uplineNickHash];
        require(uplineId > 0, "UPLINE_NICK_NOT_FOUND");
        
        _performRegistration(uplineId, nickname);
    }
}
