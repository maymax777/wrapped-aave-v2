import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { ethers } from "hardhat";

import { readContractAddress } from "../../tasks/addresses/utils";
import type { AaveWrapper, AaveWrapper__factory } from "../../types";

export async function deployAaveWrapperFixture(): Promise<{ aaveWrapper: AaveWrapper }> {
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const admin: SignerWithAddress = signers[0];

  const AAVE_LENDING_POOL_CONTRACT: string = readContractAddress("aave-lending-pool");
  const aaveWrapperFactory: AaveWrapper__factory = <AaveWrapper__factory>await ethers.getContractFactory("AaveWrapper");
  const aaveWrapper: AaveWrapper = <AaveWrapper>(
    await aaveWrapperFactory.connect(admin).deploy(AAVE_LENDING_POOL_CONTRACT)
  );
  await aaveWrapper.deployed();

  return { aaveWrapper };
}
