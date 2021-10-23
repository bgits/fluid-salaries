const { ethers } = require("hardhat");
const { use, expect } = require("chai");
const { solidity } = require("ethereum-waffle");
const {deployMockContract} = require('@ethereum-waffle/mock-contract');
const iERC20 = require("../artifacts/contracts/interfaces/IERC20.sol/IERC20.json");

use(solidity);

const toWei = x => ethers.utils.parseEther(x);
const annuityDue = (P, R, T) => {
  const e = Math.E;
  const num = e**(R*T) - 1;
  const den = e**R - 1;
  return P * (num/den);
}

describe("Subscriptions", function () {
  let myContract;
  let subscriptionContract;
  let signers;

  // quick fix to let gas reporter fetch data from gas station & coinmarketcap
  before((done) => {
    setTimeout(done, 2000);
  });

  describe("Subscriptions", function () {
    it("Should deploy contracts", async function () {
      signers = await ethers.getSigners();
      const YourContract = await ethers.getContractFactory("YourContract");
      const Subscription = await ethers.getContractFactory("Subscription");
      const dai = await deployMockContract(signers[0], iERC20.abi);

      myContract = await YourContract.deploy(dai.address);
      // deploy aDAI
      subscriptionContract = await Subscription.deploy(dai.address);
    });

    it("Should compute annuity due correctly", async function () {
      const localOwed = annuityDue(1000, 0.01, 12);
      const owedWithInterest = await subscriptionContract.getAnnuityDue(1000, 1, 12);
      expect(Math.floor(localOwed)).to.equal(owedWithInterest);
    });

    describe("setPurpose()", function () {
      it("Should be able to set a new purpose", async function () {
        const newPurpose = "Test Purpose";

        await myContract.setPurpose(newPurpose);
        expect(await myContract.purpose()).to.equal(newPurpose);
      });
    });
  });
});
