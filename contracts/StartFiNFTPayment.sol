// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.7;
import './interface/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './interface/IERC721RoyaltyMinter.sol';

/**
 * @author Eman Herawy, StartFi Team.
 *@title  StartFi NFT Payment contract.
 * [ desc ] : contract to handle minting NFT after the contract is approved to transfer the fees by STFI.
 */
contract StartFiNFTPayment is Ownable {
    /******************************************* decalrations go here ********************************************************* */
    uint256 _fees = 5;
    address private _NFTToken;
    address private _paymentToken;

    /******************************************* constructor goes here ********************************************************* */

    constructor(address _NFTContract, address _paymentContract) {
        _NFTToken = _NFTContract;
        _paymentToken = _paymentContract;
    }

    /******************************************* read state functions go here ********************************************************* */

    /**
     * @dev :wrap function to get the total allowed number of tokens that this contract can transfer from the given account .

    * @param owner: owner address.
    * @return allowed number of tokens that this contract can transfer from the owner account.
     */
    function _getAllowance(address owner) private view returns (uint256) {
        return IERC20(_paymentToken).allowance(owner, address(this));
    }

    /**
     * @dev :  function to get all the public info about the contract.
     * @return NFT token address, utility token address, minting fees.
     */
    function info()
        external
        view
        returns (
            address,
            address,
            uint256
        )
    {
        return (_NFTToken, _paymentToken, _fees);
    }

    /******************************************* state functions go here ********************************************************* */

    /**
     * @notice  caller should approve the contract to transfer the fees first.
     * @dev : tokens are transfered directly to the admin wallet . Called by the token issuer .
     * @param to: NFT issuer.
     * @param _tokenURI: serialized json object that has the following data ( category, name , desc , tages, ipfs hash).
     * @param share: eg. 25.
     * @param base: eg. 10 .
     * @return token id .
     */
    function MintNFTWithRoyalty(
        address to,
        string memory _tokenURI,
        uint8 share,
        uint8 base
    ) external returns (uint256) {
        require(_getAllowance(_msgSender()) >= _fees, 'Not enough fees paid');
        IERC20(_paymentToken).transferFrom(_msgSender(), owner(), _fees);
        return IERC721RoyaltyMinter(_NFTToken).mintWithRoyalty(to, _tokenURI, share, base);
    }

    /**
     * @notice  caller should sing a message to premit the contract to transfer the fees .
     * @dev : tokens are transfered directly to the admin wallet . Called by the token issuer .
     * @param to: NFT issuer.
     * @param _tokenURI: serialized json object that has the following data ( category, name , desc , tages, ipfs hash).
     * @param share: eg. 25.
     * @param base: eg. 10 .
     * @param deadline:  must be timestamp in future .
     * @param v needed to recover the public key
     * @param r : normal output of an ECDSA signature
     * @param s: normal output of an ECDSA signature
     * `v`, `r` and `s` must be valid `secp256k1` signature from `owner`  or 'approved for all' account over EIP712-formatted function arguments.
     * @return token id .
     */
    function MintNFTWithRoyaltyPremit(
        address to,
        string memory _tokenURI,
        uint8 share,
        uint8 base,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256) {
        IERC20(_paymentToken).permit(_msgSender(), address(this), _fees, deadline, v, r, s);
        require(_getAllowance(_msgSender()) >= _fees, 'Not enough fees paid');
        IERC20(_paymentToken).transferFrom(_msgSender(), owner(), _fees);
        return IERC721RoyaltyMinter(_NFTToken).mintWithRoyalty(to, _tokenURI, share, base);
    }

    /**
     * @notice  caller should approve the contract to transfer the fees first.
     * @dev : tokens are transfered directly to the admin wallet. Called by the token issuer .
     * @param to: NFT issuer.
     * @param _tokenURI: serialized json object that has the following data ( category, name , desc , tages, ipfs hash).
     * @return token id .
     */
    function MintNFTWithoutRoyalty(address to, string memory _tokenURI) external returns (uint256) {
        require(_getAllowance(_msgSender()) >= _fees, 'Not enough fees paid');
        IERC20(_paymentToken).transferFrom(_msgSender(), owner(), _fees);
        return IERC721RoyaltyMinter(_NFTToken).mint(to, _tokenURI);
    }

    /**
     * @notice  caller should approve the contract to transfer the fees first.
     * @dev : tokens are transfered directly to the admin wallet. Called by the token issuer .
     * @param to: NFT issuer.
     * @param _tokenURI: serialized json object that has the following data ( category, name , desc , tages, ipfs hash).
     * @param deadline:  must be timestamp in future .
     * @param v needed to recover the public key
     * @param r : normal output of an ECDSA signature
     * @param s: normal output of an ECDSA signature
     * `v`, `r` and `s` must be valid `secp256k1` signature from `owner`  or 'approved for all' account over EIP712-formatted function arguments.
     * @return token id .
     */
    function MintNFTWithoutRoyaltyPremit(
        address to,
        string memory _tokenURI,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256) {
        IERC20(_paymentToken).permit(_msgSender(), address(this), _fees, deadline, v, r, s);
        require(_getAllowance(_msgSender()) >= _fees, 'Not enough fees paid');
        IERC20(_paymentToken).transferFrom(_msgSender(), owner(), _fees);
        return IERC721RoyaltyMinter(_NFTToken).mint(to, _tokenURI);
    }

    /**
     * @notice  only called by admin wallet.
     * @param newFees : integer number represents the new fees.
     */
    function changeFees(uint256 newFees) external onlyOwner {
        // fees is a value between 1-3 %
        _fees = newFees;
    }

    /**
     * @notice  only called by admin wallet.
     * @dev for later on upgrade , if we have.
     * @param _nFTContract : startfi new NFT contract.
     */
    function changeNftContract(address _nFTContract) external onlyOwner {
        _NFTToken = _nFTContract;
    }

    /**
     * @notice  only called by admin wallet
     * @dev for later on upgrade , if we have
     * @param _paymentContractAddress : startfi new utility contract
     */
    function changePaymentContract(address _paymentContractAddress) external onlyOwner {
        _paymentToken = _paymentContractAddress;
    }
}
