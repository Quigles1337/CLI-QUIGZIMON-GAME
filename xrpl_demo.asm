; QUIGZIMON × XRPL Demo - Working Example Without Crypto
; This version demonstrates XRPL integration using read-only operations
; Can view NFTs, browse marketplace, check balances - no signing needed!

section .data
    demo_title db 0xA, "=== QUIGZIMON × XRPL DEMO ===", 0xA
               db "Connecting to XRP Ledger Testnet...", 0xA, 0xA, 0
    demo_title_len equ $ - demo_title

    demo_menu db 0xA, "XRPL Demo Menu:", 0xA
              db "1) Check Your XRP Balance", 0xA
              db "2) View Your QUIGZIMON NFTs", 0xA
              db "3) Browse Marketplace", 0xA
              db "4) View NFT Metadata", 0xA
              db "5) Simulate NFT Minting (offline)", 0xA
              db "6) Back to Game", 0xA
              db "> ", 0
    demo_menu_len equ $ - demo_menu

    demo_wallet_prompt db "Enter your XRPL testnet address (or press Enter for demo): ", 0
    demo_wallet_prompt_len equ $ - demo_wallet_prompt

    demo_address db "rN7n7otQDd6FczFgLdlqtyMVrn3LNU8KGH", 0  ; Example testnet address

    demo_balance_result db "XRP Balance: ", 0
    demo_balance_result_len equ $ - demo_balance_result

    demo_nfts_header db 0xA, "Your QUIGZIMON NFTs:", 0xA
                     db "====================", 0xA, 0
    demo_nfts_header_len equ $ - demo_nfts_header

    demo_no_nfts db "No NFTs found for this address.", 0xA, 0
    demo_no_nfts_len equ $ - demo_no_nfts

    demo_marketplace_header db 0xA, "QUIGZIMON Marketplace:", 0xA
                            db "=====================", 0xA, 0
    demo_marketplace_header_len equ $ - demo_marketplace_header

    demo_metadata_header db 0xA, "NFT Metadata Preview:", 0xA, 0
    demo_metadata_header_len equ $ - demo_metadata_header

    demo_simulate_mint db 0xA, "Simulating NFT Mint for your QUIGZIMON...", 0xA, 0
    demo_simulate_mint_len equ $ - demo_simulate_mint

    demo_mint_preview db "Generated Metadata:", 0xA, 0
    demo_mint_preview_len equ $ - demo_mint_preview

    demo_mint_tx_preview db 0xA, "Transaction Preview (not signed):", 0xA, 0
    demo_mint_tx_preview_len equ $ - demo_mint_tx_preview

    demo_note db 0xA, "Note: This is a demo. To actually mint/trade, you need:", 0xA
               db "  1. XRPL Testnet account with XRP", 0xA
               db "  2. Transaction signing (coming soon!)", 0xA, 0xA, 0
    demo_note_len equ $ - demo_note

section .bss
    demo_user_address resb 128
    demo_http_buffer resb 8192

section .text
    global xrpl_demo_menu

; Main XRPL demo menu
xrpl_demo_menu:
    push rbp
    mov rbp, rsp

    ; Display title
    mov rax, 1
    mov rdi, 1
    mov rsi, demo_title
    mov rdx, demo_title_len
    syscall

    ; Prompt for wallet address
    call get_demo_wallet_address

.menu_loop:
    ; Display menu
    mov rax, 1
    mov rdi, 1
    mov rsi, demo_menu
    mov rdx, demo_menu_len
    syscall

    ; Get input
    mov rax, 0
    mov rdi, 0
    mov rsi, input
    mov rdx, 2
    syscall

    mov al, byte [input]
    cmp al, '1'
    je .check_balance
    cmp al, '2'
    je .view_nfts
    cmp al, '3'
    je .browse_marketplace
    cmp al, '4'
    je .view_metadata
    cmp al, '5'
    je .simulate_mint
    cmp al, '6'
    je .back_to_game
    jmp .menu_loop

.check_balance:
    call demo_check_balance
    jmp .menu_loop

.view_nfts:
    call demo_view_nfts
    jmp .menu_loop

.browse_marketplace:
    call demo_browse_marketplace
    jmp .menu_loop

.view_metadata:
    call demo_view_nft_metadata
    jmp .menu_loop

.simulate_mint:
    call demo_simulate_minting
    jmp .menu_loop

.back_to_game:
    pop rbp
    ret

; Get wallet address from user
get_demo_wallet_address:
    push rbp
    mov rbp, rsp

    mov rax, 1
    mov rdi, 1
    mov rsi, demo_wallet_prompt
    mov rdx, demo_wallet_prompt_len
    syscall

    ; Read input
    mov rax, 0
    mov rdi, 0
    lea rsi, [demo_user_address]
    mov rdx, 128
    syscall

    ; Check if empty (use demo address)
    cmp byte [demo_user_address], 0xA
    je .use_demo

    ; Strip newline
    lea rdi, [demo_user_address]
.find_newline:
    mov al, byte [rdi]
    cmp al, 0xA
    je .found_newline
    cmp al, 0
    je .done
    inc rdi
    jmp .find_newline

.found_newline:
    mov byte [rdi], 0
    jmp .done

.use_demo:
    ; Copy demo address
    lea rdi, [demo_user_address]
    mov rsi, demo_address
    call strcpy

.done:
    pop rbp
    ret

; Demo: Check XRP balance
demo_check_balance:
    push rbp
    mov rbp, rsp

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_checking_balance
    mov rdx, msg_checking_balance_len
    syscall

    ; Initialize XRPL connection
    call xrpl_init
    cmp rax, 0
    jl .error

    ; Get account info
    lea rsi, [demo_user_address]
    mov [player_wallet.address], rsi
    call xrpl_get_account_info
    cmp rax, 0
    jl .error

    ; Display balance
    call xrpl_display_balance

    ; Close connection
    call xrpl_close

    pop rbp
    ret

.error:
    ; Display error message
    pop rbp
    ret

; Demo: View NFTs owned by address
demo_view_nfts:
    push rbp
    mov rbp, rsp

    ; Display header
    mov rax, 1
    mov rdi, 1
    mov rsi, demo_nfts_header
    mov rdx, demo_nfts_header_len
    syscall

    ; Initialize connection
    call xrpl_init
    cmp rax, 0
    jl .error

    ; Build account_nfts request
    lea rsi, [demo_user_address]
    call build_account_nfts_json
    mov rdx, rax

    ; Send request
    lea rsi, [json_body]
    call send_http_post

    ; Receive response
    call receive_http_response

    ; Parse and display NFTs
    call parse_and_display_nfts

    ; Close connection
    call xrpl_close

    pop rbp
    ret

.error:
    mov rax, 1
    mov rdi, 1
    mov rsi, demo_no_nfts
    mov rdx, demo_no_nfts_len
    syscall
    pop rbp
    ret

; Parse and display NFTs from response
parse_and_display_nfts:
    push rbp
    mov rbp, rsp
    push r12

    ; Find account_nfts array
    lea rdi, [http_response]
    mov rsi, json_key_nfts
    call find_json_value

    cmp rax, 0
    je .no_nfts

    mov r12, rax    ; Save position

    ; Count NFTs (simplified - just look for NFTokenID occurrences)
    xor rbx, rbx    ; Counter

.count_loop:
    mov rdi, r12
    mov rsi, json_key_token_id
    call find_json_value
    cmp rax, 0
    je .done_counting

    inc rbx
    mov r12, rax
    add r12, 64     ; Move past this token
    jmp .count_loop

.done_counting:
    ; Display count
    mov rax, rbx
    call print_number

    ; Display " QUIGZIMON NFTs found"
    ; ... (add message)

    pop r12
    pop rbp
    ret

.no_nfts:
    mov rax, 1
    mov rdi, 1
    mov rsi, demo_no_nfts
    mov rdx, demo_no_nfts_len
    syscall

    pop r12
    pop rbp
    ret

; Demo: Browse marketplace listings
demo_browse_marketplace:
    push rbp
    mov rbp, rsp

    ; Display header
    mov rax, 1
    mov rdi, 1
    mov rsi, demo_marketplace_header
    mov rdx, demo_marketplace_header_len
    syscall

    ; TODO: Query XRPL for all NFTokenCreateOffer transactions
    ; Filter for QUIGZIMON-related NFTs
    ; Display with prices

    ; For now, show placeholder
    mov rax, 1
    mov rdi, 1
    mov rsi, demo_note
    mov rdx, demo_note_len
    syscall

    pop rbp
    ret

; Demo: View NFT metadata
demo_view_nft_metadata:
    push rbp
    mov rbp, rsp

    ; Display header
    mov rax, 1
    mov rdi, 1
    mov rsi, demo_metadata_header
    mov rdx, demo_metadata_header_len
    syscall

    ; Use first QUIGZIMON in party as example
    lea rdi, [player_party]
    call generate_nft_metadata

    ; Display the generated metadata
    mov rax, 1
    mov rdi, 1
    lea rsi, [nft_metadata_json]
    mov rdx, [nft_metadata_len]
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    pop rbp
    ret

; Demo: Simulate minting (no signing)
demo_simulate_minting:
    push rbp
    mov rbp, rsp

    ; Display message
    mov rax, 1
    mov rdi, 1
    mov rsi, demo_simulate_mint
    mov rdx, demo_simulate_mint_len
    syscall

    ; Generate metadata for first party member
    lea rdi, [player_party]
    call generate_nft_metadata

    ; Show metadata
    mov rax, 1
    mov rdi, 1
    mov rsi, demo_mint_preview
    mov rdx, demo_mint_preview_len
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [nft_metadata_json]
    mov rdx, [nft_metadata_len]
    syscall

    ; Build transaction (unsigned)
    call create_nft_mint_transaction

    ; Show transaction
    mov rax, 1
    mov rdi, 1
    mov rsi, demo_mint_tx_preview
    mov rdx, demo_mint_tx_preview_len
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [nft_mint_tx_json]
    mov rdx, 1024   ; Approximate length
    syscall

    ; Show note
    mov rax, 1
    mov rdi, 1
    mov rsi, demo_note
    mov rdx, demo_note_len
    syscall

    pop rbp
    ret

; ========== HELPER FUNCTIONS ==========

; Copy string
strcpy:
    push rax
.loop:
    lodsb
    stosb
    test al, al
    jnz .loop
    pop rax
    ret
