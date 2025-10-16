import { expect } from "chai";
import { describe, it, beforeEach } from "mocha";
import {
  createPublicClient,
  createWalletClient,
  http,
  parseEther,
  getContractAddress,
} from "viem";
import { hardhat } from "viem/chains"; 
import BankArtifactRaw from "../artifacts/contracts/Bank.sol/Bank.json";
import AttackerArtifactRaw from "../artifacts/contracts/Re-entracy.sol/Attack.json";



const BankArtifact = BankArtifactRaw as { abi: any; bytecode: `0x${string}` };
const AttackerArtifact = AttackerArtifactRaw as { abi: any; bytecode: `0x${string}` };

describe("Bank re-entrancy exploit (Viem)", function () {
  let publicClient = createPublicClient({ chain: hardhat, transport: http() });
  let walletClient = createWalletClient({ chain: hardhat, transport: http() });

  let bankAddress: `0x${string}`;
  let attackerAddress: `0x${string}`;
  let accounts: `0x${string}`[];

  beforeEach(async function () {
    // request addresses from the wallet client (idiomatic Viem)
    accounts = await walletClient.transport.request({method:"eth_accounts"}) as `0x${string}`[];

    // deploy the Bank contract — deployContract returns a tx hash
    const bankDeployHash = await walletClient.deployContract({
      account: accounts[0],
      abi: BankArtifact.abi,
      bytecode: BankArtifact.bytecode,
      args: [],
    });

    // wait for receipt to get the contract address
    const bankReceipt = await publicClient.getTransactionReceipt({ hash: bankDeployHash });
    if (!bankReceipt?.contractAddress) throw new Error("Bank deployment failed");
    bankAddress = bankReceipt.contractAddress;

    // depositor seeds bank with 10 ETH (use walletClient.writeContract)
    await walletClient.writeContract({
      account: accounts[1],
      address: bankAddress,
      abi: BankArtifact.abi,
      functionName: "deposit",
      value: parseEther("10"),
      args: [] // parseEther returns bigint
    });

    // deploy Attacker contract (constructor takes bank address)
    const attackerDeployHash = await walletClient.deployContract({
      account: accounts[2],
      abi: AttackerArtifact.abi,
      bytecode: AttackerArtifact.bytecode,
      args: [bankAddress],
    });

    const attackerReceipt = await publicClient.getTransactionReceipt({ hash: attackerDeployHash });
    if (!attackerReceipt?.contractAddress) throw new Error("Attacker deployment failed");
    attackerAddress = attackerReceipt.contractAddress;
  });

  it("should drain the bank", async function () {
    // attack with 1 ETH
    const attackHash = await walletClient.writeContract({
      account: accounts[2],
      address: attackerAddress,
      abi: AttackerArtifact.abi,
      functionName: "attack",
      value: parseEther("1"),
      args: []
    });

    // optionally wait for the attack tx to be mined before checking balances
    await publicClient.waitForTransactionReceipt({ hash: attackHash });

    const bankBal = await publicClient.getBalance({ address: bankAddress });
    const attackerBal = await publicClient.getBalance({ address: attackerAddress });

    console.log("Bank balance after attack:", Number(bankBal) / 1e18, "ETH");
    console.log("Attacker contract balance:", Number(attackerBal) / 1e18, "ETH");

    // use bigint comparison
    expect(bankBal).to.be.equal(BigInt(0));
  });
});
