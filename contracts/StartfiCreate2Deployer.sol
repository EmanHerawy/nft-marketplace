// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Create2.sol';

/**
 * @title CREATE2 Deployer Smart Contract
 */

contract StartfiCreate2Deployer {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the
     * contract will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `value`.
     * - if `value` is non-zero, `bytecode` must have a `payable` constructor.
     */
    event Deployed(address addr, uint256 value, bytes32 salt);

    function deploy(
        uint256 value,
        bytes32 salt,
        bytes memory code
    ) external returns (address newAddress) {
        newAddress = Create2.deploy(value, salt, code);
        emit Deployed(newAddress, value, salt);
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}.
     * Any change in the `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 codeHash) public view returns (address) {
        return Create2.computeAddress(salt, codeHash);
    }
}
