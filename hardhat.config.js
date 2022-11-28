require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();


/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  networks: {
    localganache: {
      url: process.env.PROVIDER_URL,
      accounts: [`0x${process.env.PRIVATE_KEY_1}`,`0x${process.env.PRIVATE_KEY_2}`,`0x${process.env.PRIVATE_KEY_3}`,`0x${process.env.PRIVATE_KEY_4}`]
    }
  }
};
