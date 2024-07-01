import {
  arbitrum,
  arbitrumGoerli,
  baseGoerli,
  mainnet,
  sepolia,
  base,
  Chain,
} from "wagmi/chains";
import {
  coinbaseWallet,
  injected,
  walletConnect,
  metaMask,
  safe,
} from "wagmi/connectors";

import { walletConnectId } from "./constants";
import { http } from "viem";

// Set up Wallet connectors
const connectors = [
  injected(),
  walletConnect({
    showQrModal: true,
    projectId: walletConnectId,
  }),
  coinbaseWallet({
    appName: "Frodo Estate",
    preference: "smartWalletOnly",
  }),
  safe(),
  metaMask(),
];

const chains = [
  arbitrum,
  arbitrumGoerli,
  base,
  baseGoerli,
  mainnet,
  sepolia,
] as [Chain, ...Chain[]];

const transportsData = {
  [mainnet.id]: http(),
  [base.id]: http(),
  [baseGoerli.id]: http(),
  [sepolia.id]: http(),
  [arbitrum.id]: http(),
  [arbitrumGoerli.id]: http(),
};

export { connectors, chains, transportsData };
