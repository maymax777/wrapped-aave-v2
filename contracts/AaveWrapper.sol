// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ILendingPool } from "./interfaces/ILendingPool.sol";
import { IProtocolDataProvider } from "./interfaces/IProtocolDataProvider.sol";
import "./utils/Errors.sol";

contract AaveWrapper is Ownable, Pausable {
    using SafeERC20 for IERC20;

    uint16 private constant REFERRAL_CODE = 0;
    uint256 private constant INTEREST_RATE_MODE = 1;
    ILendingPool public immutable lendingPool;
    IProtocolDataProvider immutable dataProvider;

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
    constructor(address lendingPoolAddress, address protocolDataProviderAddress) {
        if (lendingPoolAddress == address(0)) revert ZeroAddress();
        lendingPool = ILendingPool(lendingPoolAddress);
        dataProvider = IProtocolDataProvider(protocolDataProviderAddress);
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
        IERC20 _collateralToken = IERC20(collateralToken);
        // Transfer collateral token to this smart contract
        _collateralToken.safeTransferFrom(_msgSender(), address(this), collateralAmount);

        // Approve collateral token to aave v2 lending pool smart contract
        _collateralToken.approve(address(lendingPool), collateralAmount);

        // Deposit collateral token to aave v2 lending pool smart contract
        lendingPool.deposit(collateralToken, collateralAmount, address(this), REFERRAL_CODE);

        // Borrow debtAmount of debtToken and transfer to this smart contract
        lendingPool.borrow(debtToken, debtAmount, INTEREST_RATE_MODE, REFERRAL_CODE, address(this));
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
        IERC20 _debtToken = IERC20(debtToken);
        // Approve collateral token to aave v2 lending pool smart contract
        _debtToken.approve(address(lendingPool), debtAmount);

        lendingPool.repay(debtToken, debtAmount, INTEREST_RATE_MODE, address(this));

        lendingPool.withdraw(collateralToken, collateralAmount, _msgSender());
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
