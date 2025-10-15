; QUIGZIMON NFT LAUNCHPAD
; First-ever blockchain-gated game entry in pure assembly!
; Players must mint their starter QUIGZIMON as NFT to begin

section .data
    ; ========== LAUNCHPAD BANNER ==========
    launchpad_banner db 0xA
                     db "╔════════════════════════════════════════════════════╗", 0xA
                     db "║                                                    ║", 0xA
                     db "║         🎮 QUIGZIMON NFT LAUNCHPAD 🎮             ║", 0xA
                     db "║                                                    ║", 0xA
                     db "║     The World's First Blockchain-Gated RPG        ║", 0xA
                     db "║          Written in Pure Assembly                  ║", 0xA
                     db "║                                                    ║", 0xA
                     db "╚════════════════════════════════════════════════════╝", 0xA, 0xA, 0
    launchpad_banner_len equ $ - launchpad_banner

    ; ========== WELCOME MESSAGE ==========
    welcome_msg db "Welcome to QUIGZIMON!", 0xA, 0xA
                db "To begin your adventure, you must:", 0xA
                db "  1. Create your XRPL wallet", 0xA
                db "  2. Fund your wallet with testnet XRP", 0xA
                db "  3. Choose and MINT your starter QUIGZIMON as an NFT", 0xA
                db "  4. Your NFT is your key to the game!", 0xA, 0xA, 0
    welcome_msg_len equ $ - welcome_msg

    ; ========== WALLET SETUP ==========
    wallet_setup_msg db "═══════════════════════════════════════", 0xA
                     db "      STEP 1: WALLET SETUP", 0xA
                     db "═══════════════════════════════════════", 0xA, 0xA, 0
    wallet_setup_msg_len equ $ - wallet_setup_msg

    checking_wallet_msg db "Checking for existing wallet...", 0xA, 0
    checking_wallet_msg_len equ $ - checking_wallet_msg

    wallet_found_msg db 0xA, "✅ Wallet found!", 0xA
                     db "Address: ", 0
    wallet_found_msg_len equ $ - wallet_found_msg

    no_wallet_msg db 0xA, "No wallet found. Generating new wallet...", 0xA, 0
    no_wallet_msg_len equ $ - no_wallet_msg

    wallet_created_msg db 0xA, "✅ Wallet created successfully!", 0xA, 0xA
                       db "Your XRPL Address:", 0xA
                       db ">>> ", 0
    wallet_created_msg_len equ $ - wallet_created_msg

    wallet_saved_msg db 0xA, 0xA, "💾 Wallet saved to: quigzimon_wallet.dat", 0xA
                     db "⚠️  Keep this file safe! It controls your NFTs.", 0xA, 0xA, 0
    wallet_saved_msg_len equ $ - wallet_saved_msg

    ; ========== FUNDING INSTRUCTIONS ==========
    funding_msg db "═══════════════════════════════════════", 0xA
                db "      STEP 2: FUND YOUR WALLET", 0xA
                db "═══════════════════════════════════════", 0xA, 0xA
                db "To mint NFTs, you need testnet XRP (FREE!):", 0xA, 0xA
                db "1. Copy your address above", 0xA
                db "2. Visit: https://xrpl.org/xrp-testnet-faucet.html", 0xA
                db "3. Paste your address and click 'Generate Credentials'", 0xA
                db "4. Wait 5-10 seconds for funding", 0xA
                db "5. Come back here and press Enter", 0xA, 0xA
                db "Press Enter when funded...", 0
    funding_msg_len equ $ - funding_msg

    checking_balance_msg db 0xA, 0xA, "Checking your balance...", 0xA, 0
    checking_balance_msg_len equ $ - checking_balance_msg

    balance_found_msg db "✅ Balance: ", 0
    balance_found_msg_len equ $ - balance_found_msg

    balance_suffix db " drops (XRP)", 0xA, 0xA
    balance_suffix_len equ $ - balance_suffix

    insufficient_balance_msg db "❌ Insufficient balance!", 0xA
                             db "You need at least 1,000,000 drops (1 XRP)", 0xA
                             db "Please fund your wallet and try again.", 0xA, 0xA, 0
    insufficient_balance_msg_len equ $ - insufficient_balance_msg

    ; ========== STARTER SELECTION ==========
    starter_selection_msg db "═══════════════════════════════════════", 0xA
                          db "  STEP 3: CHOOSE YOUR STARTER NFT", 0xA
                          db "═══════════════════════════════════════", 0xA, 0xA
                          db "Select your starter QUIGZIMON to mint as NFT:", 0xA, 0xA, 0
    starter_selection_msg_len equ $ - starter_selection_msg

    starter_1_msg db "1) 🔥 QUIGFLAME", 0xA
                  db "   Type: Fire", 0xA
                  db "   HP: 65  |  Attack: 22  |  Defense: 16  |  Speed: 18", 0xA
                  db "   Signature Move: Flamethrower", 0xA
                  db "   Best against: Grass types", 0xA, 0xA, 0
    starter_1_msg_len equ $ - starter_1_msg

    starter_2_msg db "2) 💧 QUIGWAVE", 0xA
                  db "   Type: Water", 0xA
                  db "   HP: 70  |  Attack: 18  |  Defense: 20  |  Speed: 16", 0xA
                  db "   Signature Move: Hydro Pump", 0xA
                  db "   Best against: Fire types", 0xA, 0xA, 0
    starter_2_msg_len equ $ - starter_2_msg

    starter_3_msg db "3) 🍃 QUIGLEAF", 0xA
                  db "   Type: Grass", 0xA
                  db "   HP: 60  |  Attack: 20  |  Defense: 18  |  Speed: 22", 0xA
                  db "   Signature Move: Solar Beam", 0xA
                  db "   Best against: Water types", 0xA, 0xA, 0
    starter_3_msg_len equ $ - starter_3_msg

    choose_prompt db "Enter your choice (1-3): ", 0
    choose_prompt_len equ $ - choose_prompt

    invalid_choice_msg db "Invalid choice! Please select 1, 2, or 3.", 0xA, 0
    invalid_choice_msg_len equ $ - invalid_choice_msg

    ; ========== MINTING PROCESS ==========
    minting_header_msg db 0xA, "═══════════════════════════════════════", 0xA
                       db "      MINTING YOUR STARTER NFT", 0xA
                       db "═══════════════════════════════════════", 0xA, 0xA, 0
    minting_header_msg_len equ $ - minting_header_msg

    selected_msg db "You selected: ", 0
    selected_msg_len equ $ - selected_msg

    confirming_msg db 0xA, 0xA, "Confirm minting this QUIGZIMON as NFT? (y/n): ", 0
    confirming_msg_len equ $ - confirming_msg

    minting_canceled_msg db 0xA, "Minting canceled. Returning to selection...", 0xA, 0xA, 0
    minting_canceled_msg_len equ $ - minting_canceled_msg

    ; Progress indicators
    progress_1 db "⏳ [1/6] Preparing transaction...", 0xA, 0
    progress_1_len equ $ - progress_1

    progress_2 db "⏳ [2/6] Generating NFT metadata...", 0xA, 0
    progress_2_len equ $ - progress_2

    progress_3 db "⏳ [3/6] Serializing transaction...", 0xA, 0
    progress_3_len equ $ - progress_3

    progress_4 db "⏳ [4/6] Signing with your wallet...", 0xA, 0
    progress_4_len equ $ - progress_4

    progress_5 db "⏳ [5/6] Submitting to XRPL...", 0xA, 0
    progress_5_len equ $ - progress_5

    progress_6 db "⏳ [6/6] Confirming transaction...", 0xA, 0
    progress_6_len equ $ - progress_6

    ; ========== SUCCESS ==========
    success_banner db 0xA, 0xA
                   db "╔════════════════════════════════════════════════════╗", 0xA
                   db "║                                                    ║", 0xA
                   db "║          🎉 NFT SUCCESSFULLY MINTED! 🎉           ║", 0xA
                   db "║                                                    ║", 0xA
                   db "╚════════════════════════════════════════════════════╝", 0xA, 0xA, 0
    success_banner_len equ $ - success_banner

    nft_details_msg db "Your NFT Details:", 0xA
                    db "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", 0xA, 0
    nft_details_msg_len equ $ - nft_details_msg

    tx_hash_label db "Transaction Hash: ", 0
    tx_hash_label_len equ $ - tx_hash_label

    explorer_link_msg db 0xA, "View on XRPL Explorer:", 0xA
                      db "https://testnet.xrpl.org/transactions/", 0
    explorer_link_msg_len equ $ - explorer_link_msg

    nft_saved_msg db 0xA, 0xA, "💾 Your NFT has been saved to your game profile.", 0xA
                  db "🎮 You can now begin your QUIGZIMON adventure!", 0xA, 0xA, 0
    nft_saved_msg_len equ $ - nft_saved_msg

    press_enter_msg db "Press Enter to start the game...", 0
    press_enter_msg_len equ $ - press_enter_msg

    ; ========== ERROR MESSAGES ==========
    error_connection_msg db "❌ ERROR: Could not connect to XRPL testnet", 0xA
                         db "Please check your internet connection and try again.", 0xA, 0xA, 0
    error_connection_msg_len equ $ - error_connection_msg

    error_minting_msg db "❌ ERROR: NFT minting failed", 0xA
                      db "This could be due to:", 0xA
                      db "  • Insufficient balance", 0xA
                      db "  • Network issues", 0xA
                      db "  • Invalid transaction", 0xA, 0xA
                      db "Please try again or contact support.", 0xA, 0xA, 0
    error_minting_msg_len equ $ - error_minting_msg

    retry_prompt db "Would you like to try again? (y/n): ", 0
    retry_prompt_len equ $ - retry_prompt

    ; ========== STARTER QUIGZIMON DATA ==========
    ; Each starter: species, level, cur_hp, max_hp, exp, status, atk, def, spd
    starter_quigflame:
        db 0                        ; Species: QUIGFLAME
        db 5                        ; Level: 5
        dw 65                       ; Current HP
        dw 65                       ; Max HP
        dw 0                        ; EXP
        db 0                        ; Status: Healthy
        dw 22                       ; Attack
        dw 16                       ; Defense
        dw 18                       ; Speed

    starter_quigwave:
        db 1                        ; Species: QUIGWAVE
        db 5                        ; Level: 5
        dw 70                       ; Current HP
        dw 70                       ; Max HP
        dw 0                        ; EXP
        db 0                        ; Status: Healthy
        dw 18                       ; Attack
        dw 20                       ; Defense
        dw 16                       ; Speed

    starter_quigleaf:
        db 2                        ; Species: QUIGLEAF
        db 5                        ; Level: 5
        dw 60                       ; Current HP
        dw 60                       ; Max HP
        dw 0                        ; EXP
        db 0                        ; Status: Healthy
        dw 20                       ; Attack
        dw 18                       ; Defense
        dw 22                       ; Speed

    ; IPFS metadata URIs for starters
    ipfs_quigflame db "ipfs://QmQuigflameStarterMetadata001", 0
    ipfs_quigwave db "ipfs://QmQuigwaveStarterMetadata001", 0
    ipfs_quigleaf db "ipfs://QmQuigleafStarterMetadata001", 0

    ; Species names for display
    name_quigflame db "QUIGFLAME", 0
    name_quigwave db "QUIGWAVE", 0
    name_quigleaf db "QUIGLEAF", 0

section .bss
    ; User input
    input_buffer resb 16

    ; Wallet state
    wallet_exists resb 1
    account_funded resb 1

    ; Starter selection
    selected_starter resb 1         ; 0=QUIGFLAME, 1=QUIGWAVE, 2=QUIGLEAF
    starter_data resb 15            ; Copy of selected starter

    ; Minting results
    tx_hash resb 128
    nft_token_id resb 128

    ; Game profile
    player_has_starter_nft resb 1

section .text
    global nft_launchpad_start
    extern crypto_bridge_init
    extern load_wallet
    extern generate_new_wallet
    extern xrpl_init
    extern xrpl_close
    extern get_account_info
    extern mint_quigzimon_to_xrpl
    extern account_address
    extern account_balance
    extern account_sequence
    extern print_string
    extern print_number

; ========== MAIN LAUNCHPAD FLOW ==========

nft_launchpad_start:
    push rbp
    mov rbp, rsp

    ; Display banner
    mov rax, 1
    mov rdi, 1
    mov rsi, launchpad_banner
    mov rdx, launchpad_banner_len
    syscall

    ; Display welcome message
    mov rax, 1
    mov rdi, 1
    mov rsi, welcome_msg
    mov rdx, welcome_msg_len
    syscall

    ; Initialize crypto
    call crypto_bridge_init
    test rax, rax
    jnz .error_init

.step1_wallet:
    ; STEP 1: Wallet Setup
    call launchpad_wallet_setup
    test rax, rax
    jnz .error_wallet

.step2_funding:
    ; STEP 2: Check funding
    call launchpad_check_funding
    test rax, rax
    jnz .step2_funding          ; Retry if not funded

.step3_selection:
    ; STEP 3: Starter selection
    call launchpad_starter_selection
    test rax, rax
    jnz .step3_selection        ; Retry if canceled

.step4_minting:
    ; STEP 4: Mint the NFT
    call launchpad_mint_starter
    test rax, rax
    jnz .minting_failed

.success:
    ; Display success banner
    mov rax, 1
    mov rdi, 1
    mov rsi, success_banner
    mov rdx, success_banner_len
    syscall

    ; Show NFT details
    call display_nft_success

    ; Mark player as having starter NFT
    mov byte [player_has_starter_nft], 1

    ; Wait for user to continue
    mov rax, 1
    mov rdi, 1
    mov rsi, press_enter_msg
    mov rdx, press_enter_msg_len
    syscall

    call wait_for_enter

    ; Return success - game can now start!
    xor rax, rax
    pop rbp
    ret

.minting_failed:
    mov rax, 1
    mov rdi, 1
    mov rsi, error_minting_msg
    mov rdx, error_minting_msg_len
    syscall

    ; Ask to retry
    mov rax, 1
    mov rdi, 1
    mov rsi, retry_prompt
    mov rdx, retry_prompt_len
    syscall

    call get_yes_no
    test rax, rax
    jnz .step3_selection        ; Try again from selection

    jmp .exit_error

.error_init:
.error_wallet:
.exit_error:
    mov rax, -1
    pop rbp
    ret

; ========== STEP 1: WALLET SETUP ==========

launchpad_wallet_setup:
    push rbp
    mov rbp, rsp

    ; Display header
    mov rax, 1
    mov rdi, 1
    mov rsi, wallet_setup_msg
    mov rdx, wallet_setup_msg_len
    syscall

    ; Check for existing wallet
    mov rax, 1
    mov rdi, 1
    mov rsi, checking_wallet_msg
    mov rdx, checking_wallet_msg_len
    syscall

    call load_wallet
    test rax, rax
    jz .wallet_found

.generate_new:
    ; No wallet found, generate new
    mov rax, 1
    mov rdi, 1
    mov rsi, no_wallet_msg
    mov rdx, no_wallet_msg_len
    syscall

    call generate_new_wallet
    test rax, rax
    jnz .error

    ; Display new wallet info
    mov rax, 1
    mov rdi, 1
    mov rsi, wallet_created_msg
    mov rdx, wallet_created_msg_len
    syscall

    lea rsi, [account_address]
    call print_string

    mov rax, 1
    mov rdi, 1
    mov rsi, wallet_saved_msg
    mov rdx, wallet_saved_msg_len
    syscall

    xor rax, rax
    pop rbp
    ret

.wallet_found:
    ; Existing wallet loaded
    mov rax, 1
    mov rdi, 1
    mov rsi, wallet_found_msg
    mov rdx, wallet_found_msg_len
    syscall

    lea rsi, [account_address]
    call print_string

    ; Newline
    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    xor rax, rax
    pop rbp
    ret

.error:
    mov rax, -1
    pop rbp
    ret

; ========== STEP 2: CHECK FUNDING ==========

launchpad_check_funding:
    push rbp
    mov rbp, rsp

    ; Display funding instructions
    mov rax, 1
    mov rdi, 1
    mov rsi, funding_msg
    mov rdx, funding_msg_len
    syscall

    ; Wait for user to fund
    call wait_for_enter

    ; Check balance
    mov rax, 1
    mov rdi, 1
    mov rsi, checking_balance_msg
    mov rdx, checking_balance_msg_len
    syscall

    ; Connect to XRPL
    call xrpl_init
    test rax, rax
    jnz .connection_error

    ; Get account info
    call get_account_info
    test rax, rax
    jnz .account_error

    ; Display balance
    mov rax, 1
    mov rdi, 1
    mov rsi, balance_found_msg
    mov rdx, balance_found_msg_len
    syscall

    mov rax, [account_balance]
    call print_number

    mov rax, 1
    mov rdi, 1
    mov rsi, balance_suffix
    mov rdx, balance_suffix_len
    syscall

    ; Check if sufficient (need at least 1 XRP = 1,000,000 drops)
    mov rax, [account_balance]
    cmp rax, 1000000
    jl .insufficient

    ; Success!
    call xrpl_close
    xor rax, rax
    pop rbp
    ret

.insufficient:
    call xrpl_close
    mov rax, 1
    mov rdi, 1
    mov rsi, insufficient_balance_msg
    mov rdx, insufficient_balance_msg_len
    syscall

    ; Return error to retry
    mov rax, -1
    pop rbp
    ret

.connection_error:
    mov rax, 1
    mov rdi, 1
    mov rsi, error_connection_msg
    mov rdx, error_connection_msg_len
    syscall
    mov rax, -1
    pop rbp
    ret

.account_error:
    call xrpl_close
    mov rax, 1
    mov rdi, 1
    mov rsi, insufficient_balance_msg
    mov rdx, insufficient_balance_msg_len
    syscall
    mov rax, -1
    pop rbp
    ret

; ========== STEP 3: STARTER SELECTION ==========

launchpad_starter_selection:
    push rbp
    mov rbp, rsp

.show_menu:
    ; Display selection menu
    mov rax, 1
    mov rdi, 1
    mov rsi, starter_selection_msg
    mov rdx, starter_selection_msg_len
    syscall

    ; Show option 1: QUIGFLAME
    mov rax, 1
    mov rdi, 1
    mov rsi, starter_1_msg
    mov rdx, starter_1_msg_len
    syscall

    ; Show option 2: QUIGWAVE
    mov rax, 1
    mov rdi, 1
    mov rsi, starter_2_msg
    mov rdx, starter_2_msg_len
    syscall

    ; Show option 3: QUIGLEAF
    mov rax, 1
    mov rdi, 1
    mov rsi, starter_3_msg
    mov rdx, starter_3_msg_len
    syscall

    ; Get user choice
    mov rax, 1
    mov rdi, 1
    mov rsi, choose_prompt
    mov rdx, choose_prompt_len
    syscall

    ; Read input
    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 16
    syscall

    ; Parse choice
    movzx rax, byte [input_buffer]
    sub al, '0'
    cmp al, 1
    jl .invalid
    cmp al, 3
    jg .invalid

    ; Valid choice (1-3), convert to 0-indexed
    dec al
    mov [selected_starter], al

    ; Confirm selection
    call confirm_starter_choice
    test rax, rax
    jnz .show_menu              ; User canceled, go back

    ; Selection confirmed!
    xor rax, rax
    pop rbp
    ret

.invalid:
    mov rax, 1
    mov rdi, 1
    mov rsi, invalid_choice_msg
    mov rdx, invalid_choice_msg_len
    syscall
    jmp .show_menu

; ========== CONFIRM STARTER CHOICE ==========

confirm_starter_choice:
    push rbp
    mov rbp, rsp

    ; Display selected starter
    mov rax, 1
    mov rdi, 1
    mov rsi, selected_msg
    mov rdx, selected_msg_len
    syscall

    ; Get starter name
    movzx rax, byte [selected_starter]
    cmp al, 0
    je .show_quigflame
    cmp al, 1
    je .show_quigwave
    jmp .show_quigleaf

.show_quigflame:
    lea rsi, [name_quigflame]
    jmp .display_name

.show_quigwave:
    lea rsi, [name_quigwave]
    jmp .display_name

.show_quigleaf:
    lea rsi, [name_quigleaf]

.display_name:
    call print_string

    ; Ask for confirmation
    mov rax, 1
    mov rdi, 1
    mov rsi, confirming_msg
    mov rdx, confirming_msg_len
    syscall

    call get_yes_no
    test rax, rax
    jz .confirmed

    ; User said no
    mov rax, 1
    mov rdi, 1
    mov rsi, minting_canceled_msg
    mov rdx, minting_canceled_msg_len
    syscall

    mov rax, -1                 ; Return error to go back
    pop rbp
    ret

.confirmed:
    xor rax, rax                ; Return success
    pop rbp
    ret

; ========== STEP 4: MINT STARTER NFT ==========

launchpad_mint_starter:
    push rbp
    mov rbp, rsp

    ; Display minting header
    mov rax, 1
    mov rdi, 1
    mov rsi, minting_header_msg
    mov rdx, minting_header_msg_len
    syscall

    ; Progress 1: Preparing
    mov rax, 1
    mov rdi, 1
    mov rsi, progress_1
    mov rdx, progress_1_len
    syscall

    ; Copy selected starter data
    movzx rax, byte [selected_starter]
    imul rax, 15                ; Each starter is 15 bytes

    cmp rax, 0
    je .copy_quigflame
    cmp rax, 15
    je .copy_quigwave
    jmp .copy_quigleaf

.copy_quigflame:
    lea rsi, [starter_quigflame]
    lea rdi, [ipfs_quigflame]
    jmp .do_copy

.copy_quigwave:
    lea rsi, [starter_quigwave]
    lea rdi, [ipfs_quigwave]
    jmp .do_copy

.copy_quigleaf:
    lea rsi, [starter_quigleaf]
    lea rdi, [ipfs_quigleaf]

.do_copy:
    push rdi                    ; Save IPFS URI pointer
    lea rdi, [starter_data]
    mov rcx, 15
    rep movsb
    pop rsi                     ; rsi = IPFS URI

    ; Progress 2: Metadata
    mov rax, 1
    mov rdi, 1
    push rsi
    mov rsi, progress_2
    mov rdx, progress_2_len
    syscall
    pop rsi

    ; Progress 3: Serializing
    mov rax, 1
    mov rdi, 1
    push rsi
    mov rsi, progress_3
    mov rdx, progress_3_len
    syscall
    pop rsi

    ; Progress 4: Signing
    mov rax, 1
    mov rdi, 1
    push rsi
    mov rsi, progress_4
    mov rdx, progress_4_len
    syscall
    pop rsi

    ; Progress 5: Submitting
    mov rax, 1
    mov rdi, 1
    push rsi
    mov rsi, progress_5
    mov rdx, progress_5_len
    syscall
    pop rsi

    ; Actually mint the NFT
    lea rdi, [starter_data]     ; QUIGZIMON data
    ; rsi already has IPFS URI
    call mint_quigzimon_to_xrpl

    test rax, rax
    jnz .minting_error

    ; Progress 6: Confirming
    mov rax, 1
    mov rdi, 1
    mov rsi, progress_6
    mov rdx, progress_6_len
    syscall

    ; Small delay for effect
    call small_delay

    ; Success!
    xor rax, rax
    pop rbp
    ret

.minting_error:
    mov rax, -1
    pop rbp
    ret

; ========== SUCCESS DISPLAY ==========

display_nft_success:
    push rbp
    mov rbp, rsp

    ; Display NFT details header
    mov rax, 1
    mov rdi, 1
    mov rsi, nft_details_msg
    mov rdx, nft_details_msg_len
    syscall

    ; Show starter name
    movzx rax, byte [selected_starter]
    cmp al, 0
    je .name_quigflame
    cmp al, 1
    je .name_quigwave
    lea rsi, [name_quigleaf]
    jmp .print_name

.name_quigflame:
    lea rsi, [name_quigflame]
    jmp .print_name

.name_quigwave:
    lea rsi, [name_quigwave]

.print_name:
    call print_string

    ; Newline
    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    ; Show transaction hash (from mint_quigzimon_to_xrpl)
    mov rax, 1
    mov rdi, 1
    mov rsi, tx_hash_label
    mov rdx, tx_hash_label_len
    syscall

    ; Print tx hash (would be from minting function)
    lea rsi, [tx_hash_result]
    call print_string

    ; Show explorer link
    mov rax, 1
    mov rdi, 1
    mov rsi, explorer_link_msg
    mov rdx, explorer_link_msg_len
    syscall

    lea rsi, [tx_hash_result]
    call print_string

    ; Newline
    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    ; Show saved message
    mov rax, 1
    mov rdi, 1
    mov rsi, nft_saved_msg
    mov rdx, nft_saved_msg_len
    syscall

    pop rbp
    ret

; ========== UTILITY FUNCTIONS ==========

; Wait for Enter key
wait_for_enter:
    push rax
    push rdi
    push rsi
    push rdx

    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 16
    syscall

    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

; Get yes/no input
; Returns: rax = 0 for yes, -1 for no
get_yes_no:
    push rbx

    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 16
    syscall

    movzx rax, byte [input_buffer]
    or al, 0x20                 ; Convert to lowercase
    cmp al, 'y'
    je .yes

    mov rax, -1
    pop rbx
    ret

.yes:
    xor rax, rax
    pop rbx
    ret

; Small delay for visual effect
small_delay:
    push rcx
    mov rcx, 50000000
.loop:
    dec rcx
    jnz .loop
    pop rcx
    ret

section .bss
    newline db 0xA
    tx_hash_result resb 128

; ========== EXPORTS ==========
global nft_launchpad_start
global player_has_starter_nft
global selected_starter
global starter_data
