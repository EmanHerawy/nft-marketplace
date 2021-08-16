import {HardhatUserConfig} from 'hardhat/types';
import '@nomiclabs/hardhat-waffle';
import 'hardhat-deploy';
import 'hardhat-deploy-ethers';
import "hardhat-docgen";
import "hardhat-gas-reporter";
import "./tasks/accounts";
import "@nomiclabs/hardhat-etherscan";

const fs = require('fs');
const privateKey = fs.readFileSync("privateKey.secret").toString().trim();
const alchemyKey = fs.readFileSync("alchemyKey.secret").toString().trim();
const config: HardhatUserConfig = {

  namedAccounts: {
    deployer: 0,
  }, defaultNetwork: "hardhat",
  networks: {
    hardhat: {
        saveDeployments: true,
    },
    localhost: {
      url: 'http://127.0.0.1:8545',
      accounts: [privateKey],
      chainId:1337,
        saveDeployments: true,
    },
    
testnet_aurora: {
  url: 'https://testnet.aurora.dev',
  accounts: [privateKey],
  saveDeployments: true,
  chainId: 1313161555,
  gasPrice: 120 * 1000000000
},
bsc_test: {
  url: 'https://data-seed-prebsc-1-s1.binance.org:8545',
  accounts: [privateKey],
  saveDeployments: true,
  chainId: 97,
  gasPrice: 120 * 1000000000
},
bsc: {
  url: 'https://bsc-dataseed1.binance.org',
  accounts: [privateKey],
  saveDeployments: true,
  chainId: 56,
  gasPrice: 120 * 1000000000
},
testnet_matic: {
  url: 'https://rpc-mumbai.matic.today',
  accounts: [privateKey],
  saveDeployments: true,
  chainId: 80001,
  gasPrice: 120 * 1000000000
},
 
      ropsten: {
        url: `https://eth-ropsten.alchemyapi.io/v2/${alchemyKey}`,
        saveDeployments: true,
        accounts: [privateKey],
      },
      mainnet: {
        url: `https://eth-mainnet.alchemyapi.io/v2/${alchemyKey}`,
      saveDeployments: true,
      accounts: [privateKey],
      loggingEnabled:true,
      throwOnTransactionFailures:true

    },
    rinkeby: {
      url: `https://eth-rinkeby.alchemyapi.io/v2/${alchemyKey}`,
      saveDeployments: true,
      accounts: [privateKey],
    }
  },
  solidity: {
    compilers: [
      {
        version: "0.8.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.8.1",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.8.2",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.8.2",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.8.3",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.8.4",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.8.5",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.8.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.8.7",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
    ],   
  },
  gasReporter: {
    currency: 'USD',
    gasPrice: 100,
    enabled: process.env.REPORT_GAS ? true : false,
    // coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    maxMethodDiff: 10,
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: "your key"
  },
  // paths: {
  //   sources: "./contracts",
  //   tests: "./test",
  //   cache: "./cache",
  //   artifacts: "./artifacts"
  // },
  paths: {
    deploy: 'deploy',
    deployments: 'deployments',
    imports: 'imports'
},
  mocha: {
    timeout: 200000000
  },
  docgen: {
    path: './docs',
    clear: true,
    runOnCompile: true,
  }
};
export default config;

