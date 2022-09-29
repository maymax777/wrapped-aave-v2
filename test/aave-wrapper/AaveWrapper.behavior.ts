import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, Contract } from "ethers";
import { ethers, network } from "hardhat";

import { AaveWrapper } from "../../types";

export function testAaveWrapperBehavior(): void {
  const inputWETHAmount = ethers.utils.parseEther("100");
  const outputDAIAmount = ethers.utils.parseEther("1000");

  const runDepositAndBorrow = async (
    token0: Contract,
    token0Amount: BigNumber,
    token1: Contract,
    token1Amount: BigNumber,
    signer: SignerWithAddress,
    aaveWrapper: AaveWrapper,
  ) => {
    // signer: Approve token to AaveWrapper smart contract
    await token0.connect(signer).approve(aaveWrapper.address, token0Amount);
    // signer: deposit weth and borrow dai
    await aaveWrapper.connect(signer).depositAndBorrow(token0.address, token0Amount, token1.address, token1Amount);
  };

  it("returns the initial contract status properly", async function () {
    // Contract should be not paused when it starts
    expect(await this.aaveWrapper.paused()).to.equal(false);
    // Bob's account should have wETH
    expect(await this.weth.balanceOf(this.signers.bob.address)).to.eq(inputWETHAmount);
  });

  it("deposits and borrows properly", async function () {
    // Bob: deposit and borrow
    await runDepositAndBorrow(
      this.weth,
      inputWETHAmount,
      this.dai,
      outputDAIAmount,
      this.signers.bob,
      this.aaveWrapper,
    );
    // Bob: weth balance should be zero
    expect(await this.weth.balanceOf(this.signers.bob.address)).to.eq(0);
    // AaveWrapper: dai balance should be 1000
    expect(await this.dai.balanceOf(this.aaveWrapper.address)).to.eq(outputDAIAmount);
  });

  it("pays back and withdraws properly", async function () {
    // Bob: deposit and borrow
    await runDepositAndBorrow(
      this.weth,
      inputWETHAmount,
      this.dai,
      outputDAIAmount,
      this.signers.bob,
      this.aaveWrapper,
    );

    // After 1 year
    await network.provider.send("evm_increaseTime", [3600 * 24 * 365]);
    await network.provider.send("evm_mine");

    // Bob: pay back and withdraw
    await this.aaveWrapper
      .connect(this.signers.bob)
      .payBackAndWithdraw(this.weth.address, inputWETHAmount, this.dai.address, outputDAIAmount);
    // AaveWrapper: dai balance should be 0 and weth balance should be 100
    expect(await this.dai.balanceOf(this.aaveWrapper.address)).to.eq(0);
    expect(await this.weth.balanceOf(this.signers.bob.address)).to.eq(inputWETHAmount);
  });
}
