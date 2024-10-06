const hre = require("hardhat");
const { Alchemy, Network } = require("alchemy-sdk");

async function main() {
  const OAOInteractionExample = await hre.ethers.getContractFactory("OAOInteractionExample");
  const oaoInteractionExample = await OAOInteractionExample.attach("YOUR_DEPLOYED_CONTRACT_ADDRESS");

  const modelId = 1; // 1 for llama, 2 for Stable Diffusion
  const prompt = "What is the capital of France?";

  console.log("Sending AI inference request...");
  const tx = await oaoInteractionExample.requestAIInference(modelId, prompt);
  
  // Initialize Alchemy SDK
  const config = {
    apiKey: process.env.ALCHEMY_API_KEY,
    network: Network.ETH_SEPOLIA,
  };
  const alchemy = new Alchemy(config);

  // Wait for transaction confirmation
  const receipt = await alchemy.core.waitForTransactionReceipt(tx.hash);
  console.log("Request sent. Transaction hash:", tx.hash);
  console.log("Transaction confirmed in block:", receipt.blockNumber);

  console.log("Waiting for the response...");

  // You would typically listen for the AIResponseReceived event here
  // For simplicity, we'll just wait for a bit and then check the lastResult
  await new Promise(resolve => setTimeout(resolve, 60000)); // Wait for 60 seconds

  const result = await oaoInteractionExample.lastResult();
  console.log("AI Response:", result);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });