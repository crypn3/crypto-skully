pragma solidity ^0.4.24;

import "./OffersAccessControl.sol";
import "../token/ERC721Token.sol";
import "./OffersBase.sol";

/**
 * @title - Crypto Skully
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
 * Game at https://skullylife.co/
 **/


/// @title Contract that manages funds from creation to fulfillment for offers made on any ERC-721 token.
/// @notice This generic contract interfaces with any ERC-721 compliant contract
contract SkullOffers is OffersBase {

    bytes4 constant InterfaceSignature_ERC721 = bytes4(0xd37c58cd);

    // Reference to contract tracking NFT ownership
    ERC721Token public nonFungibleContract;

    /// @notice Creates the main Offers smart contract instance and sets initial configuration values
    /// @param _nftAddress The address of the ERC-721 contract managing NFT ownership
    /// @param _adminAddress The address of the Admin to set
    /// @param _globalDuration The initial globalDuration value to set
    /// @param _minimumTotalValue The initial minimumTotalValue value to set
    /// @param _minimumPriceIncrement The initial minimumPriceIncrement value to set
    /// @param _unsuccessfulFee The initial unsuccessfulFee value to set
    /// @param _offerCut The initial offerCut value to set
    constructor(
        address _nftAddress,
        address _adminAddress,
        uint256 _globalDuration,
        uint256 _minimumTotalValue,
        uint256 _minimumPriceIncrement,
        uint256 _unsuccessfulFee,
        uint256 _offerCut
    ) public {
        // The creator of the contract is the root
        rootAddress = msg.sender;

        // Get reference of the address of the NFT contract
        ERC721Token candidateContract = ERC721Token(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721), "NFT Contract needs to support ERC721 Interface");
        nonFungibleContract = candidateContract;

        setAdmin(_adminAddress);

        // Set initial claw-figuration values
        globalDuration = _globalDuration;
        unsuccessfulFee = _unsuccessfulFee;
        _setOfferCut(_offerCut);
        _setMinimumPriceIncrement(_minimumPriceIncrement);
        _setMinimumTotalValue(_minimumTotalValue, _unsuccessfulFee);
    }

    /// @notice Creates an offer on a token. This contract receives bidders funds and refunds the previous bidder
    ///  if this offer overbids a previously active (unexpired) offer.
    /// @notice When this offer overbids a previously active offer, this offer must have a price greater than
    ///  a certain percentage of the previous offer price, which the minimumOverbidPrice basis point specifies.
    ///  A flat fee is also taken from the previous offer before refund the previous bidder.
    /// @notice When there is a previous offer that has already expired but not yet been removed from storage,
    ///  the new offer can be created with any total value as long as it is greater than the minimumTotalValue.
    /// @notice Works only when contract is not frozen.
    /// @param _tokenId The token a bidder wants to create an offer for.
    function createOffer(uint256 _tokenId) external payable whenNotFrozen {
        // T = msg.value
        // Check that the total amount of the offer isn't below the meow-nimum
        require(msg.value >= minimumTotalValue, "offer total value must be above minimumTotalValue");

        uint256 _offerCut = offerCut;

        // P, the price that owner will see and receive if the offer is accepted.
        uint256 offerPrice = _computeOfferPrice(msg.value, _offerCut);

        Offer storage previousOffer = tokenIdToOffer[_tokenId];
        uint256 previousExpiresAt = previousOffer.expiresAt;

        uint256 toRefund = 0;

        // Check if tokenId already has an offer
        if (_offerExists(previousExpiresAt)) {
            uint256 previousOfferTotal = uint256(previousOffer.total);

            // If the previous offer is still active, the new offer needs to match the previous offer's price
            // plus a minimum required increment (minimumOverbidPrice).
            // We calculate the previous offer's price, the corresponding minimumOverbidPrice, and check if the
            // new offerPrice is greater than or equal to the minimumOverbidPrice
            // The owner is fur-tunate to have such a desirable skully
            if (_isOfferActive(previousExpiresAt)) {
                uint256 previousPriceForOwner = _computeOfferPrice(previousOfferTotal, uint256(previousOffer.offerCut));
                uint256 minimumOverbidPrice = _computeMinimumOverbidPrice(previousPriceForOwner);
                require(offerPrice >= minimumOverbidPrice, "overbid price must match minimum price increment criteria");
            }

            uint256 rootEarnings = previousOffer.unsuccessfulFee;
            // Bidder gets refund: T - flat fee
            // The in-fur-ior offer gets refunded for free, how nice.
            toRefund = previousOfferTotal - rootEarnings;

            totalRootEarnings += rootEarnings;
        }

        uint256 newExpiresAt = now + globalDuration;

        // Get a reference of previous bidder address before overwriting with new offer.
        // This is only needed if there is refund
        address previousBidder;
        if (toRefund > 0) {
            previousBidder = previousOffer.bidder;
        }

        tokenIdToOffer[_tokenId] = Offer(
            uint64(newExpiresAt),
            msg.sender,
            uint16(_offerCut),
            uint128(msg.value),
            uint128(unsuccessfulFee)
        );

        // Postpone the refund until the previous offer has been overwritten by the new offer.
        if (toRefund > 0) {
            // Finally, sending funds to this bidder. If failed, the fund will be kept in escrow
            // under lostAndFound's address
            _tryPushFunds(
                _tokenId,
                previousBidder,
                toRefund
            );
        }

        emit OfferCreated(
            _tokenId,
            msg.sender,
            newExpiresAt,
            msg.value,
            offerPrice
        );
    }

    /// @notice Cancels an offer that must exist and be active currently. This moves funds from this contract
    ///  back to the the bidder, after a cut has been taken.
    /// @notice Works only when contract is not frozen.
    /// @param _tokenId The token specified by the offer a bidder wants to cancel
    function cancelOffer(uint256 _tokenId) external whenNotFrozen {
        // Check that offer exists and is active currently
        Offer storage offer = tokenIdToOffer[_tokenId];
        uint256 expiresAt = offer.expiresAt;
        require(_offerExists(expiresAt), "offer to cancel must exist");
        require(_isOfferActive(expiresAt), "offer to cancel must not be expired");

        address bidder = offer.bidder;
        require(msg.sender == bidder, "caller must be bidder of offer to be cancelled");

        // T
        uint256 total = uint256(offer.total);
        // P = T - S; Bidder gets all of P, Root gets all of T - P
        uint256 toRefund = _computeOfferPrice(total, offer.offerCut);
        uint256 rootEarnings = total - toRefund;

        // Remove offer from storage
        delete tokenIdToOffer[_tokenId];

        // Add to Root's balance
        totalRootEarnings += rootEarnings;

        // Transfer money in escrow back to bidder
        _tryPushFunds(_tokenId, bidder, toRefund);

        emit OfferCancelled(
            _tokenId,
            bidder,
            toRefund,
            rootEarnings
        );
    }

    /// @notice Fulfills an offer that must exist and be active currently. This moves the funds of the
    ///  offer held in escrow in this contract to the owner of the token, and atomically transfers the
    ///  token from the owner to the bidder. A cut is taken by this contract.
    /// @notice We also acknowledge the paw-sible difficulties of keeping in-sync with the Ethereum
    ///  blockchain, and have allowed for fulfilling offers by specifying the _minOfferPrice at which the owner
    ///  of the token is happy to accept the offer. Thus, the owner will always receive the latest offer
    ///  price, which can only be at least the _minOfferPrice that was specified. Specifically, this
    ///  implementation is designed to prevent the edge case where the owner accidentally accepts an offer
    ///  with a price lower than intended. For example, this can happen when the owner fulfills the offer
    ///  precisely when the offer expires and is subsequently replaced with a new offer priced lower.
    /// @notice Works only when contract is not frozen.
    /// @dev We make sure that the token is not on auction when we fulfill an offer, because the owner of the
    ///  token would be the auction contract instead of the user. This function requires that this Offers contract
    ///  is approved for the token in order to make the call to transfer token ownership. This is sufficient
    ///  because approvals are cleared on transfer (including transfer to the auction).
    /// @param _tokenId The token specified by the offer that will be fulfilled.
    /// @param _minOfferPrice The minimum price at which the owner of the token is happy to accept the offer.
    function fulfillOffer(uint256 _tokenId, uint128 _minOfferPrice) external whenNotFrozen {
        // Check that offer exists and is active currently
        Offer storage offer = tokenIdToOffer[_tokenId];
        uint256 expiresAt = offer.expiresAt;
        require(_offerExists(expiresAt), "offer to fulfill must exist");
        require(_isOfferActive(expiresAt), "offer to fulfill must not be expired");

        // Get the owner of the token
        address owner = nonFungibleContract.ownerOf(_tokenId);

        require(msg.sender == adminAddress || msg.sender == owner, "only Admin or the owner can fulfill order");

        // T
        uint256 total = uint256(offer.total);
        // P = T - S
        uint256 offerPrice = _computeOfferPrice(total, offer.offerCut);

        // Check if the offer price is below the minimum that the owner is happy to accept the offer for
        require(offerPrice >= _minOfferPrice, "cannot fulfill offer – offer price too low");

        // Get a reference of the bidder address befur removing offer from storage
        address bidder = offer.bidder;

        // Remove offer from storage
        delete tokenIdToOffer[_tokenId];

        // Transfer token on behalf of owner to bidder
        nonFungibleContract.transferFrom(owner, bidder, _tokenId);

        // NFT has been transferred! Now calculate fees and transfer fund to the owner
        // T - P, the Root's earnings
        uint256 rootEarnings = total - offerPrice;
        totalRootEarnings += rootEarnings;

        // Transfer money in escrow to owner
        _tryPushFunds(_tokenId, owner, offerPrice);

        emit OfferFulfilled(
            _tokenId,
            bidder,
            owner,
            offerPrice,
            rootEarnings
        );
    }

    /// @notice Removes any existing and inactive (expired) offers from storage. In doing so, this contract
    ///  takes a flat fee from the total amount attached to each offer before sending the remaining funds
    ///  back to the bidder.
    /// @notice Nothing will be done if the offer for a token is either non-existent or active.
    /// @param _tokenIds The array of tokenIds that will be removed from storage
    function batchRemoveExpired(uint256[] _tokenIds) external whenNotFrozen {
        uint256 len = _tokenIds.length;

        // Use temporary accumulator
        uint256 cumulativeRootEarnings = 0;

        for (uint256 i = 0; i < len; i++) {
            uint256 tokenId = _tokenIds[i];
            Offer storage offer = tokenIdToOffer[tokenId];
            uint256 expiresAt = offer.expiresAt;

            // Skip the offer if not exist
            if (!_offerExists(expiresAt)) {
                continue;
            }
            // Skip if the offer has not expired yet
            if (_isOfferActive(expiresAt)) {
                continue;
            }

            // Get a reference of the bidder address before removing offer from storage
            address bidder = offer.bidder;

            // Root gets the flat fee
            uint256 rootEarnings = uint256(offer.unsuccessfulFee);

            // Bidder gets refund: T - flat
            uint256 toRefund = uint256(offer.total) - rootEarnings;

            // Ensure the previous offer has been removed before refunding
            delete tokenIdToOffer[tokenId];

            // Add to cumulative balance of Root's earnings
            cumulativeRootEarnings += rootEarnings;

            // Finally, sending funds to this bidder. If failed, the fund will be kept in escrow
            // under lostAndFound's address
            _tryPushFunds(
                tokenId,
                bidder,
                toRefund
            );

            emit ExpiredOfferRemoved(
                tokenId,
                bidder,
                toRefund,
                rootEarnings
            );
        }

        // Add to Root's balance if any expired offer has been removed
        if (cumulativeRootEarnings > 0) {
            totalRootEarnings += cumulativeRootEarnings;
        }
    }

    /// @notice Updates an existing and active offer by setting a new expiration time and, optionally, raise
    ///  the price of the offer.
    /// @notice As the offers are always using the configuration values currently in storage, the updated
    ///  offer may be adhering to configuration values that are different at the time of its original creation.
    /// @dev We check msg.value to determine if the offer price should be raised. If 0, only a new
    ///  expiration time is set.
    /// @param _tokenId The token specified by the offer that will be updated.
    function updateOffer(uint256 _tokenId) external payable whenNotFrozen {
        // Check that offer exists and is active currently
        Offer storage offer = tokenIdToOffer[_tokenId];
        uint256 expiresAt = uint256(offer.expiresAt);
        require(_offerExists(expiresAt), "offer to update must exist");
        require(_isOfferActive(expiresAt), "offer to update must not be expired");

        require(msg.sender == offer.bidder, "caller must be bidder of offer to be updated");

        uint256 newExpiresAt = now + globalDuration;

        // Check if the caller wants to raise the offer as well
        if (msg.value > 0) {
            // Set the new price
            offer.total += uint128(msg.value);
        }

        offer.expiresAt = uint64(newExpiresAt);

        emit OfferUpdated(_tokenId, msg.sender, newExpiresAt, msg.value);

    }

    /// @notice Sends funds of each existing offer held in escrow back to bidders. The function is callable
    ///  by anyone.
    /// @notice Works only when contract is frozen. In this case, we want to allow all funds to be returned
    ///  without taking any fees.
    /// @param _tokenId The token specified by the offer a bidder wants to withdraw funds for.
    function bidderWithdrawFunds(uint256 _tokenId) external whenFrozen {
        // Check that offer exists
        Offer storage offer = tokenIdToOffer[_tokenId];
        require(_offerExists(offer.expiresAt), "offer to withdraw funds from must exist");
        require(msg.sender == offer.bidder, "only bidders can withdraw their funds in escrow");

        // Get a reference of the total to withdraw before removing offer from storage
        uint256 total = uint256(offer.total);

        delete tokenIdToOffer[_tokenId];

        // Send funds back to bidders!
        msg.sender.transfer(total);

        emit BidderWithdrewFundsWhenFrozen(_tokenId, msg.sender, total);
    }

    /// @notice we don't accept any value transfer.
    function() external payable {
        revert("we don't accept any payments!");
    }
}
