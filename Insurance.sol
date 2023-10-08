// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FlightDelayInsurance {
    address public owner;
    uint256 public premiumAmount;
    uint256 public payoutAmount;
    uint256 public delayThreshold; // Delay threshold in minutes
    uint256 public startTime;
    uint256 public endTime;
    
    mapping(address => uint256) public policyHolders; // Mapping of insured addresses to policy amounts
    mapping(address => uint256) public claimAmounts; // Mapping of addresses to claimed amounts
    mapping(address => uint256) public claimTimestamps; // Mapping of addresses to claim timestamps
    
    event PolicyPurchased(address indexed holder, uint256 amount);
    event FlightDelayed(address indexed holder, uint256 delayMinutes);
    event ClaimSubmitted(address indexed holder, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can execute this.");
        _;
    }
    
    constructor(
        uint256 _premiumAmount,
        uint256 _payoutAmount,
        uint256 _delayThresholdMinutes,
        uint256 _durationDays
    ) {
        owner = msg.sender;
        premiumAmount = _premiumAmount;
        payoutAmount = _payoutAmount;
        delayThreshold = _delayThresholdMinutes * 1 minutes;
        startTime = block.timestamp;
        endTime = startTime + _durationDays * 1 days;
    }

    function purchasePolicy() external payable {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Policy purchase is not allowed outside the coverage period.");
        require(msg.value == premiumAmount, "Premium amount does not match the policy premium.");
        
        policyHolders[msg.sender] += msg.value;
        
        emit PolicyPurchased(msg.sender, msg.value);
    }

    function checkFlightDelay(uint256 delayMinutes) external onlyOwner {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Coverage period has ended.");
        
        if (delayMinutes >= delayThreshold) {
            for (uint256 i = 0; i < address(this).balance; i++) {
                address holder = payable(address(i));
                if (policyHolders[holder] > 0 && claimTimestamps[holder] == 0) {
                    claimTimestamps[holder] = block.timestamp;
                    claimAmounts[holder] = payoutAmount;
                    emit FlightDelayed(holder, delayMinutes);
                }
            }
        }
    }

    function submitClaim() external {
        require(claimTimestamps[msg.sender] > 0, "No valid claim to submit.");
        
        uint256 claimTimestamp = claimTimestamps[msg.sender];
        require(block.timestamp >= claimTimestamp + 1 days, "Claims can only be submitted after 24 hours.");
        
        uint256 claimAmount = claimAmounts[msg.sender];
        claimAmounts[msg.sender] = 0;
        payable(msg.sender).transfer(claimAmount);
        
        emit ClaimSubmitted(msg.sender, claimAmount);
    }

    function withdrawUnclaimedPolicies() external onlyOwner {
        require(block.timestamp > endTime, "Coverage period has not ended yet.");
        
        for (uint256 i = 0; i < address(this).balance; i++) {
            address holder = payable(address(i));
            if (policyHolders[holder] > 0 && claimTimestamps[holder] == 0) {
                uint256 refundAmount = policyHolders[holder];
                policyHolders[holder] = 0;
                payable(holder).transfer(refundAmount);
            }
        }
    }
}
