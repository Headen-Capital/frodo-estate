import { mainnet } from "wagmi/chains";

// Chain to host dApp upon
const defaultChain = mainnet;

// Extract environment variables into constants
const appName = process.env.APP_NAME as string;

const infuraId = process.env.INFURA_ID as string;
const alchemyId = process.env.ALCHEMY_ID as string;
const etherscanApiKey = process.env.ETHERSCAN_API_KEY as string;
const onchainKitKey = process.env.ONCHAIN_KIT_KEY as string;
const walletConnectId = process.env.WALLET_CONNECT_ID as string;

export {
  defaultChain,
  appName,
  infuraId,
  alchemyId,
  etherscanApiKey,
  onchainKitKey,
  walletConnectId,
};
