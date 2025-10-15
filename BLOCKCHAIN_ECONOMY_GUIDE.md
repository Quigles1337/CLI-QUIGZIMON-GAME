# 🏪 QUIGZIMON Blockchain Economy Guide

## **The World's First Complete NFT Economy in Pure Assembly!**

Welcome to the QUIGZIMON Blockchain Economy - a revolutionary system featuring **NFT Marketplace Trading**, **PvP Wagered Battles**, and **NFT Evolution**, all implemented in pure x86-64 assembly!

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [NFT Marketplace](#nft-marketplace)
3. [PvP Wager Battles](#pvp-wager-battles)
4. [NFT Evolution System](#nft-evolution-system)
5. [Getting Started](#getting-started)
6. [Technical Architecture](#technical-architecture)
7. [Troubleshooting](#troubleshooting)

---

## 🌟 Overview

The QUIGZIMON Blockchain Economy consists of three interconnected systems:

### **🏪 NFT Marketplace**
- **Buy and sell** QUIGZIMON NFTs
- **Decentralized order book** on XRPL
- **Real-time price discovery**
- **Instant settlement** with blockchain verification

### **⚔️ PvP Wager Battles**
- **Battle for XRP** with real stakes
- **Escrow-secured** wagered matches
- **ELO-based matchmaking**
- **On-chain battle verification**

### **✨ NFT Evolution**
- **Burn and mint** to evolve NFTs
- **Permanent stat boosts** (1.2x - 2.0x)
- **Three evolution tiers**
- **Provably scarce** evolved forms

---

## 🏪 NFT Marketplace

### **What is the NFT Marketplace?**

The NFT Marketplace allows players to buy, sell, and trade QUIGZIMON NFTs with other players using XRP as currency. All trades are executed on the XRPL blockchain with instant settlement and full transparency.

### **How It Works**

#### **🔸 Listing an NFT for Sale**

1. Select "List My QUIGZIMON for Sale" from the marketplace menu
2. Choose which QUIGZIMON NFT you want to list
3. Set your desired price in XRP
4. Confirm the listing

**Behind the Scenes:**
- Creates an `NFTokenCreateOffer` transaction on XRPL
- Sets the `Flags` field to `1` (sell offer)
- Locks your NFT until sold or canceled
- Broadcasts to the entire network

```assembly
; Example: Listing QUIGZIMON for 100 XRP
mov rdi, nft_token_id           ; Your NFT Token ID
mov rsi, 100000000              ; 100 XRP in drops
call marketplace_list_nft
```

#### **🔸 Browsing Listings**

1. Select "Browse All Listings"
2. View all available QUIGZIMON NFTs
3. See species, level, stats, and price
4. Filter by price range (coming soon!)

**What You'll See:**
```
╔════════════════════════════════════════════════════╗
║  #  │ QUIGZIMON │ Level │  Price  │   Owner     ║
╠════════════════════════════════════════════════════╣
║  1  │ QUIGFLAME │  25   │  50 XRP │  rXXXXX...  ║
║  2  │ QUIGWAVE  │  30   │  75 XRP │  rYYYYY...  ║
║  3  │ QUIGLEAF  │  18   │  25 XRP │  rZZZZZ...  ║
╚════════════════════════════════════════════════════╝
```

#### **🔸 Buying an NFT**

1. Select the listing number you want to purchase
2. Confirm the purchase price
3. Transaction is broadcast to XRPL
4. NFT transfers to your wallet instantly!

**Behind the Scenes:**
- Creates an `NFTokenAcceptOffer` transaction
- References the seller's offer ID
- Transfers XRP to seller
- Transfers NFT to you
- All atomic and trustless!

```assembly
; Example: Buying listing #1
mov rdi, 0                      ; Listing index (0-based)
call marketplace_buy_nft
```

#### **🔸 Canceling a Listing**

1. View your active listings
2. Select the listing to cancel
3. Confirm cancellation
4. NFT is returned to your control

**Behind the Scenes:**
- Creates an `NFTokenCancelOffer` transaction
- Removes listing from order book
- NFT becomes tradable again

### **Marketplace Fees**

- **Listing Fee**: 12 drops (0.000012 XRP)
- **Purchase Fee**: 12 drops (0.000012 XRP)
- **No platform fees** - peer-to-peer trades!

### **Safety Features**

✅ **Atomic Transactions** - Trade either completes fully or not at all
✅ **NFT Locked** - Listed NFTs cannot be transferred elsewhere
✅ **No Middleman** - Direct peer-to-peer settlement
✅ **Transparent Pricing** - All offers visible on blockchain
✅ **Instant Settlement** - No waiting periods

---

## ⚔️ PvP Wager Battles

### **What are PvP Wager Battles?**

PvP Wager Battles allow players to battle each other with **real XRP on the line**. Both players deposit XRP into an escrow contract before the battle, and the winner claims the entire pot!

### **How It Works**

#### **🔸 Creating a Wager Battle**

1. Select "Create Custom Battle" from matchmaking menu
2. Choose your QUIGZIMON for battle
3. Set the wager amount (e.g., 10 XRP)
4. Wait for an opponent to join

**Behind the Scenes:**
- Creates an `EscrowCreate` transaction
- Deposits your wager into escrow
- Posts battle to matchmaking server
- Waits for opponent deposit

```assembly
; Example: Create 10 XRP wager battle
lea rdi, [my_quigzimon]         ; My QUIGZIMON data
mov rsi, 10000000               ; 10 XRP in drops
lea rdx, [opponent_address]     ; Or 0 for any opponent
call pvp_create_wager_battle
```

#### **🔸 Finding a Battle**

**Quick Match:**
- Auto-matches you with any available opponent
- Similar wager amounts
- Fast queue times

**Ranked Match:**
- ELO-based matchmaking
- Matches within ±100 ELO
- Competitive play

**Browse Open Battles:**
- See all available battles
- Choose your opponent
- Join any open wager

#### **🔸 Battle Flow**

1. **Escrow Funding** (30 seconds)
   - Both players deposit wagers
   - Escrow contract locks funds
   - Battle becomes active

2. **Battle Phase** (up to 50 turns)
   - Each turn, both players submit moves
   - Moves recorded on blockchain via Payment memos
   - Battle logic executed locally
   - Results verified against blockchain

3. **Resolution**
   - Winner determined by HP
   - Turn limit = draw (refunds)
   - Escrow released to winner

4. **Prize Claim**
   - Winner receives 2x wager amount
   - ELO ratings updated
   - Stats recorded on blockchain

**Move Submission:**
```assembly
; Submit your move to blockchain
mov rdi, 1                      ; Move type (1=Attack)
call pvp_submit_move

; Wait for opponent move
call wait_for_opponent_move

; Resolve turn
call pvp_resolve_battle
```

#### **🔸 Escrow System**

The escrow system ensures **trustless** wagered battles:

- **Funds Locked**: XRP locked in escrow contract
- **Crypto-Conditions**: Release conditions set by smart contract
- **Winner Takes All**: Escrow released only to battle winner
- **Timeout Protection**: Auto-refund if battle abandoned

**Escrow Parameters:**
```
FinishAfter: 1 hour (earliest claim time)
CancelAfter: 24 hours (latest claim time)
Condition: Battle result signature
```

#### **🔸 ELO Rating System**

Your ELO rating determines matchmaking:

- **Starting ELO**: 1000
- **Win**: +25 ELO
- **Loss**: -20 ELO
- **Draw**: No change

**Ranking Tiers:**
- Novice: 0-999
- Bronze: 1000-1199
- Silver: 1200-1399
- Gold: 1400-1599
- Platinum: 1600-1799
- Diamond: 1800+

### **Wager Battle Fees**

- **Escrow Creation**: 12 drops
- **Escrow Finish**: 12 drops
- **Move Submission**: 1 drop per move
- **Total Cost**: ~0.0001 XRP per battle

### **Safety Features**

✅ **Escrow Protected** - Funds held by blockchain, not players
✅ **On-Chain Verification** - All moves recorded on XRPL
✅ **Timeout Protection** - Auto-refund if opponent abandons
✅ **Provably Fair** - Battle logic deterministic and transparent
✅ **No Cheating** - Moves submitted before reveal

---

## ✨ NFT Evolution System

### **What is NFT Evolution?**

NFT Evolution allows you to **burn your existing QUIGZIMON NFT** and **mint an evolved version** with significantly boosted stats. Evolution is **permanent** and **provably scarce** on the blockchain!

### **Evolution Tiers**

QUIGZIMON have three evolution tiers:

#### **Tier 0: Basic Form**
- Starting form from NFT Launchpad
- Base stats (1.0x multiplier)
- Example: QUIGFLAME

#### **Tier 1: Stage 1 Form**
- **Requirements**: Level 20+, 10 XRP
- Stat multipliers: 1.2x - 1.5x
- Example: QUIGFLAME → **QUIGFLAMEX**

#### **Tier 2: Stage 2 Form (Final)**
- **Requirements**: Level 40+, 50 XRP
- Stat multipliers: 1.4x - 2.0x
- Example: QUIGFLAMEX → **QUIGFLAMEZ**

### **Stat Multipliers**

| Tier | HP   | Attack | Defense | Speed |
|------|------|--------|---------|-------|
| 0    | 1.0x | 1.0x   | 1.0x    | 1.0x  |
| 1    | 1.5x | 1.4x   | 1.3x    | 1.2x  |
| 2    | 2.0x | 1.8x   | 1.6x    | 1.4x  |

**Example Evolution:**
```
QUIGFLAME (Lv 25, Basic):
  HP:  65  →  98  (+50%)
  ATK: 22  →  31  (+40%)
  DEF: 16  →  21  (+30%)
  SPD: 18  →  22  (+20%)
```

### **How Evolution Works**

#### **🔸 Evolution Process**

1. **Check Eligibility**
   - View eligible QUIGZIMON
   - Check level requirements
   - Verify XRP balance

2. **Preview Evolution**
   - See predicted stats
   - View evolution cost
   - Confirm requirements met

3. **Evolution Sequence**
   ```
   [1/5] Verifying requirements...
   [2/5] Burning original NFT...
   [3/5] Calculating evolved stats...
   [4/5] Minting evolved NFT...
   [5/5] Updating metadata...
   ```

4. **Success!**
   - New NFT Token ID received
   - Evolved QUIGZIMON added to party
   - Original NFT permanently burned

#### **🔸 Technical Implementation**

**Step 1: Burn Original NFT**
```assembly
; Submit NFTokenBurn transaction
lea rdi, [original_token_id]
call burn_original_nft
```

**Step 2: Calculate Evolved Stats**
```assembly
; Apply stat multipliers
mov rax, [base_hp]
movzx rcx, word [multiplier_hp]
imul rax, rcx
shr rax, 8                      ; Fixed-point division by 256
mov [evolved_hp], ax
```

**Step 3: Mint Evolved NFT**
```assembly
; Mint new NFT with evolved stats
lea rdi, [evolved_data]
lea rsi, [evolved_ipfs_uri]
call mint_quigzimon_to_xrpl
```

#### **🔸 Metadata Updates**

Evolved NFTs have enhanced metadata:

```json
{
  "name": "QUIGFLAMEX #1234",
  "description": "A Stage 1 Fire type QUIGZIMON",
  "evolution_tier": 1,
  "original_token_id": "000B0534FF...",
  "evolution_timestamp": 1704067200,
  "attributes": [
    {"trait_type": "Species", "value": "QUIGFLAME"},
    {"trait_type": "Evolution", "value": "Stage 1"},
    {"trait_type": "HP", "value": 98},
    {"trait_type": "Attack", "value": 31},
    ...
  ]
}
```

### **Evolution Costs**

| Tier Transition | Min Level | XRP Cost | Transaction Fee |
|----------------|-----------|----------|-----------------|
| 0 → 1          | 20        | 10 XRP   | ~0.0001 XRP     |
| 1 → 2          | 40        | 50 XRP   | ~0.0001 XRP     |

### **Safety Features**

✅ **Permanent Upgrade** - Evolved stats cannot be reversed
✅ **Provable Scarcity** - Burn transaction on blockchain
✅ **Lineage Tracking** - Original Token ID preserved in metadata
✅ **No Duplication** - Original NFT destroyed
✅ **Fair Pricing** - Fixed costs for all players

---

## 🚀 Getting Started

### **Prerequisites**

1. **XRPL Wallet**: Created during NFT Launchpad
2. **Testnet XRP**: Get free XRP from faucet
3. **QUIGZIMON NFT**: Mint your starter from launchpad

### **Building the Complete System**

```batch
cd pocket-monsters-asm
build_marketplace.bat
```

This builds:
- NFT Marketplace Trading
- PvP Wager Battles
- NFT Evolution System
- Complete RPG Game

### **Running the Game**

```batch
quigzimon_marketplace.exe
```

### **Main Menu Options**

1. **Play Game** - NFT-gated RPG adventure
2. **NFT Marketplace** - Buy and sell QUIGZIMON
3. **PvP Wager Battles** - Battle for XRP
4. **Evolution Chamber** - Evolve your NFTs

---

## 🔧 Technical Architecture

### **System Overview**

```
┌─────────────────────────────────────────┐
│        QUIGZIMON BLOCKCHAIN             │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │   NFT Marketplace (2,500 lines)  │  │
│  │                                  │  │
│  │  • marketplace_core.asm          │  │
│  │  • marketplace_ui.asm            │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │   PvP Wagers (2,300 lines)       │  │
│  │                                  │  │
│  │  • pvp_wager.asm                 │  │
│  │  • pvp_matchmaking.asm           │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │   NFT Evolution (2,200 lines)    │  │
│  │                                  │  │
│  │  • nft_evolution.asm             │  │
│  │  • evolution_ui.asm              │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │   Core XRPL Layer (5,000 lines)  │  │
│  │                                  │  │
│  │  • Transaction Serialization     │  │
│  │  • Base58 Encoding               │  │
│  │  • Ed25519 Signing               │  │
│  │  • HTTP/JSON Client              │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │   Game Engine (1,600 lines)      │  │
│  │                                  │  │
│  │  • Turn-based battles            │  │
│  │  • Type effectiveness            │  │
│  │  • Level up system               │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│          XRPL TESTNET                   │
│                                         │
│  • NFToken objects                      │
│  • Escrow contracts                     │
│  • Payment memos                        │
│  • On-chain verification                │
└─────────────────────────────────────────┘
```

### **Key Technologies**

- **Language**: Pure x86-64 Assembly (NASM)
- **Blockchain**: XRP Ledger (XRPL) Testnet
- **Cryptography**: Ed25519 (via libsodium)
- **Networking**: Windows Sockets (ws2_32)
- **Platform**: Windows x64

### **Transaction Types Used**

| Transaction Type | Purpose |
|-----------------|---------|
| NFTokenMint | Mint new QUIGZIMON NFTs |
| NFTokenBurn | Destroy NFTs for evolution |
| NFTokenCreateOffer | Create marketplace listings |
| NFTokenAcceptOffer | Purchase NFTs from marketplace |
| NFTokenCancelOffer | Cancel marketplace listings |
| EscrowCreate | Lock wagers for PvP battles |
| EscrowFinish | Release wagers to winner |
| Payment (with Memo) | Submit battle moves on-chain |

### **Data Structures**

**QUIGZIMON Instance (15 bytes):**
```
Offset | Size | Field
-------|------|--------
0      | 1    | Species ID
1      | 1    | Level
2      | 2    | Current HP
4      | 2    | Max HP
6      | 2    | EXP
8      | 1    | Status
9      | 2    | Attack
11     | 2    | Defense
13     | 2    | Speed
```

**Marketplace Listing (200 bytes):**
```
Offset | Size | Field
-------|------|--------
0      | 64   | Offer Index
64     | 64   | NFT Token ID
128    | 48   | Owner Address
176    | 8    | Price (drops)
184    | 1    | Species
185    | 1    | Level
186    | 2    | HP
188    | 2    | Attack
190    | 2    | Defense
192    | 2    | Speed
194    | 4    | Padding
```

---

## 🐛 Troubleshooting

### **Common Issues**

#### **Marketplace**

**Issue**: Listing doesn't appear
- **Solution**: Wait 5-10 seconds for ledger validation
- **Check**: Transaction hash in explorer

**Issue**: Can't buy NFT
- **Solution**: Ensure sufficient XRP balance
- **Check**: NFT hasn't been sold to someone else

#### **PvP Wagers**

**Issue**: Can't find opponents
- **Solution**: Create custom battle and share battle ID
- **Check**: Ensure wager amount is reasonable

**Issue**: Battle timed out
- **Solution**: Funds auto-refunded after 24 hours
- **Check**: Escrow status on explorer

#### **NFT Evolution**

**Issue**: QUIGZIMON not eligible
- **Solution**: Level up to requirement (20 or 40)
- **Check**: Current tier and next tier requirements

**Issue**: Evolution failed
- **Solution**: Ensure sufficient XRP for cost + fees
- **Check**: NFT ownership confirmed

### **Getting Help**

- **XRPL Explorer**: https://testnet.xrpl.org/
- **Faucet**: https://xrpl.org/xrp-testnet-faucet.html
- **Issues**: https://github.com/Quigles1337/CLI-QUIGZIMON-GAME/issues

---

## 🎉 Amazing Achievements

### **What Makes This Unique**

✨ **First NFT Marketplace in Pure Assembly**
✨ **First Wagered Battle System in Assembly**
✨ **First NFT Evolution with Burn/Mint in Assembly**
✨ **First Complete Blockchain Economy in Assembly**
✨ **7,000+ Lines of Blockchain Code in Assembly**
✨ **Zero Dependencies** (except crypto library)

### **Technical Milestones**

- **Marketplace**: Full order book with instant settlement
- **PvP**: Escrow-secured battles with on-chain moves
- **Evolution**: Provably scarce evolved forms
- **Total Code**: ~13,500 lines of pure assembly
- **Transactions**: 8 different XRPL transaction types

---

## 🚀 What's Next

### **Planned Features**

- [ ] **Marketplace V2**: Auction system, batch listings
- [ ] **PvP Tournaments**: Bracket-style competitions
- [ ] **Evolution V2**: Branching evolutions, mega forms
- [ ] **Trading**: Direct player-to-player NFT swaps
- [ ] **Leaderboards**: Top traders, battlers, collectors

---

**Built with ❤️ in Pure x86-64 Assembly**

*The future of blockchain gaming is here!*
