require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("solidity-coverage");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.23",
    settings: {
      outputSelection: {
        "*": {
          "*": ["storageLayout"],
        }
      }
    },
    optimizer: {
      enabled: true,
      runs: 800,
    },
  },
};
