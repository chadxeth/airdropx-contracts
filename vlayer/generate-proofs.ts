import { baseSepolia } from "viem/chains";
import { createVlayerClient } from "@vlayer/sdk";
import { createContext, getConfig } from "@vlayer/sdk/config";
import { readFileSync } from "fs";
import { join } from "path";
import AverageBalanceABI from "../out/AverageBalance.sol/AverageBalance.json";

interface DeploymentInfo {
  transactions: {
    contractName: string;
    contractAddress: string;
  }[];
}

async function getDeployedAddresses(): Promise<{
  averageBalanceAddress: string;
  vlayerEligibilityAddress: string;
}> {
  const deploymentPath = join(
    __dirname,
    "../broadcast/Deploy.s.sol/84532/run-latest.json",
  );
  const deployment = JSON.parse(
    readFileSync(deploymentPath, "utf-8"),
  ) as DeploymentInfo;

  const averageBalanceAddress = deployment.transactions.find(
    (tx) => tx.contractName === "AverageBalance",
  )?.contractAddress;

  const vlayerEligibilityAddress = deployment.transactions.find(
    (tx) => tx.contractName === "VLayerEligibility",
  )?.contractAddress;

  if (!averageBalanceAddress || !vlayerEligibilityAddress) {
    throw new Error(
      "Required contract addresses not found in deployment artifacts",
    );
  }

  return { averageBalanceAddress, vlayerEligibilityAddress };
}

async function generateProof(
  vlayer: ReturnType<typeof createVlayerClient>,
  averageBalanceAddress: string,
  userAddress: string,
) {
  console.log(`Generating proof for user ${userAddress}...`);
  const provingHash = await vlayer.prove({
    address: averageBalanceAddress,
    proverAbi: AverageBalanceABI.abi,
    functionName: "averageBalanceOf",
    args: [userAddress],
    chainId: baseSepolia.id,
  });

  console.log("Waiting for proving result...");
  return await vlayer.waitForProvingResult(provingHash);
}

async function submitProof(
  ethClient: any,
  vlayerEligibilityAddress: string,
  proofResult: any,
  account: string,
) {
  console.log("Submitting proof to VLayerEligibility contract...");

  const vlayerEligibilityAbi = [
    {
      name: "submitProof",
      type: "function",
      stateMutability: "nonpayable",
      inputs: [
        {
          name: "proof",
          type: "tuple",
          components: [
            // Add the Proof struct components here based on your contract
            // This should match your contract's Proof struct definition
          ],
        },
        {
          name: "user",
          type: "address",
        },
        {
          name: "averageBalance",
          type: "uint256",
        },
      ],
      outputs: [],
    },
  ];
  // Get deployed contract addresses
  const { averageBalanceAddress } = await getDeployedAddresses();
  // Get user address
  const userAddress = "0x1D96F2f6BeF1202E4Ce1Ff6Dad0c2CB002861d3e";
  // Get average balance from AverageBalance contract
  const averageBalance = await ethClient.readContract({
    address: averageBalanceAddress,
    abi: AverageBalanceABI.abi,
    functionName: "averageBalanceOf",
    args: [userAddress],
  });
  const submissionHash = await ethClient.writeContract({
    address: vlayerEligibilityAddress,
    abi: vlayerEligibilityAbi,
    functionName: "submitProof",
    args: [proofResult, account, averageBalance],
    account,
  });

  console.log(`Proof submission transaction: ${submissionHash}`);
  return submissionHash;
}

async function main() {
  // Load environment variables
  const userAddress = "0x1D96F2f6BeF1202E4Ce1Ff6Dad0c2CB002861d3e";
  if (!userAddress) {
    throw new Error("USER_ADDRESS environment variable not set");
  }

  // Initialize VLayer client
  const config = getConfig();
  const { ethClient, account, proverUrl } = await createContext(config);

  const vlayer = createVlayerClient({
    url: proverUrl,
  });

  // Get deployed contract addresses
  const { averageBalanceAddress, vlayerEligibilityAddress } =
    await getDeployedAddresses();
  console.log("AverageBalance contract:", averageBalanceAddress);
  console.log("VLayerEligibility contract:", vlayerEligibilityAddress);

  try {
    // Generate proof
    const proofResult = await generateProof(
      vlayer,
      averageBalanceAddress,
      userAddress,
    );
    console.log("Proof generated successfully");

    // Submit proof to eligibility contract
    const txHash = await submitProof(
      ethClient,
      vlayerEligibilityAddress,
      proofResult,
      account,
    );

    console.log("Proof submitted successfully");
    console.log("Transaction hash:", txHash);
  } catch (error) {
    console.error("Error in proof generation/submission:", error);
    process.exit(1);
  }
}

main().catch(console.error);
