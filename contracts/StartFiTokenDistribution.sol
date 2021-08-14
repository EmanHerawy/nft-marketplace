// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.7;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interface/IERC20.sol";

/**
 * @author Eman Herawy, StartFi Team
 *@title StartFiTokenDistribution
 * 
 */
contract StartFiTokenDistribution is  Ownable ,Pausable,ReentrancyGuard {
  
  /******************************************* decalrations go here ********************************************************* */
	
	address[2] public tokenOwners ; /* Tracks distributions mapping (iterable) */ 
	uint256 public TGEDate = 0; /* Date From where the distribution starts (TGE) */
	
	uint256 constant public month = 30 days;
	uint256 constant public year = 365 days;
	uint256 public lastDateDistribution = 0;
  
	
	mapping(address => DistributionStep[]) private _distributions; /* Distribution object */
	
	address public erc20;

	struct DistributionStep {
		uint256 amountAllocated;
		uint256 currentAllocated;
		uint256 unlockDay;
		uint256 amountSent;
	}

// events 




 /******************************************* constructor goes here ********************************************************* */

 	constructor(address _erc20, uint256 _time,address _owner){
		erc20=_erc20;
		TGEDate =	_time<block.timestamp?block.timestamp:_time;
		transferOwnership(_owner);
		// /* Seed */
		// setInitialDistribution(0xc97, 3000000, 0 /* No Lock */);
		// setInitialDistribution(0xc97, 1500000, 1 * month); /* After 1 Month */
		// setInitialDistribution(0xc97, 1500000, 2 * month); /* After 2 Months */
		// setInitialDistribution(0xc97, 1500000, 3 * month); /* After 3 Months */
		// setInitialDistribution(0xc97, 1500000, 4 * month); /* After 4 Months */
		// setInitialDistribution(0xc97, 1500000, 5 * month); /* After 5 Months */
		// setInitialDistribution(0xc97, 1500000, 6 * month); /* After 6 Months */
		// setInitialDistribution(0xc97, 1500000, 7 * month); /* After 7 Months */
		// setInitialDistribution(0xc97, 1500000, 8 * month); /* After 8 Months */
		// setInitialDistribution(0xc97, 1500000, 9 * month); /* After 9 Months */
		// setInitialDistribution(0xc97, 1500000, 10 * month); /* After 10 Months */

		// /* Private Sale */
		// setInitialDistribution(0xc1, 6875000, 0 /* No Lock */);
		// setInitialDistribution(0xc1, 6875000, 1 * month); /* After 1 Month */
		// setInitialDistribution(0xc1, 6875000, 2 * month); /* After 2 Months */
		// setInitialDistribution(0xc1, 6875000, 3 * month); /* After 3 Months */
		// setInitialDistribution(0xc1, 6875000, 4 * month); /* After 4 Months */
		// setInitialDistribution(0xc1, 6875000, 5 * month); /* After 5 Months */
		// setInitialDistribution(0xc1, 6875000, 6 * month); /* After 6 Months */
		// setInitialDistribution(0xc1, 6875000, 7 * month); /* After 7 Months */
		// setInitialDistribution(0xc1, 6875000, 8 * month); /* After 8 Months */
		// setInitialDistribution(0xc1, 6875000, 9 * month); /* After 9 Months */
		// setInitialDistribution(0xc1, 6875000, 10 * month); /* After 10 Months */

		// /* Team & Advisors */
		// setInitialDistribution(0x5d, 2500000, year);
		// setInitialDistribution(0x5d, 2500000, year.add(3 * month)); /* After 3 Month */
		// setInitialDistribution(0x5d, 2500000, year.add(6 * month)); /* After 6 Month */
		// setInitialDistribution(0x5d, 2500000, year.add(9 * month)); /* After 9 Month */

		// /* Network Growth Growth */
		// setInitialDistribution(0x36, 3000000, 0 /* No Lock */);
		// setInitialDistribution(0x36, 1000000, 1 * month); /* After 1 Month */
		// setInitialDistribution(0x36, 1000000, 2 * month); /* After 2 Months */
		// setInitialDistribution(0x36, 1000000, 3 * month); /* After 3 Months */
		// setInitialDistribution(0x36, 1000000, 4 * month); /* After 4 Months */
		// setInitialDistribution(0x36, 1000000, 5 * month); /* After 5 Months */
		// setInitialDistribution(0x36, 1000000, 6 * month); /* After 6 Months */
		// setInitialDistribution(0x36, 1000000, 7 * month); /* After 7 Months */
		// setInitialDistribution(0x36, 1000000, 8 * month); /* After 8 Months */
		// setInitialDistribution(0x36, 1000000, 9 * month); /* After 9 Months */
		// setInitialDistribution(0x36, 1000000, 10 * month); /* After 10 Months */
		// setInitialDistribution(0x36, 1000000, 11 * month); /* After 11 Months */
		// setInitialDistribution(0x36, 1000000, 12 * month); /* After 12 Months */

		// /* Liquidity Fund */
		// setInitialDistribution(0xDD, 5000000, 0 /* No Lock */);
		// setInitialDistribution(0xDD, 2000000, 1 * month); /* After 1 Month */
		// setInitialDistribution(0xDD, 2000000, 2 * month); /* After 2 Months */
		// setInitialDistribution(0xDD, 2000000, 3 * month); /* After 3 Months */
		// setInitialDistribution(0xDD, 2000000, 4 * month); /* After 4 Months */
		// setInitialDistribution(0xDD, 2000000, 5 * month); /* After 5 Months */
		// setInitialDistribution(0xDD, 1500000, 6 * month); /* After 6 Months */
		// setInitialDistribution(0xDD, 1000000, 7 * month); /* After 7 Months */
		// setInitialDistribution(0xDD, 1000000, 8 * month); /* After 8 Months */
		// setInitialDistribution(0xDD, 1000000, 9 * month); /* After 9 Months */
		// setInitialDistribution(0xDD, 1000000, 10 * month); /* After 10 Months */
		// setInitialDistribution(0xDD, 1000000, 11 * month); /* After 11 Months */
		// setInitialDistribution(0xDD, 1000000, 12 * month); /* After 12 Months */

		// /* Foundational Reserve Fund */
		// setInitialDistribution(0x20, 2500000, year);
		// setInitialDistribution(0x20, 2500000, year.add(3 * month)); /* After 3 Month */
		// setInitialDistribution(0x20, 2500000, year.add(6 * month)); /* After 6 Month */
		// setInitialDistribution(0x20, 2500000, year.add(9 * month)); /* After 9 Month */
		
		// test 
		//tokenOwners.push(_address);
		_setInitialDistribution(msg.sender, 10, 0 /* No Lock */);
		_setInitialDistribution(_owner, 10, 0 /* No Lock */);
		_setInitialDistribution(msg.sender, 50, 10 * month); /* After 1 Month */
		_setInitialDistribution(_owner, 100, 10 * month); /* After 1 Month */
		tokenOwners[0]=msg.sender;
		tokenOwners[1]=_owner;
	}

  /******************************************* modifiers go here ********************************************************* */
  
  
  /******************************************* rescue function ********************************************************* */

	function safeGuardAllTokens(address _address) external onlyOwner whenPaused  { /* In case of needed urgency for the sake of contract bug */
		require(IERC20(erc20).transfer(_address, IERC20(erc20).balanceOf(address(this))));
	}


  /******************************************* read state functions go here ********************************************************* */

function getBeneficiaryPoolLength(address beneficary) view public returns (uint256 arrayLneght) {
	return _distributions[beneficary].length;
}
function getBeneficiaryPoolInfo(address beneficary, uint256 index) view external returns (	uint256 amountAllocated,
		uint256 currentAllocated,
		uint256 unlockDay,
		uint256 amountSent) {
			amountAllocated= _distributions[beneficary][index]. amountAllocated;
			currentAllocated=_distributions[beneficary][index].  currentAllocated;
			unlockDay= _distributions[beneficary][index]. unlockDay;
			amountSent= _distributions[beneficary][index].amountSent;
}
  /******************************************* state functions go here ********************************************************* */



    /**
     * @dev Pauses contract.
     *
     * 
     *
     * Requirements:
     *
     * - the caller must be the owner.
     */
    function pause() public virtual onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses contract.
     *
     * 
     *
     * Requirements:
     *
     * - the caller must be the owner.
     */
    function unpause() public virtual onlyOwner whenPaused {
        _unpause();
    }
	/**
	*   Should allow any address to trigger it, but since the calls are atomic it should do only once per day
	 */

	function triggerTokenSend() external whenNotPaused nonReentrant {
	
		/* TGE has not started */
		require(block.timestamp > TGEDate, "TGE still has not started");
		/* Test that the call be only done once per day */
		require(block.timestamp - lastDateDistribution > 1 days , "Can only be called once a day");
		lastDateDistribution = block.timestamp;
		/* Go thru all tokenOwners */
		for(uint i = 0; i < tokenOwners.length; i++) {
			/* Get Address Distribution */
			DistributionStep[] memory d = _distributions[tokenOwners[i]];
			/* Go thru all distributions array */
			for(uint j = 0; j < d.length; j++){
				if( (block.timestamp-TGEDate > d[j].unlockDay) /* Verify if unlockDay has passed */
					&& (d[j].currentAllocated > 0) /* Verify if currentAllocated > 0, so that address has tokens to be sent still */
				){
					uint256 sendingAmount;
					sendingAmount = d[j].currentAllocated;
					_distributions[tokenOwners[i]][j].currentAllocated = _distributions[tokenOwners[i]][j].currentAllocated-sendingAmount;
					_distributions[tokenOwners[i]][j].amountSent = _distributions[tokenOwners[i]][j].amountSent+sendingAmount;
					require(IERC20(erc20).transfer(tokenOwners[i], sendingAmount));
				}
			}
		}   
	}

	function _setInitialDistribution(address _address, uint256 _tokenAmount, uint256 _unlockDays) private  {
	
		/* Create DistributionStep Object */
		DistributionStep memory distributionStep = DistributionStep(_tokenAmount , _tokenAmount , _unlockDays, 0);
		/* Attach */
		_distributions[_address].push(distributionStep);

	}
}