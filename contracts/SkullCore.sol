pragma solidity ^0.4.24;

import "./auction/SkullAuction.sol";
contract SkullCore is SkullAuction {

    // Set in case the core contract is broken and an upgrade is required
    address public newContractAddress;
    event Mint(address _to, uint256 attack, uint256 defend, uint256 rank, uint256 _tokenId);
    event UpdateSkill(uint256 _id, uint256 _attack, uint256 _defend, uint256 _rank);

    constructor () public {
        // Starts paused.
        paused = true;

        rootAddress = msg.sender;
        adminAddress = msg.sender;

        // start with the mythical skull 0
        _createSkull(0, 0, 0, 0, msg.sender);
    }

    function setNewAddress(address _v2Address) external onlyAdministrator whenPaused {
        // See README.md for upgrade plan
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
        uint256 rank,
        uint256 genes
    ) {
        uint256 skullId = _allTokensIndex[_id];
        Skull storage skull = skulls[skullId];

        birthTime = uint256(skull.birthTime);
        attack = uint256(skull.attack);
        defend = uint256(skull.defend);
        rank = uint256(skull.rank);
        genes = skull.genes;
    }

    function updateSkill(uint256 _id, uint256 _newAttack, uint256 _newDefend, uint256 _newRank) public whenNotPaused onlyUpdateAddress returns (bool){
        uint256 skullId = _allTokensIndex[_id];
        if (_newAttack > 0) {
            skulls[skullId].attack = uint16(_newAttack);
        }
        if (_newDefend > 0) {
            skulls[skullId].defend = uint16(_newDefend);
        }
        if (_newRank >= 0) {
            skulls[skullId].rank = uint16(_newRank);
        }
        emit UpdateSkill(skullId, _newAttack, _newDefend, _newRank);
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

    function mint(address _to, uint256 _attack, uint256 _defend, uint256 _rank, uint256 _genes, string _tokenURI, uint256 tokenId) public whenNotPaused onlyAdministrator {
        Skull memory _sklObj = Skull({
            birthTime: uint64(now),
            attack: uint16(_attack),
            defend: uint16(_defend),
            rank: uint16(_rank),
            genes: _genes
            });

        // The new Skull is pushed onto the array and minted
        // note that solidity uses 0 as a default value when an item is not found in a mapping
        if (_allTokensIndex[tokenId] == 0) {
            _mint(_to, tokenId);
            _setTokenURI(tokenId, _tokenURI);
            _allTokensIndex[tokenId] = skulls.length;
            skulls.push(_sklObj);
            emit Mint(_to, _attack, _defend, _rank, tokenId);
        }
    }

    function mintMany(address _to, uint256 startId, uint256 endId) public whenNotPaused onlyAdministrator onlyOwner {
        require(startId <= endId);
        require(endId - startId < 10000);
        for (uint256 tokenId = startId; tokenId <= endId; tokenId ++) {
            uint16 attack = uint16(randomAttack(tokenId));
            uint16 defend = uint16(randomDefend(tokenId + attack));
            string memory tokenURI = strConcat("https://api.skullylife.co/skullies/", uint2str(tokenId));

            Skull memory _sklObj = Skull({
                birthTime: uint64(now),
                attack: uint16(attack),
                defend: uint16(defend),
                rank: uint16(0),
                genes: 0
                });

            // The new Skull is pushed onto the array and minted
            // note that solidity uses 0 as a default value when an item is not found in a mapping
            if (_allTokensIndex[tokenId] == 0) {
                _mint(_to, tokenId);
                _setTokenURI(tokenId, tokenURI);
                _allTokensIndex[tokenId] = skulls.length;
                skulls.push(_sklObj);
                emit Mint(_to, attack, defend, 0, tokenId);
            }
        }
    }

    /// @dev setTokenURI(): Set an existing token URI.
    /// @param _tokenId The token id.
    /// @param _tokenURI The tokenURI string.  Typically this will be a link to a json file on IPFS.
    function setTokenURI(uint256 _tokenId, string _tokenURI) public whenNotPaused onlyAdministrator {
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

    function randomAttack(uint256 index) private view returns (uint8) {
        return uint8(30 + uint256(keccak256(block.timestamp, block.difficulty, index)) % 60); // random 30-90
    }

    function randomDefend(uint256 index) private view returns (uint8) {
        return uint8(30 + uint256(keccak256(block.timestamp, block.difficulty, index)) % 30); // random 30-60
    }

    function strConcat(string _a, string _b) internal pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory bab = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) bab[k++] = _bb[i];

        return string(bab);
    }

    function uint2str(uint i) internal pure returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

}
