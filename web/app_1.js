import { createPublicClient, http, formatEther } from './vendor/viem.js';

const byId = (id) => document.getElementById(id);
const when = (seconds) => new Date(Number(seconds) * 1000).toLocaleString();

// Everything the page knows about the contract comes from deployment.json.
let deployment, chain, publicClient;

function say(id, text, cssClass = '') {
    const element = byId(id);
    element.textContent = text;
    element.className = cssClass;
}

// Turn a failure into a sentence the user can act on.
function explain(err) {
    return err?.shortMessage ?? err?.message ?? String(err);
}

async function loadDeployment() {
    const response = await fetch('../deployment.json', { cache: 'no-store' });
    if (!response.ok) throw new Error('Could not load ../deployment.json. Copy deployment.example.json to deployment.json first.');
    const deploymentFile = await response.json();
    const isValid = Number.isInteger(deploymentFile.chainId) && /^0x[0-9a-fA-F]{40}$/.test(deploymentFile.address)
        && typeof deploymentFile.rpcUrl === 'string' && Array.isArray(deploymentFile.abi) && Number.isInteger(deploymentFile.deployBlock);
    if (!isValid) throw new Error('deployment.json needs chainId, rpcUrl, address, deployBlock and abi.');
    return deploymentFile;
}

// Read the contract through the page's own RPC connection; no wallet is needed for this.
async function refresh() {
    const read = (functionName, args) =>
        publicClient.readContract({ address: deployment.address, abi: deployment.abi, functionName, args });
    const [creator, goal, deadline, raised, withdrawn, block] = await Promise.all([
        read('creator'), read('goal'), read('deadline'), read('totalRaised'), read('withdrawn'),
        publicClient.getBlock(),
    ]);
    byId('v-creator').textContent = creator;
    byId('v-goal').textContent = `${formatEther(goal)} ETH`;
    byId('v-raised').textContent = `${formatEther(raised)} ETH`;
    byId('v-deadline').textContent = when(deadline);
    // The chain's clock is the contract's clock, so compare with the latest block, not the computer clock.
    const ended = block.timestamp >= deadline;
    const status = !ended ? 'Running'
        : withdrawn ? 'Ended, funds withdrawn'
            : raised >= goal ? 'Ended, goal met' : 'Ended, goal missed';
    byId('v-status').textContent = status;
}

async function main() {
  deployment = await loadDeployment();
  chain = {
    id: deployment.chainId, name: deployment.network ?? 'Campaign chain',
    nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
    rpcUrls: { default: { http: [deployment.rpcUrl] } },
  };
  publicClient = createPublicClient({ chain, transport: http(deployment.rpcUrl) });
  const rpcChain = await publicClient.getChainId();
  if (rpcChain !== deployment.chainId) throw new Error(`The RPC node reports chain ${rpcChain}, not ${deployment.chainId}. Is Anvil running?`);
  byId('v-address').textContent = deployment.address;
  byId('v-chain').textContent = deployment.chainId;
  await refresh();
}

main().catch((err) => say('banner', explain(err), 'bad'));