// AgentCheck frontend logic (ethers v6, loaded from CDN in index.html).
// The user always signs the check-in transaction in their own wallet.
// This page never asks for a seed phrase, private key, or pairing code,
// never stores a session, and never sends a transaction on the user's behalf.
let provider = null;
let signer = null;
let account = null;
let contract = null;

const $ = (id) => document.getElementById(id);

function shortAddr(a) {
  return a ? a.slice(0, 6) + "..." + a.slice(-4) : "";
}

function setStatus(msg, isError) {
  const el = $("status");
  el.textContent = msg;
  el.style.color = isError ? "#c0392b" : "#555";
}

function contractReady() {
  return CONFIG.contractAddress !== "0x0000000000000000000000000000000000000000";
}

async function connectWallet() {
  if (!window.ethereum) {
    setStatus("No wallet found. Install a wallet that supports this chain, then reload.", true);
    return;
  }
  try {
    provider = new ethers.BrowserProvider(window.ethereum);
    const accounts = await provider.send("eth_requestAccounts", []);
    account = accounts[0];
    signer = await provider.getSigner();
    $("walletAddress").textContent = shortAddr(account);
    $("connectBtn").textContent = "Connected";
    $("connectBtn").disabled = true;

    const net = await provider.getNetwork();
    if (Number(net.chainId) !== CONFIG.chainId) {
      await switchNetwork();
    }
    if (contractReady()) {
      contract = new ethers.Contract(CONFIG.contractAddress, CONFIG.abi, signer);
      await refreshAll();
    } else {
      setStatus("Contract not deployed yet — the check-in button activates once the contract address is set in config.js.");
      await refreshLeaderboard();
    }
  } catch (e) {
    setStatus("Connection failed: " + (e && e.message ? e.message : e), true);
  }
}

async function switchNetwork() {
  try {
    await window.ethereum.request({
      method: "wallet_switchEthereumChain",
      params: [{ chainId: "0x" + CONFIG.chainId.toString(16) }],
    });
  } catch (e) {
    setStatus("Please switch your wallet to " + CONFIG.chainName + " (chain " + CONFIG.chainId + ").", true);
    throw e;
  }
}

async function refreshAll() {
  await refreshMyStats();
  await refreshLeaderboard();
}

async function refreshMyStats() {
  if (!contract || !account) return;
  const registry = new ethers.Contract(CONFIG.agentIdRegistry, CONFIG.registryAbi, provider);
  const idBalance = await registry.balanceOf(account);
  $("hasAgentId").textContent = idBalance > 0n ? "Yes" : "No";
  if (idBalance === 0n) {
    setStatus("This wallet holds no Agent ID, so it cannot check in. Check in with a wallet that holds an Agent ID.", true);
    $("checkInBtn").disabled = true;
    return;
  }
  const [total, streak] = await contract.getStats(account);
  const doneToday = await contract.hasCheckedInToday(account);
  $("myTotal").textContent = total.toString();
  $("myStreak").textContent = streak.toString();
  $("doneToday").textContent = doneToday ? "Yes" : "No";
  $("checkInBtn").disabled = doneToday;
  $("checkInBtn").textContent = doneToday ? "Already checked in today" : "Check in";
  if (doneToday) setStatus("Checked in for today. Come back tomorrow to keep the streak going.");
}

async function doCheckIn() {
  if (!contract || !account) return;
  $("checkInBtn").disabled = true;
  setStatus("Waiting for you to confirm the transaction in your wallet…");
  try {
    // The user reviews and signs this transaction in their own wallet.
    const tx = await contract.checkIn();
    setStatus("Transaction sent (" + tx.hash.slice(0, 10) + "…). Waiting for confirmation…");
    await tx.wait();
    setStatus("Checked in! Your streak is updated on-chain.");
    await refreshAll();
  } catch (e) {
    const msg = (e && e.message) || String(e);
    if (msg.includes("AlreadyCheckedInToday")) setStatus("Already checked in today.", true);
    else if (msg.includes("NotAgentIdHolder")) setStatus("This wallet holds no Agent ID.", true);
    else if (msg.toLowerCase().includes("user rejected") || msg.includes("4001")) setStatus("Transaction cancelled in your wallet.", true);
    else setStatus("Check-in failed: " + msg.slice(0, 200), true);
    $("checkInBtn").disabled = false;
  }
}

async function refreshLeaderboard() {
  const list = $("leaderboard");
  list.innerHTML = "<li>Loading…</li>";
  if (!contractReady()) {
    list.innerHTML = "<li>Leaderboard appears once the contract is deployed.</li>";
    $("participantCount").textContent = "—";
    return;
  }
  const readOnly = contract || new ethers.Contract(
    CONFIG.contractAddress,
    CONFIG.abi,
    provider || new ethers.JsonRpcProvider("https://bsc-dataseed.binance.org")
  );
  try {
    const count = Number(await readOnly.participantCount());
    $("participantCount").textContent = count.toString();
    if (count === 0) {
      list.innerHTML = "<li>No check-ins yet. Be the first!</li>";
      return;
    }
    // Read participants in pages, then fetch each one's stats.
    const addrs = [];
    const PAGE = 100;
    for (let start = 0; start < count; start += PAGE) {
      const page = await readOnly.getParticipants(start, PAGE);
      addrs.push(...page);
    }
    const rows = await Promise.all(
      addrs.slice(0, 200).map(async (a) => {
        const [total, streak] = await readOnly.getStats(a);
        return { addr: a, total: Number(total), streak: Number(streak) };
      })
    );
    rows.sort((x, y) => y.total - x.total || y.streak - x.streak);
    const top = rows.slice(0, 10);
    list.innerHTML = top
      .map((r, i) => {
        const you = account && r.addr.toLowerCase() === account.toLowerCase() ? " (you)" : "";
        return `<li>#${i + 1} ${shortAddr(r.addr)}${you} — ${r.total} check-in${r.total === 1 ? "" : "s"} · streak ${r.streak}</li>`;
      })
      .join("");
  } catch (e) {
    list.innerHTML = "<li>Could not load the leaderboard: " + String(e).slice(0, 120) + "</li>";
  }
}

$("connectBtn").addEventListener("click", connectWallet);
$("checkInBtn").addEventListener("click", doCheckIn);
$("refreshBtn").addEventListener("click", () => {
  if (contract) refreshAll();
  else refreshLeaderboard();
});

// Public leaderboard loads even before connecting a wallet.
window.addEventListener("load", () => {
  if (contractReady()) refreshLeaderboard();
  else {
    $("participantCount").textContent = "—";
    $("leaderboard").innerHTML = "<li>Leaderboard appears once the contract is deployed.</li>";
  }
});
