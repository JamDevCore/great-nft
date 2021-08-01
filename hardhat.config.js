require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");

const mnemonic = '';

//good-day@byom.de

module.exports = {
  solidity: {
  version: "0.8.4",
  settings: {
    optimizer: {
      enabled: true,
      runs: 200
    }
   }
  },
  etherscan: {
    apiKey: '' //TODO: change Etherscan API key
  },
  networks: {
    ropsten: {
      url: ``, //TODO: change Infura project Key
      accounts: {mnemonic: mnemonic}
    },
  }
};
