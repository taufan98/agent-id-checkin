# AgentCheck — Daily Check-in for Agent ID Holders

A free daily check-in dApp for Agent ID holders, built for the Agent ID
Hackathon. One check-in per address per day, streaks tracked on-chain, and a
public leaderboard. No token, no fees, no sign-up — just show up once a day.

## How Agent ID is used (core to the product)

Agent ID is the product's identity and access control, enforced **on-chain**:

- `checkIn()` calls `balanceOf(msg.sender)` on the Agent ID registry
  (`0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`, ERC-721, non-transferable)
  and reverts with `NotAgentIdHolder()` unless the caller holds at least one
  Agent ID.
- Agent ID is non-transferable, so a check-in streak is tied to the holder's
  identity and cannot be bought, sold, or transferred to another wallet.
- Holding more than one Agent ID does not give extra check-ins — one address,
  one check-in per day, regardless of how many IDs it holds.
- The leaderboard reads only the contract's own `participants` list and
  per-address stats. There is no lookup of other people's wallets by name.

## Contract

`src/AgentCheck.sol` (Solidity ^0.8.20, no dependencies, no owner, no fees):

| Function | Description |
|---|---|
| `checkIn()` | Free daily check-in. Reverts if the caller holds no Agent ID or already checked in today. Updates total, streak, and last check-in day; emits `CheckIn`. |
| `getStats(address)` | Returns `(totalCheckIns, currentStreak, lastCheckInDay)` for an address. |
| `hasCheckedInToday(address)` | Whether an address already checked in today. |
| `participantCount()` / `getParticipants(start, count)` | Paginated list of all addresses that ever checked in (for the leaderboard). |
| `totalCheckIns / currentStreak / lastCheckInDay` | Public per-address state. |

Rules enforced by the contract:

- One check-in per address per UTC day (`block.timestamp / 1 days`).
- Streak increments only on consecutive days; any missed day resets it to 1.
- The contract accepts no value (`checkIn` is non-payable), holds no funds,
  and has **no owner, no pause, no mint, no withdraw, and no privileged
  functions at all**.
- A `CheckIn` event is emitted on every check-in, so all history is public.

## Tests

```bash
forge test
```

10 tests, all passing, covering: non-holder rejection, first check-in, duplicate
check-in on the same day, streak increments on consecutive days, streak reset
after a gap, same-day edge cases, participant tracking and pagination, value
rejection, empty stats, and holders with multiple Agent IDs.

A local end-to-end smoke test (deploy + check-in on a local chain) lives in
`script/SmokeTest.s.sol` and uses a mock registry — never point a production
deployment at the mock.

## Deployment

```bash
forge script script/Deploy.s.sol --rpc-url <BSC_RPC_URL> --private-key <DEPLOYER_KEY> --broadcast
```

- Deployment gas (measured on a local chain, same bytecode): **931,278 gas**
  (runtime 4,052 bytes, initcode 4,327 bytes). At 0.1 gwei that is about
  0.000093 BNB; at 1 gwei about 0.00093 BNB. Check the live gas price before
  deploying.
- After deployment, verify the source on BscScan (Contracts → Verify &
  Publish), then set the deployed address as `contractAddress` in
  `frontend/config.js`.
- Deployment needs a funded deployer wallet and is a separate, explicit step —
  nothing in this repo deploys or submits anything by itself.

## Verifying on BscScan

1. Open the deployed contract address on BscScan.
2. Use "Verify & Publish", compiler type "Solidity (Single file)" or
   "Solidity (Standard JSON Input)", compiler version matching `foundry.toml`
   (0.8.20), license MIT.
3. The constructor takes one argument: the Agent ID registry
   `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`.
4. After verification, "Read Contract" shows `agentIdRegistry`, `DAY`,
   `participantCount`, `getStats`, and the rest; "Write Contract" exposes
   `checkIn()` (connect a wallet holding an Agent ID to try it).

## Running the frontend

The frontend is static (`frontend/`), no build step:

```bash
cd frontend
python3 -m http.server 8000
# open http://localhost:8000
```

1. Set `contractAddress` in `frontend/config.js` to the deployed contract.
2. Open the page, click "Connect wallet", switch to BSC mainnet (chain 56)
   if asked.
3. Click "Check in" and confirm the transaction in your own wallet. The page
   never asks for a seed phrase, private key, or pairing code, never stores a
   session, and never sends a transaction on your behalf.

## Hackathon compliance

- No web QR-code login; no stored user sessions; the user reviews and signs
  every transaction in their own wallet.
- No transfers, no bundled extra transfers, no approvals of any kind.
- No collection of seed phrases, private keys, API secrets, or pairing codes.
- No promised returns of any kind — the streak is a public record of showing
  up, nothing more.
- No "Binance" or "BNB" in the project name, token name, or domain.
- No feature that looks up other people's wallets by Agent ID name.
- No mass account registration or artificial interaction.

## License

MIT — see `LICENSE`.
