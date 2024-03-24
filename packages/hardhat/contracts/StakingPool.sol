//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// Useful for debugging. Remove when deploying to a live network.
import "hardhat/console.sol";

// Use openzeppelin to inherit battle-tested implementations (ERC20, ERC721, etc)
// import "@openzeppelin/contracts/access/Ownable.sol";


interface IDepositContract {
	function deposit(
		bytes calldata pubkey,
		bytes calldata withdrawal_credentials,
		bytes calldata signature,
		bytes32 deposit_data_root
	) external payable;
}

/**
 * A smart contract that allows changing a state variable of the contract and tracking the changes
 * It also allows the owner to withdraw the Ether in the contract
 * @author BuidlGuidl
 */
contract StakingPool {
	
	// Keep track of how much ETH per investor
	mapping(address => uint256) public balances;
	// When the deposit to contract happened
	mapping(address => uint256) public depositTimestamp;
	// Keep track of if the investor has withdrawn their excess ETH from staking pool
	mapping(address => bool) public changeClaimed;
	// 
	mapping(bytes => bool) public pubkeysUsed;
	// Fill address
	IDepositContract public depositContract = IDepositContract(0x00000000219ab540356cBB839Cbe05303d7705Fa);

	// If wanted to take fee as admin
	// address payable public admin;
	address public admin;
	uint public end;
	bool public finalized;
	uint public totalInvested;
	uint public totalChange;

	event NewInvestor(
		address investor
	);

	// Admin creates staking pool and sets latest time to contribute
	constructor() {
		admin = msg.sender;
		end = block.timestamp + 7 days;
	}

	// New investor deposites ETH to staking pool
	function invest() external payable {
		require(block.timestamp < end, "too late to invest");

		if (balances[msg.sender] == 0) {
			emit NewInvestor(msg.sender);
		}

		// If wanted to take fee as admin
		// uint fee = msg.value * 1 / 100;
		// uint amountInvested = msg.value - fee;
		// admin.transfer(fee);
		// balances[msg.sender] += amountInvested;
		balances[msg.sender] += msg.value;
	}

	// Admin finalizes staking pool
	function finalize() external {
		require(finalized == false, "staking pool already finalized");
		require(block.timestamp >= end, "too early to finalize staking pool");

		finalized = true;
		totalInvested = address(this).balance;
		totalChange = totalInvested % 32 ether;
	}

	function claimChange() external {
		require(finalized == true, "staking pool has not been finalized");
		require(changeClaimed[msg.sender] == false, "change already claimed");
		require(balances[msg.sender] > 0, "not an investor");
		require(totalChange > 0, "no change left to claim");

		changeClaimed[msg.sender] = true;
		uint amount = totalChange * balances[msg.sender] / totalInvested;
		address payable investor = payable(msg.sender);
		investor.transfer(amount);
	}

	// Called by admin to stake 32 ETH
	// One call will stake 32 ETH
	function deposit(
		bytes calldata pubkey,
		bytes calldata withdrawal_credentials,
		bytes calldata signature,
		bytes32 deposit_data_root
	) external
	{
		require(finalized == true, 'too early');
		require(msg.sender == admin, 'only admin can stake ETH');
		require(address(this).balance >= 32 ether, 'not enough ETH to stake');
		require(pubkeysUsed[pubkey] == false, 'pubkey already used');

		depositContract.deposit{value: 32 ether}(
			pubkey,
			withdrawal_credentials,
			signature,
			deposit_data_root
		);
	}











	// State Variables
	address public immutable owner;
	string public greeting = "Building Unstoppable Apps!!!";
	bool public premium = false;
	uint256 public totalCounter = 0;
	mapping(address => uint) public userGreetingCounter;

	// Events: a way to emit log statements from smart contract that can be listened to by external parties
	event GreetingChange(
		address indexed greetingSetter,
		string newGreeting,
		bool premium,
		uint256 value
	);

/*
	// Constructor: Called once on contract deployment
	// Check packages/hardhat/deploy/00_deploy_your_contract.ts
	constructor(address _owner) {
		owner = _owner;
	}
*/

	// Modifier: used to define a set of rules that must be met before or after a function is executed
	// Check the withdraw() function
	modifier isOwner() {
		// msg.sender: predefined variable that represents address of the account that called the current function
		require(msg.sender == owner, "Not the Owner");
		_;
	}

	/**
	 * Function that allows anyone to change the state variable "greeting" of the contract and increase the counters
	 *
	 * @param _newGreeting (string memory) - new greeting to save on the contract
	 */
	function setGreeting(string memory _newGreeting) public payable {
		// Print data to the hardhat chain console. Remove when deploying to a live network.
		console.log(
			"Setting new greeting '%s' from %s",
			_newGreeting,
			msg.sender
		);

		// Change state variables
		greeting = _newGreeting;
		totalCounter += 1;
		userGreetingCounter[msg.sender] += 1;

		// msg.value: built-in global variable that represents the amount of ether sent with the transaction
		if (msg.value > 0) {
			premium = true;
		} else {
			premium = false;
		}

		// emit: keyword used to trigger an event
		emit GreetingChange(msg.sender, _newGreeting, msg.value > 0, msg.value);
	}

	/**
	 * Function that allows the owner to withdraw all the Ether in the contract
	 * The function can only be called by the owner of the contract as defined by the isOwner modifier
	 */
	function withdraw() public isOwner {
		(bool success, ) = owner.call{ value: address(this).balance }("");
		require(success, "Failed to send Ether");
	}

	/**
	 * Function that allows the contract to receive ETH
	 */
	receive() external payable {}
}
