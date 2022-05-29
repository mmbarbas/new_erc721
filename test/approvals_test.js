const { expect } = require("chai");
const { ethers } = require("hardhat");


describe("Approvals tests", function()  {
  let myContract,deployer, minter, approved,operator;

  beforeEach(async () =>{
    const ERC721_Barbas = await ethers.getContractFactory('ERC721_Barbas');
    myContract = await ERC721_Barbas.deploy('ERC721_token','Barbas');
    [deployer, minter, approved, operator, receiver] = await ethers.getSigners();

    await myContract.connect(minter)._safeMint(minter.address,1);
  });

   describe('GetApproved', function(){
    
    it('returns address that has been approved', async () => {
      await myContract.connect(minter).approve(approved.address, 0);

      expect(await myContract.getApproved(0)).to.be.equal(approved.address);
    });
    
    it('returns AddressZero', async()=>{
        expect(await myContract.getApproved(0)).to.be.equal(ethers.constants.AddressZero);
      });

    });

    describe('IsApprovedForAll', function () {
      it("returns true if operator is in msg.sender's approvals list and marked as approved", async () => {
        myContract.connect(minter).setApprovalForAll(operator.address, true);
        expect(await myContract.isAllApproved(minter.address, operator.address)).to.be.equal(true);
      });

      it("returns false if operator is in msg.sender's approvals list and marked as not approved", async () => {
        myContract.connect(minter).setApprovalForAll(operator.address, false);
        expect(await myContract.isAllApproved(minter.address, operator.address)).to.be.equal(false);
      });

      it("returns false if operator is in not msg.sender's approvals list", async () => {
        expect(await myContract.isAllApproved(minter.address, operator.address)).to.be.equal(false);
      });
    });

    describe('SetApprovalForAll', function () {
      it('emits an ApprovalForAll event when set', async () => {
        await expect(myContract.connect(minter).setApprovalForAll(operator.address, true)).to.emit(myContract, 'ApprovalForAll').withArgs(minter.address, operator.address, true);
      });

      it('can have multiple operators in approval for all list', async () => {
        await myContract.connect(minter).setApprovalForAll(approved.address, true);
        await myContract.connect(minter).setApprovalForAll(operator.address, true);

        expect(await myContract.isAllApproved(minter.address, approved.address)).to.be.equal(true);
        expect(await myContract.isAllApproved(minter.address, operator.address)).to.be.equal(true);
      });
    });

    describe('Approve', function () {
      it("sets approved address if caller is owner or is in owner's approved list", async () => {
        await myContract.connect(minter).approve(approved.address, 0);

        expect(await myContract.getApproved(0)).to.be.equal(approved.address);

        await myContract.connect(minter).setApprovalForAll(operator.address, true);

        expect(await myContract.getApproved(0)).to.be.equal(approved.address);

        await myContract.connect(operator).approve(operator.address, 0);

        expect(await myContract.getApproved(0)).to.be.equal(operator.address);
      });

      it('emits an approval event when set', async () => {
        await expect(myContract.connect(minter).approve(operator.address, 0)).to.emit(myContract, 'Approval').withArgs(minter.address, operator.address, 0);
      });

      it('reverts if owner tries to set approved to themselves', async () => {
        await expect(myContract.connect(minter).approve(minter.address, 0)).to.be.revertedWith('ApprovalToCurrentOwner');
      });

      it("reverts if approve caller is not owner of token or in owner's approved list", async () => {
        await expect(myContract.connect(approved).approve(approved.address, 0)).to.be.revertedWith('ApproveCallerIsNotOwnerNorApprovedForAll'
        );
      });
    });
    
});
