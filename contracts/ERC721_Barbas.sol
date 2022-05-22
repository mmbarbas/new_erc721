//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import './IERC721_Barbas.sol';

contract ERC721_Barbas is IERC721_Barbas{
    
    //Token name
    string private _name;

    //Token symbol
    string private _symbol;

    //Tokens burned
    uint256 internal _counterBurnToks;

    address[] internal _tokens = [address(0x0)];

    //Mapp token count to each address
    mapping(address => uint256) private _balance;

    //Mapping token ID to correct address
    mapping(uint256 => address) private _tokenApprovs;

    //Mapping owner to opperator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovs;

    error BalanceQueryForZeroAddress();
    error OwnerIndexOutOfBounds();
    error ApprovalToCurrentOwner();
    error URIQueryForNonExistentToken();
    error OwnerQueryForNonExistentToken();
    error ApproveToCaller();
    error ApprovedQueryForNonExistentToken();
    error TransferCallerIsNotOwnerNorApproved();
    error TransferToNonERC721ReceiverImplementer();
    error ApproveCallerIsNotOwnerNorApprovedForAll();
    error OperatorQueryForNonExistentToken();
    error TransferOfTokenThatIsNotOwn();
    error TransferToTheZeroAddress();
    error MintToTheZeroAddress();
    
    constructor(string memory name, string memory tokenSymbol) {
        _name = name;
        _symbol = tokenSymbol;
    }

    function unsafe_inc(uint256 x) private pure returns (uint) {
        unchecked { return x + 1; }
    }

    function totalTokenMinted() public view returns(uint256) {
        return _tokens.length - 1;
    }

    function totalUnminted() public view returns (uint256) {
        return totalTokenMinted() - _counterBurnToks;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256){
        uint256 currentI = 0;
        address[] memory tokensAux = _tokens;


        for(uint256 i= 0; i < _tokens.length; i = unsafe_inc(i)) 
        {
            if(tokensAux[i] == owner) {
                if(currentI == index) {
                    return i;
                }
                currentI +=1;
            }
        }

        revert OwnerIndexOutOfBounds();
    }

    function balanceOf(address owner) public view virtual override returns(uint256){
        if(owner == address(0)) revert BalanceQueryForZeroAddress();
        
        return _balance[owner];
    }

    function tokenOwner(uint256 idToken) public view virtual override returns(address) {
        address owner = _tokens[idToken];
        if(owner == address(0)) revert OwnerQueryForNonExistentToken(); 

        return owner;
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
        return bytes(baseURI).length > 0 
        ? string(abi.encodePacked(baseURI, toString(idToken)))
        : "";
    }

   
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }


    // --------------------------  Approval functions ---------------------------------

    function approve(address to, uint256 idToken) public virtual {
        address owner = tokenOwner(idToken);

        if(to == owner) revert ApprovalToCurrentOwner();

        if(msg.sender != owner && !isAllApproved(owner,msg.sender)) revert ApproveCallerIsNotOwnerNorApprovedForAll();
    
        _approve(to,idToken);
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

    function _approve(address to, uint256 idToken) internal virtual {
        _tokenApprovs[idToken] = to;
        emit Approval(tokenOwner(idToken),to,idToken); 
    }
    // -------------------------- End approval functions ---------------------------------

    //--------------------------  Transfer functions -------------------------------------

    function transferFrom(address from, address to, uint256 idToken) public virtual TokenAproveVerif(idToken){
       // if(!ownerOrApproved(msg.sender, idToken))revert TransferCallerIsNotOwnerNorApproved();

        _transfer(from, to, idToken);

    }

    function safeTransfer(address from, address to, uint256 idToken) public virtual {
        safeTransfer(from,to,idToken,"");
    }

    function safeTransfer(address from, address to, uint256 idToken, bytes memory data) public virtual TokenAproveVerif(idToken) {
        //if(!ownerOrApproved(msg.sender, idToken))revert TransferCallerIsNotOwnerNorApproved();

        _safeTransfer(from,to,idToken,data);
    }

    function _safeTransfer(address from, address to, uint256 idToken, bytes memory data) internal virtual {
        _transfer(from,to,idToken);
       //  if (!_checkOnERC721Received(from, to, tokenId, _data)) revert TransferToNonERC721ReceiverImplementer();
        
    }

    function _transfer(address from, address to, uint256 idToken) internal virtual {
        if(tokenOwner(idToken)!= from) revert TransferOfTokenThatIsNotOwn();
        if(to == address(0)) revert TransferToTheZeroAddress();

        _beforeTokenTransfer(from, to, idToken);
        _approve(address(0), idToken);
        _balance[from] -= 1;
        _balance[to] += 1;
        _tokens[idToken] = to;

        emit Transfer(from,to,idToken);
    }

    function ownerOrApproved(address transferSponsor, uint256 idToken) internal view virtual returns(bool) {
        if(!hasToken(idToken)) revert OperatorQueryForNonExistentToken();

        address owner = tokenOwner(idToken);

        return (transferSponsor == owner || getApproved(idToken) == transferSponsor || isAllApproved(owner, transferSponsor));
    }

    //--------------------------  End transfer functions ---------------------------------


    //--------------------------  Mint functions -------------------------------------

    function _safeMint(address to) internal virtual {
        _safeMint(to,"");
    }

    function _safeMint(address to, bytes memory _data) internal virtual {
        _mint(to);
        //if (!_checkOnERC721Received(address(0), to, _tokens.length - 1, _data)) revert TransferToNonERC721ReceiverImplementer();
        
    }

    function _mint(address to) internal virtual {
        if(to == address(0)) revert MintToTheZeroAddress();

        uint256 idToken =_tokens.length;
        _beforeTokenTransfer(address(0),to,idToken);
        _balance[to] += 1;
        _tokens.push(to);
        
        emit Transfer(address(0),to,idToken);

    }


    //--------------------------  End Mint functions ---------------------------------

    //-------------------------- Burn Functions---------------------------------------

    function burn(uint256 idToken) internal virtual {
        //Token must exist

        address owner = tokenOwner(idToken);
        _beforeTokenTransfer(owner,address(0),idToken);
        _approve(address(0), idToken);
        _counterBurnToks++;
        _balance[owner] -=1;
        _tokens[idToken] = address(0);

        emit Transfer(owner, address(0),idToken);

    }

    //---------------------------End burn functions-----------------------------------


    //-------------------------- Aux function ------------------------------------
    
    function _beforeTokenTransfer(address from,address to, uint256 tokenId) internal virtual {}

      function hasToken(uint256 idToken) internal view virtual returns (bool) {
        return _tokens[idToken] != address(0);
    }

     //Converts uint256 to string
    function toString(uint256 value) internal pure returns (string memory ptr) {
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
    //-------------------------- End aux funtions --------------------------------

   
    modifier TokenAproveVerif(uint256 idToken){
        if(!ownerOrApproved(msg.sender, idToken))revert TransferCallerIsNotOwnerNorApproved();
        _;
    }

}