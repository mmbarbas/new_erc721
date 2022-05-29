const { expect } = require("chai");
const { ethers } = require("hardhat");


describe("Burn tests", function()  {
  let myContract,deployer, minter, approved,operator;

  beforeEach(async () =>{
    const ERC721_Barbas = await ethers.getContractFactory('ERC721_Barbas');
    myContract = await ERC721_Barbas.deploy('ERC721_token','Barbas');
    [deployer, minter, approved, operator, receiver] = await ethers.getSigners();
  });

  it('reverts if attemping to burn token that does not exist', async () => {
    await expect(myContract.burn(0)).to.be.reverted;
  });

  it('increments burnCount to adjust totalSupply correctly', async () => {
    await myContract.connect(minter)._safeMint(minter.address,1);
    expect(await myContract.totalSupply()).to.be.equal(1);
    await myContract.connect(minter).burn(0);
    expect(await myContract.totalSupply()).to.be.equal(0);
  });

  it("clears approved, reduces owner's balance, and sets new owner as address 0", async () => {
    await myContract.connect(minter)._safeMint(minter.address,1);
    await myContract.connect(minter).approve(approved.address, 0);

    expect(await myContract.getApproved(0)).to.be.equal(approved.address);

    await myContract.connect(minter).burn(0);

   expect(await myContract.balanceOf(minter.address)).to.be.equal(0);

    await expect(myContract.getApproved(0)).to.be.revertedWith('ApprovedQueryForNonExistentToken');

    await expect(myContract.tokenOwner(0)).to.be.revertedWith('OwnerQueryForNonExistentToken');
  });

  it('emits a transfer request to address 0', async () => {  
    await myContract.connect(minter)._safeMint(minter.address,1);
    await expect(myContract.connect(minter).burn(0)).to.emit(myContract, 'Transfer').withArgs(minter.address, ethers.constants.AddressZero, 0);
  });  
    

});
