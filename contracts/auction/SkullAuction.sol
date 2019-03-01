pragma solidity ^0.4.24;

/**
 * @title - Crypto Skylly
 *  ________       ___  __        ___  ___      ___           ___            ___    ___
 * |\   ____\     |\  \|\  \     |\  \|\  \    |\  \         |\  \          |\  \  /  /|
 * \ \  \___|_    \ \  \/  /|_   \ \  \\\  \   \ \  \        \ \  \         \ \  \/  / /
 *  \ \_____  \    \ \   ___  \   \ \  \\\  \   \ \  \        \ \  \         \ \    / /
 *   \|____|\  \    \ \  \\ \  \   \ \  \\\  \   \ \  \____    \ \  \____     \/  /  /
 *     ____\_\  \    \ \__\\ \__\   \ \_______\   \ \_______\   \ \_______\ __/  / /
 *    |\_________\    \|__| \|__|    \|_______|    \|_______|    \|_______||\___/ /
 *    \|_________|                                                         \|___|/
 *
 * ---
 *
 * POWERED BY
 *    ____                  _          _   _ _____ _ _
 *  / ___|_ __ _   _ _ __ | |_ ___   | \ | |___ /| | |
 * | |   | '__| | | | '_ \| __/ _ \  |  \| | |_ \| | |
 * | |___| |  | |_| | |_) | || (_) | | |\  |___) |_|_|
 *  \____|_|   \__, | .__/ \__\___/  |_| \_|____/(_|_)
 *             |___/|_|
 *
 **/

import "../SkullBase.sol";
import "../ownership/SkullAccessControl.sol";
import "./SaleClockAuction.sol";

/// @title Handles creating auctions for sale and siring of skullies.
///  This wrapper of ReverseAuction exists only so that users can create
///  auctions with only one transaction.
contract SkullAuction is SkullBase, SkullAccessControl {
    SaleClockAuction public saleAuction;

    /// @dev Sets the reference to the sale auction.
    /// @param _address - Address of sale contract.
    function setSaleAuctionAddress(address _address) external onlyAdministrator {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

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

    function withdrawAuctionBalances() external onlyAdministrator {
        saleAuction.withdrawBalance();
    }
}
