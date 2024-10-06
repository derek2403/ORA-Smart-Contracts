const hre = require("hardhat");

async function main() {
  // Use the Sepolia OAO address from the documentation
  const AIOracleAddress = "0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0";

  // Get contract factory for the renamed contract "Comment"
  const Comment = await hre.ethers.getContractFactory("Comment");

  // Deploy the contract, passing AIOracleAddress if your constructor expects it
  const comment = await Comment.deploy(AIOracleAddress);

  // Wait for deployment to complete
  await comment.deployed();

  console.log("Comment contract deployed to:", comment.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });