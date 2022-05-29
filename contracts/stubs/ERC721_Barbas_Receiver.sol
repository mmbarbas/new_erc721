//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import '../ERC721_Barbas.sol';


contract ERC721_Barbas_Receiver is ERC721Barbas__Receiver{
    
    event Received(address operator, address from, uint256 tokenId, bytes data, uint256 gas);

    

    function onERC721_Barbas_Received(address operator,address from,uint256 idToken,bytes memory data) public override returns (bytes4) {
        
        //assembly { switch case} -> not used because consumes more gas
           
        bytes memory foo = hex"01";
        bytes memory foo2 = hex"02";


        if (keccak256(data) == keccak256(foo)) {
            revert('reverted in the receiver contract!');
        }
        if (keccak256(data) == keccak256(foo2)) {
            return 0x0;
        }
        
        emit Received(operator, from, idToken, data, 20000);
        return ERC721Barbas__Receiver.onERC721_Barbas_Received.selector;
 }
}