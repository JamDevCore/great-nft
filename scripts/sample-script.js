const hre = require("hardhat");

async function main() {
  const NFT = await hre.ethers.getContractFactory("YourNFToken");
  const nft = await NFT.deploy('name', 'symbol', 'baseURI', 'admin_address', 100000); //TODO: change arguments

  await nft.deployed();

  console.log("NFT deployed to:", nft.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
