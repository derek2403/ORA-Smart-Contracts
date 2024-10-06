const hre = require("hardhat");

async function main() {
  // Use the Sepolia OAO address from the documentation
  const AIOracleAddress = "0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0";

  // Get contract factory for the renamed contract "Dashboard"
  const Dashboard = await hre.ethers.getContractFactory("Dashboard");

  // Deploy the contract, passing AIOracleAddress if your constructor expects it
  const dashboard = await Dashboard.deploy(AIOracleAddress);

  // Wait for deployment to complete
  await dashboard.deployed();

  console.log("Dashboard contract deployed to:", dashboard.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });