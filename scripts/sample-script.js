const hre = require("hardhat");

async function main() {
  const NFT = await hre.ethers.getContractFactory("YourNFToken");
  const nft = await NFT.deploy('name', 'symbol', 'baseURI', '0x61d9bA3e270f7158C3FEb67b00aDFEc921aac681', 100000); //TODO: change arguments

  await nft.deployed();

  console.log("NFT deployed to:", nft.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
