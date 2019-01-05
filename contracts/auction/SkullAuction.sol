pragma solidity ^0.4.24;

import "../SkullBase.sol";
import "../ownership/SkullAccessControl.sol";
import "./SaleClockAuction.sol";

/// @title Handles creating auctions for sale and siring of skullies.
///  This wrapper of ReverseAuction exists only so that users can create
///  auctions with only one transaction.
contract SkullAuction is SkullBase, SkullAccessControl {
    SaleClockAuction public saleAuction;
    // @notice The auction contract variables are defined in KittyBase to allow
    //  us to refer to them in KittyOwnership to prevent accidental transfers.
    // `saleAuction` refers to the auction for gen0 and p2p sale of kitties.
    // `siringAuction` refers to the auction for siring rights of kitties.

    /// @dev Sets the reference to the sale auction.
    /// @param _address - Address of sale contract.
    function setSaleAuctionAddress(address _address) external onlyAdministrator {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

        // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateContract.isSaleClockAuction());

        // Set the new contract address
        saleAuction = candidateContract;
    }

    /// @dev Put a skull up for auction.
    ///  Does some ownership trickery to create auctions in one tx.
    function createSaleAuction(
        uint256 _skullId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    ) external whenNotPaused {
        require(ownerOf(_skullId) == msg.sender);
        approve(saleAuction, _skullId);
        saleAuction.createAuction(
            _skullId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

    /// @dev Transfers the balance of the sale auction contract
    /// to the KittyCore contract. We use two-step withdrawal to
    /// prevent two transfer calls in the auction bid function.
    function withdrawAuctionBalances() external onlyAdministrator {
        saleAuction.withdrawBalance();
    }
}
