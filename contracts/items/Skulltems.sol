pragma solidity ^0.4.24;

import "./ERC1155.sol";

contract SkullItems is ERC1155 {
    event Mint(string _name, uint256 _totalSupply, string _uri, uint8 _decimals, string _symbol, uint256 _itemId);
    event SetURI(uint256 _id, string _uri);
    mapping (uint256 => address) public minters;

    modifier minterOnly(uint256 _id) {
        require(minters[_id] == msg.sender);
        _;
    }

    function mint(string _name, uint256 _totalSupply, string _uri, uint8 _decimals, string _symbol, uint256 _itemId)
    external returns(uint256 _id) {
        //TODO add require to avoid duplicate items
        _id = _itemId;
        minters[_id] = msg.sender;

        items[_id].name = _name;
        items[_id].totalSupply = _totalSupply;
        metadataURIs[_id] = _uri;
        decimals[_id] = _decimals;
        symbols[_id] = _symbol;

        // Grant the items to the minter
        items[_id].balances[msg.sender] = _totalSupply;
        emit Mint(_name, _totalSupply, _uri, _decimals, _symbol, _itemId);
    }

    function setURI(uint256 _id, string _uri) external minterOnly(_id) {
        metadataURIs[_id] = _uri;
        emit SetURI(_id, _uri);
    }
}
