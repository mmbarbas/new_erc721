// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


contract ERC721_OppenZepplin is ERC721Enumerable {
    address[] internal _test;
    string public baseURI = "";
    uint256 public maxTokensPerWallet = 200;

    constructor() ERC721("ERC721_OppenZepplin", "opzzp") { }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function MintBatch(address to,uint256 number) public {
        uint256 supply = totalSupply();
        for( uint i; i < number; ++i ) {
            _mint(to, supply + i);
        }
    }

    function SafeMintBatch(address to,uint256 number) public {
        uint256 supply = totalSupply();
        for( uint i; i < number; ++i ) {
            _safeMint(to, supply + i);
        }
    }   

    function TransferFrom(address from, address to,uint256 idToken) public {
       transferFrom(from,to,idToken);
    }
    function Burn(uint256 idToken) public {
        _burn(idToken);
    }



}