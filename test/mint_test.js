const { expect } = require("chai");
const { ethers } = require("hardhat");

const RECEIVER_MAGIC_VALUE = '0x150b7a02';

  


describe("Mint tests", function()  {
  let myContract,deployer, minter, receiverStub;

  beforeEach(async () =>{
    const ERC721_Barbas = await ethers.getContractFactory('ERC721_Barbas');
    myContract = await ERC721_Barbas.deploy('ERC721_token','Barbas');
    
    const ERC721_Barbas_Receiver = await ethers.getContractFactory('ERC721_Barbas_Receiver');
    receiverStub = await ERC721_Barbas_Receiver.deploy();
    
    [deployer, minter,luckyJohn] = await ethers.getSigners();
  
  
  });

  const successfulMint = function (safe, quantity, mintForContract = true) {
    beforeEach(async function () {

      minter = mintForContract ? receiverStub : luckyJohn;

      const mintType = safe ? '_safeMint(address,uint256)' : '_mint(address,uint256)';

      this.mintTx = await myContract[mintType](minter.address, quantity);
    });


    it('checks ownership', async function () {
      for (let tokenId = 0; tokenId < quantity; tokenId++) {
        expect(await myContract.tokenOwner(tokenId)).to.equal(minter.address);
      }
    });
      it('emits a Transfer event', async function () {
      for (let tokenId = 0; tokenId < quantity; tokenId++) {
        await expect(this.mintTx).to.emit(myContract, 'Transfer').withArgs(ethers.constants.AddressZero, minter.address, tokenId);
      }
      });
  };

  const unsuccessfulMint = function (safe) {
    beforeEach(async function () {
      this.mintFn = safe ? '_safeMint(address,uint256)' : '_mint(address,uint256)';
    });

    it('rejects mints to the zero address', async function () {
      await expect(myContract[this.mintFn](ethers.constants.AddressZero, 1)).to.be.revertedWith('MintToTheZeroAddress');
    });

    it('requires quantity to be greater than 0', async function () {
      await expect(myContract[this.mintFn](minter.address, 0)).to.be.revertedWith('MintZeroQuantity');
    });
  };

  context('Successful Mint', function () {
    context('Normal mint', function(){
      context('to contract', function (){
        describe('single token', function(){
          successfulMint(false,1);
        });
        
        describe('multiple tokens', function(){
          successfulMint(false,5);
        });

        it('does not revert for non-receivers', async function () {
          const nonReceiver = myContract;
          await myContract._mint(nonReceiver.address, 1);
          expect(await myContract.tokenOwner(0)).to.equal(nonReceiver.address);
        });
      });
      context('to luckyJohn', function(){
        describe('single token', function(){
          successfulMint(false,1, false);
        });
        
        describe('multiple tokens', function(){
          successfulMint(false,5,false);
        });
      });
    });
    context('Safe mint', function(){
      context('to contract', function(){
        describe('single token', function(){
          successfulMint(true,1);
        });
        
        describe('multiple tokens', function(){
          successfulMint(true,5);
        });

       /* it.only('validates ERC721Received with data', async function () {
          const customData = ethers.utils.formatBytes32String('custom data');
          const tx = await myContract['_safeMint(address,uint256,bytes)'](receiverStub.address, 1, customData);
          await expect(tx).to.emit(receiverStub, 'Received').withArgs(minter.address, ethers.constants.AddressZero, 0, customData, 20000);
        });*/

      });
      context('to luckyJohn', function(){
        describe('single token', function(){
          successfulMint(true,1, false);
        });
        
        describe('multiple tokens', function(){
          successfulMint(true,5,false);
        });
      });
    });
  });
  context('Unsuccessful Mint', function() {
    context('mint', function () {
      unsuccessfulMint(false);
    });

    context('safeMint', function () {
      unsuccessfulMint(true);

      it('reverts for non-receivers', async function () {
        const nonReceiver = myContract;
        await expect(myContract['_safeMint(address,uint256)'](nonReceiver.address, 1)).to.be.revertedWith(
          'TransferToNonERC721ReceiverImplementer'
        );
      });

      it('reverts when the receiver reverted', async function () {
        await expect(
          myContract['_safeMint2(address,uint256,bytes)'](receiverStub.address, 1, '0x01')
        ).to.be.revertedWith('reverted in the receiver contract!');
      });

      it('reverts if the receiver returns the wrong value', async function () {
        await expect(
          myContract['_safeMint2(address,uint256,bytes)'](receiverStub.address, 1, '0x02')
        ).to.be.revertedWith('TransferToNonERC721ReceiverImplementer');
      });
  });
});

});
