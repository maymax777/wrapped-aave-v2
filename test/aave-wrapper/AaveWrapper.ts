import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { ethers, network } from "hardhat";

import { IERC20, IWETH } from "../../types";
import type { Signers } from "../types";
import { DAI_CONTRACT, DAI_WHALE, WETH_CONTRACT } from "../utils";
import { testAaveWrapperBehavior } from "./AaveWrapper.behavior";
import { deployAaveWrapperFixture } from "./AaveWrapper.fixture";

describe("Unit tests", function () {
  const inputWETHAmount = ethers.utils.parseEther("100");

  before(async function () {
    this.signers = {} as Signers;
    const signers: SignerWithAddress[] = await ethers.getSigners();

    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [DAI_WHALE],
    });

    // Initialize signers wallets
    this.signers.admin = signers[0];
    this.signers.bob = signers[1];
    this.signers.daiWhale = await ethers.getSigner(DAI_WHALE);

    // Initialize DAI smart contract
    this.dai = <IERC20>await ethers.getContractAt("IERC20", DAI_CONTRACT, this.signers.daiWhale);
    this.weth = <IWETH>await ethers.getContractAt("IWETH", WETH_CONTRACT, this.signers.admin);

    this.loadFixture = loadFixture;
  });

  describe("AaveWrapper", function () {
    beforeEach(async function () {
      const { aaveWrapper } = await this.loadFixture(deployAaveWrapperFixture);
      this.aaveWrapper = aaveWrapper;

      // Bob: Convert ETH to wETH
      await this.weth.connect(this.signers.bob).deposit({ value: inputWETHAmount });
    });

    testAaveWrapperBehavior();
  });
});
