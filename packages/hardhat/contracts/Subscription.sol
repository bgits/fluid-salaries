pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "./math/PRBMathSD59x18.sol";
import "./math/PRBMathUD60x18.sol";
import "./interfaces/IAToken.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ILendingPool.sol";

contract Subscription {
    using PRBMathSD59x18 for int256;
    using PRBMathUD60x18 for uint256;

    IAToken public aToken;
    ILendingPool public lendingPool;
    uint256 public constant rateBase = 100;
    uint256 public immutable ONE = PRBMathUD60x18.scale();
    uint256 public minDepositRatio = 12;
    uint256 public totalBalances;
    uint256 public interestIndex = PRBMathUD60x18.scale();

    /**
     * @dev map: keccask256(...args) -> Agreement
     */
    mapping(bytes32 => Agreement) agreements;
    mapping(address => uint256) public payorBalances;
    mapping(uint256 => uint256) public interestIndexSnapshots;

    constructor(
       address _aTokenAddress,
       address _lendingPool
    )
    {
        aToken = IAToken(_aTokenAddress);
        lendingPool = ILendingPool(_lendingPool);
    }

    struct Agreement {
        address receiver;
        address payor;
        address token; // Token to be paid in
        uint256 payRate; // per second in denomination token
        uint256 accruedValue;
        uint256 lastPayment;
        uint256 endDate;
        string description;
        bool terminated;
    }

    event SupplyReceived(
       address account,
       uint256 amount,
       uint256 startingBalance,
       uint256 newBalance,
       uint256 totalBalances
    );

    event AddAgreement(
        bytes32 agreementId,
        address indexed receiver,
        address indexed payor,
        address token,
        uint256 annualAmount,
        uint256 startDate,
        string indexed description
    );

    function createAgreement(
       address receiver,
       address payor,
       address token,
       uint256 annualAmount,
       uint256 startDate,
       string calldata description
    )
      external
    {
      require(msg.sender == payor, "Agreement must be created by payor");
      require(annualAmount > 0, "AnnualAmount can not be zero");
      bytes32 agreementId = keccak256(abi.encode(receiver, payor, token, annualAmount, startDate, description));
      uint supplyAmount = annualAmount / minDepositRatio;
      supply(supplyAmount);
      Agreement storage agreement = agreements[agreementId];

      agreement.receiver = receiver;
      agreement.payor = payor;
      agreement.token = aToken.UNDERLYING_ASSET_ADDRESS();
      agreement.payRate = annualAmount.div(365.25 days);
      agreement.lastPayment = startDate > 0 ? startDate : block.timestamp;
      agreement.description = description;

      emit AddAgreement(
          agreementId,
          receiver,
          payor,
          token,
          annualAmount,
          startDate > 0 ? startDate : block.timestamp,
          description
     );
    }

    function getAmountOwed(bytes32 agreementId) view public returns (uint256) {
        Agreement memory agreement = agreements[agreementId];
        return (block.timestamp - agreement.lastPayment).mul(agreement.payRate);
    }

    function getAnnuityDue(uint256 periodicPayment, uint256 rate, uint256 elapsedTime)
        public
        pure
        returns (uint256)
    {
        uint256 interestRate = rate.div(rateBase);
        uint256 rateTime = interestRate.mul(elapsedTime.fromUint());
        uint256 eToRT = rateTime.exp();
        uint256 eToR = interestRate.exp();
        uint256 reduced = (eToRT - PRBMathUD60x18.scale()).div(eToR - PRBMathUD60x18.scale());
        uint256 result = periodicPayment.mul(reduced);
        return result;
    }

    function supply(uint256 amount) public {
        uint256 balance = payorBalances[msg.sender];
        bool tokenTransfer = IERC20(aToken.UNDERLYING_ASSET_ADDRESS()).transferFrom(msg.sender, address(this), amount);
        require(tokenTransfer, "Failed to transfer token");
        updateInterestIndex();
        lendingPool.deposit(aToken.UNDERLYING_ASSET_ADDRESS(), amount, address(this), 0);
        uint256 newBalance = balance + amount;
        payorBalances[msg.sender] = newBalance;
        totalBalances = getTotalAmount();
        emit SupplyReceived(msg.sender, amount, balance, newBalance, totalBalances);
    }

    function updateInterestIndex() internal {
        uint256 updatedInterestIndex = calculateInterestIndex();
        interestIndexSnapshots[block.timestamp] = updatedInterestIndex;
        interestIndex = updatedInterestIndex;
    }

    function calculateInterestIndex() view public returns (uint256){
        uint256 totalAmount = getTotalAmount();
        uint256 balances = totalBalances;
        if (totalAmount == balances) {
            return interestIndex;
        }
        uint256 totalInterest = totalAmount - balances;
        uint256 totalReturn = totalInterest.div(balances);
        return interestIndex.mul(ONE + totalReturn);
    }

    function getTotalAmount() view public returns (uint256) {
        return aToken.balanceOf(address(this));
    }
}
