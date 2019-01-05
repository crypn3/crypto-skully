pragma solidity ^0.4.24;

import "./token/ERC721Token.sol";

contract SkullBase is ERC721Token {

    event Birth(address owner, uint256 skullyId, uint256 attack, uint256 defend, uint256 genes);
    event Transfer(address from, address to, uint256 tokenId);
    struct Skull {
        uint256 genes;
        // The timestamp from the block when this cat came into existence.
        uint64 birthTime;
        uint16 attack;
        uint16 defend;
    }

    Skull[] skulls;

    function _createSkull(
        uint256 _attack,
        uint256 _defend,
        uint256 _genes,
        address _tmpOwner
    ) internal returns (uint256) {
        require(_attack == uint256(uint16(_attack)));
        require(_defend == uint256(uint16(_defend)));

        Skull memory _skull = Skull({
            genes: _genes,
            birthTime: uint64(now),
            attack: uint16(_attack),
            defend: uint16(_defend)
            });
        uint256 newSkullId = skulls.push(_skull) - 1;

        _mint(_tmpOwner, newSkullId);

        // // emit the birth event
        emit Birth(
            _tmpOwner,
            newSkullId,
            uint256(_skull.attack),
            uint256(_skull.defend),
            _skull.genes
        );
        return newSkullId;
    }
}
