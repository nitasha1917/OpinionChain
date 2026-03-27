# OpinionChain — Deployment Guide
> AI-Analyzed, Immutable Opinion Ledger · Built on Ethereum

---

## What It Is

OpinionChain combines two technologies:
- **Anthropic Claude API** — analyzes each answer and profiles your thinking style
- **Ethereum Smart Contract** — stores a cryptographically-linked chain of your opinions

Every opinion is:
1. Analyzed by Claude (thinking style, traits, scores)
2. Hashed using SHA-256
3. Mined with Proof-of-Work (finding nonce where hash starts with `00`)
4. Linked to the previous block (like a real blockchain)
5. Optionally recorded to Ethereum (immutable forever)

---

## File Structure

```
OpinionChain/
├── OpinionChain.html     ← Frontend DApp (open in browser)
├── OpinionChain.sol      ← Ethereum smart contract
└── DEPLOYMENT_GUIDE.md   ← This file
```

---

## STEP 1: Run the Frontend (No Setup Needed)

The HTML file works standalone as a simulated blockchain.

> **Important:** Serve over `http://`, not `file://` — the Anthropic API requires it.

```bash
npx serve .
```

Then open: `http://localhost:3000/OpinionChain.html`

**What works immediately (no contract needed):**
- All 25 questions across 5 categories
- Real Claude AI analysis (needs API key — see Step 2)
- Simulated blockchain with SHA-256 hashing + Proof-of-Work
- Evolving thinker profile
- Block verification

---

## STEP 2: Enable Real Claude AI Analysis

The frontend calls the Anthropic API directly from the browser.

1. Get an API key at [console.anthropic.com](https://console.anthropic.com)
2. Open `OpinionChain.html` in a text editor
3. Find the fetch call:
   ```javascript
   const response = await fetch("https://api.anthropic.com/v1/messages", {
     method: "POST",
     headers: { "Content-Type": "application/json" },
   ```
4. Add your API key header:
   ```javascript
   headers: {
     "Content-Type": "application/json",
     "x-api-key": "YOUR_API_KEY_HERE",
     "anthropic-version": "2023-06-01",
     "anthropic-dangerous-direct-browser-access": "true"
   },
   ```

> ⚠️ For production, proxy API calls through a backend. Direct browser API calls expose the key.

---

## STEP 3: Deploy the Smart Contract (Optional — for Real Immutability)

### Prerequisites
- MetaMask installed ([metamask.io](https://metamask.io))
- Sepolia test ETH from a faucet

### Deploy via Remix

1. Open [remix.ethereum.org](https://remix.ethereum.org)
2. Create `OpinionChain.sol` and paste the contract code
3. Compile with Solidity `^0.8.20`
4. Deploy via **Injected Provider - MetaMask** on Sepolia
5. Copy the deployed contract address

### Connect Frontend to Contract

In `OpinionChain.html`, add the ethers.js integration:

```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/ethers/6.13.4/ethers.umd.min.js"></script>
```

Then use the ABI (from Remix → Compilation Details) to call `recordOpinion()` after each block is mined.

---

## Key Blockchain Concepts Demonstrated

| Concept | Where It Appears |
|---------|-----------------|
| Hash chaining | Each block's `prevHash` links to previous block's hash |
| Proof-of-Work | Frontend mines nonce until `sha256(data+nonce)` starts with `00` |
| Immutability | Changing any past answer invalidates all subsequent hashes |
| Smart Contract | `OpinionChain.sol` — on-chain storage with chain verification |
| Access Control | Each user owns their own chain (`msg.sender`) |
| Privacy | Answers stored as `keccak256` hashes, not plaintext, on-chain |
| Events | `OpinionRecorded`, `ArchetypeUpdated`, `ChainVerified` |
| View Functions | Read chain data without gas fees |

---

## How the Blockchain Works (Under the Hood)

```
GENESIS BLOCK (index 0)
  prevHash = 0x000...000
  contentHash = sha256(question + answer + aiStyle + nonce)
       │
       ▼
BLOCK 1
  prevHash = contentHash of block 0   ← LINKS THE CHAIN
  contentHash = sha256(question + answer + aiStyle + prevHash + nonce)
       │
       ▼
BLOCK 2
  prevHash = contentHash of block 1
  ...
```

If you tamper with Block 0's answer → its contentHash changes → Block 1's prevHash no longer matches → **chain is broken and invalid**.

---

## AI Analysis Flow

```
User writes answer
       │
       ▼
Claude API (claude-sonnet-4)
  ├─ Thinking style label   ("Critical Idealist")
  ├─ 2-3 sentence analysis
  ├─ Trait chips            ["systems thinker", "principled", ...]
  └─ Dimension scores       {analytical: 78, empathetic: 45, ...}
       │
       ▼
Scores averaged across all blocks → Evolving Thinker Profile
       │
       ▼
Archetype determined from dominant dimension:
  analytical → "The Architect"
  empathetic → "The Humanist"
  skeptical  → "The Questioner"
  creative   → "The Synthesizer"
  pragmatic  → "The Realist"
  idealistic → "The Visionary"
```

---

## Demo Talking Points

- **"Every vote is cryptographically signed"** — each block contains the previous block's hash
- **"Proof-of-Work"** — the browser actually mines a nonce before the block is accepted
- **"Tamper-evident"** — change any past answer and the entire chain becomes invalid
- **"AI + Blockchain"** — two cutting-edge technologies working together
- **"Your opinions as data"** — watch your thinker profile evolve in real-time
- **"Privacy-preserving"** — on-chain version stores only the hash of your answer, not the text

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| AI analysis shows fallback data | Add API key (Step 2) |
| `file://` doesn't work | Use `npx serve .` |
| MetaMask doesn't connect | Switch to Sepolia testnet |
| Blocks mine slowly | This is real PoW — it's finding a valid nonce! |
| Chain shows invalid | You may have refreshed — chain resets on page reload (add localStorage persistence for production) |
