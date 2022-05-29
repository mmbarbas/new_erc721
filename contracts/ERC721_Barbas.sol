//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import './IERC721_Barbas.sol';

interface ERC721Barbas__Receiver {
    function onERC721_Barbas_Received(address operator, address from, uint256 tokenId,bytes calldata data) external returns (bytes4);
}

contract ERC721_Barbas is IERC721_Barbas{
    
   // Mask of an entry in packed address data.
    uint256 private constant BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant BITMASK_BURNED = 1 << 224;
    
    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITMASK_NEXT_INITIALIZED = 1 << 225;


    uint256 private _curentTokenIndex;

    //Token name
    string private _name;

    //Token symbol
    string private _symbol;

    //Tokens burned
    uint256 internal _counterBurnedToks;

    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    //Mapping token ID to correct address
    mapping(uint256 => address) private _tokenApprovs;

    //Mapping owner to opperator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovs;

    constructor(string memory name, string memory tokenSymbol) {
        _name = name;
        _symbol = tokenSymbol;
        _curentTokenIndex = initIdToken();
    }


    function initIdToken() public view virtual returns(uint256) {
        return 0;
    }

    function nextTokenIdToMint() public view returns(uint256) {
        return _curentTokenIndex;
    }

    function totalTokenMinted() public view returns(uint256) {
        unchecked {
            return _curentTokenIndex - initIdToken();
        }
    }

    function totalSupply() public view returns (uint256) {
        //No need for check because _counterBurnedToks is never > (_curentTokenIndex - initIdToken())
        unchecked {
            return totalTokenMinted() - _counterBurnedToks;
        }
    }


    function tokenOwner(uint256 idToken) public view virtual returns(address) {
       return address(uint160(_packedOwnershipOf(idToken)));
    }

    function getName() public view virtual returns (string memory) {
        return _name;
    }
   
    function getSymbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function getTokenURI(uint256 idToken) public view virtual returns(string memory) {
        if(!hasToken(idToken)) revert URIQueryForNonExistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0  ? string(abi.encodePacked(baseURI, toString(idToken))): "";
    }



    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }


    // --------------------------  Approval functions ---------------------------------

    function approve(address to, uint256 idToken) public virtual {
        address owner = tokenOwner(idToken);

        if(to == owner) revert ApprovalToCurrentOwner();

        //console.log("sender" ,msg.sender);
       //console.log("owner" ,owner);
        //console.log("function" ,isAllApproved(owner,msg.sender));

        if(msg.sender != owner) {
            if(!isAllApproved(owner,msg.sender)) {
                revert ApproveCallerIsNotOwnerNorApprovedForAll();
            }
        }
        //if(msg.sender != owner && !isAllApproved(owner,msg.sender)) revert ApproveCallerIsNotOwnerNorApprovedForAll();
    
        _tokenApprovs[idToken] = to;
        emit Approval(tokenOwner(idToken),to,idToken); 

    }

    function getApproved(uint256 idToken) public view virtual returns(address) {
        if(!hasToken(idToken)) revert ApprovedQueryForNonExistentToken();

        return _tokenApprovs[idToken];
    }

    function setApprovalForAll(address operator, bool isApproved) public virtual{
        if(operator == msg.sender) revert ApproveToCaller();

        _operatorApprovs[msg.sender][operator]=isApproved; 
        emit ApprovalForAll(msg.sender, operator, isApproved);
    }

    function isAllApproved(address owner, address opperator) public view virtual returns (bool) {
        return _operatorApprovs[owner][opperator];
    }   

    // -------------------------- End approval functions ---------------------------------

    //--------------------------  Transfer functions -------------------------------------

    function transferFrom(address from, address to, uint256 idToken) public virtual {
        if(!ownerOrApproved(msg.sender, idToken))revert TransferCallerIsNotOwnerNorApproved();

        _transfer(from, to, idToken);

    }

    function safeTransfer(address from, address to, uint256 idToken) public virtual {
        safeTransfer(from,to,idToken,"");
    }

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

      function _transfer(address from, address to, uint256 idToken) private {
        
        uint256 previousOnwerPackInfo = _packedOwnershipOf(idToken);
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
            --_packedAddressData[from]; //Account balances -1
            ++_packedAddressData[to]; //Account balances +1

            _packedOwnerships[idToken] = _addressToUint256(to) | (block.timestamp << BITPOS_START_TIMESTAMP) | BITMASK_NEXT_INITIALIZED;

            if (previousOnwerPackInfo & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = idToken + 1;
                // If the next slot's address is zero
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _curentTokenIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = previousOnwerPackInfo;
                    }
                }
            }
        }

        emit Transfer(from,to,idToken);
        _afterTokenTransfers(from, to, idToken, 1);

    }


    //--------------------------  End transfer functions ---------------------------------


    //--------------------------  Mint functions -------------------------------------

    function _safeMint(address to, uint256 quantity) public virtual {
        _safeMint2(to,quantity,"");
    }

    function _safeMint2(address to, uint256 quantity ,bytes memory _data) public virtual {
        uint256 startTokId = _curentTokenIndex;

        if(to == address(0)) revert MintToTheZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokId, quantity);

        unchecked {
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);
            _packedOwnerships[startTokId] =_addressToUint256(to) | (block.timestamp << BITPOS_START_TIMESTAMP) | (_boolToUint256(quantity == 1) << BITPOS_NEXT_INITIALIZED);
        
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

    function _mint(address to, uint256 quantity) public virtual {
        uint256 startTokId = _curentTokenIndex;

        if(to == address(0)) revert MintToTheZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokId, quantity);

        unchecked {
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);
            _packedOwnerships[startTokId] =_addressToUint256(to) | (block.timestamp << BITPOS_START_TIMESTAMP) | (_boolToUint256(quantity == 1) << BITPOS_NEXT_INITIALIZED);
        
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

    function burn(uint256 idToken) public virtual {
        burn(idToken, false);
    }

    function burn(uint256 idToken, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(idToken);
        address from = address(uint160(prevOwnershipPacked));
        address approvedAddress = _tokenApprovs[idToken];

        if(approvalCheck) {
            if(!ownerOrApproved(msg.sender, idToken)) revert TransferCallerIsNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), idToken, 1);
        //approve(address(0), idToken);
        if (_addressToUint256(approvedAddress) != 0) {
            delete _tokenApprovs[idToken];
        }


        unchecked {
            _packedAddressData[from] -= 1;
            _packedAddressData[from] += (1 << BITPOS_NUMBER_BURNED);

            _packedOwnerships[idToken] = _addressToUint256(from) | (block.timestamp << BITPOS_START_TIMESTAMP) | BITMASK_BURNED |  BITMASK_NEXT_INITIALIZED;
            
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = idToken + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _curentTokenIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        
        }

        emit Transfer(from, address(0),idToken);
        _afterTokenTransfers(from, address(0), idToken, 1);

            // Overflow not possible
        unchecked {
            _counterBurnedToks++;
        }
    }

    function totalBurn() public view returns(uint256) {
        return _counterBurnedToks;
    }

    //---------------------------End burn functions-----------------------------------


    //-------------------------- Aux function ------------------------------------
    
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

    function _beforeTokenTransfers(address from,address to,uint256 startTokenId, uint256 quantity) internal virtual {}
    function _afterTokenTransfers(address from,address to,uint256 startTokenId, uint256 quantity) internal virtual {}

    function hasToken(uint256 idToken) internal view virtual returns (bool) {
            return (initIdToken() <= idToken && idToken < _curentTokenIndex && _packedOwnerships[idToken] & BITMASK_BURNED == 0);
    }

    function _addressToUint256(address value) private pure returns (uint256 result) {
        assembly {
            result := value
        }
    }

    function _boolToUint256(bool value) private pure returns (uint256 result) {
        assembly {
            result := value
        }
    }

     //Converts uint256 to string
    function toString(uint256 value) public pure returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), 
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length, 
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for { 
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp { 
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } { // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }
            
            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }

    function toStrin2(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    //-------------------------- End aux funtions --------------------------------

   
    // Functions from packed owner info

    
    function balanceOf(address owner) public view virtual returns(uint256){
        if(owner == address(0)) revert BalanceQueryForZeroAddress();
        
        return _packedAddressData[owner] & BITMASK_ADDRESS_DATA_ENTRY;
    }

    function _numberMintedByOwner(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_MINTED) & BITMASK_ADDRESS_DATA_ENTRY;
    }
    
    function _numberBurnedByOwner(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_BURNED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    function _getAuxByOwner(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> BITPOS_AUX); 
    }

   
    function _setAuxByOwner(address owner, uint64 aux) internal {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        assembly { // Cast aux without masking.
            auxCasted := aux
        }
        packed = (packed & BITMASK_AUX_COMPLEMENT) | (auxCasted << BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // End Functions from packed owner info

    // Functions from packed token info

    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 toke = tokenId;

        unchecked {
            if (initIdToken() <= toke)
                if (toke < _curentTokenIndex) {
                    uint256 packed = _packedOwnerships[toke];
                    if (packed & BITMASK_BURNED == 0) {
                        while (packed == 0) {
                            packed = _packedOwnerships[--toke];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonExistentToken();
    }

    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> BITPOS_START_TIMESTAMP);
        ownership.burned = packed & BITMASK_BURNED != 0;
    }

    function _ownershipAt(uint256 index) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    function _initializeOwnershipAt(uint256 index) internal {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    // End functions from packed token info


}