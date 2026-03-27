// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title OpinionChain — AI-Analyzed, Immutable Opinion Ledger
/// @notice Users record opinions on-chain. AI analysis metadata is stored alongside.
/// @dev Each user maintains their own opinion chain with linked block hashes.
contract OpinionChain {

    // ─── STRUCTS ─────────────────────────────────────────────────
    struct OpinionBlock {
        uint256 index;          // Position in this user's chain
        uint256 timestamp;      // Block timestamp
        string  question;       // The question answered
        string  category;       // Philosophy, Ethics, Society, etc.
        bytes32 answerHash;     // keccak256 of the answer (privacy-preserving)
        string  aiStyle;        // AI-generated thinking style label e.g. "Pragmatic Humanist"
        bytes32 contentHash;    // keccak256(question + answerHash + aiStyle + prevHash)
        bytes32 prevHash;       // Hash of the previous block (links the chain)
        uint256 nonce;          // Proof-of-work nonce found by frontend
    }

    struct UserProfile {
        uint256 opinionCount;
        string  latestArchetype;   // AI-determined thinking archetype
        uint256 firstOpinionAt;
        uint256 lastOpinionAt;
    }

    // ─── STATE ───────────────────────────────────────────────────
    mapping(address => OpinionBlock[])  private userChain;
    mapping(address => UserProfile)     public  userProfiles;
    mapping(address => mapping(uint256 => bytes32)) private blockHashes;

    uint256 public totalOpinions;
    uint256 public totalUsers;

    // ─── EVENTS ──────────────────────────────────────────────────
    event OpinionRecorded(
        address indexed user,
        uint256 indexed blockIndex,
        string  category,
        string  aiStyle,
        bytes32 contentHash,
        uint256 timestamp
    );
    event ArchetypeUpdated(address indexed user, string archetype);
    event ChainVerified(address indexed user, bool isValid, uint256 length);

    // ─── ERRORS ──────────────────────────────────────────────────
    error EmptyAnswer();
    error EmptyQuestion();
    error InvalidPrevHash(bytes32 expected, bytes32 provided);
    error InvalidBlockIndex(uint256 expected, uint256 provided);

    // ─── RECORD OPINION ──────────────────────────────────────────

    /// @notice Record a new opinion block onto your personal chain
    /// @param _question   The question being answered
    /// @param _category   Topic category (philosophy, ethics, society, tech, personal)
    /// @param _answerHash keccak256 of the raw answer text (keeps answer private on-chain)
    /// @param _aiStyle    The AI-generated thinking style label for this answer
    /// @param _archetype  AI-determined overall thinking archetype
    /// @param _nonce      Proof-of-work nonce found by the frontend miner
    /// @param _prevHash   Hash of the previous block (must match chain head)
    function recordOpinion(
        string  memory _question,
        string  memory _category,
        bytes32        _answerHash,
        string  memory _aiStyle,
        string  memory _archetype,
        uint256        _nonce,
        bytes32        _prevHash
    ) external {
        if (bytes(_question).length == 0)  revert EmptyQuestion();
        if (bytes(_aiStyle).length  == 0)  revert EmptyAnswer();

        address user = msg.sender;
        OpinionBlock[] storage chain = userChain[user];
        uint256 idx = chain.length;

        // Verify prev hash linkage
        bytes32 expectedPrev = idx == 0
            ? bytes32(0)
            : blockHashes[user][idx - 1];

        if (_prevHash != expectedPrev)
            revert InvalidPrevHash(expectedPrev, _prevHash);

        // Build content hash — this is what the frontend mines against
        bytes32 contentHash = keccak256(abi.encodePacked(
            idx,
            block.timestamp,
            _question,
            _answerHash,
            _aiStyle,
            _prevHash,
            _nonce
        ));

        // Store the block
        chain.push(OpinionBlock({
            index:       idx,
            timestamp:   block.timestamp,
            question:    _question,
            category:    _category,
            answerHash:  _answerHash,
            aiStyle:     _aiStyle,
            contentHash: contentHash,
            prevHash:    _prevHash,
            nonce:       _nonce
        }));

        blockHashes[user][idx] = contentHash;

        // Update profile
        UserProfile storage profile = userProfiles[user];
        if (profile.opinionCount == 0) {
            profile.firstOpinionAt = block.timestamp;
            totalUsers++;
        }
        profile.opinionCount++;
        profile.lastOpinionAt  = block.timestamp;

        if (bytes(_archetype).length > 0) {
            profile.latestArchetype = _archetype;
            emit ArchetypeUpdated(user, _archetype);
        }

        totalOpinions++;

        emit OpinionRecorded(user, idx, _category, _aiStyle, contentHash, block.timestamp);
    }

    // ─── READ FUNCTIONS ──────────────────────────────────────────

    /// @notice Get a specific block from a user's chain
    function getBlock(address _user, uint256 _index) external view returns (
        uint256 index,
        uint256 timestamp,
        string  memory question,
        string  memory category,
        bytes32 answerHash,
        string  memory aiStyle,
        bytes32 contentHash,
        bytes32 prevHash,
        uint256 nonce
    ) {
        OpinionBlock storage b = userChain[_user][_index];
        return (
            b.index, b.timestamp, b.question, b.category,
            b.answerHash, b.aiStyle, b.contentHash, b.prevHash, b.nonce
        );
    }

    /// @notice Get the number of opinions a user has recorded
    function getChainLength(address _user) external view returns (uint256) {
        return userChain[_user].length;
    }

    /// @notice Get the latest block hash for a user (used to link the next block)
    function getLatestHash(address _user) external view returns (bytes32) {
        uint256 len = userChain[_user].length;
        if (len == 0) return bytes32(0);
        return blockHashes[_user][len - 1];
    }

    /// @notice Verify entire chain integrity for a user
    /// @dev Walks the chain and confirms each prevHash matches the previous block's contentHash
    function verifyChain(address _user) external returns (bool isValid) {
        OpinionBlock[] storage chain = userChain[_user];
        if (chain.length == 0) {
            emit ChainVerified(_user, true, 0);
            return true;
        }

        // Genesis block must have prevHash == 0
        if (chain[0].prevHash != bytes32(0)) {
            emit ChainVerified(_user, false, chain.length);
            return false;
        }

        for (uint256 i = 1; i < chain.length; i++) {
            if (chain[i].prevHash != chain[i-1].contentHash) {
                emit ChainVerified(_user, false, chain.length);
                return false;
            }
        }

        emit ChainVerified(_user, true, chain.length);
        return true;
    }

    /// @notice Get all AI thinking styles recorded by a user (their evolution over time)
    function getThinkingHistory(address _user) external view returns (
        string[] memory styles,
        string[] memory categories,
        uint256[] memory timestamps
    ) {
        OpinionBlock[] storage chain = userChain[_user];
        uint256 len = chain.length;
        styles     = new string[](len);
        categories = new string[](len);
        timestamps = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            styles[i]     = chain[i].aiStyle;
            categories[i] = chain[i].category;
            timestamps[i] = chain[i].timestamp;
        }
    }

    /// @notice Returns platform-wide stats
    function getStats() external view returns (
        uint256 _totalOpinions,
        uint256 _totalUsers
    ) {
        return (totalOpinions, totalUsers);
    }
}
