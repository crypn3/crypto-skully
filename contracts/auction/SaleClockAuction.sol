pragma solidity ^0.4.24;
import './ClockAuction.sol';
import "../token/PO8BaseToken.sol";

/// @title Clock auction modified for sale of skull
/// @notice We omit a fallback function to prevent accidental sends to this contract.
contract SaleClockAuction is ClockAuction {

    // @dev Hoank check that allows us to ensure that we are pointing to the
    //  right auction in our setSaleAuctionAddress() call.
    bool public isSaleClockAuction = true;
    mapping (uint256 => uint256) totalBuySkull;
    event ClaimToken(address owner, uint256 tokenId);


    // Delegate constructor
    constructor(address _nftAddr, uint256 _cut) public
        ClockAuction(_nftAddr, _cut) {}

    /// @dev Creates and begins a new auction.
    /// @param _tokenId - ID of token to auction, sender must be owner.
    /// @param _startingPrice - Price of item (in wei) at beginning of auction.
    /// @param _endingPrice - Price of item (in wei) at end of auction.
    /// @param _duration - Length of auction (in seconds).
    /// @param _seller - Seller, if not the message sender
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    ) external {
        // Hoank check that no inputs overflow how many bits we've allocated
        // to store them in the auction struct.
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

    /// @dev Updates lastSalePrice if seller is the nft contract
    /// Otherwise, works the same as default bid method.
    function bid(uint256 _tokenId) external payable {
        // _bid verifies token ID size

        uint256 price;
        address seller;
        (price, seller) = _bid(_tokenId, msg.value, msg.sender);
        _transfer(msg.sender, _tokenId);
        if (msg.sender != seller) {
            totalBuySkull[_tokenId] += 1;
            uint256 totalBuy = totalBuySkull[_tokenId];
            uint256 valuePO8Transfer = totalBuy * 5 * 1000000000000000000;
            PO8BaseToken tokenPO8 = PO8BaseToken(0x8744a672D5a2df51Da92B4BAb608CE7ff4Ddd804);
            tokenPO8.transferFrom(_owner, seller, valuePO8Transfer);
        }
    }

    function getTotalBuyBySkull(uint256 _tokenId) public view returns (uint256) {
        return totalBuySkull[_tokenId];
    }


    function claimToken(uint256 _tokenId) external {
        require(isOwnerOf(msg.sender, _tokenId));
        uint256 totalBuy = totalBuySkull[_tokenId];
        uint256 valuePO8Transfer = totalBuy * 2500000000000000000;
        PO8BaseToken tokenPO8 = PO8BaseToken(0x8744a672D5a2df51Da92B4BAb608CE7ff4Ddd804);
        tokenPO8.transferFrom(_owner, msg.sender, valuePO8Transfer);
        totalBuySkull[_tokenId] = 0;
        emit ClaimToken(msg.sender, _tokenId);
    }

}
