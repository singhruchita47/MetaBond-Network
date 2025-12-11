// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC20 {
    function transferFrom(address sender, address receiver, uint256 amount) external returns (bool);
    function transfer(address receiver, uint256 amount) external returns (bool);
}

/**
 * @title MetaBond Network
 * @notice A decentralized bond creation protocol where users lock tokens and earn yield after maturity.
 */
contract MetaBondNetwork {

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // ----------------------------------------
    // STRUCTS
    // ----------------------------------------

    struct Bond {
        address user;
        address token;
        uint256 principal;
        uint256 yieldRate;      // percentage yield (e.g., 10 = 10%)
        uint256 startTime;
        uint256 maturityTime;
        bool withdrawn;
    }

    // ----------------------------------------
    // STATE VARIABLES
    // ----------------------------------------

    uint256 public bondCount;
    mapping(uint256 => Bond) public bonds;

    // ----------------------------------------
    // EVENTS
    // ----------------------------------------

    event BondCreated(
        uint256 indexed bondId,
        address indexed user,
        address token,
        uint256 principal,
        uint256 yieldRate,
        uint256 maturityTime
    );

    event BondWithdrawn(
        uint256 indexed bondId,
        address indexed user,
        uint256 totalPayout
    );

    // ----------------------------------------
    // CORE FUNCTIONS
    // ----------------------------------------

    /**
     * @notice Create a new bond by locking tokens
     * @param token ERC20 token address to lock
     * @param principal Amount to lock
     * @param yieldRate Interest percentage
     * @param maturityTime Unix timestamp when withdrawal becomes available
     */
    function createBond(
        address token,
        uint256 principal,
        uint256 yieldRate,
        uint256 maturityTime
    ) external returns (uint256) {
        require(principal > 0, "Principal must be >0");
        require(yieldRate > 0, "Yield rate must be >0");
        require(maturityTime > block.timestamp, "Maturity must be future");

        IERC20(token).transferFrom(msg.sender, address(this), principal);

        bonds[bondCount] = Bond({
            user: msg.sender,
            token: token,
            principal: principal,
            yieldRate: yieldRate,
            startTime: block.timestamp,
            maturityTime: maturityTime,
            withdrawn: false
        });

        emit BondCreated(
            bondCount,
            msg.sender,
            token,
            principal,
            yieldRate,
            maturityTime
        );

        bondCount++;
        return bondCount - 1;
    }

    /**
     * @notice Withdraw principal + yield after maturity
     * @param bondId ID of the bond
     */
    function withdrawBond(uint256 bondId) external {
        Bond storage b = bonds[bondId];
        require(msg.sender == b.user, "Not bond owner");
        require(!b.withdrawn, "Already withdrawn");
        require(block.timestamp >= b.maturityTime, "Bond not matured");

        b.withdrawn = true;

        uint256 yieldAmount = (b.principal * b.yieldRate) / 100;
        uint256 total = b.principal + yieldAmount;

        IERC20(b.token).transfer(msg.sender, total);

        emit BondWithdrawn(bondId, msg.sender, total);
    }

    // ----------------------------------------
    // VIEW FUNCTIONS
    // ----------------------------------------

    function getBond(uint256 bondId)
        external
        view
        returns (
            address user,
            address token,
            uint256 principal,
            uint256 yieldRate,
            uint256 startTime,
            uint256 maturityTime,
            bool withdrawn
        )
    {
        Bond memory b = bonds[bondId];
        return (
            b.user,
            b.token,
            b.principal,
            b.yieldRate,
            b.startTime,
            b.maturityTime,
            b.withdrawn
        );
    }
}
