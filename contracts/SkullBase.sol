pragma solidity ^0.4.24;

import "./token/ERC721Token.sol";

contract SkullBase is ERC721Token {

    event Birth(address owner, uint256 skullyId, uint256 attack, uint256 defend, uint256 rank, uint256 genes);
    struct Skull {
        uint256 genes;
        // The timestamp from the block when this cat came into existence.
        uint64 birthTime;
        uint16 attack;
        uint16 defend;
        uint16 rank;
    }

    Skull[] skulls;
    mapping (uint256 => uint256) _allTokensIndex;

    function _createSkull(
        uint256 _attack,
        uint256 _defend,
        uint256 _genes,
        uint256 _rank,
        address _tmpOwner
    ) internal returns (uint256) {
        require(_attack == uint256(uint16(_attack)));
        require(_defend == uint256(uint16(_defend)));
        require(_rank == uint256(uint16(_rank)));

        Skull memory _skull = Skull({
            genes: _genes,
            birthTime: uint64(now),
            attack: uint16(_attack),
            defend: uint16(_defend),
            rank: uint16(_rank)
        });
        uint256 newSkullId = skulls.push(_skull) - 1;

        _mint(_tmpOwner, newSkullId);

        // // emit the birth event
        emit Birth(
            _tmpOwner,
            newSkullId,
            uint256(_skull.attack),
            uint256(_skull.defend),
            uint256(_skull.rank),
            _skull.genes
        );
        return newSkullId;
    }
}
