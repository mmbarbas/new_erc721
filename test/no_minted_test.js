const { expect } = require("chai");
const { ethers } = require("hardhat");



describe("No minted tokens functions", function()  {
  let myContract,deployer, minter, approved,operator;

  beforeEach(async () =>{
    const ERC721_Barbas = await ethers.getContractFactory('ERC721_Barbas');
    myContract = await ERC721_Barbas.deploy('ERC721_token','Barbas');
    [deployer, minter, approved, operator, receiver] = await ethers.getSigners();
  });

  it("has 0 totalSupply", async ()=> {
    const supply = await myContract.totalSupply();
    expect(supply).to.equal(0);
  });

  it('has 0 totalMinted', async ()=> {
    const totalMinted = await myContract.totalTokenMinted();
    expect(totalMinted).to.equal(0);
  });

  it('has 0 totalBurned', async ()=> {
    const totalBurned = await myContract.totalBurn();
    expect(totalBurned).to.equal(0);
  });

  it('_nextTokenId must be equal to _startTokenId', async ()=> {
    const nextTokenId = await myContract.nextTokenIdToMint();
    const startToken = await myContract.initIdToken();
    expect(nextTokenId).to.equal(startToken);
  });

  context('_toString', async function () {
    it('returns correct value', async function () {
      expect(await myContract['toString(uint256)']('0')).to.eq('0');
      expect(await myContract['toString(uint256)']('1')).to.eq('1');
      expect(await myContract['toString(uint256)']('2')).to.eq('2');
    });
  });
});
