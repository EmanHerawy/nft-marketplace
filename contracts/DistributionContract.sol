// SPDX-License-Identifier: AGPL-3.0-or-later

// pragma solidity 0.5.8; 

// contract ERC20Basic {
// 	function totalSupply() public view returns (uint256);
// 	function balanceOf(address who) public view returns (uint256);
// 	function transfer(address to, uint256 value) public returns (bool);
// 	event Transfer(address indexed from, address indexed to, uint256 value);
// }


// library SafeMath {

// 	function add(uint256 a, uint256 b) internal pure returns (uint256) {
// 		uint256 c = a + b;
// 		require(c >= a, "SafeMath: addition overflow");

// 		return c;
// 	}

// 	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
// 		return sub(a, b, "SafeMath: subtraction overflow");
// 	}

// 	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
// 		require(b <= a, errorMessage);
// 		uint256 c = a - b;

// 		return c;
// 	}

// 	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
// 		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
// 		// benefit is lost if 'b' is also tested.
// 		// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
// 		if (a == 0) {
// 			return 0;
// 		}

// 		uint256 c = a * b;
// 		require(c / a == b, "SafeMath: multiplication overflow");

// 		return c;
// 	}

// 	function div(uint256 a, uint256 b) internal pure returns (uint256) {
// 		return div(a, b, "SafeMath: division by zero");
// 	}

// 	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
// 		// Solidity only automatically asserts when dividing by 0
// 		require(b > 0, errorMessage);
// 		uint256 c = a / b;
// 		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

// 		return c;
// 	}


// 	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
// 		return mod(a, b, "SafeMath: modulo by zero");
// 	}


// 	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
// 		require(b != 0, errorMessage);
// 		return a % b;
// 	}
// }

// contract ERC20 is ERC20Basic {
//   function allowance(address owner, address spender) public view returns (uint256);
//   function transferFrom(address from, address to, uint256 value) public returns (bool);
//   function approve(address spender, uint256 value) public returns (bool);
//   event Approval(address indexed owner, address indexed spender, uint256 value);
// }

// contract Ownable {
// 	address public owner;
// 	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


// 	/**
// 	* @dev The Ownable constructor sets the original `owner` of the contract to the sender
// 	* account.
// 	*/
// 	constructor() public {
// 		owner = msg.sender;
// 	}

// 	/**
// 	* @dev Throws if called by any account other than the owner.
// 	*/
// 	modifier onlyOwner() {
// 		require(msg.sender == owner);
// 		_;
// 	}

// 	/**
// 	* @dev Allows the current owner to transfer control of the contract to a newOwner.
// 	* @param newOwner The address to transfer ownership to.
// 	*/
// 	function transferOwnership(address newOwner) public onlyOwner {
// 		require(newOwner != address(0));
// 		emit OwnershipTransferred(owner, newOwner);
// 		owner = newOwner;
// 	}
// }

// // File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

// /**
//  * @title Pausable
//  * @dev Base contract which allows children to implement an emergency stop mechanism.
//  */
// contract Pausable is Ownable {
// 	event Pause();
// 	event Unpause();

// 	bool public paused = false;


// 	/**
// 	* @dev Modifier to make a function callable only when the contract is not paused.
// 	*/
// 	modifier whenNotPaused() {
// 		require(!paused);
// 		_;
// 	}

// 	/**
// 	* @dev Modifier to make a function callable only when the contract is paused.
// 	*/
// 	modifier whenPaused() {
// 		require(paused);
// 		_;
// 	}

// 	/**
// 	* @dev called by the owner to pause, triggers stopped state
// 	*/
// 	function pause() onlyOwner whenNotPaused public {
// 		paused = true;
// 		emit Pause();
// 	}

// 	/**
// 	* @dev called by the owner to unpause, returns to normal state
// 	*/
// 	function unpause() onlyOwner whenPaused public {
// 		paused = false;
// 		emit Unpause();
// 	}
// }

// // This program is free software: you can redistribute it and/or modify
// // it under the terms of the GNU General Public License as published by
// // the Free Software Foundation, either version 3 of the License, or
// // (at your option) any later version.
// //
// // This program is distributed in the hope that it will be useful,
// // but WITHOUT ANY WARRANTY; without even the implied warranty of
// // MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// // GNU General Public License for more details.
// //
// // You should have received a copy of the GNU General Public License
// // along with this program.  If not, see <https://www.gnu.org/licenses/>.



// contract StartFiDistributionContract is Pausable {
// 	using SafeMath for uint256;

// 	uint256 constant public decimals = 1 ether;
// 	address[] public tokenOwners ; /* Tracks distributions mapping (iterable) */
// 	uint256 public TGEDate = 0; /* Date From where the distribution starts (TGE) */
// 	uint256 constant public month = 30 days;
// 	uint256 constant public year = 365 days;
// 	uint256 public lastDateDistribution = 0;
  
	
// 	mapping(address => DistributionStep[]) public distributions; /* Distribution object */
	
// 	ERC20 public erc20;

// 	struct DistributionStep {
// 		uint256 amountAllocated;
// 		uint256 currentAllocated;
// 		uint256 unlockDay;
// 		uint256 amountSent;
// 	}
	
// 	constructor() public{
		
// 		/* Seed */
// 		setInitialDistribution(0xc97, 3000000, 0 /* No Lock */);
// 		setInitialDistribution(0xc97, 1500000, 1 * month); /* After 1 Month */
// 		setInitialDistribution(0xc97, 1500000, 2 * month); /* After 2 Months */
// 		setInitialDistribution(0xc97, 1500000, 3 * month); /* After 3 Months */
// 		setInitialDistribution(0xc97, 1500000, 4 * month); /* After 4 Months */
// 		setInitialDistribution(0xc97, 1500000, 5 * month); /* After 5 Months */
// 		setInitialDistribution(0xc97, 1500000, 6 * month); /* After 6 Months */
// 		setInitialDistribution(0xc97, 1500000, 7 * month); /* After 7 Months */
// 		setInitialDistribution(0xc97, 1500000, 8 * month); /* After 8 Months */
// 		setInitialDistribution(0xc97, 1500000, 9 * month); /* After 9 Months */
// 		setInitialDistribution(0xc97, 1500000, 10 * month); /* After 10 Months */

// 		/* Private Sale */
// 		setInitialDistribution(0xc1, 6875000, 0 /* No Lock */);
// 		setInitialDistribution(0xc1, 6875000, 1 * month); /* After 1 Month */
// 		setInitialDistribution(0xc1, 6875000, 2 * month); /* After 2 Months */
// 		setInitialDistribution(0xc1, 6875000, 3 * month); /* After 3 Months */
// 		setInitialDistribution(0xc1, 6875000, 4 * month); /* After 4 Months */
// 		setInitialDistribution(0xc1, 6875000, 5 * month); /* After 5 Months */
// 		setInitialDistribution(0xc1, 6875000, 6 * month); /* After 6 Months */
// 		setInitialDistribution(0xc1, 6875000, 7 * month); /* After 7 Months */
// 		setInitialDistribution(0xc1, 6875000, 8 * month); /* After 8 Months */
// 		setInitialDistribution(0xc1, 6875000, 9 * month); /* After 9 Months */
// 		setInitialDistribution(0xc1, 6875000, 10 * month); /* After 10 Months */

// 		/* Team & Advisors */
// 		setInitialDistribution(0x5d, 2500000, year);
// 		setInitialDistribution(0x5d, 2500000, year.add(3 * month)); /* After 3 Month */
// 		setInitialDistribution(0x5d, 2500000, year.add(6 * month)); /* After 6 Month */
// 		setInitialDistribution(0x5d, 2500000, year.add(9 * month)); /* After 9 Month */

// 		/* Network Growth Growth */
// 		setInitialDistribution(0x36, 3000000, 0 /* No Lock */);
// 		setInitialDistribution(0x36, 1000000, 1 * month); /* After 1 Month */
// 		setInitialDistribution(0x36, 1000000, 2 * month); /* After 2 Months */
// 		setInitialDistribution(0x36, 1000000, 3 * month); /* After 3 Months */
// 		setInitialDistribution(0x36, 1000000, 4 * month); /* After 4 Months */
// 		setInitialDistribution(0x36, 1000000, 5 * month); /* After 5 Months */
// 		setInitialDistribution(0x36, 1000000, 6 * month); /* After 6 Months */
// 		setInitialDistribution(0x36, 1000000, 7 * month); /* After 7 Months */
// 		setInitialDistribution(0x36, 1000000, 8 * month); /* After 8 Months */
// 		setInitialDistribution(0x36, 1000000, 9 * month); /* After 9 Months */
// 		setInitialDistribution(0x36, 1000000, 10 * month); /* After 10 Months */
// 		setInitialDistribution(0x36, 1000000, 11 * month); /* After 11 Months */
// 		setInitialDistribution(0x36, 1000000, 12 * month); /* After 12 Months */

// 		/* Liquidity Fund */
// 		setInitialDistribution(0xDD, 5000000, 0 /* No Lock */);
// 		setInitialDistribution(0xDD, 2000000, 1 * month); /* After 1 Month */
// 		setInitialDistribution(0xDD, 2000000, 2 * month); /* After 2 Months */
// 		setInitialDistribution(0xDD, 2000000, 3 * month); /* After 3 Months */
// 		setInitialDistribution(0xDD, 2000000, 4 * month); /* After 4 Months */
// 		setInitialDistribution(0xDD, 2000000, 5 * month); /* After 5 Months */
// 		setInitialDistribution(0xDD, 1500000, 6 * month); /* After 6 Months */
// 		setInitialDistribution(0xDD, 1000000, 7 * month); /* After 7 Months */
// 		setInitialDistribution(0xDD, 1000000, 8 * month); /* After 8 Months */
// 		setInitialDistribution(0xDD, 1000000, 9 * month); /* After 9 Months */
// 		setInitialDistribution(0xDD, 1000000, 10 * month); /* After 10 Months */
// 		setInitialDistribution(0xDD, 1000000, 11 * month); /* After 11 Months */
// 		setInitialDistribution(0xDD, 1000000, 12 * month); /* After 12 Months */

// 		/* Foundational Reserve Fund */
// 		setInitialDistribution(0x20, 2500000, year);
// 		setInitialDistribution(0x20, 2500000, year.add(3 * month)); /* After 3 Month */
// 		setInitialDistribution(0x20, 2500000, year.add(6 * month)); /* After 6 Month */
// 		setInitialDistribution(0x20, 2500000, year.add(9 * month)); /* After 9 Month */
// 	}

// 	function setTokenAddress(address _tokenAddress) external onlyOwner whenNotPaused  {
// 		erc20 = ERC20(_tokenAddress);
// 	}
	
// 	function safeGuardAllTokens(address _address) external onlyOwner whenPaused  { /* In case of needed urgency for the sake of contract bug */
// 		require(erc20.transfer(_address, erc20.balanceOf(address(this))));
// 	}

// 	function setTGEDate(uint256 _time) external onlyOwner whenNotPaused  {
// 		TGEDate = _time;
// 	}

// 	/**
// 	*   Should allow any address to trigger it, but since the calls are atomic it should do only once per day
// 	 */

// 	function triggerTokenSend() external whenNotPaused  {
// 		/* Require TGE Date already been set */
// 		require(TGEDate != 0, "TGE date not set yet");
// 		/* TGE has not started */
// 		require(block.timestamp > TGEDate, "TGE still hasn´t started");
// 		/* Test that the call be only done once per day */
// 		require(block.timestamp.sub(lastDateDistribution) > 1 days, "Can only be called once a day");
// 		lastDateDistribution = block.timestamp;
// 		/* Go thru all tokenOwners */
// 		for(uint i = 0; i < tokenOwners.length; i++) {
// 			/* Get Address Distribution */
// 			DistributionStep[] memory d = distributions[tokenOwners[i]];
// 			/* Go thru all distributions array */
// 			for(uint j = 0; j < d.length; j++){
// 				if( (block.timestamp.sub(TGEDate) > d[j].unlockDay) /* Verify if unlockDay has passed */
// 					&& (d[j].currentAllocated > 0) /* Verify if currentAllocated > 0, so that address has tokens to be sent still */
// 				){
// 					uint256 sendingAmount;
// 					sendingAmount = d[j].currentAllocated;
// 					distributions[tokenOwners[i]][j].currentAllocated = distributions[tokenOwners[i]][j].currentAllocated.sub(sendingAmount);
// 					distributions[tokenOwners[i]][j].amountSent = distributions[tokenOwners[i]][j].amountSent.add(sendingAmount);
// 					require(erc20.transfer(tokenOwners[i], sendingAmount));
// 				}
// 			}
// 		}   
// 	}

// 	function setInitialDistribution(address _address, uint256 _tokenAmount, uint256 _unlockDays) internal onlyOwner whenNotPaused {
// 		/* Add tokenOwner to Eachable Mapping */
// 		bool isAddressPresent = false;

// 		/* Verify if tokenOwner was already added */
// 		for(uint i = 0; i < tokenOwners.length; i++) {
// 			if(tokenOwners[i] == _address){
// 				isAddressPresent = true;
// 			}
// 		}
// 		/* Create DistributionStep Object */
// 		DistributionStep memory distributionStep = DistributionStep(_tokenAmount * decimals, _tokenAmount * decimals, _unlockDays, 0);
// 		/* Attach */
// 		distributions[_address].push(distributionStep);

// 		/* If Address not present in array of iterable token owners */
// 		if(!isAddressPresent){
// 			tokenOwners.push(_address);
// 		}

// 	}
// }