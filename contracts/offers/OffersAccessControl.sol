pragma solidity ^0.4.24;

contract OffersAccessControl {

    address public rootAddress;
    address public adminAddress;
    address public lostAndFoundAddress;

    // The total amount of ether (in wei) in escrow owned by Root
    uint256 public totalRootEarnings;
    // The total amount of ether (in wei) in escrow owned by lostAndFound
    uint256 public totalLostAndFoundBalance;

    /// @notice Keeps track whether the contract is frozen.
    ///  When frozen is set to be true, it cannot be set back to false again,
    ///  and all whenNotFrozen actions will be blocked.
    bool public frozen = false;

    /// @notice Access modifier for Root-only functionality
    modifier onlyRoot() {
        require(msg.sender == rootAddress, "only Root is allowed to perform this operation");
        _;
    }

    /// @notice Access modifier for Admin-only functionality
    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "only Admin is allowed to perform this operation");
        _;
    }

    /// @notice Access modifier for Admin-only or Root-only functionality
    modifier onlyAdminOrRoot() {
        require(
            msg.sender != address(0) &&
        (
        msg.sender == adminAddress ||
        msg.sender == rootAddress
        ),
            "only Admin or Root is allowed to perform this operation"
        );
        _;
    }

    /// @notice Access modifier for LostAndFound-only functionality
    modifier onlyLostAndFound() {
        require(
            msg.sender == lostAndFoundAddress &&
            msg.sender != address(0),
            "only LostAndFound is allowed to perform this operation"
        );
        _;
    }

    /// @notice Assigns a new address to act as the Admin. Only available to the current Admin or Root.
    /// @param _newAdmin The address of the new Admin
    function setAdmin(address _newAdmin) public onlyAdminOrRoot {
        require(_newAdmin != address(0), "new Admin address cannot be the zero-account");
        adminAddress = _newAdmin;
    }


    /// @notice Assigns a new address to act as the Root. Only available to the current Root.
    /// @param _newRoot The address of the new Root
    function setRoot(address _newRoot) external onlyRoot {
        require(_newRoot != address(0), "new Root address cannot be the zero-account");
        rootAddress = _newRoot;
    }

    /// @notice Assigns a new address to act as the LostAndFound account. Only available to the current Root
    /// @param _newLostAndFound The address of the new lostAndFound address
    function setLostAndFound(address _newLostAndFound) external onlyRoot {
        require(_newLostAndFound != address(0), "new lost and found cannot be the zero-account");
        lostAndFoundAddress = _newLostAndFound;
    }

    /// @notice Root withdraws the Root earnings
    function withdrawTotalRootEarnings() external onlyRoot {
        // Obtain reference
        uint256 balance = totalRootEarnings;
        totalRootEarnings = 0;
        rootAddress.transfer(balance);
    }

    /// @notice LostAndFound account withdraws all the lost and found amount
    function withdrawTotalLostAndFoundBalance() external onlyLostAndFound {
        // Obtain reference
        uint256 balance = totalLostAndFoundBalance;
        totalLostAndFoundBalance = 0;
        lostAndFoundAddress.transfer(balance);
    }

    /// @notice Modifier to allow actions only when the contract is not frozen
    modifier whenNotFrozen() {
        require(!frozen, "contract needs to not be frozen");
        _;
    }

    /// @notice Modifier to allow actions only when the contract is frozen
    modifier whenFrozen() {
        require(frozen, "contract needs to be frozen");
        _;
    }

    /// @notice Called by Root or Admin role to freeze the contract.
    /// @dev A frozen contract will be frozen forever, there's no way to undo this action.
    function freeze() external onlyAdminOrRoot whenNotFrozen {
        frozen = true;
    }
}
