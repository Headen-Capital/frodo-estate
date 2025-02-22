import { Chain, connectorsForWallets, getDefaultConfig } from '@rainbow-me/rainbowkit';
import {coinbaseWallet, ledgerWallet, metaMaskWallet, phantomWallet, rabbyWallet, rainbowWallet, safeWallet, trustWallet, uniswapWallet, walletConnectWallet, zerionWallet} from "@rainbow-me/rainbowkit/wallets"
import { createConfig, http } from 'wagmi';
import {
  arbitrum,
  base,
  baseSepolia,
  mainnet,
  optimism,
  polygon,
  sepolia,
} from 'wagmi/chains';
// import { coinbaseWallet, injected, metaMask, safe, walletConnect } from 'wagmi/connectors';

const walletConnectId = process.env.NEXT_PUBLIC_WALLET_CONNECT_ID as string;
coinbaseWallet.preference = 'smartWalletOnly'
// Set up Wallet connectors
const connectors = connectorsForWallets(
  [
    {
      groupName:"Recommended",
      wallets:[rainbowWallet, walletConnectWallet, safeWallet, coinbaseWallet, ledgerWallet]
    },
    {
      groupName:"Others",
      wallets:[metaMaskWallet, rabbyWallet, phantomWallet, trustWallet, zerionWallet, uniswapWallet]
    }
  ],
  {
    appName: 'Frodo App',
    projectId: walletConnectId,
  }
) 

// [
//   injected({

//   }),
//   walletConnect({
//     // name: 'Frodo App',
//     showQrModal: true,
//     projectId: walletConnectId,
//   }),
//   coinbaseWallet({
//     appName: "Frodo Estate",
//     preference: "smartWalletOnly",
//   }),
//   safe(),
//   metaMask(),
// ];

const chains = [
  arbitrum,
  optimism,
  polygon,
  base,
  baseSepolia,
  mainnet,
  sepolia,
] as [Chain, ...Chain[]];

const transportsData = {
  [mainnet.id]: http(),
  [base.id]: http(),
  [baseSepolia.id]: http(),
  [sepolia.id]: http(),
  [arbitrum.id]: http(),
  [optimism.id]: http(),
};

export const config = createConfig({
  
  chains: chains,
  connectors: connectors,
  transports: transportsData,
});

// export const config = getDefaultConfig({
//   appName: 'Frodo App',
//   projectId: walletConnectId,
//   chains: [
//     mainnet,
//     polygon,
//     optimism,
//     arbitrum,
//     base,
//     ...(process.env.NEXT_PUBLIC_ENABLE_TESTNETS === 'true' ? [sepolia, baseSepolia] : []),
//   ],
//   ssr: true,
// });