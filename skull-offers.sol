pragma solidity ^0.4.24;

// File: contracts/offers/OffersAccessControl.sol

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

// File: openzeppelin-solidity/contracts/introspection/IERC165.sol

/**
 * @title IERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {

  /**
   * @notice Query if a contract implements an interface
   * @param interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract IERC721 is IERC165 {

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );
  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );
  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  function balanceOf(address owner) public view returns (uint256 balance);
  function ownerOf(uint256 tokenId) public view returns (address owner);

  function approve(address to, uint256 tokenId) public;
  function getApproved(uint256 tokenId)
    public view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) public;
  function isApprovedForAll(address owner, address operator)
    public view returns (bool);

  function transferFrom(address from, address to, uint256 tokenId) public;
  function safeTransferFrom(address from, address to, uint256 tokenId)
    public;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes data
  )
    public;
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   * after a `safeTransfer`. This function MUST return the function selector,
   * otherwise the caller will revert the transaction. The selector to be
   * returned can be obtained as `this.onERC721Received.selector`. This
   * function MAY throw to revert and reject the transfer.
   * Note: the ERC721 contract address is always the message sender.
   * @param operator The address which called `safeTransferFrom` function
   * @param from The address which previously owned the token
   * @param tokenId The NFT identifier which is being transferred
   * @param data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
   */
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes data
  )
    public
    returns(bytes4);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: openzeppelin-solidity/contracts/utils/Address.sol

/**
 * Utility library of inline functions on addresses
 */
library Address {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param account address of the account to check
   * @return whether the target address is a contract
   */
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(account) }
    return size > 0;
  }

}

// File: openzeppelin-solidity/contracts/introspection/ERC165.sol

/**
 * @title ERC165
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */
contract ERC165 is IERC165 {

  bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
  /**
   * 0x01ffc9a7 ===
   *   bytes4(keccak256('supportsInterface(bytes4)'))
   */

  /**
   * @dev a mapping of interface id to whether or not it's supported
   */
  mapping(bytes4 => bool) private _supportedInterfaces;

  /**
   * @dev A contract implementing SupportsInterfaceWithLookup
   * implement ERC165 itself
   */
  constructor()
    internal
  {
    _registerInterface(_InterfaceId_ERC165);
  }

  /**
   * @dev implement supportsInterface(bytes4) using a lookup table
   */
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool)
  {
    return _supportedInterfaces[interfaceId];
  }

  /**
   * @dev internal method for registering an interface
   */
  function _registerInterface(bytes4 interfaceId)
    internal
  {
    require(interfaceId != 0xffffffff);
    _supportedInterfaces[interfaceId] = true;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC165, IERC721 {

  using SafeMath for uint256;
  using Address for address;

  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

  // Mapping from token ID to owner
  mapping (uint256 => address) private _tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) private _tokenApprovals;

  // Mapping from owner to number of owned token
  mapping (address => uint256) private _ownedTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) private _operatorApprovals;

  bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;
  /*
   * 0x80ac58cd ===
   *   bytes4(keccak256('balanceOf(address)')) ^
   *   bytes4(keccak256('ownerOf(uint256)')) ^
   *   bytes4(keccak256('approve(address,uint256)')) ^
   *   bytes4(keccak256('getApproved(uint256)')) ^
   *   bytes4(keccak256('setApprovalForAll(address,bool)')) ^
   *   bytes4(keccak256('isApprovedForAll(address,address)')) ^
   *   bytes4(keccak256('transferFrom(address,address,uint256)')) ^
   *   bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
   *   bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))
   */

  constructor()
    public
  {
    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(_InterfaceId_ERC721);
  }

  /**
   * @dev Gets the balance of the specified address
   * @param owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address owner) public view returns (uint256) {
    require(owner != address(0));
    return _ownedTokensCount[owner];
  }

  /**
   * @dev Gets the owner of the specified token ID
   * @param tokenId uint256 ID of the token to query the owner of
   * @return owner address currently marked as the owner of the given token ID
   */
  function ownerOf(uint256 tokenId) public view returns (address) {
    address owner = _tokenOwner[tokenId];
    require(owner != address(0));
    return owner;
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per token at a given time.
   * Can only be called by the token owner or an approved operator.
   * @param to address to be approved for the given token ID
   * @param tokenId uint256 ID of the token to be approved
   */
  function approve(address to, uint256 tokenId) public {
    address owner = ownerOf(tokenId);
    require(to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * Reverts if the token ID does not exist.
   * @param tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for the given token ID
   */
  function getApproved(uint256 tokenId) public view returns (address) {
    require(_exists(tokenId));
    return _tokenApprovals[tokenId];
  }

  /**
   * @dev Sets or unsets the approval of a given operator
   * An operator is allowed to transfer all tokens of the sender on their behalf
   * @param to operator address to set the approval
   * @param approved representing the status of the approval to be set
   */
  function setApprovalForAll(address to, bool approved) public {
    require(to != msg.sender);
    _operatorApprovals[msg.sender][to] = approved;
    emit ApprovalForAll(msg.sender, to, approved);
  }

  /**
   * @dev Tells whether an operator is approved by a given owner
   * @param owner owner address which you want to query the approval of
   * @param operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(
    address owner,
    address operator
  )
    public
    view
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address
   * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
  */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
  {
    require(_isApprovedOrOwner(msg.sender, tokenId));
    require(to != address(0));

    _clearApproval(from, tokenId);
    _removeTokenFrom(from, tokenId);
    _addTokenTo(to, tokenId);

    emit Transfer(from, to, tokenId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   *
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
  */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
  {
    // solium-disable-next-line arg-overflow
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes _data
  )
    public
  {
    transferFrom(from, to, tokenId);
    // solium-disable-next-line arg-overflow
    require(_checkOnERC721Received(from, to, tokenId, _data));
  }

  /**
   * @dev Returns whether the specified token exists
   * @param tokenId uint256 ID of the token to query the existence of
   * @return whether the token exists
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    address owner = _tokenOwner[tokenId];
    return owner != address(0);
  }

  /**
   * @dev Returns whether the given spender can transfer a given token ID
   * @param spender address of the spender to query
   * @param tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   *  is an operator of the owner, or is the owner of the token
   */
  function _isApprovedOrOwner(
    address spender,
    uint256 tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(tokenId);
    // Disable solium check because of
    // https://github.com/duaraghav8/Solium/issues/175
    // solium-disable-next-line operator-whitespace
    return (
      spender == owner ||
      getApproved(tokenId) == spender ||
      isApprovedForAll(owner, spender)
    );
  }

  /**
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
   * @param to The address that will own the minted token
   * @param tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address to, uint256 tokenId) internal {
    require(to != address(0));
    _addTokenTo(to, tokenId);
    emit Transfer(address(0), to, tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * @param tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address owner, uint256 tokenId) internal {
    _clearApproval(owner, tokenId);
    _removeTokenFrom(owner, tokenId);
    emit Transfer(owner, address(0), tokenId);
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * Note that this function is left internal to make ERC721Enumerable possible, but is not
   * intended to be called by custom derived contracts: in particular, it emits no Transfer event.
   * @param to address representing the new owner of the given token ID
   * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenTo(address to, uint256 tokenId) internal {
    require(_tokenOwner[tokenId] == address(0));
    _tokenOwner[tokenId] = to;
    _ownedTokensCount[to] = _ownedTokensCount[to].add(1);
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * Note that this function is left internal to make ERC721Enumerable possible, but is not
   * intended to be called by custom derived contracts: in particular, it emits no Transfer event,
   * and doesn't clear approvals.
   * @param from address representing the previous owner of the given token ID
   * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function _removeTokenFrom(address from, uint256 tokenId) internal {
    require(ownerOf(tokenId) == from);
    _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
    _tokenOwner[tokenId] = address(0);
  }

  /**
   * @dev Internal function to invoke `onERC721Received` on a target address
   * The call is not executed if the target address is not a contract
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return whether the call correctly returned the expected magic value
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!to.isContract()) {
      return true;
    }
    bytes4 retval = IERC721Receiver(to).onERC721Received(
      msg.sender, from, tokenId, _data);
    return (retval == _ERC721_RECEIVED);
  }

  /**
   * @dev Private function to clear current approval of a given token ID
   * Reverts if the given address is not indeed the owner of the token
   * @param owner owner of the token
   * @param tokenId uint256 ID of the token to be transferred
   */
  function _clearApproval(address owner, uint256 tokenId) private {
    require(ownerOf(tokenId) == owner);
    if (_tokenApprovals[tokenId] != address(0)) {
      _tokenApprovals[tokenId] = address(0);
    }
  }
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721Enumerable.sol

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract IERC721Enumerable is IERC721 {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  )
    public
    view
    returns (uint256 tokenId);

  function tokenByIndex(uint256 index) public view returns (uint256);
}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721Enumerable.sol

contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
  // Mapping from owner to list of owned token IDs
  mapping(address => uint256[]) private _ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private _ownedTokensIndex;

  // Array with all token ids, used for enumeration
  uint256[] private _allTokens;

  // Mapping from token id to position in the allTokens array
  mapping(uint256 => uint256) private _allTokensIndex;

  bytes4 private constant _InterfaceId_ERC721Enumerable = 0x780e9d63;
  /**
   * 0x780e9d63 ===
   *   bytes4(keccak256('totalSupply()')) ^
   *   bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) ^
   *   bytes4(keccak256('tokenByIndex(uint256)'))
   */

  /**
   * @dev Constructor function
   */
  constructor() public {
    // register the supported interface to conform to ERC721 via ERC165
    _registerInterface(_InterfaceId_ERC721Enumerable);
  }

  /**
   * @dev Gets the token ID at a given index of the tokens list of the requested owner
   * @param owner address owning the tokens list to be accessed
   * @param index uint256 representing the index to be accessed of the requested tokens list
   * @return uint256 token ID at the given index of the tokens list owned by the requested address
   */
  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  )
    public
    view
    returns (uint256)
  {
    require(index < balanceOf(owner));
    return _ownedTokens[owner][index];
  }

  /**
   * @dev Gets the total amount of tokens stored by the contract
   * @return uint256 representing the total amount of tokens
   */
  function totalSupply() public view returns (uint256) {
    return _allTokens.length;
  }

  /**
   * @dev Gets the token ID at a given index of all the tokens in this contract
   * Reverts if the index is greater or equal to the total number of tokens
   * @param index uint256 representing the index to be accessed of the tokens list
   * @return uint256 token ID at the given index of the tokens list
   */
  function tokenByIndex(uint256 index) public view returns (uint256) {
    require(index < totalSupply());
    return _allTokens[index];
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * This function is internal due to language limitations, see the note in ERC721.sol.
   * It is not intended to be called by custom derived contracts: in particular, it emits no Transfer event.
   * @param to address representing the new owner of the given token ID
   * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenTo(address to, uint256 tokenId) internal {
    super._addTokenTo(to, tokenId);
    uint256 length = _ownedTokens[to].length;
    _ownedTokens[to].push(tokenId);
    _ownedTokensIndex[tokenId] = length;
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * This function is internal due to language limitations, see the note in ERC721.sol.
   * It is not intended to be called by custom derived contracts: in particular, it emits no Transfer event,
   * and doesn't clear approvals.
   * @param from address representing the previous owner of the given token ID
   * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function _removeTokenFrom(address from, uint256 tokenId) internal {
    super._removeTokenFrom(from, tokenId);

    // To prevent a gap in the array, we store the last token in the index of the token to delete, and
    // then delete the last slot.
    uint256 tokenIndex = _ownedTokensIndex[tokenId];
    uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
    uint256 lastToken = _ownedTokens[from][lastTokenIndex];

    _ownedTokens[from][tokenIndex] = lastToken;
    // This also deletes the contents at the last position of the array
    _ownedTokens[from].length--;

    // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
    // be zero. Then we can make sure that we will remove tokenId from the ownedTokens list since we are first swapping
    // the lastToken to the first position, and then dropping the element placed in the last position of the list

    _ownedTokensIndex[tokenId] = 0;
    _ownedTokensIndex[lastToken] = tokenIndex;
  }

  /**
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
   * @param to address the beneficiary that will own the minted token
   * @param tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address to, uint256 tokenId) internal {
    super._mint(to, tokenId);

    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * @param owner owner of the token to burn
   * @param tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address owner, uint256 tokenId) internal {
    super._burn(owner, tokenId);

    // Reorg all tokens array
    uint256 tokenIndex = _allTokensIndex[tokenId];
    uint256 lastTokenIndex = _allTokens.length.sub(1);
    uint256 lastToken = _allTokens[lastTokenIndex];

    _allTokens[tokenIndex] = lastToken;
    _allTokens[lastTokenIndex] = 0;

    _allTokens.length--;
    _allTokensIndex[tokenId] = 0;
    _allTokensIndex[lastToken] = tokenIndex;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721Metadata.sol

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract IERC721Metadata is IERC721 {
  function name() external view returns (string);
  function symbol() external view returns (string);
  function tokenURI(uint256 tokenId) external view returns (string);
}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721Metadata.sol

contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Optional mapping for token URIs
  mapping(uint256 => string) private _tokenURIs;

  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
  /**
   * 0x5b5e139f ===
   *   bytes4(keccak256('name()')) ^
   *   bytes4(keccak256('symbol()')) ^
   *   bytes4(keccak256('tokenURI(uint256)'))
   */

  /**
   * @dev Constructor function
   */
  constructor(string name, string symbol) public {
    _name = name;
    _symbol = symbol;

    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(InterfaceId_ERC721Metadata);
  }

  /**
   * @dev Gets the token name
   * @return string representing the token name
   */
  function name() external view returns (string) {
    return _name;
  }

  /**
   * @dev Gets the token symbol
   * @return string representing the token symbol
   */
  function symbol() external view returns (string) {
    return _symbol;
  }

  /**
   * @dev Returns an URI for a given token ID
   * Throws if the token ID does not exist. May return an empty string.
   * @param tokenId uint256 ID of the token to query
   */
  function tokenURI(uint256 tokenId) external view returns (string) {
    require(_exists(tokenId));
    return _tokenURIs[tokenId];
  }

  /**
   * @dev Internal function to set the token URI for a given token
   * Reverts if the token ID does not exist
   * @param tokenId uint256 ID of the token to set its URI
   * @param uri string URI to assign
   */
  function _setTokenURI(uint256 tokenId, string uri) internal {
    require(_exists(tokenId));
    _tokenURIs[tokenId] = uri;
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * @param owner owner of the token to burn
   * @param tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address owner, uint256 tokenId) internal {
    super._burn(owner, tokenId);

    // Clear metadata (if any)
    if (bytes(_tokenURIs[tokenId]).length != 0) {
      delete _tokenURIs[tokenId];
    }
  }
}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol

/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
  constructor(string name, string symbol) ERC721Metadata(name, symbol)
    public
  {
  }
}

// File: contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor () internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: contracts/token/ERC721Token.sol

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens

contract ERC721Token is ERC721Full("SKULLY", "SKULL"), Ownable {
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

// File: contracts/offers/OffersConfig.sol

/// @title Contract that manages configuration values and fee structure for offers.
contract OffersConfig is OffersAccessControl {

    /* ************************* */
    /* ADJUSTABLE CONFIGURATIONS */
    /* ************************* */

    // The duration (in seconds) of all offers that are created. This parameter is also used in calculating
    // new expiration times when extending offers.
    uint256 public globalDuration;
    // The global minimum offer value (price + offer fee, in wei)
    uint256 public minimumTotalValue;
    // The minimum overbid increment % (expressed in basis points, which is 1/100 of a percent)
    // For basis points, values 0-10,000 map to 0%-100%
    uint256 public minimumPriceIncrement;

    /* *************** */
    /* ADJUSTABLE FEES */
    /* *************** */

    // Throughout the various contracts there will be various symbols used for the purpose of a clear display
    // of the underlying mathematical formulation. Specifically,
    //
    //          - T: This is the total amount of funds associated with an offer, comprised of 1) the offer
    //                  price which the bidder is proposing the owner of the token receive, and 2) an amount
    //                  that is the maximum the main Offers contract will ever take - this is when the offer
    //                  is cancelled, or fulfilled. In other scenarios, the amount taken by the main contract
    //                  may be less, depending on other configurations.
    //
    //          - S: This is called the offerCut, expressed as a basis point. This determines the maximum amount
    //                  of ether the main contract can ever take in the various possible outcomes of an offer
    //                  (cancelled, expired, overbid, fulfilled, updated).
    //
    //          - P: This simply refers to the price that the bidder is offering the owner receive, upon
    //                  fulfillment of the offer process.
    //
    //          - Below is the formula that ties the symbols listed above together (S is % for brevity):
    //                  T = P + S * P

    // Flat fee (in wei) the main contract takes when offer has been expired or overbid. The fee serves as a
    // disincentive for abuse and allows recoupment of ether spent calling batchRemoveExpired on behalf of users.
    uint256 public unsuccessfulFee;
    // This is S, the maximum % the main contract takes on each offer. S represents the total amount paid when
    // an offer has been fulfilled or cancelled.
    uint256 public offerCut;

    /* ****** */
    /* EVENTS */
    /* ****** */

    event GlobalDurationUpdated(uint256 value);
    event MinimumTotalValueUpdated(uint256 value);
    event MinimumPriceIncrementUpdated(uint256 value);
    event OfferCutUpdated(uint256 value);
    event UnsuccessfulFeeUpdated(uint256 value);

    /* ********* */
    /* FUNCTIONS */
    /* ********* */

    /// @notice Sets the minimumTotalValue value. This would impact offers created after this has been set, but
    ///  not existing offers.
    /// @notice Only callable by Admin or Root, when not frozen.
    /// @param _newMinTotal The minimumTotalValue value to set
    function setMinimumTotalValue(uint256 _newMinTotal) external onlyAdminOrRoot whenNotFrozen {
        _setMinimumTotalValue(_newMinTotal, unsuccessfulFee);
        emit MinimumTotalValueUpdated(_newMinTotal);
    }

    /// @notice Sets the globalDuration value. All offers that are created or updated will compute a new expiration
    ///  time based on this.
    /// @notice Only callable by Admin or Root, when not frozen.
    /// @dev Need to check for underflow since function argument is 256 bits, and the offer expiration time is
    ///  packed into 64 bits in the Offer struct.
    /// @param _newDuration The globalDuration value to set.
    function setGlobalDuration(uint256 _newDuration) external onlyAdminOrRoot whenNotFrozen {
        require(_newDuration == uint256(uint64(_newDuration)), "new globalDuration value must not underflow");
        globalDuration = _newDuration;
        emit GlobalDurationUpdated(_newDuration);
    }

    /// @notice Sets the offerCut value. All offers will compute a fee taken by this contract based on this
    ///  configuration.
    /// @notice Only callable by Admin or Root, when not frozen.
    /// @dev As this configuration is a basis point, the value to set must be less than or equal to 10000.
    /// @param _newOfferCut The offerCut value to set.
    function setOfferCut(uint256 _newOfferCut) external onlyAdminOrRoot whenNotFrozen {
        _setOfferCut(_newOfferCut);
        emit OfferCutUpdated(_newOfferCut);
    }

    /// @notice Sets the unsuccessfulFee value. All offers that are unsuccessful (overbid or expired)
    ///  will have a flat fee taken by the main contract before being refunded to bidders.
    /// @notice Given Tmin (_minTotal), flat fee (_unsuccessfulFee),
    ///  Tmin ≥ (2 * flat fee) guarantees that offer prices ≥ flat fee, always. This is important to prevent the
    ///  existence of offers that, when overbid or expired, would result in the main contract taking too big of a cut.
    ///  In the case of a sufficiently low offer price, eg. the same as unsuccessfulFee, the most the main contract can
    ///  ever take is simply the amount of unsuccessfulFee.
    /// @notice Only callable by Admin or Root, when not frozen.
    /// @param _newUnsuccessfulFee The unsuccessfulFee value to set.
    function setUnsuccessfulFee(uint256 _newUnsuccessfulFee) external onlyAdminOrRoot whenNotFrozen {
        require(minimumTotalValue >= (2 * _newUnsuccessfulFee), "unsuccessful value must be <= half of minimumTotalValue");
        unsuccessfulFee = _newUnsuccessfulFee;
        emit UnsuccessfulFeeUpdated(_newUnsuccessfulFee);
    }

    /// @notice Sets the minimumPriceIncrement value. All offers that are overbid must have a price greater
    ///  than the minimum increment computed from this basis point.
    /// @notice Only callable by Admin or Root, when not frozen.
    /// @dev As this configuration is a basis point, the value to set must be less than or equal to 10000.
    /// @param _newMinimumPriceIncrement The minimumPriceIncrement value to set.
    function setMinimumPriceIncrement(uint256 _newMinimumPriceIncrement) external onlyAdmin whenNotFrozen {
        _setMinimumPriceIncrement(_newMinimumPriceIncrement);
        emit MinimumPriceIncrementUpdated(_newMinimumPriceIncrement);
    }

    /// @notice Utility function used internally for the setMinimumTotalValue method.
    /// @notice Given Tmin (_minTotal), flat fee (_unsuccessfulFee),
    ///  Tmin ≥ (2 * flat fee) guarantees that offer prices ≥ flat fee, always. This is important to prevent the
    ///  existence of offers that, when overbid or expired, would result in the main contract taking too big of a cut.
    ///  In the case of a sufficiently low offer price, eg. the same as unsuccessfulFee, the most the main contract can
    ///  ever take is simply the amount of unsuccessfulFee.
    /// @param _newMinTotal The minimumTotalValue value to set.
    /// @param _unsuccessfulFee The unsuccessfulFee value used to check if the _minTotal specified
    ///  is too low.
    function _setMinimumTotalValue(uint256 _newMinTotal, uint256 _unsuccessfulFee) internal {
        require(_newMinTotal >= (2 * _unsuccessfulFee), "minimum value must be >= 2 * unsuccessful fee");
        minimumTotalValue = _newMinTotal;
    }

    /// @dev As offerCut is a basis point, the value to set must be less than or equal to 10000.
    /// @param _newOfferCut The offerCut value to set.
    function _setOfferCut(uint256 _newOfferCut) internal {
        require(_newOfferCut <= 1e4, "offer cut must be a valid basis point");
        offerCut = _newOfferCut;
    }

    /// @dev As minimumPriceIncrement is a basis point, the value to set must be less than or equal to 10000.
    /// @param _newMinimumPriceIncrement The minimumPriceIncrement value to set.
    function _setMinimumPriceIncrement(uint256 _newMinimumPriceIncrement) internal {
        require(_newMinimumPriceIncrement <= 1e4, "minimum price increment must be a valid basis point");
        minimumPriceIncrement = _newMinimumPriceIncrement;
    }
}

// File: contracts/offers/OffersBase.sol

/// @title Base contract for Crypto Skully Offers. Holds all common structs, events, and base variables.
contract OffersBase is OffersConfig {
    /*** EVENTS ***/

    /// @notice The OfferCreated event is emitted when an offer is created through
    ///  createOffer method.
    /// @param tokenId The token id that a bidder is offering to buy from the owner.
    /// @param bidder The creator of the offer.
    /// @param expiresAt The timestamp when the offer will be expire.
    /// @param total The total eth value the bidder sent to the Offer contract.
    /// @param offerPrice The eth price that the owner of the token will receive
    ///  if the offer is accepted.
    event OfferCreated(
        uint256 tokenId,
        address bidder,
        uint256 expiresAt,
        uint256 total,
        uint256 offerPrice
    );

    /// @notice The OfferCancelled event is emitted when an offer is cancelled before expired.
    /// @param tokenId The token id that the cancelled offer was offering to buy.
    /// @param bidder The creator of the offer.
    /// @param bidderReceived The eth amount that the bidder received as refund.
    /// @param fee The eth amount that Root received as the fee for the cancellation.
    event OfferCancelled(
        uint256 tokenId,
        address bidder,
        uint256 bidderReceived,
        uint256 fee
    );

    /// @notice The OfferFulfilled event is emitted when an active offer has been fulfilled, meaning
    ///  the bidder now owns the token, and the orignal owner receives the eth amount from the offer.
    /// @param tokenId The token id that the fulfilled offer was offering to buy.
    /// @param bidder The creator of the offer.
    /// @param owner The original owner of the token who accepted the offer.
    /// @param ownerReceived The eth amount that the original owner received from the offer
    /// @param fee The eth amount that Root received as the fee for the successfully fulfilling.
    event OfferFulfilled(
        uint256 tokenId,
        address bidder,
        address owner,
        uint256 ownerReceived,
        uint256 fee
    );

    /// @notice The OfferUpdated event is emitted when an active offer was either extended the expiry
    ///  or raised the price.
    /// @param tokenId The token id that the updated offer was offering to buy.
    /// @param bidder The creator of the offer, also is whom updated the offer.
    /// @param newExpiresAt The new expiry date of the updated offer.
    /// @param totalRaised The total eth value the bidder sent to the Offer contract to raise the offer.
    ///  if the totalRaised is 0, it means the offer was extended without raising the price.
    event OfferUpdated(
        uint256 tokenId,
        address bidder,
        uint256 newExpiresAt,
        uint256 totalRaised
    );

    /// @notice The ExpiredOfferRemoved event is emitted when an expired offer gets removed. The eth value will
    ///  be returned to the bidder's account, excluding the fee.
    /// @param tokenId The token id that the removed offer was offering to buy
    /// @param bidder The creator of the offer.
    /// @param bidderReceived The eth amount that the bidder received from the offer.
    /// @param fee The eth amount that Root received as the fee.
    event ExpiredOfferRemoved(
        uint256 tokenId,
        address bidder,
        uint256 bidderReceived,
        uint256 fee
    );

    /// @notice The BidderWithdrewFundsWhenFrozen event is emitted when a bidder withdrew their eth value of
    ///  the offer when the contract is frozen.
    /// @param tokenId The token id that withdrawed offer was offering to buy
    /// @param bidder The creator of the offer, also is whom withdrawed the fund.
    /// @param amount The total amount that the bidder received.
    event BidderWithdrewFundsWhenFrozen(
        uint256 tokenId,
        address bidder,
        uint256 amount
    );


    /// @dev The PushFundsFailed event is emitted when the Offer contract fails to send certain amount of eth
    ///  to an address, e.g. sending the fund back to the bidder when the offer was overbidden by a higher offer.
    /// @param tokenId The token id of an offer that the sending fund is involved.
    /// @param to The address that is supposed to receive the fund but failed for any reason.
    /// @param amount The eth amount that the receiver fails to receive.
    event PushFundsFailed(
        uint256 tokenId,
        address to,
        uint256 amount
    );

    /*** DATA TYPES ***/

    /// @dev The Offer struct. The struct fits in two 256-bits words.
    struct Offer {
        // Time when offer expires
        uint64 expiresAt;
        // Bidder The creator of the offer
        address bidder;
        // Offer cut in basis points, which ranges from 0-10000.
        uint16 offerCut;
        // Total value (in wei) a bidder sent in msg.value to create the offer
        uint128 total;
        // Fee (in wei) that Admin takes when the offer is expired or overbid.
        // the `unsuccessfulFee` for new offers.
        uint128 unsuccessfulFee;
    }

    /*** STORAGE ***/
    /// @notice Mapping from token id to its corresponding offer.
    /// @dev One token can only have one offer.
    ///  Making it public so that solc-0.4.24 will generate code to query offer by a given token id.
    mapping (uint256 => Offer) public tokenIdToOffer;

    /// @notice computes the minimum offer price to overbid a given offer with its offer price.
    ///  The new offer price has to be a certain percentage, which defined by `minimumPriceIncrement`,
    ///  higher than the previous offer price.
    /// @dev This won't overflow, because `_offerPrice` is in uint128, and `minimumPriceIncrement`
    ///  is 16 bits max.
    /// @param _offerPrice The amount of ether in wei as the offer price
    /// @return The minimum amount of ether in wei to overbid the given offer price
    function _computeMinimumOverbidPrice(uint256 _offerPrice) internal view returns (uint256) {
        return _offerPrice * (1e4 + minimumPriceIncrement) / 1e4;
    }

    /// @notice Computes the offer price that the owner will receive if the offer is accepted.
    /// @dev This is safe against overflow because msg.value and the total supply of ether is capped within 128 bits.
    /// @param _total The total value of the offer. Also is the msg.value that the bidder sent when
    ///  creating the offer.
    /// @param _offerCut The percentage in basis points that will be taken by the Admin if the offer is fulfilled.
    /// @return The offer price that the owner will receive if the offer is fulfilled.
    function _computeOfferPrice(uint256 _total, uint256 _offerCut) internal pure returns (uint256) {
        return _total * 1e4 / (1e4 + _offerCut);
    }

    /// @notice Check if an offer exists or not by checking the expiresAt field of the offer.
    ///  True if exists, False if not.
    /// @dev Assuming the expiresAt field is from the offer struct in storage.
    /// @dev Since expiry check always come right after the offer existance check, it will save some gas by checking
    /// both existance and expiry on one field, as it only reads from the storage once.
    /// @param _expiresAt The time at which the offer we want to validate expires.
    /// @return True or false (if the offer exists not).
    function _offerExists(uint256 _expiresAt) internal pure returns (bool) {
        return _expiresAt > 0;
    }

    /// @notice Check if an offer is still active by checking the expiresAt field of the offer. True if the offer is,
    ///  still active, False if the offer has expired,
    /// @dev Assuming the expiresAt field is from the offer struct in storage.
    /// @param _expiresAt The time at which the offer we want to validate expires.
    /// @return True or false (if the offer has expired or not).
    function _isOfferActive(uint256 _expiresAt) internal view returns (bool) {
        return now < _expiresAt;
    }

    /// @dev Try pushing the fund to an address.
    /// @notice If sending the fund to the `_to` address fails for whatever reason, then the logic
    ///  will continue and the amount will be kept under the LostAndFound account. Also an event `PushFundsFailed`
    ///  will be emitted for notifying the failure.
    /// @param _tokenId The token id for the offer.
    /// @param _to The address the main contract is attempting to send funds to.
    /// @param _amount The amount of funds (in wei) the main contract is attempting to send.
    function _tryPushFunds(uint256 _tokenId, address _to, uint256 _amount) internal {
        // Sending the amount of eth in wei, and handling the failure.
        // The gas spent transferring funds has a set upper limit
        bool success = _to.send(_amount);
        if (!success) {
            // If failed sending to the `_to` address, then keep the amount under the LostAndFound account by
            // accumulating totalLostAndFoundBalance.
            totalLostAndFoundBalance = totalLostAndFoundBalance + _amount;

            // Emitting the event lost amount.
            emit PushFundsFailed(_tokenId, _to, _amount);
        }
    }
}

// File: contracts/offers/SkullOffers.sol

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
