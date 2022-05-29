//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IERC721_Barbas {

    //Emits when approval function is called 
    event Approval(address indexed prevOwner, address indexed to, uint256 indexed idToken);
    
    //Emits when approval all function is called
    event ApprovalForAll(address indexed owner, address indexed operator, bool isApproved);

    //Emits is done a transfer of tokens
    event Transfer(address indexed from, address indexed to, uint256 indexed idToken);

    //Custom errors
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
    error MintZeroQuantity();
    error TransferFromIncorrectOwner();

}