//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IERC721_Barbas {

    event Approval(address indexed prevOwner, address indexed to, uint256 indexed idToken);
    
    event ApprovalForAll(address indexed owner, address indexed operator, bool isApproved);

    event Transfer(address indexed from, address indexed to, uint256 indexed idToken);

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

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
        bool burned;
    }

}