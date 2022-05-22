//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IERC721_Barbas {

    event Approval(address indexed prevOwner, address indexed to, uint256 indexed idToken);
    
    event ApprovalForAll(address indexed owner, address indexed operator, bool isApproved);

    event Transfer(address indexed from, address indexed to, uint256 indexed idToken);

    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOwner(uint256 id) external view returns (address adrss);

}