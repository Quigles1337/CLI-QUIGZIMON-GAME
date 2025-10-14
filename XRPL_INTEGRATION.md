# QUIGZIMON × XRPL Integration Architecture

## 🎯 Overview

Pure x86-64 assembly implementation connecting QUIGZIMON directly to the XRP Ledger blockchain using HTTP/JSON-RPC API calls.

**No external libraries. No high-level languages. Pure assembly blockchain gaming.**

---

## 🏗️ Architecture

```
┌─────────────────────────────────────┐
│   QUIGZIMON Game (Assembly)         │
│   - Game logic                      │
│   - Battle system                   │
│   - Catching mechanics              │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│   HTTP Client (Assembly)            │
│   - Socket creation                 │
│   - TCP connection                  │
│   - HTTP POST requests              │
│   - JSON parsing                    │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│   XRPL JSON-RPC API                 │
│   - s.altnet.rippletest.net:51234   │
│   - submit, account_info, nfts      │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│   XRP Ledger Testnet                │
│   - NFT storage                     │
│   - XRP transactions                │
│   - Account management              │
└─────────────────────────────────────┘
```

---

## 🎮 Feature 1: QUIGZIMON as NFTs

### NFT Structure

Each caught QUIGZIMON becomes an NFT on XRPL with:

```json
{
  "nft_id": "000B0000...",
  "uri": "ipfs://Qm.../quigflame_1337.json",
  "metadata": {
    "name": "QUIGFLAME #1337",
    "description": "A rare Fire-type QUIGZIMON",
    "image": "ipfs://Qm.../quigflame.png",
    "attributes": [
      {"trait_type": "Species", "value": "QUIGFLAME"},
      {"trait_type": "Type", "value": "Fire"},
      {"trait_type": "Level", "value": 15},
      {"trait_type": "HP", "value": 65},
      {"trait_type": "Attack", "value": 22},
      {"trait_type": "Defense", "value": 16},
      {"trait_type": "Speed", "value": 18},
      {"trait_type": "Move 1", "value": "Ember"},
      {"trait_type": "Move 2", "value": "Flamethrower"},
      {"trait_type": "Status", "value": "Healthy"},
      {"trait_type": "Experience", "value": 350},
      {"trait_type": "Caught Date", "value": "2025-10-14T12:00:00Z"},
      {"trait_type": "Original Trainer", "value": "rQuigles1337..."}
    ]
  }
}
```

### Minting Flow

```assembly
; When player successfully catches QUIGZIMON
catch_success:
    ; 1. Generate NFT metadata from QUIGZIMON stats
    call generate_nft_metadata

    ; 2. Upload metadata to IPFS (or embed in URI)
    call upload_to_ipfs  ; Returns CID

    ; 3. Create NFTokenMint transaction
    call prepare_nft_mint_tx

    ; 4. Sign transaction with player wallet
    call sign_transaction

    ; 5. Submit to XRPL
    call submit_to_xrpl

    ; 6. Store NFT TokenID in save data
    mov [player_party + offset + nft_token_id], rax

    ; 7. Display success message
    call display_nft_minted_msg
```

### Assembly Data Structures

```assembly
section .data
    ; XRPL Configuration
    xrpl_host db "s.altnet.rippletest.net", 0
    xrpl_port dw 51234

    ; Player wallet (seed/keypair)
    player_wallet:
        .address db "rQuigles1337...", 0  ; 34 chars
        .seed db "sEd...", 0               ; Secret seed
        .public_key resb 33
        .private_key resb 32

section .bss
    ; NFT token IDs for each QUIGZIMON in party
    party_nft_ids resb 384  ; 6 QUIGZIMON * 64 bytes per TokenID

    ; HTTP response buffer
    http_response resb 4096

    ; Socket descriptor
    xrpl_socket resq 1
```

---

## 💰 Feature 4: Trading System

### NFT Sell Offer Flow

```assembly
trade_menu:
    ; Display party with "Sell" option
    call display_party_for_trade

    ; Player selects QUIGZIMON and price
    call get_trade_selection  ; Returns: rbx=index, rcx=price_xrp

    ; Create NFTokenCreateOffer transaction
    call create_sell_offer

    ; Submit to XRPL
    call submit_to_xrpl

    ; Update UI
    call display_listing_created
```

### Buy from Marketplace

```assembly
marketplace_browse:
    ; 1. Fetch all NFT offers for QUIGZIMON
    call fetch_nft_offers

    ; 2. Parse and display offers
    call display_marketplace_listings

    ; 3. Player selects offer to accept
    call get_marketplace_selection

    ; 4. Create NFTokenAcceptOffer transaction
    call accept_nft_offer

    ; 5. Submit payment
    call submit_to_xrpl

    ; 6. Add QUIGZIMON to player party
    call add_to_party
```

### Trading Data Structures

```assembly
section .data
    ; Marketplace filters
    max_listings equ 20

    ; Transaction templates
    nft_sell_offer_template db '{"method":"submit","params":[{"tx_json":{"TransactionType":"NFTokenCreateOffer","Account":"", ...}}]}', 0

    nft_buy_template db '{"method":"submit","params":[{"tx_json":{"TransactionType":"NFTokenAcceptOffer", ...}}]}', 0

section .bss
    ; Current marketplace listings
    marketplace_offers:
        .count resb 1
        .offers resb 2000  ; 20 offers * 100 bytes each
```

---

## ⚔️ Feature 5: PvP Battles with XRP Wagers

### Battle Wagering System

```assembly
pvp_battle_setup:
    ; 1. Player creates battle challenge
    call create_battle_challenge

    ; 2. Set wager amount (in XRP)
    call get_wager_amount  ; Returns: rax = XRP drops

    ; 3. Create Escrow for player's wager
    call create_battle_escrow

    ; 4. Broadcast challenge to network
    call broadcast_challenge

    ; 5. Wait for opponent
    call wait_for_opponent

    ; 6. Opponent creates matching escrow
    call verify_opponent_escrow

    ; 7. Start battle
    call pvp_battle_loop

    ; 8. Submit battle result
    call submit_battle_result

    ; 9. Release escrow to winner
    call release_escrow_to_winner
```

### Battle Escrow Mechanism

```
Player A                    XRPL                    Player B
   |                          |                         |
   |--Create Escrow (1 XRP)-->|                         |
   |                          |<--Create Escrow (1 XRP)--|
   |                          |                         |
   |<-------Battle Starts--------------------->|        |
   |                          |                         |
   |--Winner: Player A------->|                         |
   |                          |--Winner: Player A------>|
   |                          |                         |
   |<--Release 2 XRP----------|                         |
   |                          |                         |
```

### Battle Challenge Structure

```assembly
section .bss
    battle_challenge:
        .challenger_address resb 34
        .wager_amount resq 1          ; XRP in drops
        .escrow_sequence resq 1       ; Escrow tx sequence
        .challenge_id resq 1          ; Unique ID
        .expiry_time resq 1           ; Unix timestamp
        .selected_quigzimon resb 1    ; Party index

    active_battles resb 1000  ; Up to 10 concurrent battles
```

### PvP Battle Loop

```assembly
pvp_battle_loop:
    push rbp
    mov rbp, rsp

    ; Initialize both players' QUIGZIMON
    call init_pvp_battle

.turn_loop:
    ; Check for winner
    call check_battle_end
    cmp rax, 0
    jne .battle_over

    ; Player 1 turn (local)
    call player1_turn

    ; Send move to opponent via XRPL memo
    call send_battle_move

    ; Receive opponent's move
    call receive_opponent_move

    ; Execute both moves
    call execute_pvp_turn

    ; Update battle state
    call update_battle_state

    ; Display results
    call display_pvp_battle_status

    jmp .turn_loop

.battle_over:
    ; Determine winner
    call determine_winner

    ; Create FinishEscrow transaction
    call finish_battle_escrow

    ; Display result
    call display_pvp_result

    pop rbp
    ret
```

### Battle Communication Protocol

Using XRPL Payment with Memos:

```json
{
  "TransactionType": "Payment",
  "Account": "rPlayer1...",
  "Destination": "rPlayer2...",
  "Amount": "1",
  "Memos": [{
    "Memo": {
      "MemoType": "51554947425554544C45",  // "QUIGBATTLE" in hex
      "MemoData": "010215..."               // Battle move data in hex
    }
  }]
}
```

Battle Move Data Format (hex encoded):
```
Byte 0: Move type (0=attack, 1=special, 2=item, 3=forfeit)
Byte 1: Target (always 0 for 1v1)
Bytes 2-9: Battle ID
Bytes 10-11: Turn number
Bytes 12-15: Checksum
```

---

## 🔧 HTTP Client Implementation (Assembly)

### Socket Creation

```assembly
; Create TCP socket
create_socket:
    mov rax, 41        ; sys_socket
    mov rdi, 2         ; AF_INET
    mov rsi, 1         ; SOCK_STREAM
    mov rdx, 0         ; protocol
    syscall
    mov [xrpl_socket], rax
    ret

; Connect to XRPL server
connect_xrpl:
    ; Setup sockaddr_in structure
    lea rdi, [sockaddr]
    mov word [rdi], 2           ; AF_INET
    mov word [rdi + 2], 0xEAC8  ; Port 51234 (network byte order)

    ; Resolve hostname to IP
    call resolve_hostname
    mov [rdi + 4], eax

    ; Connect
    mov rax, 42        ; sys_connect
    mov rdi, [xrpl_socket]
    lea rsi, [sockaddr]
    mov rdx, 16
    syscall
    ret
```

### JSON-RPC Request Builder

```assembly
; Build account_info request
build_account_info_request:
    push rbp
    mov rbp, rsp

    ; Start building JSON
    lea rdi, [http_request_body]

    ; {"method":"account_info","params":[{"account":"rXXX"}]}
    mov rsi, json_request_start
    call strcpy

    ; Add account address
    mov rsi, [player_wallet.address]
    call strcat

    ; Close JSON
    mov rsi, json_request_end
    call strcat

    pop rbp
    ret
```

### HTTP POST Request

```assembly
send_http_post:
    push rbp
    mov rbp, rsp

    ; Build HTTP headers
    lea rdi, [http_request]
    mov rsi, http_post_header
    call strcpy

    ; Add Content-Length
    call calculate_content_length
    call append_content_length

    ; Add body
    lea rsi, [http_request_body]
    call strcat

    ; Send via socket
    mov rax, 1         ; sys_write
    mov rdi, [xrpl_socket]
    lea rsi, [http_request]
    mov rdx, [http_request_len]
    syscall

    pop rbp
    ret
```

### JSON Response Parser

```assembly
; Parse JSON response (simple implementation)
parse_json_response:
    push rbp
    mov rbp, rsp

    ; Find "result" field
    lea rdi, [http_response]
    mov rsi, result_key
    call strstr

    ; Extract value
    add rax, result_key_len
    call extract_json_value

    pop rbp
    ret
```

---

## 📊 Data Flow Examples

### Example 1: Mint NFT when catching QUIGZIMON

```
1. Player catches QUIGFLAME
   ↓
2. Generate metadata JSON
   {
     "name": "QUIGFLAME #1337",
     "level": 5,
     "hp": 45,
     ...
   }
   ↓
3. Create NFTokenMint JSON-RPC request
   {
     "method": "submit",
     "params": [{
       "tx_json": {
         "TransactionType": "NFTokenMint",
         "Account": "rQuigles1337...",
         "URI": "697066733A2F2F...",  // IPFS link in hex
         "Flags": 8,  // Transferable
         "TransferFee": 0
       }
     }]
   }
   ↓
4. Sign with player's secret key
   ↓
5. HTTP POST to s.altnet.rippletest.net:51234
   ↓
6. Parse response, extract NFTokenID
   ↓
7. Store in player_party[nft_token_id]
   ↓
8. Save to disk
```

### Example 2: Trade QUIGZIMON

```
SELLER:
1. Select QUIGZIMON from party
   ↓
2. Enter asking price (e.g., 10 XRP)
   ↓
3. Create NFTokenCreateOffer
   {
     "NFTokenID": "000B0000...",
     "Amount": "10000000",  // 10 XRP in drops
     "Flags": 1  // Sell offer
   }
   ↓
4. Submit to XRPL
   ↓
5. Get OfferID, display to player

BUYER:
1. Browse marketplace
   ↓
2. Query XRPL for all sell offers
   ↓
3. Display list with prices
   ↓
4. Player selects offer
   ↓
5. Create NFTokenAcceptOffer
   {
     "NFTokenSellOffer": "OFFER_ID..."
   }
   ↓
6. Submit to XRPL (pays XRP automatically)
   ↓
7. NFT transferred to buyer's wallet
   ↓
8. Add QUIGZIMON to buyer's party
```

### Example 3: PvP Battle

```
PLAYER 1:
1. Select QUIGZIMON for battle
   ↓
2. Set wager: 1 XRP
   ↓
3. Create Escrow (1 XRP, locked for 1 hour)
   ↓
4. Broadcast challenge via XRPL memo

PLAYER 2:
5. See challenge notification
   ↓
6. Accept challenge
   ↓
7. Create matching Escrow (1 XRP)

BATTLE:
8. Both players battle (turns sent as memos)
   ↓
9. Player 1 wins

PAYOUT:
10. Both submit winner signature
    ↓
11. Finish Escrow, release 2 XRP to Player 1
    ↓
12. Winner gets XRP + EXP
```

---

## 🔐 Security Considerations

### Wallet Security
- **Secret keys stored encrypted** in save file
- **Password-based encryption** (AES-256 implemented in assembly)
- **Never transmit seeds** over network
- **Sign transactions locally**

### Battle Verification
- **Escrow system** prevents cheating on wagers
- **Both players must agree** on battle result
- **Timeout mechanism** if opponent disconnects
- **Refund if no consensus**

### NFT Integrity
- **Metadata hash** stored on-chain
- **Immutable stats** at time of minting
- **Can't modify** NFT attributes after creation
- **Provable ownership** via XRPL

---

## 🚀 Implementation Plan

### Phase 1: Core Infrastructure ✅ (Current Task)
- [x] Architecture design
- [ ] HTTP client in assembly
- [ ] Socket communication
- [ ] JSON builder/parser
- [ ] XRPL API wrapper functions

### Phase 2: NFT Integration
- [ ] Wallet connection
- [ ] NFT minting on catch
- [ ] Metadata generation
- [ ] NFT viewing in party

### Phase 3: Trading System
- [ ] Create sell offers
- [ ] Marketplace browser
- [ ] Buy functionality
- [ ] Trade history

### Phase 4: PvP Battles
- [ ] Battle challenges
- [ ] Escrow system
- [ ] Turn-by-turn via memos
- [ ] Winner payout

### Phase 5: Polish & Testing
- [ ] Testnet testing
- [ ] Error handling
- [ ] UI improvements
- [ ] Documentation

---

## 📝 File Structure

```
pocket-monsters-asm/
├── game_enhanced.asm         # Core game
├── xrpl_client.asm          # HTTP/XRPL client (NEW)
├── xrpl_nft.asm             # NFT minting/trading (NEW)
├── xrpl_pvp.asm             # PvP battles (NEW)
├── xrpl_crypto.asm          # Signing/encryption (NEW)
├── json_parser.asm          # JSON parsing (NEW)
├── build_xrpl.bat           # Build with XRPL features
└── XRPL_INTEGRATION.md      # This file
```

---

**Next step: Implement HTTP client in pure assembly!** 🚀
