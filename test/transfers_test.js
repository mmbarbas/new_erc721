const {
  expect
} = require("chai");
const {
  ethers
} = require("hardhat");

const RECEIVER_MAGIC_VALUE = '0x150b7a02';


describe("Transfer tests", function () {
  let myContract, deployer, minter, approved, operator, receiverStub;

  beforeEach(async () => {
    const ERC721_Barbas = await ethers.getContractFactory('ERC721_Barbas');
    myContract = await ERC721_Barbas.deploy('ERC721_token', 'Barbas');
    //const ERC721_Barbas_Receiver = await ethers.getContractFactory('ERC721_Barbas_Receiver');
   // receiverStub = await ERC721_Barbas_Receiver.deploy();


    [deployer, minter, approved, operator, luckybob] = await ethers.getSigners();

    await myContract.connect(minter)._safeMint(minter.address, 4);

  });

  context('Successful transfers', function () {
    context('Transfer from', function () {
      describe('to lucky bob', function () {
        it("transfers to 'to' address if sender is owner, approved, or in approval for all list", async () => {

          await myContract.connect(minter).approve(approved.address, 0);
          await myContract.connect(minter).setApprovalForAll(operator.address, true);

          await myContract.connect(approved).transferFrom(minter.address, luckybob.address, 0);
          await myContract.connect(operator).transferFrom(minter.address, luckybob.address, 1);
          await myContract.connect(minter).transferFrom(minter.address, luckybob.address, 2);

          expect(await myContract.balanceOf(luckybob.address)).to.be.equal(3);
          expect(await myContract.tokenOwner(0)).to.be.equal(luckybob.address);
          expect(await myContract.tokenOwner(1)).to.be.equal(luckybob.address);
          expect(await myContract.tokenOwner(2)).to.be.equal(luckybob.address);
        });

        it('clear approved and sets new owner for token id and updates balances', async () => {

          await myContract.connect(minter).approve(approved.address, 3);

          expect(await myContract.balanceOf(minter.address)).to.be.equal(4);
          expect(await myContract.getApproved(3)).to.be.equal(approved.address);

          await myContract.connect(minter).transferFrom(minter.address, luckybob.address, 3);

          expect(await myContract.balanceOf(minter.address)).to.be.equal(3);
          expect(await myContract.balanceOf(luckybob.address)).to.be.equal(1);
          expect(await myContract.getApproved(3)).to.be.equal(ethers.constants.AddressZero);
        });

        it('emits Transfer event', async () => {
          await expect(myContract.connect(minter).transferFrom(minter.address, luckybob.address, 3)).to.emit(myContract, 'Transfer').withArgs(minter.address, luckybob.address, 3);
        });
      });
      describe('To contract', function () {

        it("transfers to contract address", async () => {
          const ERC721_Barbas_Receiver = await ethers.getContractFactory('ERC721_Barbas_Receiver');
          receiverStub = await ERC721_Barbas_Receiver.deploy();

          await expect(myContract.connect(minter)['transferFrom(address,address,uint256)'](minter.address, receiverStub.address, 0)).to.emit(myContract, 'Transfer').withArgs(minter.address, receiverStub.address, 0);

        });

        it("checks owner", async () => {
          const ERC721_Barbas_Receiver = await ethers.getContractFactory('ERC721_Barbas_Receiver');
          receiverStub = await ERC721_Barbas_Receiver.deploy();

          await myContract.connect(minter).transferFrom(minter.address, receiverStub.address, 0);

          expect(await myContract.tokenOwner(0)).to.be.equal(receiverStub.address);

        });

        it("checks balance", async () => {

          await myContract.connect(minter).transferFrom(minter.address, receiverStub.address, 0);
          await myContract.connect(minter).transferFrom(minter.address, receiverStub.address, 1);

          expect(await myContract.balanceOf(receiverStub.address)).to.be.equal(2);
        });

      });
    });
    context('SafeTransfer from', function () {
      describe('to lucky bob', function () {
        it("transfers to 'to' address if sender is owner, approved, or in approval for all list", async () => {

          await myContract.connect(minter).setApprovalForAll(operator.address, true);
          await myContract.connect(minter).approve(approved.address, 2);

          await myContract.connect(minter)['safeTransfer(address,address,uint256)'](minter.address, luckybob.address, 1);
          await myContract.connect(operator)['safeTransfer(address,address,uint256)'](minter.address, luckybob.address, 3);
          await myContract.connect(approved)['safeTransfer(address,address,uint256)'](minter.address, luckybob.address, 2);

          expect(await myContract.balanceOf(luckybob.address)).to.be.equal(3);
          expect(await myContract.tokenOwner(1)).to.be.equal(luckybob.address);
          expect(await myContract.tokenOwner(2)).to.be.equal(luckybob.address);
          expect(await myContract.tokenOwner(3)).to.be.equal(luckybob.address);
        });
      });
      describe('to contract', function () {
        it("successfully transfers to a contract address if receiving contract handles onERC721Received correctly", async () => {

          await expect(
              myContract.connect(minter)['safeTransfer(address,address,uint256)'](minter.address, receiverStub.address, 0)).to.emit(receiverStub, 'Received')
            .withArgs(minter.address, minter.address, 0, '0x', 20000);
        });


      });
    });

  });
  context('Unsuccessful transfers', function () {
    it('reverts if sender is not approved, in approval for all list, or owner of token', async () => {
      await expect(myContract.connect(luckybob)['safeTransfer(address,address,uint256)'](minter.address, luckybob.address, 0)).to.be.revertedWith('TransferCallerIsNotOwnerNorApproved');
    });
    it('reverts for non-receivers', async () => {

      await expect(
        myContract.connect(minter)['safeTransfer(address,address,uint256)'](minter.address, myContract.address, 0)
      ).to.be.revertedWith('TransferToNonERC721ReceiverImplementer');

    });

    it('reverts when the receiver reverted', async () => {

      await expect(
        myContract.connect(minter)['safeTransfer(address,address,uint256,bytes)'](minter.address, receiverStub.address, 0, '0x01')
      ).to.be.revertedWith('reverted in the receiver contract!');

    });

    it('reverts if the receiver returns the wrong value', async () => {

      await expect(
        myContract.connect(minter)['safeTransfer(address,address,uint256,bytes)'](minter.address, receiverStub.address, 0, '0x02')
      ).to.be.revertedWith('TransferToNonERC721ReceiverImplementer');

    });

  });

});