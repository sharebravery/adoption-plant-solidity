import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import 'solidity-docgen';
import * as dotenv from 'dotenv';

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: `0.8.24`,
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000
          },
          viaIR: true,
          evmVersion: `shanghai`, // downgrade to `paris` if you encounter 'invalid opcode' error
        }
      },
    ],
  },
  defaultNetwork: "blast-local",
  networks: {
    // for mainnet
    "blast-mainnet": {
      url: "https://rpc.blast.io",
      accounts: [process.env.PRIVATE_KEY as string],
      gasPrice: 1000000000,
    },
    // for Sepolia testnet
    "blast-sepolia": {
      url: "https://sepolia.blast.io",
      accounts: [process.env.PRIVATE_KEY as string],
      gasPrice: 1000000000,
    },
    // for local dev environment
    "blast-local": {
      url: "http://localhost:8545",
      accounts: [process.env.PRIVATE_KEY as string],
      gasPrice: 1000000000,
    },
    mumbai: {
      url: "https://polygon-mumbai.g.alchemy.com/v2/k_wjgD_vDNows-mCiUJ_ikKh-0Gd2c0C",
      accounts: [process.env.PRIVATE_KEY || ''] // 使用环境变量中的私钥
    }
  },
  etherscan: {
    apiKey: {
      blast_mainnet: process.env.BLASTSCAN_API_KEY!,
    },
    customChains: [
      {
        network: "blast-mainnet",
        chainId: 81457,
        urls: {
          apiURL: "https: //rpc.blast.io",
          browserURL: "https: //blastscan.io",
        },
      },
      {
        network: "blast-sepolia",
        chainId: 168587773,
        urls: {
          apiURL: "https: //sepolia.blast.io",
          browserURL: "https: //testnet.blastscan.io",
        },
      },
    ],
  },
};

export default {
  ...config,
  docgen: {
    outputDir: './',
    pages: () => 'README.md',
  },
};
