async function main() {
    // Use the Sepolia OAO address from the documentation
    const AIOracleAddress = "0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0";
  
    // Get contract factory
    const Prompt = await ethers.getContractFactory("FoodProAI");
  
    // Deploy the contract
    const prompt = await Prompt.deploy(AIOracleAddress);
  
    // Wait for deployment to complete
    await prompt.deployed();
  
    console.log("Prompt.sol deployed to:", prompt.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });