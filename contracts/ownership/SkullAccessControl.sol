pragma solidity ^0.4.24;

contract SkullAccessControl {
    event ContractUpgrade(address newContract);

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public rootAddress;
    address public adminAddress;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    modifier onlyRoot() {
        require(msg.sender == rootAddress);
        _;
    }

    modifier onlyAdmin()  {
        require(msg.sender == adminAddress);
        _;
    }

    modifier onlyAdministrator() {
        require(msg.sender == rootAddress || msg.sender == adminAddress);
        _;
    }

    function setRoot(address _newRoot) external onlyAdministrator {
        require(_newRoot != address(0));
        rootAddress = _newRoot;
    }

    function setAdmin(address _newAdmin) external onlyRoot {
        require(_newAdmin != address(0));
        adminAddress = _newAdmin;
    }

    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    function setPaused() public onlyAdministrator whenNotPaused {
        paused = true;
    }

    function setUnPaused() public onlyAdministrator whenPaused {
        paused = false;
    }
}


