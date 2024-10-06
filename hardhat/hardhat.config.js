require("@nomiclabs/hardhat-ethers");

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.9",  // You were using 0.8.9 in Prompt.sol
      },
      {
        version: "0.8.20", // Add support for ^0.8.20 contracts
      }
    ]
  },
  networks: {
    sepolia: {
      url: "https://opt-sepolia.g.alchemy.com/v2/2iPF_MT9jp-O4mQ0eWd1HpeamV3zWWt4",  // Sepolia public RPC URL
      accounts: [`28f88112e577b6a15dde9fb7868fcd01954f7ccc02c61797d664db7a9a4e0f5a`] // Your private key from .env file
    }
  }
};