require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");

const mnemonic = ''; //TODO: add mnemonic

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
    apiKey: '3U3G4BKNXH6P4AVVCGN22BC46IY5PZ4XSP' //TODO: change Etherscan API key
  },
  networks: {
    ropsten: {
      url: `https://ropsten.infura.io/v3/59d4e21f46a64e5c9d4c50750ca80c84`, //TODO: change Infura project Key
      accounts: {mnemonic: mnemonic}
    },
  }
};
