; QUIGZIMON NFT Minting Test
; Standalone test program for NFT minting functionality

section .data
    test_banner db 0xA
                db "╔════════════════════════════════════════╗", 0xA
                db "║   QUIGZIMON NFT MINTING TEST          ║", 0xA
                db "║   XRPL Testnet Integration            ║", 0xA
                db "╚════════════════════════════════════════╝", 0xA, 0xA, 0
    test_banner_len equ $ - test_banner

    test_menu db "Select test:", 0xA
              db "1) Test Base58 encoding/decoding", 0xA
              db "2) Test transaction serialization", 0xA
              db "3) Test wallet generation", 0xA
              db "4) Test account info fetching", 0xA
              db "5) Test complete NFT minting (requires funded account)", 0xA
              db "6) Generate new wallet and display address", 0xA
              db "7) Check account balance", 0xA
              db "0) Exit", 0xA
              db "> ", 0
    test_menu_len equ $ - test_menu

    ; Test QUIGZIMON for minting
    test_quigzimon:
        db 0                        ; Species: QUIGFLAME
        db 15                       ; Level: 15
        dw 0                        ; Current HP (not used for NFT)
        dw 65                       ; Max HP
        dw 1200                     ; EXP
        db 0                        ; Status: Healthy
        dw 22                       ; Attack
        dw 16                       ; Defense
        dw 18                       ; Speed

    test_ipfs_uri db "ipfs://QmYourTestMetadataHash123456789", 0

    msg_test_passed db "[PASS] ", 0
    msg_test_passed_len equ $ - msg_test_passed

    msg_test_failed db "[FAIL] ", 0
    msg_test_failed_len equ $ - msg_test_failed

    msg_test_base58 db "Base58 encoding/decoding...", 0xA, 0
    msg_test_base58_len equ $ - msg_test_base58

    msg_test_serialization db "Transaction serialization...", 0xA, 0
    msg_test_serialization_len equ $ - msg_test_serialization

    msg_test_wallet db "Wallet generation...", 0xA, 0
    msg_test_wallet_len equ $ - msg_test_wallet

    msg_test_account db "Account info fetching...", 0xA, 0
    msg_test_account_len equ $ - msg_test_account

    msg_test_minting db "Complete NFT minting...", 0xA, 0
    msg_test_minting_len equ $ - msg_test_minting

    newline db 0xA, 0

section .bss
    input_buffer resb 16
    test_results resb 1

section .text
    global _start

_start:
    ; Initialize
    call crypto_bridge_init
    test rax, rax
    jnz .init_error

.main_loop:
    ; Clear screen (optional)
    ; call clear_screen

    ; Display banner
    mov rax, 1
    mov rdi, 1
    mov rsi, test_banner
    mov rdx, test_banner_len
    syscall

    ; Display menu
    mov rax, 1
    mov rdi, 1
    mov rsi, test_menu
    mov rdx, test_menu_len
    syscall

    ; Get user input
    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 16
    syscall

    ; Parse input
    movzx rax, byte [input_buffer]
    sub al, '0'

    cmp al, 0
    je .exit

    cmp al, 1
    je .test_base58

    cmp al, 2
    je .test_serialization

    cmp al, 3
    je .test_wallet

    cmp al, 4
    je .test_account_info

    cmp al, 5
    je .test_minting

    cmp al, 6
    je .generate_wallet

    cmp al, 7
    je .check_balance

    jmp .main_loop

.test_base58:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_test_base58
    mov rdx, msg_test_base58_len
    syscall

    call test_base58
    call display_test_result

    call wait_key
    jmp .main_loop

.test_serialization:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_test_serialization
    mov rdx, msg_test_serialization_len
    syscall

    call test_transaction_serialization
    call display_test_result

    call wait_key
    jmp .main_loop

.test_wallet:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_test_wallet
    mov rdx, msg_test_wallet_len
    syscall

    call load_wallet
    test rax, rax
    jnz .wallet_not_found

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_test_passed
    mov rdx, msg_test_passed_len
    syscall

    ; Display address
    mov rax, 1
    mov rdi, 1
    lea rsi, [msg_wallet_address]
    mov rdx, msg_wallet_address_len
    syscall

    lea rsi, [account_address]
    call print_string

    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    call wait_key
    jmp .main_loop

.wallet_not_found:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_test_failed
    mov rdx, msg_test_failed_len
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [msg_no_wallet]
    mov rdx, msg_no_wallet_len
    syscall

    call wait_key
    jmp .main_loop

.test_account_info:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_test_account
    mov rdx, msg_test_account_len
    syscall

    ; Load wallet first
    call load_wallet
    test rax, rax
    jnz .wallet_not_found

    ; Connect to XRPL
    call xrpl_init
    test rax, rax
    jnz .connection_failed

    ; Get account info
    call get_account_info
    test rax, rax
    jnz .account_info_failed

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_test_passed
    mov rdx, msg_test_passed_len
    syscall

    ; Display sequence and balance
    call display_account_info

    call xrpl_close
    call wait_key
    jmp .main_loop

.test_minting:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_test_minting
    mov rdx, msg_test_minting_len
    syscall

    ; Mint test QUIGZIMON
    lea rdi, [test_quigzimon]
    lea rsi, [test_ipfs_uri]
    call mint_quigzimon_to_xrpl

    test rax, rax
    jnz .minting_failed

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_test_passed
    mov rdx, msg_test_passed_len
    syscall

    call wait_key
    jmp .main_loop

.minting_failed:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_test_failed
    mov rdx, msg_test_failed_len
    syscall

    call wait_key
    jmp .main_loop

.generate_wallet:
    call generate_new_wallet
    test rax, rax
    jnz .wallet_gen_failed

    mov rax, 1
    mov rdi, 1
    lea rsi, [msg_wallet_generated]
    mov rdx, msg_wallet_generated_len
    syscall

    call display_funding_instructions

    call wait_key
    jmp .main_loop

.wallet_gen_failed:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_test_failed
    mov rdx, msg_test_failed_len
    syscall

    call wait_key
    jmp .main_loop

.check_balance:
    call load_wallet
    test rax, rax
    jnz .wallet_not_found

    call xrpl_init
    test rax, rax
    jnz .connection_failed

    call get_account_info
    test rax, rax
    jnz .account_info_failed

    call display_account_info
    call xrpl_close

    call wait_key
    jmp .main_loop

.connection_failed:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_test_failed
    mov rdx, msg_test_failed_len
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [msg_connection_error]
    mov rdx, msg_connection_error_len
    syscall

    call wait_key
    jmp .main_loop

.account_info_failed:
    call xrpl_close

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_test_failed
    mov rdx, msg_test_failed_len
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [msg_account_not_found]
    mov rdx, msg_account_not_found_len
    syscall

    call display_funding_instructions

    call wait_key
    jmp .main_loop

.init_error:
    mov rax, 1
    mov rdi, 1
    lea rsi, [msg_init_error]
    mov rdx, msg_init_error_len
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall

.exit:
    ; Exit program
    mov rax, 60
    xor rdi, rdi
    syscall

; ========== HELPER FUNCTIONS ==========

display_test_result:
    push rax
    push rdi
    push rsi
    push rdx

    cmp rax, 0
    jne .failed

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_test_passed
    mov rdx, msg_test_passed_len
    syscall

    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

.failed:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_test_failed
    mov rdx, msg_test_failed_len
    syscall

    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

display_account_info:
    push rax
    push rdi
    push rsi
    push rdx

    ; Display sequence
    mov rax, 1
    mov rdi, 1
    lea rsi, [msg_sequence]
    mov rdx, msg_sequence_len
    syscall

    mov rax, [account_sequence]
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    ; Display balance
    mov rax, 1
    mov rdi, 1
    lea rsi, [msg_balance]
    mov rdx, msg_balance_len
    syscall

    mov rax, [account_balance]
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [msg_drops]
    mov rdx, msg_drops_len
    syscall

    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

wait_key:
    push rax
    push rdi
    push rsi
    push rdx

    mov rax, 1
    mov rdi, 1
    lea rsi, [msg_press_key]
    mov rdx, msg_press_key_len
    syscall

    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 1
    syscall

    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

print_number:
    push rbx
    push rcx
    push rdx
    push rdi

    mov rbx, 10
    lea rdi, [number_buffer + 19]
    mov byte [rdi], 0
    dec rdi

.convert:
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rdi], dl
    dec rdi

    test rax, rax
    jnz .convert

    inc rdi
    mov rsi, rdi
    call print_string

    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret

print_string:
    push rax
    push rdi
    push rdx

    mov rdi, rsi
    call strlen
    mov rdx, rax

    mov rax, 1
    mov rdi, 1
    syscall

    pop rdx
    pop rdi
    pop rax
    ret

strlen:
    push rcx
    push rdi

    mov rdi, rsi
    xor rcx, rcx
    xor al, al
    not rcx
    repnz scasb
    not rcx
    dec rcx
    mov rax, rcx

    pop rdi
    pop rcx
    ret

; ========== TEST FUNCTIONS ==========

test_transaction_serialization:
    push rbp
    mov rbp, rsp

    ; Build test NFTokenMint transaction
    lea rdi, [test_mint_params]

    ; Set parameters
    mov dword [rdi + 0], 8          ; Flags: Transferable
    mov dword [rdi + 4], 1          ; Sequence: 1
    mov dword [rdi + 8], 0          ; TransferFee: 0
    mov qword [rdi + 12], 12        ; Fee: 12 drops

    ; Serialize
    call serialize_nftoken_mint

    ; Verify length is reasonable (> 100 bytes)
    cmp rax, 100
    jl .error

    ; Verify starts with correct transaction type field
    cmp byte [tx_buffer], 0x12
    jne .error

    xor rax, rax
    pop rbp
    ret

.error:
    mov rax, -1
    pop rbp
    ret

section .bss
    test_mint_params resb 512
    number_buffer resb 20
    account_address resb 64
    account_sequence resq 1
    account_balance resq 1

section .data
    msg_wallet_address db "Address: ", 0
    msg_wallet_address_len equ $ - msg_wallet_address

    msg_no_wallet db "No wallet found. Run option 6 to generate.", 0xA, 0
    msg_no_wallet_len equ $ - msg_no_wallet

    msg_sequence db "Sequence: ", 0
    msg_sequence_len equ $ - msg_sequence

    msg_balance db "Balance: ", 0
    msg_balance_len equ $ - msg_balance

    msg_drops db " drops (XRP)", 0xA, 0
    msg_drops_len equ $ - msg_drops

    msg_press_key db 0xA, "Press Enter to continue...", 0
    msg_press_key_len equ $ - msg_press_key

    msg_wallet_generated db "New wallet generated!", 0xA, 0
    msg_wallet_generated_len equ $ - msg_wallet_generated

    msg_connection_error db "Failed to connect to XRPL testnet.", 0xA, 0
    msg_connection_error_len equ $ - msg_connection_error

    msg_account_not_found db "Account not found or not funded.", 0xA, 0
    msg_account_not_found_len equ $ - msg_account_not_found

    msg_init_error db "Failed to initialize crypto system.", 0xA, 0
    msg_init_error_len equ $ - msg_init_error

; ========== EXTERNAL DEPENDENCIES ==========
extern crypto_bridge_init
extern test_base58
extern serialize_nftoken_mint
extern tx_buffer
extern load_wallet
extern generate_new_wallet
extern display_funding_instructions
extern xrpl_init
extern xrpl_close
extern get_account_info
extern mint_quigzimon_to_xrpl
