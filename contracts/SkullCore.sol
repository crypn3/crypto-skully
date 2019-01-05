pragma solidity ^0.4.24;

import "./auction/SkullAuction.sol";
contract SkullCore is SkullAuction {

    // Set in case the core contract is broken and an upgrade is required
    address public newContractAddress;
    event Mint(address _to, uint256 _tokenId);

    constructor () public {
        // Starts paused.
        paused = true;

        rootAddress = msg.sender;
        adminAddress = msg.sender;

        // start with the mythical skull 0
        _createSkull(0, 0, 0, msg.sender);
    }

    function setNewAddress(address _v2Address) external onlyAdministrator whenPaused {
        // See README.md for updgrade plan
        newContractAddress = _v2Address;
        emit ContractUpgrade(_v2Address);
    }

    /// @notice No tipping!
    /// @dev Reject all Ether from being sent here, unless it's from one of the
    ///  two auction contracts. (Hopefully, we can prevent user accidents.)
    function() external payable {
        require(
            msg.sender == address(saleAuction)
        );
    }

    /// @notice Returns all the relevant information about a specific skull.
    /// @param _id The ID of the skull of interest.
    function getSkull(uint256 _id) external view returns (
        uint256 birthTime,
        uint256 attack,
        uint256 defend,
        uint256 genes
    ) {
        Skull storage skull = skulls[_id];

        birthTime = uint256(skull.birthTime);
        attack = uint256(skull.attack);
        defend = uint256(skull.defend);
        genes = skull.genes;
    }

    function unpause() public onlyAdministrator whenPaused {
        require(saleAuction != address(0));
        require(newContractAddress == address(0));

        // Actually unpause the contract.
        super.setUnPaused();
    }

    function withdrawBalance() external onlyAdministrator {
        rootAddress.transfer(address(this).balance);
    }

    function mint(address _to, uint256 _attack, uint256 _defend, uint256 _genes, string _tokenURI) public whenNotPaused onlyAdministrator returns (uint256 tokenId) {
        Skull memory _sklObj = Skull({
            birthTime: uint64(now),
            attack: uint16(_attack),
            defend: uint16(_defend),
            genes: _genes
            });

        // The new Skull is pushed onto the array and minted
        // note that solidity uses 0 as a default value when an item is not found in a mapping

        tokenId = skulls.push(_sklObj) - 1;
        _mint(_to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        emit Mint(_to, tokenId);
    }

    /// @dev setTokenURI(): Set an existing token URI.
    /// @param _tokenId The token id.
    /// @param _tokenURI The tokenURI string.  Typically this will be a link to a json file on IPFS.
    function setTokenURI(uint256 _tokenId, string _tokenURI) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }

    /// @dev getLatestId(): Returns the newest skull Id in the skull array.
    /// @return the latest skull id.
    function getLatestId() view public returns (uint256 tokenId)
    {
        if (skulls.length == 0) {
            tokenId = 0;
        } else {
            tokenId = skulls.length - 1;
        }
    }

}
