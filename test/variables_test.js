const { expect } = require("chai");
const { ethers } = require("hardhat");



describe("No minted tokens functions", function()  {
  let myContract,deployer, minter;

  beforeEach(async () =>{
    const ERC721_Barbas = await ethers.getContractFactory('ERC721_Barbas');
    myContract = await ERC721_Barbas.deploy('ERC721_token','Barbas');
    [deployer, minter] = await ethers.getSigners();
  });

  it('check name', async () => {
    expect(await myContract.getName()).to.be.equal('ERC721_token');
  });

  it('check symbol', async () => {
    expect(await myContract.getSymbol()).to.be.equal('Barbas');
  });

  describe('tokenURI', function () {
    it('returns an empty string if no baseURI is set', async () => {
      await myContract.connect(minter)._safeMint(minter.address,1);

      expect(await myContract.getTokenURI(0)).to.be.equal('');
    });

    it('reverts if given token id does not exist', async () => {
      await expect(myContract.getTokenURI(0)).to.be.reverted;
    });
  });
});