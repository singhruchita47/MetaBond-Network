in basis points (e.g., 500 = 5%)
        uint256 totalSupply;
        uint256 availableSupply;
        bool isActive;
    }
    
    struct Investment {
        uint256 bondId;
        uint256 amount;
        uint256 purchaseDate;
        uint256 lastCouponClaim;
    }
    
    Events
    event BondIssued(
        uint256 indexed bondId,
        address indexed issuer,
        string bondName,
        uint256 faceValue,
        uint256 totalSupply
    );
    
    event BondPurchased(
        uint256 indexed bondId,
        address indexed investor,
        uint256 amount,
        uint256 purchaseDate
    );
    
    event CouponClaimed(
        uint256 indexed bondId,
        address indexed investor,
        uint256 couponAmount
    );
    
    /**
     * @dev Issue a new bond on the network
     * @param _bondName Name of the bond
     * @param _faceValue Face value of each bond unit
     * @param _maturityDate Unix timestamp of maturity date
     * @param _couponRate Annual coupon rate in basis points
     * @param _totalSupply Total supply of bond units
     */
    function issueBond(
        string memory _bondName,
        uint256 _faceValue,
        uint256 _maturityDate,
        uint256 _couponRate,
        uint256 _totalSupply
    ) external returns (uint256) {
        require(_faceValue > 0, "Face value must be greater than 0");
        require(_maturityDate > block.timestamp, "Maturity date must be in the future");
        require(_couponRate > 0 && _couponRate <= 10000, "Invalid coupon rate");
        require(_totalSupply > 0, "Total supply must be greater than 0");
        
        bondCounter++;
        
        bonds[bondCounter] = Bond({
            bondId: bondCounter,
            issuer: msg.sender,
            bondName: _bondName,
            faceValue: _faceValue,
            maturityDate: _maturityDate,
            couponRate: _couponRate,
            totalSupply: _totalSupply,
            availableSupply: _totalSupply,
            isActive: true
        });
        
        emit BondIssued(bondCounter, msg.sender, _bondName, _faceValue, _totalSupply);
        
        return bondCounter;
    }
    
    /**
     * @dev Purchase bonds from the network
     * @param _bondId ID of the bond to purchase
     * @param _amount Number of bond units to purchase
     */
    function purchaseBond(uint256 _bondId, uint256 _amount) external payable {
        Bond storage bond = bonds[_bondId];
        
        require(bond.isActive, "Bond is not active");
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= bond.availableSupply, "Insufficient bond supply");
        require(block.timestamp < bond.maturityDate, "Bond has matured");
        
        uint256 totalCost = bond.faceValue * _amount;
        require(msg.value >= totalCost, "Insufficient payment");
        
        Record investment
        if (investments[msg.sender][_bondId].amount == 0) {
            investments[msg.sender][_bondId] = Investment({
                bondId: _bondId,
                amount: _amount,
                purchaseDate: block.timestamp,
                lastCouponClaim: block.timestamp
            });
            bondInvestors[_bondId][msg.sender] = true;
        } else {
            investments[msg.sender][_bondId].amount += _amount;
        }
        
        Refund excess payment
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
        
        emit BondPurchased(_bondId, msg.sender, _amount, block.timestamp);
    }
    
    /**
     * @dev Claim coupon payments for held bonds
     * @param _bondId ID of the bond to claim coupons for
     */
    function claimCoupon(uint256 _bondId) external {
        Bond storage bond = bonds[_bondId];
        Investment storage investment = investments[msg.sender][_bondId];
        
        require(investment.amount > 0, "No investment found");
        require(bond.isActive, "Bond is not active");
        require(block.timestamp < bond.maturityDate, "Bond has matured");
        
        uint256 timeElapsed = block.timestamp - investment.lastCouponClaim;
        require(timeElapsed >= 30 days, "Coupon claim period not reached");
        
        Transfer coupon payment from issuer
        payable(msg.sender).transfer(couponPayment);
        
        emit CouponClaimed(_bondId, msg.sender, couponPayment);
    }
    
    /**
     * @dev Get bond details
     * @param _bondId ID of the bond
     */
    function getBondDetails(uint256 _bondId) external view returns (
        address issuer,
        string memory bondName,
        uint256 faceValue,
        uint256 maturityDate,
        uint256 couponRate,
        uint256 totalSupply,
        uint256 availableSupply,
        bool isActive
    ) {
        Bond memory bond = bonds[_bondId];
        return (
            bond.issuer,
            bond.bondName,
            bond.faceValue,
            bond.maturityDate,
            bond.couponRate,
            bond.totalSupply,
            bond.availableSupply,
            bond.isActive
        );
    }
    
    /**
     * @dev Get investment details for an investor
     * @param _investor Address of the investor
     * @param _bondId ID of the bond
     */
    function getInvestmentDetails(address _investor, uint256 _bondId) external view returns (
        uint256 amount,
        uint256 purchaseDate,
        uint256 lastCouponClaim
    ) {
        Investment memory investment = investments[_investor][_bondId];
        return (
            investment.amount,
            investment.purchaseDate,
            investment.lastCouponClaim
        );
    }
    
    /**
     * @dev Get total number of bonds issued
     */
    function getTotalBonds() external view returns (uint256) {
        return bondCounter;
    }
}
// 
End
// 
