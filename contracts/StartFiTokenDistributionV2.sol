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
contract StartFiTokenDistributionV2 is  Ownable ,Pausable,ReentrancyGuard {
  
  /******************************************* decalrations go here ********************************************************* */
	
	address[2] public tokenOwners ; /* Tracks distributions mapping (iterable) */ 
	uint256 public TGEDate = 0; /* Date From where the distribution starts (TGE) */  
	
	mapping(address => DistributionStep[]) private _distributions; /* Distribution object */
	
	address public erc20;

	struct DistributionStep {
		uint256 amountAllocated;
 		uint256 unlockTime;
		bool sent;
	}

// events 




 /******************************************* constructor goes here ********************************************************* */

 	constructor(address _erc20, uint256 _time,address _owner){
		erc20=_erc20;
		TGEDate =	_time<block.timestamp?block.timestamp:_time;
		transferOwnership(_owner);
		
		// test 
		//tokenOwners.push(_address);
		_setInitialDistribution(msg.sender, 10, 0 /* No Lock */);
		_setInitialDistribution(_owner, 10, 0 /* No Lock */);
		_setInitialDistribution(msg.sender, 50, 10 * 30 days); /* After 1 Month */
		_setInitialDistribution(_owner, 100, 10 * 30 days); /* After 1 Month */
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
	    uint256 unlockTime,
		bool sent) {
			amountAllocated= _distributions[beneficary][index]. amountAllocated;
			unlockTime= _distributions[beneficary][index]. unlockTime;
			sent= _distributions[beneficary][index].sent;
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
	
		/* Go thru all tokenOwners */
		for(uint i = 0; i < tokenOwners.length; i++) {
			/* Get Address Distribution */
			DistributionStep[] memory d = _distributions[tokenOwners[i]];
			/* Go thru all distributions array */
			for(uint j = 0; j < d.length; j++){
				if(!d[j].sent && d[j].unlockTime< block.timestamp) 
              {
					_distributions[tokenOwners[i]][j].sent = true;
					require(IERC20(erc20).transfer(tokenOwners[i],_distributions[tokenOwners[i]][j]. amountAllocated));
				}
			}
		}   
	}

	function _setInitialDistribution(address _address, uint256 _tokenAmount, uint256 _unlockDays) private  {
	
		/* Create DistributionStep Object */
		DistributionStep memory distributionStep = DistributionStep(_tokenAmount , block.timestamp+ _unlockDays, false);
		/* Attach */
		_distributions[_address].push(distributionStep);

	}
}