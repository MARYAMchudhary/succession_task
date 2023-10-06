const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const STRToken = await ethers.getContractFactory("STRToken");
  const strToken = await STRToken.deploy();
  await strToken.deployed();

  const EscrowContract = await ethers.getContractFactory("EscrowContract");
  const escrowContract = await EscrowContract.deploy(strToken.address, YOUR_UNISWAP_ROUTER_ADDRESS);
  await escrowContract.deployed();

  console.log("STR Token deployed to:", strToken.address);
  console.log("Escrow Contract deployed to:", escrowContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
