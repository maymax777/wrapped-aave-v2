import { readContractAddress } from "../addresses/utils";

const AAVE_LENDING_POOL_CONTRACT = readContractAddress("aave-lending-pool");
const PROTOCOL_DATA_PROVIDER_CONTRACT = readContractAddress("protocol-data-provider");

const values = {
  AAVE_LENDING_POOL_CONTRACT,
  PROTOCOL_DATA_PROVIDER_CONTRACT,
};

export default values;
