import { encodeFunctionData } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { VennClient } from '@vennbuild/venn-dapp-sdk';
import { readFileSync } from 'fs';
import { join } from 'path';
import { Wallet, JsonRpcProvider } from 'ethers';
import dotenv from 'dotenv';

dotenv.config();

// Define interface for deployment transaction
interface DeploymentTransaction {
  contractName: string | null;
  contractAddress: string;
  [key: string]: any;
}

// Define interface for deployment info
interface DeploymentInfo {
  transactions: DeploymentTransaction[];
}
const provider = new JsonRpcProvider('https://sepolia.base.org');
const wallet = new Wallet(process.env.PRIVATE_KEY as string, provider);
// ERC20 ABI
const MockERC20ABI = [
  {
    name: "approve",
    type: "function",
    inputs: [{ name: "spender", type: "address" }, { name: "value", type: "uint256" }],
    outputs: []
  }
] as const;
// Reference the AirdropManager ABI
const AirdropManagerABI = [
  {
    name: "createCampaign",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "rewardToken", type: "address" },
      { name: "totalRewards", type: "uint256" },
      { name: "maxParticipants", type: "uint256" },
      { name: "startTime", type: "uint256" },
      { name: "endTime", type: "uint256" },
      { name: "criteriaLogic", type: "address" }
    ],
    outputs: [{ type: "uint256" }]
  },
  {
    name: "claimReward",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [{ name: "campaignId", type: "uint256" }],
    outputs: []
  }
] as const;

async function main() {
  // Load deployed contract addresses
  const deploymentPath = join(__dirname, '../broadcast/Deploy.s.sol/84532/run-latest.json');
  const deployment = JSON.parse(readFileSync(deploymentPath, 'utf-8')) as DeploymentInfo;

  const airdropManagerAddress = deployment.transactions.find(
    (tx: DeploymentTransaction) => tx.contractName === 'AirdropManager'
  )?.contractAddress;

  const mockDeployPath = join(__dirname, '../broadcast/DeployMock.s.sol/84532/run-latest.json');
  const mockDeployment = JSON.parse(readFileSync(mockDeployPath, 'utf-8')) as DeploymentInfo;
  const mockTokenAddress = mockDeployment.transactions.find(
    (tx: DeploymentTransaction) => tx.contractName == null
  )?.contractAddress;
  if (!airdropManagerAddress || !mockTokenAddress) {
    throw new Error('Required contract addresses not found');
  }
  const nonce = await wallet.getNonce();
  console.log('Current nonce:', nonce);
  // Initialize Venn client
  const vennClient = new VennClient({
    vennURL: "https://dc7sea.venn.build/sign",
    vennPolicyAddress: "0x04f3B196E30e6F78174EF95a612E1f85A3B4110C" // From your deployment
  });
  // Setup wallet and public client
  const account = privateKeyToAccount(process.env.PRIVATE_KEY as `0x${string}`);
  console.log(account.address);
  // Approve airdrop manager to spend mock token
  const approveMockTx = {
    to: mockTokenAddress,
    from: account.address,
    data: encodeFunctionData({
      abi: MockERC20ABI,
      functionName: 'approve',
      args: [airdropManagerAddress, BigInt('1000000000000000000000')]
    }),
    value: '0',
    nonce: nonce
  };
    
  await wallet.sendTransaction(approveMockTx);

  // Create campaign transaction
  const createCampaignTx = {
  to: airdropManagerAddress,
  from: account.address,
  data: encodeFunctionData({
    abi: AirdropManagerABI,
    functionName: 'createCampaign',
    args: [
      mockTokenAddress as `0x${string}`,
      BigInt('1000000000000000000000'),
      100n,
      BigInt(Math.floor(Date.now() / 1000)),
      BigInt(Math.floor(Date.now() / 1000) + 86400),
      mockTokenAddress as `0x${string}`
    ]
  }),
  value: '0',
  nonce: nonce
};
  try {
    // Get Venn approval
    console.log('Getting Venn approval for campaign creation...');
    const approvedTx = await vennClient.approve(createCampaignTx);
    // Send transaction
    console.log('Sending approved transaction...');
    const receipt = await wallet.sendTransaction(
      approvedTx
    )
    console.log('Campaign created! Transaction:', receipt.hash);

    // Get campaign ID from logs (you'd need to implement this based on your event structure)
    const campaignId = 1n; // For testing purposes

    // Try claiming reward
    const claimTx = {
      to: airdropManagerAddress,
      from: account.address,
      data: encodeFunctionData({
        abi: AirdropManagerABI,
        functionName: 'claimReward',
        args: [campaignId]
      }),
      value: '0',
      nonce: nonce
    } 

    // Get Venn approval for claim
    console.log('Getting Venn approval for claim...');
    const approvedClaimTx = await vennClient.approve(claimTx);
    
    // Send claim transaction
    console.log('Sending approved claim transaction...');
    const claimReceipt = await wallet.sendTransaction(approvedClaimTx);
    console.log('Reward claimed! Transaction:', claimReceipt.hash);

  } catch (error) {
    console.error('Error:', error);
  }
}

main().catch(console.error);