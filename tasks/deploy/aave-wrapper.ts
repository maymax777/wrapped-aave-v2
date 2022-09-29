import { Signer } from "@ethersproject/abstract-signer";
import { task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { AaveWrapper, AaveWrapper__factory } from "../../types";
import { readContractAddress, writeContractAddress } from "../addresses/utils";
import cArguments from "../arguments/aave-wrapper";

task("deploy:AaveWrapper")
  .addParam("signer", "Index of the signer in the metamask address list")
  .setAction(async function (taskArguments: TaskArguments, { ethers }) {
    console.log("--- start deploying the AaveWrapper Contract ---");
    const accounts: Signer[] = await ethers.getSigners();
    const index: number = Number(taskArguments.signer);

    const aaveWrapperFactory: AaveWrapper__factory = <AaveWrapper__factory>(
      await ethers.getContractFactory("AaveWrapper", accounts[index])
    );
    const aaveWrapper: AaveWrapper = <AaveWrapper>(
      await aaveWrapperFactory.deploy(cArguments.AAVE_LENDING_POOL_CONTRACT, cArguments.PROTOCOL_DATA_PROVIDER_CONTRACT)
    );
    await aaveWrapper.deployed();

    writeContractAddress("aave-wrapper", aaveWrapper.address);
    console.log("AaveWrapper deployed to: ", aaveWrapper.address);
  });

task("verify:AaveWrapper").setAction(async function (taskArguments: TaskArguments, { run }) {
  const address = readContractAddress("aave-wrapper");
  await run("verify:verify", {
    address,
    constructorArguments: [],
  });
});
