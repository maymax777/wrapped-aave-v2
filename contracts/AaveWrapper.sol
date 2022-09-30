// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ILendingPool } from "./interfaces/ILendingPool.sol";

// import "./utils/Errors.sol";

contract AaveWrapper is Ownable, Pausable {
    error AlreadyStaked();
    error InvalidInput();
    error NoStake();
    error ZeroAddress();

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint16 private constant REFERRAL_CODE = 0;
    uint256 private constant INTEREST_RATE_MODE = 2;
    ILendingPool public immutable lendingPool;

    struct Stake {
        address collateralToken;
        uint256 collateralAmount;
        address debtToken;
        uint256 debtAmount;
        bool staked;
    }

    mapping(address => Stake) private _stakes;

    /* ==================== EVENTS ==================== */

    /**
     * @dev Emit on depositAndBorrow()
     * @param user the address of the user
     * @param collateralToken The address of the underlying asset to deposit
     * @param collateralAmount The amount to be deposited
     * @param debtToken The address of the underlying asset to borrow
     * @param debtAmount The amount to be borrowed
     */
    event DepositAndBorrow(
        address indexed user,
        address collateralToken,
        uint256 collateralAmount,
        address debtToken,
        uint256 debtAmount
    );

    /**
     * @dev Emit on payBackAndWithdraw()
     * @param user the address of the user
     * @param collateralToken The address of the underlying asset to deposit
     * @param collateralAmount The amount to be deposited
     * @param debtToken The address of the underlying asset to borrow
     * @param debtAmount The amount to be borrowed
     */
    event PayBackAndWithdraw(
        address indexed user,
        address collateralToken,
        uint256 collateralAmount,
        address debtToken,
        uint256 debtAmount
    );

    /* ==================== METHODS ==================== */

    /**
     * @param lendingPoolAddress Aave v2 lending pool address
     */
    constructor(address lendingPoolAddress) {
        if (lendingPoolAddress == address(0)) revert ZeroAddress();
        lendingPool = ILendingPool(lendingPoolAddress);
    }

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     *      Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower.
     * @param collateralToken The address of the underlying asset to deposit
     * @param collateralAmount The amount to be deposited
     * @param debtToken The address of the underlying asset to borrow
     * @param debtAmount The amount to be borrowed
     */
    function depositAndBorrow(
        address collateralToken,
        uint256 collateralAmount,
        address debtToken,
        uint256 debtAmount
    ) external whenNotPaused {
        Stake memory stake = _stakes[_msgSender()];
        if (stake.collateralToken == collateralToken && stake.debtToken == debtToken && stake.staked == true)
            revert AlreadyStaked();

        stake.collateralAmount = collateralAmount;
        stake.collateralToken = collateralToken;
        stake.debtAmount = debtAmount;
        stake.debtToken = debtToken;
        stake.staked = true;
        _stakes[_msgSender()] = stake;

        IERC20 _collateralToken = IERC20(collateralToken);
        // Transfer collateral token to this smart contract
        _collateralToken.safeTransferFrom(_msgSender(), address(this), collateralAmount);

        // Approve collateral token to aave v2 lending pool smart contract
        _collateralToken.approve(address(lendingPool), collateralAmount);

        // Deposit collateral token to aave v2 lending pool smart contract
        lendingPool.deposit(collateralToken, collateralAmount, address(this), REFERRAL_CODE);

        // Borrow debtAmount of debtToken and transfer to this smart contract
        lendingPool.borrow(debtToken, debtAmount, INTEREST_RATE_MODE, REFERRAL_CODE, address(this));

        emit DepositAndBorrow(_msgSender(), collateralToken, collateralAmount, debtToken, debtAmount);
    }

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned.
     * @param collateralToken The address of the underlying asset to deposit
     * @param collateralAmount The amount to be deposited
     * @param debtToken The address of the underlying asset to borrow
     * @param debtAmount The amount to be borrowed
     */
    function payBackAndWithdraw(
        address collateralToken,
        uint256 collateralAmount,
        address debtToken,
        uint256 debtAmount
    ) external whenNotPaused {
        Stake memory stake = _stakes[_msgSender()];
        if (stake.collateralToken == collateralToken && stake.debtToken == debtToken && stake.staked == false)
            revert NoStake();
        if (stake.collateralAmount != collateralAmount || stake.debtAmount != debtAmount) revert InvalidInput();

        stake.staked = false;
        stake.collateralAmount = 0;
        stake.debtAmount = 0;
        _stakes[_msgSender()].staked = false;

        IERC20 _debtToken = IERC20(debtToken);
        // Approve collateral token to aave v2 lending pool smart contract
        _debtToken.approve(address(lendingPool), debtAmount);

        // Deposit debt token to aave v2 lending pool smart contract
        lendingPool.repay(debtToken, debtAmount, INTEREST_RATE_MODE, address(this));

        // Withdraw collateral token to sender
        lendingPool.withdraw(collateralToken, collateralAmount, _msgSender());

        emit PayBackAndWithdraw(_msgSender(), collateralToken, collateralAmount, debtToken, debtAmount);
    }

    /* ==================== OWNER METHODS ==================== */

    /**
     * @dev The owner can unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev The owner can pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }
}
