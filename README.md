# ERC721_Barbas implementation

This project focus in reducing the gas usage in the batch mint and transfer of the token ERC721.

Optimizations:
    1- update the owner data and balance once per batch mint request, instead of per minted NFT
    2- removing reduntant owner storage. Instead of storing for each token the owners address it's only saved the owner data for the first token as well as the number of minted tokens. Because the tokens minted sequentially, we can easily know from where to where the tokens belong to an certain account. 
   
