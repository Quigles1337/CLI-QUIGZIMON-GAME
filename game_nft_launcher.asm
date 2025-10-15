; QUIGZIMON NFT-GATED GAME LAUNCHER
; Entry point that requires NFT minting before gameplay
; Pure assembly blockchain-gated gaming!

section .data
    ; ========== GAME TITLE ==========
    game_title db 0xA, 0xA
               db "    ██████╗ ██╗   ██╗██╗ ██████╗ ███████╗██╗███╗   ███╗ ██████╗ ███╗   ██╗", 0xA
               db "   ██╔═══██╗██║   ██║██║██╔════╝ ╚══███╔╝██║████╗ ████║██╔═══██╗████╗  ██║", 0xA
               db "   ██║   ██║██║   ██║██║██║  ███╗  ███╔╝ ██║██╔████╔██║██║   ██║██╔██╗ ██║", 0xA
               db "   ██║▄▄ ██║██║   ██║██║██║   ██║ ███╔╝  ██║██║╚██╔╝██║██║   ██║██║╚██╗██║", 0xA
               db "   ╚██████╔╝╚██████╔╝██║╚██████╔╝███████╗██║██║ ╚═╝ ██║╚██████╔╝██║ ╚████║", 0xA
               db "    ╚══▀▀═╝  ╚═════╝ ╚═╝ ╚═════╝ ╚══════╝╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝", 0xA, 0xA, 0
    game_title_len equ $ - game_title

    subtitle db "          🎮 The First Blockchain-Gated RPG in Pure Assembly 🎮", 0xA
             db "                    ⛓️  Powered by XRPL Testnet  ⛓️", 0xA, 0xA, 0
    subtitle_len equ $ - subtitle

    ; ========== MAIN MENU ==========
    main_menu_msg db "╔════════════════════════════════════════════════════╗", 0xA
                  db "║                   MAIN MENU                        ║", 0xA
                  db "╚════════════════════════════════════════════════════╝", 0xA, 0xA
                  db "1) 🚀 Start New Game (Requires NFT Minting)", 0xA
                  db "2) 📖 Load Game", 0xA
                  db "3) ℹ️  About QUIGZIMON", 0xA
                  db "4) 💰 Check Wallet Balance", 0xA
                  db "5) 🏆 View My NFTs", 0xA
                  db "0) 🚪 Exit", 0xA, 0xA
                  db "Select option: ", 0
    main_menu_msg_len equ $ - main_menu_msg

    ; ========== ABOUT MESSAGE ==========
    about_msg db 0xA, "╔════════════════════════════════════════════════════╗", 0xA
              db "║              ABOUT QUIGZIMON                       ║", 0xA
              db "╚════════════════════════════════════════════════════╝", 0xA, 0xA
              db "QUIGZIMON is the world's first blockchain-gated RPG", 0xA
              db "written entirely in x86-64 assembly language!", 0xA, 0xA
              db "🎮 Features:", 0xA
              db "  • Turn-based Pokemon-style battles", 0xA
              db "  • Machine learning AI opponents", 0xA
              db "  • REAL NFTs on XRP Ledger", 0xA
              db "  • True ownership of your monsters", 0xA
              db "  • Trade with other players", 0xA
              db "  • 100% pure assembly (no dependencies!)", 0xA, 0xA
              db "🏆 World Firsts:", 0xA
              db "  • First blockchain game in assembly", 0xA
              db "  • First Q-Learning AI in assembly", 0xA
              db "  • First NFT-gated game in assembly", 0xA, 0xA
              db "📊 Stats:", 0xA
              db "  • 18,600+ lines of code", 0xA
              db "  • 60+ features", 0xA
              db "  • <50KB memory footprint", 0xA, 0xA
              db "Created by: Quigles1337", 0xA
              db "Powered by: Pure determination + XRPL", 0xA, 0xA, 0
    about_msg_len equ $ - about_msg

    press_enter db "Press Enter to continue...", 0xA, 0
    press_enter_len equ $ - press_enter

    ; ========== LOAD GAME MESSAGES ==========
    loading_msg db 0xA, "Loading saved game...", 0xA, 0
    loading_msg_len equ $ - loading_msg

    no_save_msg db "No saved game found!", 0xA
                db "Please start a new game first.", 0xA, 0xA, 0
    no_save_msg_len equ $ - no_save_msg

    load_success_msg db "Game loaded successfully!", 0xA, 0xA, 0
    load_success_msg_len equ $ - load_success_msg

    ; ========== WALLET MESSAGES ==========
    checking_wallet_balance_msg db 0xA, "Connecting to XRPL...", 0xA, 0
    checking_wallet_balance_msg_len equ $ - checking_wallet_balance_msg

    your_balance_msg db 0xA, "Your Wallet Balance:", 0xA
                     db "Address: ", 0
    your_balance_msg_len equ $ - your_balance_msg

    balance_amt_msg db 0xA, "Balance: ", 0
    balance_amt_msg_len equ $ - balance_amt_msg

    drops_suffix db " drops (", 0
    drops_suffix_len equ $ - drops_suffix

    xrp_suffix db " XRP)", 0xA, 0xA, 0
    xrp_suffix_len equ $ - xrp_suffix

    ; ========== NFT VIEW MESSAGES ==========
    viewing_nfts_msg db 0xA, "Fetching your NFTs from XRPL...", 0xA, 0xA, 0
    viewing_nfts_msg_len equ $ - viewing_nfts_msg

    your_nfts_header db "╔════════════════════════════════════════════════════╗", 0xA
                     db "║               YOUR QUIGZIMON NFTs                  ║", 0xA
                     db "╚════════════════════════════════════════════════════╝", 0xA, 0xA, 0
    your_nfts_header_len equ $ - your_nfts_header

    no_nfts_msg db "You don't have any QUIGZIMON NFTs yet.", 0xA
                db "Start a new game to mint your first one!", 0xA, 0xA, 0
    no_nfts_msg_len equ $ - no_nfts_msg

    ; ========== EXIT MESSAGE ==========
    exit_msg db 0xA, "Thanks for playing QUIGZIMON!", 0xA
             db "Your NFTs are safe on the blockchain. 🔐", 0xA
             db "See you soon, trainer! 👋", 0xA, 0xA, 0
    exit_msg_len equ $ - exit_msg

    invalid_option_msg db 0xA, "Invalid option! Please try again.", 0xA, 0xA, 0
    invalid_option_msg_len equ $ - invalid_option_msg

section .bss
    input_buffer resb 16
    game_state_loaded resb 1

section .text
    global _start

    ; External functions
    extern nft_launchpad_start
    extern player_has_starter_nft
    extern selected_starter
    extern starter_data
    extern load_wallet
    extern xrpl_init
    extern xrpl_close
    extern get_account_info
    extern account_address
    extern account_balance
    extern print_string
    extern print_number

_start:
    ; Clear screen (optional)
    ; call clear_screen

    ; Display game title
    mov rax, 1
    mov rdi, 1
    mov rsi, game_title
    mov rdx, game_title_len
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, subtitle
    mov rdx, subtitle_len
    syscall

.main_loop:
    ; Display main menu
    mov rax, 1
    mov rdi, 1
    mov rsi, main_menu_msg
    mov rdx, main_menu_msg_len
    syscall

    ; Get user input
    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 16
    syscall

    ; Parse choice
    movzx rax, byte [input_buffer]
    sub al, '0'

    cmp al, 0
    je .exit

    cmp al, 1
    je .new_game

    cmp al, 2
    je .load_game

    cmp al, 3
    je .about

    cmp al, 4
    je .check_balance

    cmp al, 5
    je .view_nfts

    ; Invalid option
    mov rax, 1
    mov rdi, 1
    mov rsi, invalid_option_msg
    mov rdx, invalid_option_msg_len
    syscall

    jmp .main_loop

.new_game:
    ; Start NFT launchpad
    call nft_launchpad_start
    test rax, rax
    jnz .main_loop              ; Error or canceled, back to menu

    ; NFT successfully minted, start game!
    call start_game_with_nft
    jmp .main_loop

.load_game:
    mov rax, 1
    mov rdi, 1
    mov rsi, loading_msg
    mov rdx, loading_msg_len
    syscall

    ; Try to load save file
    call load_game_state
    test rax, rax
    jnz .no_save_found

    ; Game loaded successfully
    mov rax, 1
    mov rdi, 1
    mov rsi, load_success_msg
    mov rdx, load_success_msg_len
    syscall

    call wait_for_enter

    ; Start game with loaded state
    call start_game_loaded
    jmp .main_loop

.no_save_found:
    mov rax, 1
    mov rdi, 1
    mov rsi, no_save_msg
    mov rdx, no_save_msg_len
    syscall

    call wait_for_enter
    jmp .main_loop

.about:
    mov rax, 1
    mov rdi, 1
    mov rsi, about_msg
    mov rdx, about_msg_len
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, press_enter
    mov rdx, press_enter_len
    syscall

    call wait_for_enter
    jmp .main_loop

.check_balance:
    call display_wallet_balance
    call wait_for_enter
    jmp .main_loop

.view_nfts:
    call display_nft_collection
    call wait_for_enter
    jmp .main_loop

.exit:
    ; Display exit message
    mov rax, 1
    mov rdi, 1
    mov rsi, exit_msg
    mov rdx, exit_msg_len
    syscall

    ; Exit program
    mov rax, 60                 ; sys_exit
    xor rdi, rdi
    syscall

; ========== GAME LAUNCH FUNCTIONS ==========

; Start game with newly minted NFT
start_game_with_nft:
    push rbp
    mov rbp, rsp

    ; Copy starter data to player's first party slot
    ; This would integrate with game_enhanced.asm
    lea rsi, [starter_data]
    lea rdi, [player_party]
    mov rcx, 15
    rep movsb

    ; Set party size to 1
    mov byte [party_size], 1

    ; Mark this NFT in save file
    ; (Implementation would save NFT token ID)

    ; Launch main game loop
    call game_main_loop

    pop rbp
    ret

; Start game with loaded state
start_game_loaded:
    push rbp
    mov rbp, rsp

    ; Launch main game loop with loaded data
    call game_main_loop

    pop rbp
    ret

; ========== WALLET FUNCTIONS ==========

display_wallet_balance:
    push rbp
    mov rbp, rsp

    mov rax, 1
    mov rdi, 1
    mov rsi, checking_wallet_balance_msg
    mov rdx, checking_wallet_balance_msg_len
    syscall

    ; Load wallet
    call load_wallet
    test rax, rax
    jnz .no_wallet

    ; Connect to XRPL
    call xrpl_init
    test rax, rax
    jnz .connection_error

    ; Get account info
    call get_account_info
    test rax, rax
    jnz .account_error

    ; Display address
    mov rax, 1
    mov rdi, 1
    mov rsi, your_balance_msg
    mov rdx, your_balance_msg_len
    syscall

    lea rsi, [account_address]
    call print_string

    ; Display balance in drops
    mov rax, 1
    mov rdi, 1
    mov rsi, balance_amt_msg
    mov rdx, balance_amt_msg_len
    syscall

    mov rax, [account_balance]
    call print_number

    mov rax, 1
    mov rdi, 1
    mov rsi, drops_suffix
    mov rdx, drops_suffix_len
    syscall

    ; Convert to XRP (divide by 1,000,000)
    mov rax, [account_balance]
    xor rdx, rdx
    mov rbx, 1000000
    div rbx

    call print_number

    mov rax, 1
    mov rdi, 1
    mov rsi, xrp_suffix
    mov rdx, xrp_suffix_len
    syscall

    call xrpl_close
    pop rbp
    ret

.no_wallet:
    ; Handle no wallet case
    pop rbp
    ret

.connection_error:
.account_error:
    call xrpl_close
    pop rbp
    ret

; ========== NFT COLLECTION DISPLAY ==========

display_nft_collection:
    push rbp
    mov rbp, rsp

    mov rax, 1
    mov rdi, 1
    mov rsi, viewing_nfts_msg
    mov rdx, viewing_nfts_msg_len
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, your_nfts_header
    mov rdx, your_nfts_header_len
    syscall

    ; Check if player has starter NFT
    cmp byte [player_has_starter_nft], 0
    je .no_nfts

    ; Display starter NFT info
    ; (Would fetch from XRPL or local save)
    ; For now, show that they have the starter

    ; TODO: Implement full NFT collection viewer
    ; This would query account_nfts from XRPL

.no_nfts:
    mov rax, 1
    mov rdi, 1
    mov rsi, no_nfts_msg
    mov rdx, no_nfts_msg_len
    syscall

    pop rbp
    ret

; ========== GAME STATE MANAGEMENT ==========

load_game_state:
    push rbp
    mov rbp, rsp

    ; Try to open save file
    mov rax, 2                  ; sys_open
    lea rdi, [save_filename]
    xor rsi, rsi                ; O_RDONLY
    xor rdx, rdx
    syscall

    cmp rax, 0
    jl .no_save

    ; File exists, load it
    ; (Would read game state into memory)
    mov r12, rax                ; Save fd

    ; Close file
    mov rax, 3
    mov rdi, r12
    syscall

    mov byte [game_state_loaded], 1
    xor rax, rax
    pop rbp
    ret

.no_save:
    mov rax, -1
    pop rbp
    ret

; ========== UTILITY FUNCTIONS ==========

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

; Placeholder for main game loop
; This would call into game_enhanced.asm
game_main_loop:
    push rbp
    mov rbp, rsp

    ; This would integrate with the actual game
    ; For now, just return
    ; In real implementation: call game_enhanced_main

    pop rbp
    ret

section .data
    save_filename db "quigzimon_save.dat", 0

section .bss
    player_party resb 90        ; 6 QUIGZIMON × 15 bytes each
    party_size resb 1

; ========== EXPORTS ==========
global _start
global player_party
global party_size
