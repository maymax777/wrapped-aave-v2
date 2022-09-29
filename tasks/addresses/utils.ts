import { config as dotenvConfig } from "dotenv";
import * as fs from "fs";
import * as path from "path";

dotenvConfig({ path: path.resolve(__dirname, "../../.env") });

console.log("DEPLOY_NETWORK: ", process.env.DEPLOY_NETWORK);

type FileName = "aave-wrapper" | "aave-lending-pool" | "protocol-data-provider";

const network = () => {
  const { DEPLOY_NETWORK } = process.env;
  if (DEPLOY_NETWORK) return DEPLOY_NETWORK;
  return "goerli";
};

export const writeContractAddress = (contractFileName: FileName, addresses: string) => {
  const NETWORK: string = network();

  fs.writeFileSync(
    path.join(__dirname, `${NETWORK}/${contractFileName}.json`),
    JSON.stringify({
      addresses,
    }),
  );
};

export const readContractAddress = (contractFileName: FileName): string => {
  const envNetwork: string = network();
  const NETWORK: string = envNetwork === "hardhat" ? "mainnet" : envNetwork;

  const rawData = fs.readFileSync(path.join(__dirname, `${NETWORK}/${contractFileName}.json`));
  const info = JSON.parse(rawData.toString());

  return info.address;
};
