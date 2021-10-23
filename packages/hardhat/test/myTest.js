const { ethers } = require("hardhat");
const { use, expect } = require("chai");
const { solidity } = require("ethereum-waffle");
const {deployMockContract} = require('@ethereum-waffle/mock-contract');
const iERC20 = require("../artifacts/contracts/interfaces/IERC20.sol/IERC20.json");

use(solidity);

const AUSDC_MAINNET = "0xBcca60bB61934080951369a648Fb03DF4F96263C";
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
      // assumes mainnet or mainnet fork
      signers = await ethers.getSigners();
      const YourContract = await ethers.getContractFactory("YourContract");
      const Subscription = await ethers.getContractFactory("Subscription");
      const dai = await deployMockContract(signers[0], iERC20.abi);

      myContract = await YourContract.deploy(AUSDC_MAINNET);
      subscriptionContract = await Subscription.deploy(AUSDC_MAINNET);
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
