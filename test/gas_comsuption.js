const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Gas comsumption tests", function()  {
    let myContract,deployer, minter;
    let oppenzepplin,deployer2, minter2;
  
    beforeEach(async () =>{
      const ERC721_Barbas = await ethers.getContractFactory('ERC721_Barbas');
      myContract = await ERC721_Barbas.deploy('ERC721_token','Barbas');     
      
      [deployer, minter] = await ethers.getSigners(); 

      const ERC721 = await ethers.getContractFactory('ERC721_OppenZepplin');
      oppenzepplin = await ERC721.deploy();     
      
      [deployer2, minter2] = await ethers.getSigners(); 
    });

    context('Mint test', function(){
        context('Single mint each time', function(){
            describe('Mint function', function(){
                it('my mint 100 times', async function(){
                    for(let i = 0; i < 100; i++){
                        await myContract._mint(minter.address,1);
                    }
                });
                it('Oppenzepplin mint 100 times', async function(){
                    for(let i = 0; i < 100; i++){
                        await oppenzepplin.MintBatch(minter.address,1);
                    }
                });
            });
            describe('SafeMint function', function(){
                it('mint 100 times', async function(){
                    for(let i = 0; i < 100; i++){
                        await myContract._safeMint(minter.address,1);
                    }
                });
                it('Oppenzepplin mint 100 times', async function(){
                    for(let i = 0; i < 100; i++){
                        await oppenzepplin.SafeMintBatch(minter.address,1);
                    }
                });
            });
        });
        context('Multiple mint each time', function(){
            describe('Mint function', function(){
                it('mint 30 * 5 times', async function(){
                    for(let i = 0; i < 30; i++){
                        await myContract._mint(minter.address,5);
                    }
                });
                it('Oppenzepplin mint 30*5 times', async function(){
                    for(let i = 0; i < 30; i++){
                        await oppenzepplin.MintBatch(minter.address,5);
                    }
                });
            });
            describe('SafeMint function', function(){
                it('safemint 30 * 5 times', async function(){
                    for(let i = 0; i < 30; i++){
                        await myContract._safeMint(minter.address,5);
                    }
                });
                it('Oppenzepplin safemint 30*5 times', async function(){
                    for(let i = 0; i < 30; i++){
                        await oppenzepplin.SafeMintBatch(minter.address,5);
                    }
                });
            });
        });
    })
    
    context('Transfer from test', function () {
        it('transfer to and from two addresses', async function () {
          await myContract._mint(deployer.address,10);
          await myContract._mint(minter.address,10);
          for (let i = 0; i < 10; ++i) {
            await myContract.connect(deployer).transferFrom(deployer.address, minter.address, 0);
            await myContract.connect(minter).transferFrom(minter.address, deployer.address, 0);
          }  
        });

        it('oppenzeplin transfer to and from two addresses', async function () {
            await oppenzepplin.MintBatch(deployer2.address,10);
            await oppenzepplin.MintBatch(minter2.address,10);
            for (let i = 0; i < 10; ++i) {
              await oppenzepplin.connect(deployer2).TransferFrom(deployer2.address, minter2.address, i);
              await oppenzepplin.connect(minter2).TransferFrom(minter2.address, deployer2.address, i);
            }  
          });
      });
    context('burn token', function(){
        it('Burn', async()=>{
            await myContract._mint(minter.address,1);
            await myContract.connect(minter).burn(0);
        });
       it('Oppenzeplin Burn', async()=>{
            await oppenzepplin.MintBatch(minter2.address,1);
            await oppenzepplin.connect(minter2).Burn(0);
        });
    });
});