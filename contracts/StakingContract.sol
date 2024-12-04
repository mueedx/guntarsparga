// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SimpleERC20.sol";

contract Staking {
    SimpleERC20 public token;
    address public owner;
    uint256 public rewardRate; // Reward rate in tokens per token staked
    uint256 public stakingDuration = 30 days;

    struct Stake {
        uint256 amount;
        uint256 startTime;
        bool withdrawn;
    }

    mapping(address => Stake) public stakes;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 reward);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    constructor(SimpleERC20 _token, uint256 _rewardRate) {
        token = _token;
        owner = msg.sender;
        rewardRate = _rewardRate;
    }

    function stake(uint256 _amount) public {
        require(_amount > 0, "Cannot stake zero tokens");
        require(token.balanceOf(msg.sender) >= _amount, "Not enough tokens");
        require(stakes[msg.sender].amount == 0, "Already staking");

        token.transferFrom(msg.sender, address(this), _amount);
        stakes[msg.sender] = Stake(_amount, block.timestamp, false);

        emit Staked(msg.sender, _amount);
    }

    function withdraw() public {
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No active stake");
        require(!userStake.withdrawn, "Already withdrawn");
        require(block.timestamp >= userStake.startTime + stakingDuration, "Staking period not over");

        uint256 reward = (userStake.amount * rewardRate) / 1e18;
        uint256 totalAmount = userStake.amount + reward;

        userStake.withdrawn = true;
        token.transfer(msg.sender, totalAmount);

        emit Withdrawn(msg.sender, userStake.amount, reward);
    }

    function addRewards(uint256 _amount) external onlyOwner {
        token.transferFrom(msg.sender, address(this), _amount);
    }
}