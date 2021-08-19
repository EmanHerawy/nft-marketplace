// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.7;

/**
 * @author Eman Herawy, StartFi Team
 *@title  Startfi Reputation contract
 * desc contract to mamange the reputation for startfi users
 */
interface IStartFiReputation {
    function mintReputation(address to, uint256 amount) external returns (uint256 balance);
    function calcAndMintintReputation(address buyer, address seller, uint256 totalAmount) external returns (bool);

    function burnReputation(address to, uint256 amount) external returns (uint256 balance);

    function getUserReputation(address user) external view returns (uint256 balance);
}
