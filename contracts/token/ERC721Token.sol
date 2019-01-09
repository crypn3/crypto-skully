pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import "../ownership/Ownable.sol";
/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)

contract ERC721Token is ERC721Full("SKULLY", "SKL"), Ownable {
    bytes4 constant InterfaceSignature_ERC721 = 0xd37c58cd;
    bytes4 constant InterfaceSignature_ERC721Enumerable = 0xd37e9d63;
    bytes4 constant InterfaceSignature_ERC721Metadata = 0xd37e139f;
    bytes4 constant InterfaceSignature_ERC165 = 0xd37fc9a7;

    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        return ((_interfaceID == InterfaceSignature_ERC165)
        || (_interfaceID == InterfaceSignature_ERC721)
        || (_interfaceID == InterfaceSignature_ERC721Enumerable)
        || (_interfaceID == InterfaceSignature_ERC721Metadata));
    }

    function implementsERC721() public pure returns (bool) {
        return true;
    }
}
