require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades")

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.23",
    optimizer: {
      enabled: true,
      runs: 800,
    },
  },
};
