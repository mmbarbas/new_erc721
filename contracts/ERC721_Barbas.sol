//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import './IERC721_Barbas.sol';

/**
 * @dev Token receiver interface.
 */
interface ERC721Barbas__Receiver {
    function onERC721_Barbas_Received(address operator, address from, uint256 tokenId,bytes calldata data) external returns (bytes4);
}
/**
    @dev Implementation of the token ERC721 with focus on the gas optimization for the
         batch minting as well as the transfer of tokens.

         In the test folder there is a script to specifically test gas comsuption.

         Tokens are sequentially minted.

 */
contract ERC721_Barbas is IERC721_Barbas{
    
    /**
        Variables to manipulate bits of _accountData.
        _accountData has 4 diferent values stored inside each uint256
             - [0..63]    `balance`
             - [64..127]  `numberMinted`
             - [128..191] `numberBurned`
             - [192..255] `aux`
     */
    uint256 private constant BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;
    uint256 private constant BITPOS_NUMBER_MINTED = 64;
    uint256 private constant BITPOS_NUMBER_BURNED = 128;
    uint256 private constant BITPOS_AUX = 192;
    uint256 private constant BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    mapping(address => uint256) private _accountData;
    //token -> adresses (addresses in uint256)
    mapping(uint256 => uint256) private _tokenOwnerships;

    //Id of the next token to be minted
    uint256 private _curentTokenIndex;

    //Token name
    string private _name;
    
    //Token symbol
    string private _symbol;

    //Number of burned tokens
    uint256 internal _counterBurnedToks;

    
    //Mapping token ID to correct address
    mapping(uint256 => address) private _tokenApprovs;

    //Mapping owner to opperator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovs;

    /**
    @dev Initializes the contract by setting a `name`,`symbol` and the id of the next token to be minted as 0.    
    */
    constructor(string memory name, string memory tokenSymbol) {
        _name = name;
        _symbol = tokenSymbol;
        _curentTokenIndex = initIdToken();
    }

    /**
        @dev returns the id of the first token -> 0
     */
    function initIdToken() public view virtual returns(uint256) {
        return 0;
    }

    /**
        @dev returns the id of the next token to be minted
     */
    function nextTokenIdToMint() public view returns(uint256) {
        return _curentTokenIndex;
    }

    /**
        @dev returns the total minted tokens
    */
    function totalTokenMinted() public view returns(uint256) {
        unchecked {
            return nextTokenIdToMint() - initIdToken();
        }
    }
    
    /**
        @dev returns the total available minted tokens, having in consideration the burned tokens
    */
    function totalSupply() public view returns (uint256) {
        //No need for check because _counterBurnedToks is never > (_curentTokenIndex - initIdToken())
        unchecked {
            return totalTokenMinted() - totalBurn();
        }
    }

    /**
        @dev Function to know whos the token owner
        @param idToken intenger representing the token
        @return address of the token owner
    */
    function tokenOwner(uint256 idToken) public view virtual returns(address) {
       return address(uint160(getTokenOwner(idToken)));
    }

    /**
        @dev Returns the name of the token type created
     */
    function getName() public view virtual returns (string memory) {
        return _name;
    }
   
    /**
        @dev Returns the name of the symbol created
     */
    function getSymbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
        @dev Returns the uri associated to the token
     */
    function getTokenURI(uint256 idToken) public view virtual returns(string memory) {
        if(!hasToken(idToken)) revert URIQueryForNonExistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0  ? string(abi.encodePacked(baseURI, toString(idToken))): "";
    }

    /**
      @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
      token will be the concatenation of the `baseURI` and the `tokenId`. Empty
      by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
        @dev Checks if the token exists or not. Meaning to check if was minted or
        if it doesn't exist/was burned
     */
    function hasToken(uint256 idToken) internal view virtual returns (bool) {
            return (initIdToken() <= idToken && idToken < _curentTokenIndex && _tokenOwnerships[idToken] != 1);
    }

    // --------------------------  Approval functions ---------------------------------

     /**
        @dev Makes an address eligible to tranfer the id token to other account
        @param to address of the account to make eligible to tranfer
        @param idToken authorized for the account 'to' to transfer
     */
    function approve(address to, uint256 idToken) public virtual {
        address owner = tokenOwner(idToken);
  
        if(to == owner) revert ApprovalToCurrentOwner();

        if(msg.sender != owner) {
            if(!isAllApproved(owner,msg.sender)) {
                revert ApproveCallerIsNotOwnerNorApprovedForAll();
            }
        }    
        _tokenApprovs[idToken] = to;
        emit Approval(tokenOwner(idToken),to,idToken); 

    }
    /**
        @dev Returns the account approved for tokenId token.
     */
    function getApproved(uint256 idToken) public view virtual returns(address) {
        if(!hasToken(idToken)) revert ApprovedQueryForNonExistentToken();

        return _tokenApprovs[idToken];
    }

    /**
        @dev Approve or remove operator as an operator for the caller. 
        Operators can call transferFrom or safeTransferFrom for any token owned by the caller.
     */
    function setApprovalForAll(address operator, bool isApproved) public virtual{
        if(operator == msg.sender) revert ApproveToCaller();

        _operatorApprovs[msg.sender][operator]=isApproved; 
        emit ApprovalForAll(msg.sender, operator, isApproved);
    }

      /**
        @dev Returns if the operator is allowed to manage all of the assets of owner.
     */
    function isAllApproved(address owner, address opperator) public view virtual returns (bool) {
        return _operatorApprovs[owner][opperator];
    }   

    // -------------------------- End approval functions ---------------------------------

    //--------------------------  Transfer functions -------------------------------------

    /**
        @dev transfers the token 'form' one account to the othe account 'to'
     */
    function transferFrom(address from, address to, uint256 idToken) public virtual {
        if(!ownerOrApproved(msg.sender, idToken))revert TransferCallerIsNotOwnerNorApproved();

        _transfer(from, to, idToken);

    }

    /**
        @dev Safely transfers tokenId token from from to to.
    */
    function safeTransfer(address from, address to, uint256 idToken) public virtual {
        safeTransfer(from,to,idToken,"");
    }

    /**
        @dev Safely transfers tokenId token from from to to.
    */
    function safeTransfer(address from, address to, uint256 idToken, bytes memory data) public virtual {
        _transfer(from,to,idToken);

        if(to.code.length != 0)
            if(!_checkContractOnERC721Received(from, to, idToken, data)) {
                        revert TransferToNonERC721ReceiverImplementer();
            }
    }

  
    function ownerOrApproved(address caller, uint256 idToken) internal view virtual returns(bool) {        
        if(!hasToken(idToken)) revert OperatorQueryForNonExistentToken();

         address owner = tokenOwner(idToken);
        return (owner == caller || getApproved(idToken) == caller || isAllApproved(owner,caller));
    }

    
    /**
        @dev Makes the transfer.
        Verifies if the the token owner is equal to the addres 'from'
        Verifies if the address 'from' is authorized to make that transfer
        Verifies if the adress destination, 'to', is no 0
        Emits a transfer Event
    */
    function _transfer(address from, address to, uint256 idToken) private {
        
        uint256 previousOnwerPackInfo = getTokenOwner(idToken);
        address approvedAddress = _tokenApprovs[idToken];

        if(tokenOwner(idToken)!= from) revert TransferOfTokenThatIsNotOwn();
        if(!ownerOrApproved(msg.sender, idToken))revert TransferCallerIsNotOwnerNorApproved();
        if(to == address(0)) revert TransferToTheZeroAddress();

        _beforeTokenTransfers(from, to, idToken,1);    
       // approve(address(0), idToken);
        if (_addressToUint256(approvedAddress) != 0) {
            delete _tokenApprovs[idToken];
        }

        unchecked {
            --_accountData[from]; //Account balances -1
            ++_accountData[to]; //Account balances +1

            _tokenOwnerships[idToken] = _addressToUint256(to);

            uint256 nextTokenId = idToken + 1;
                // If the next slot's address is zero
            if (_tokenOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                if (nextTokenId != _curentTokenIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                    _tokenOwnerships[nextTokenId] = previousOnwerPackInfo;
                }
            }
        }

        emit Transfer(from,to,idToken);
        _afterTokenTransfers(from, to, idToken, 1);

    }


    //--------------------------  End transfer functions ---------------------------------


    //--------------------------  Mint functions -------------------------------------

    /**
        @dev safe mint of token(s) to a specific adress, 'to'
        @param to address of minted tokens destination
        @param quantity amount of tokens to be minted
     */
    function _safeMint(address to, uint256 quantity) public virtual {
        _safeMint2(to,quantity,"");
    }

     /**
        @dev safe mint of token(s) to a specific adress, 'to'
        @param to address of minted tokens destination
        @param quantity amount of tokens to be minted

        Requirements:
            address 'to' must exist
            quantity of tokens to be minted > 0
     */
    function _safeMint2(address to, uint256 quantity ,bytes memory _data) public virtual {
        uint256 startTokId = _curentTokenIndex;

        if(to == address(0)) revert MintToTheZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokId, quantity);

        unchecked {
            _accountData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);
            
            _tokenOwnerships[startTokId] =_addressToUint256(to) ;


            uint256 updatedIndex = startTokId;
            uint256 endTokensOwned = updatedIndex + quantity;
            if (to.code.length != 0) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex < endTokensOwned);
                if (_curentTokenIndex != startTokId) revert();
            } else {
             do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex < endTokensOwned);
            }
            _curentTokenIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokId, quantity);
    }

  /**
        @dev mint of token(s) to a specific adress, 'to'
        @param to address of minted tokens destination
        @param quantity amount of tokens to be minted

        Requirements:
            address 'to' must exist
            quantity of tokens to be minted > 0
     */
    function _mint(address to, uint256 quantity) public virtual {
        uint256 startTokId = _curentTokenIndex;

        if(to == address(0)) revert MintToTheZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokId, quantity);

        unchecked {
            _accountData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);
            _tokenOwnerships[startTokId] =_addressToUint256(to) ;

            uint256 updatedIndex = startTokId;
            uint256 endTokensOwned = updatedIndex + quantity;

             do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex < endTokensOwned);
            _curentTokenIndex = updatedIndex;
        }
        
        _afterTokenTransfers(address(0), to, startTokId, quantity);
    }


    //--------------------------  End Mint functions ---------------------------------

    //-------------------------- Burn Functions---------------------------------------

    /**
        @dev burn of the given token
     */
    function burn(uint256 idToken) public virtual {
        burn(idToken, false);
    }

     /**
        @dev burn of the given token

        Requirements:
            The account that calls the methos must be an approved account to burn the token
     */
    function burn(uint256 idToken, bool approvalCheck) internal virtual {
        address from = address(uint160(getTokenOwner(idToken)));

        if(approvalCheck) {
            if(!ownerOrApproved(msg.sender, idToken)) revert TransferCallerIsNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), idToken, 1);
        approve(address(0), idToken);
  
        //overflow not possible
        unchecked {
            _accountData[from] += (1 << BITPOS_NUMBER_BURNED) - 1;

            // 1 = burned
            _tokenOwnerships[idToken] =1;
            _counterBurnedToks++;
        }

        emit Transfer(from, address(0),idToken);
        _afterTokenTransfers(from, address(0), idToken, 1);
      
    }
    /**
        @dev return the total tokens burned
     */
    function totalBurn() public view returns(uint256) {
        return _counterBurnedToks;
    }

    //---------------------------End burn functions-----------------------------------


    //-------------------------- Aux function ------------------------------------
    
    /**
     * @dev Function to invoke ERC721Barbas__Receiver a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param idToken id of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected value
     */
    function _checkContractOnERC721Received( address from, address to, uint256 idToken, bytes memory _data) private returns (bool) {
        try ERC721Barbas__Receiver(to).onERC721_Barbas_Received(msg.sender, from, idToken, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721Barbas__Receiver(to).onERC721_Barbas_Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

     /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     */
    function _beforeTokenTransfers(address from,address to,uint256 startTokenId, uint256 quantity) internal virtual {}
    
     /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     */
    function _afterTokenTransfers(address from,address to,uint256 startTokenId, uint256 quantity) internal virtual {}

     /**
     * @dev Casts the address to uint256.
     */
    function _addressToUint256(address value) private pure returns (uint256 result) {
        assembly {
            result := value
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) public pure returns (string memory ptr) {
        assembly {
            ptr := add(mload(0x40), 128)
            mstore(0x40, ptr)
            let end := ptr
            for { 
                let temp := value
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp { 
                temp := div(temp, 10)
            } { 
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }
            let length := sub(end, ptr)
            ptr := sub(ptr, 32)
            mstore(ptr, length)
        }
    }

    //-------------------------- End aux funtions --------------------------------

   
    // Functions from packed owner info

    /**
        @dev balance of tokens for the account 'owner'
     */    
    function balanceOf(address owner) public view virtual returns(uint256){
        if(owner == address(0)) revert BalanceQueryForZeroAddress();
        
        return _accountData[owner] & BITMASK_ADDRESS_DATA_ENTRY;
    }

      /**
        @dev returns the minted tokens by the owner
     */    
    function _numberMintedByOwner(address owner) internal view returns (uint256) {
        return (_accountData[owner] >> BITPOS_NUMBER_MINTED) & BITMASK_ADDRESS_DATA_ENTRY;
    }
    
    /**
        @dev returns the burned tokens by the owner
     */ 
    function _numberBurnedByOwner(address owner) internal view returns (uint256) {
        return (_accountData[owner] >> BITPOS_NUMBER_BURNED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
      @dev Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAuxByOwner(address owner) internal view returns (uint64) {
        return uint64(_accountData[owner] >> BITPOS_AUX); 
    }

   /**
    @dev Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
    */
    function _setAuxByOwner(address owner, uint64 aux) internal {
        uint256 packed = _accountData[owner];
        uint256 auxCasted;
        assembly { // Cast aux without masking.
            auxCasted := aux
        }
        packed = (packed & BITMASK_AUX_COMPLEMENT) | (auxCasted << BITPOS_AUX);
        _accountData[owner] = packed;
    }

    // End Functions from packed owner info

    // Functions from packed token info

    /**
        @dev Returns in uint256 the owner of the token. 
        The value return need after to be coverted to an address like this: address(unit160(unit256_value))

     */
    function getTokenOwner(uint256 tokenId) private view returns (uint256) {
        uint256 toke = tokenId;
     
        unchecked {
            if (initIdToken() <= toke)
                if (toke < _curentTokenIndex) {
                    uint256 packed = _tokenOwnerships[toke];
                    if (packed != 1) {
                        while (packed == 0) {
                            packed = _tokenOwnerships[--toke];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonExistentToken();
    }

    // End functions from packed token info


}