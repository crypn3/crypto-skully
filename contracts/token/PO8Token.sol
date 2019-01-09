pragma solidity ^0.4.24;
import "./PO8BaseToken.sol";
import "../ownership/Ownable.sol";

contract PO8Token is PO8BaseToken("PO8 Token", "PO8", 18, 10000000000000000000000000000), Ownable {

    uint256 internal privateToken;
    uint256 internal preSaleToken;
    uint256 internal crowdSaleToken;
    uint256 internal bountyToken;
    uint256 internal foundationToken;
    address public founderAddress;
    bool public unlockAllTokens;

    mapping (address => bool) public approvedAccount;

    event UnFrozenFunds(address target, bool unfrozen);
    event UnLockTokens(bool unlock);

    constructor() public {
        founderAddress = address(msg.sender);
        balances[founderAddress] = totalSupply_;
        emit Transfer(address(0), founderAddress, totalSupply_);
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != address(0));
        require (balances[_from] >= _value);
        require (balances[_to].add(_value) >= balances[_to]);
        require(approvedAccount[_from] || unlockAllTokens);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    function unlockAllTokens(bool _unlock) public onlyOwner {
        unlockAllTokens = _unlock;
        emit UnLockTokens(_unlock);
    }

    function approvedAccount(address target, bool approval) public onlyOwner {
        approvedAccount[target] = approval;
        emit UnFrozenFunds(target, approval);
    }
}
