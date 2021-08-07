// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.8.0;
pragma experimental SMTChecker;
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/**
 * @author Eman Herawy, StartFi Team
 *@title  Startfi Reputation contract
 * desc contract to mamange the reputation for startfi users
 */
contract StartFiReputation  is Context, AccessControlEnumerable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    mapping (address=>uint256) private userReputation;
  constructor ()  {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());
  }
 /**
        * @dev this function is to mint reputation points for the "to"
        * @notice only called by caller in the minter role
        * @param to : reciepiant address
        * @param amount : points to be added to the " to " balance
        * @return balance : "to" current reputation balance
      */
  function mintReputation(address to, uint256 amount)  external returns(uint256 balance) {
            require(hasRole(MINTER_ROLE, _msgSender()), "StartFiReputation: must have minter role to mint");
            balance=userReputation[to] + amount;
            _setReputation(to, balance);
  }
   /**
        * @dev this function is to burn reputation points for the "to"
        * @notice only called by caller in the burner role
        * @param to : reciepiant address
        * @param amount : points to be subtract to the " to " balance
        * @return balance : "to" current reputation balance
      */

  function burnReputation(address to, uint256 amount)  external returns(uint256 balance) {
        require(hasRole(BURNER_ROLE, _msgSender()), "StartFiReputation: must have burn role to burn reputation");
        require(userReputation[to]>=amount, "StartFiReputation: Not enought balance");
        balance=userReputation[to] - amount;
        _setReputation(to, balance);
  }
  function _setReputation(address to, uint256 amount) internal  {
      userReputation[to]=amount;
  }
 
 function getUserReputation(address user) view external returns (uint256 balance) {
      balance=userReputation[user];
 }

}
