; QUIGZIMON XRPL NFT Minting - Complete Implementation
; This ties together serialization, signing, and HTTP submission

section .data
    ; ========== XRPL Testnet Configuration ==========
    xrpl_testnet_host db "s.altnet.rippletest.net", 0
    xrpl_testnet_port equ 80

    ; ========== JSON-RPC Templates ==========
    submit_template_start db '{"method":"submit","params":[{"tx_blob":"', 0
    submit_template_end db '"}]}', 0

    account_info_template db '{"method":"account_info","params":[{"account":"', 0
    account_info_end db '","ledger_index":"validated"}]}', 0

    ; ========== Messages ==========
    msg_connecting db "Connecting to XRPL testnet...", 0xA, 0
    msg_connecting_len equ $ - msg_connecting

    msg_checking_account db "Checking account info...", 0xA, 0
    msg_checking_account_len equ $ - msg_checking_account

    msg_preparing_tx db "Preparing NFT mint transaction...", 0xA, 0
    msg_preparing_tx_len equ $ - msg_preparing_tx

    msg_submitting db "Submitting to XRPL...", 0xA, 0
    msg_submitting_len equ $ - msg_submitting

    msg_success db "SUCCESS! NFT minted on XRPL!", 0xA, 0
    msg_success_len equ $ - msg_success

    msg_tx_hash db "Transaction hash: ", 0
    msg_tx_hash_len equ $ - msg_tx_hash

    msg_error db "ERROR: Transaction failed", 0xA, 0
    msg_error_len equ $ - msg_error

    msg_needs_funding db "ERROR: Account not funded. Get testnet XRP from faucet!", 0xA, 0
    msg_needs_funding_len equ $ - msg_needs_funding

    faucet_url db "https://xrpl.org/xrp-testnet-faucet.html", 0xA, 0
    faucet_url_len equ $ - faucet_url

section .bss
    ; Account state
    account_address resb 64
    account_sequence resq 1
    account_balance resq 1
    account_public_key resb 33
    account_private_key resb 64

    ; Transaction parameters
    nft_mint_params:
        .flags resd 1
        .sequence resd 1
        .transfer_fee resd 1
        .fee resq 1
        .public_key resb 33
        .uri resb 512
        .account_id resb 20

    ; Response parsing
    response_buffer resb 8192
    tx_hash_result resb 128
    nft_token_id_result resb 128

section .text

; ========== MAIN NFT MINTING WORKFLOW ==========

; Mint QUIGZIMON as NFT on XRPL
; Input: rdi = pointer to QUIGZIMON struct
;        rsi = pointer to IPFS URI (null-terminated)
; Output: rax = 0 on success, -1 on error
mint_quigzimon_to_xrpl:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi                    ; QUIGZIMON pointer
    mov r13, rsi                    ; IPFS URI

    ; Step 1: Initialize crypto
    call crypto_bridge_init
    test rax, rax
    jnz .error

    ; Step 2: Load or generate wallet
    call load_wallet
    test rax, rax
    jnz .create_wallet

.wallet_loaded:
    ; Step 3: Connect to XRPL
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_connecting
    mov rdx, msg_connecting_len
    syscall

    call xrpl_init
    test rax, rax
    jnz .error

    ; Step 4: Get account info (sequence number, balance)
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_checking_account
    mov rdx, msg_checking_account_len
    syscall

    call get_account_info
    test rax, rax
    jnz .account_not_found

    ; Check balance
    mov rax, [account_balance]
    cmp rax, 1000000                ; Need at least 1 XRP
    jl .insufficient_funds

    ; Step 5: Prepare NFT metadata URI (hex-encoded)
    mov rdi, r13
    call hex_encode_uri
    lea r14, [hex_uri_buffer]

    ; Step 6: Build transaction parameters
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_preparing_tx
    mov rdx, msg_preparing_tx_len
    syscall

    call build_nft_mint_params

    ; Step 7: Serialize transaction
    lea rdi, [nft_mint_params]
    call serialize_nftoken_mint

    ; Step 8: Sign transaction
    call sign_transaction

    ; Step 9: Submit to XRPL
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_submitting
    mov rdx, msg_submitting_len
    syscall

    call submit_signed_transaction
    test rax, rax
    jnz .submission_error

    ; Step 10: Parse response for transaction hash
    call extract_transaction_hash

    ; Step 11: Display success
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_success
    mov rdx, msg_success_len
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_tx_hash
    mov rdx, msg_tx_hash_len
    syscall

    lea rsi, [tx_hash_result]
    call print_string

    ; Newline
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    ; Step 12: Save NFT token ID to QUIGZIMON data (if needed)
    ; This would update the save file with the NFT association

    ; Cleanup
    call xrpl_close

    xor rax, rax
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

.create_wallet:
    ; Generate new wallet for first-time users
    call generate_new_wallet
    test rax, rax
    jnz .error

    ; Display address and ask user to fund it
    call display_funding_instructions
    jmp .wallet_loaded

.account_not_found:
    call display_funding_instructions
    jmp .error

.insufficient_funds:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_needs_funding
    mov rdx, msg_needs_funding_len
    syscall
    jmp .error

.submission_error:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_error
    mov rdx, msg_error_len
    syscall
    ; Fall through to error

.error:
    call xrpl_close
    mov rax, -1
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

; ========== WALLET MANAGEMENT ==========

; Load wallet from file
; Output: rax = 0 if loaded, -1 if not found
load_wallet:
    push rbp
    mov rbp, rsp

    ; Open wallet file
    mov rax, 2                      ; sys_open
    lea rdi, [wallet_filename]
    mov rsi, 0                      ; O_RDONLY
    xor rdx, rdx
    syscall

    cmp rax, 0
    jl .not_found

    mov r12, rax                    ; Save fd

    ; Read seed
    mov rax, 0                      ; sys_read
    mov rdi, r12
    lea rsi, [wallet_seed]
    mov rdx, 32
    syscall

    ; Close file
    mov rax, 3                      ; sys_close
    mov rdi, r12
    syscall

    ; Generate keypair from seed
    lea rsi, [wallet_seed]
    call crypto_generate_keypair

    ; Compute address
    call compute_account_address

    xor rax, rax
    pop rbp
    ret

.not_found:
    mov rax, -1
    pop rbp
    ret

; Generate new wallet
; Output: rax = 0 on success
generate_new_wallet:
    push rbp
    mov rbp, rsp

    ; Generate random seed (32 bytes)
    mov rax, 318                    ; sys_getrandom
    lea rdi, [wallet_seed]
    mov rsi, 32
    xor rdx, rdx
    syscall

    ; Generate keypair
    lea rsi, [wallet_seed]
    call crypto_generate_keypair

    ; Compute address
    call compute_account_address

    ; Save wallet to file
    mov rax, 2                      ; sys_open
    lea rdi, [wallet_filename]
    mov rsi, 0x41                   ; O_WRONLY | O_CREAT
    mov rdx, 0600                   ; -rw-------
    syscall

    mov r12, rax

    ; Write seed
    mov rax, 1                      ; sys_write
    mov rdi, r12
    lea rsi, [wallet_seed]
    mov rdx, 32
    syscall

    ; Close
    mov rax, 3
    mov rdi, r12
    syscall

    xor rax, rax
    pop rbp
    ret

; Compute XRPL account address from public key
compute_account_address:
    push rbp
    mov rbp, rsp

    ; Hash public key with SHA-256
    lea rsi, [wallet_public_key]
    mov rdx, 33
    lea rdi, [temp_buffer]
    call crypto_sha256

    ; Hash again with RIPEMD-160 (for now, use first 20 bytes of SHA-256)
    ; NOTE: Proper implementation would use RIPEMD-160
    lea rsi, [temp_buffer]
    mov rdx, 32
    lea rdi, [temp_buffer2]
    call crypto_sha256

    ; Take first 20 bytes as account ID
    lea rsi, [temp_buffer2]
    lea rdi, [nft_mint_params.account_id]
    mov rcx, 20
    rep movsb

    ; Encode as classic address (rXXX...)
    lea rsi, [nft_mint_params.account_id]
    lea rdi, [account_address]
    call xrpl_encode_address

    pop rbp
    ret

; Display funding instructions
display_funding_instructions:
    push rbp
    mov rbp, rsp

    ; Print "Your address: "
    mov rax, 1
    mov rdi, 1
    lea rsi, [msg_your_address]
    mov rdx, msg_your_address_len
    syscall

    ; Print address
    lea rsi, [account_address]
    call print_string

    ; Newline
    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    ; Print faucet URL
    mov rax, 1
    mov rdi, 1
    lea rsi, [msg_fund_account]
    mov rdx, msg_fund_account_len
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [faucet_url]
    mov rdx, faucet_url_len
    syscall

    pop rbp
    ret

section .data
    msg_your_address db "Your XRPL address: ", 0
    msg_your_address_len equ $ - msg_your_address

    msg_fund_account db "Fund your account at: ", 0
    msg_fund_account_len equ $ - msg_fund_account

    wallet_filename db "quigzimon_wallet.dat", 0
    wallet_seed resb 32

section .bss
    temp_buffer resb 256
    temp_buffer2 resb 256

section .text

; ========== ACCOUNT INFO ==========

; Get account sequence and balance from XRPL
get_account_info:
    push rbp
    mov rbp, rsp

    ; Build account_info request
    lea rdi, [json_body]
    mov rsi, account_info_template
    call strcpy

    lea rsi, [account_address]
    call strcat

    mov rsi, account_info_end
    call strcat

    ; Send request
    lea rsi, [json_body]
    call send_http_post

    ; Receive response
    call receive_http_response

    ; Parse for sequence
    lea rdi, [http_response]
    mov rsi, json_key_sequence
    call find_json_value

    test rax, rax
    jz .error

    call parse_number
    mov [account_sequence], rax

    ; Parse for balance
    lea rdi, [http_response]
    mov rsi, json_key_balance
    call find_json_value

    test rax, rax
    jz .error

    call parse_number
    mov [account_balance], rax

    xor rax, rax
    pop rbp
    ret

.error:
    mov rax, -1
    pop rbp
    ret

section .data
    json_key_sequence db '"Sequence":', 0
    json_key_balance db '"Balance":', 0
    json_key_hash db '"hash":', 0
    json_key_nftoken db '"NFTokenID":', 0

section .bss
    json_body resb 4096
    http_response resb 8192

section .text

; ========== TRANSACTION BUILDING ==========

; Build NFT mint parameters
build_nft_mint_params:
    push rbp
    mov rbp, rsp

    ; Flags (8 = Transferable)
    mov dword [nft_mint_params.flags], 8

    ; Sequence
    mov eax, [account_sequence]
    mov [nft_mint_params.sequence], eax

    ; Transfer fee (0 = no transfer fee)
    mov dword [nft_mint_params.transfer_fee], 0

    ; Fee (12 drops = 0.000012 XRP)
    mov qword [nft_mint_params.fee], 12

    ; Public key (33 bytes)
    lea rsi, [wallet_public_key]
    lea rdi, [nft_mint_params.public_key]
    mov rcx, 33
    rep movsb

    ; URI (already hex-encoded in r14)
    mov rsi, r14
    lea rdi, [nft_mint_params.uri]
    call strcpy

    ; Account ID (20 bytes) - already filled

    pop rbp
    ret

; ========== SUBMISSION ==========

; Submit signed transaction to XRPL
submit_signed_transaction:
    push rbp
    mov rbp, rsp

    ; Build submit request
    lea rdi, [json_body]
    mov rsi, submit_template_start
    call strcpy

    lea rsi, [signed_tx_blob]
    call strcat

    mov rsi, submit_template_end
    call strcat

    ; Send request
    lea rsi, [json_body]
    call send_http_post

    ; Receive response
    lea rdi, [response_buffer]
    call receive_http_response

    ; Check for "tesSUCCESS" in response
    lea rdi, [response_buffer]
    mov rsi, success_marker
    call strstr

    test rax, rax
    jz .error

    xor rax, rax
    pop rbp
    ret

.error:
    mov rax, -1
    pop rbp
    ret

section .data
    success_marker db '"tesSUCCESS"', 0

section .text

; Extract transaction hash from response
extract_transaction_hash:
    push rbp
    mov rbp, rsp

    lea rdi, [response_buffer]
    mov rsi, json_key_hash
    call find_json_value

    test rax, rax
    jz .error

    ; Extract quoted value
    mov rdi, rax
    call extract_quoted_value

    ; Copy to result buffer
    lea rdi, [tx_hash_result]
    mov rcx, rax
    rep movsb

    xor rax, rax
    pop rbp
    ret

.error:
    mov rax, -1
    pop rbp
    ret

; ========== UTILITY FUNCTIONS ==========

; Hex-encode URI for XRPL
hex_encode_uri:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov r12, rdi                    ; URI pointer
    lea r13, [hex_uri_buffer]

    xor r14, r14                    ; Position

.loop:
    movzx rax, byte [r12 + r14]
    test al, al
    jz .done

    ; Convert to hex
    mov rbx, rax
    shr rbx, 4
    and rbx, 0x0F

    cmp rbx, 10
    jl .high_digit
    add rbx, 'A' - 10
    jmp .high_store

.high_digit:
    add rbx, '0'

.high_store:
    mov [r13], bl
    inc r13

    ; Low nibble
    mov rbx, rax
    and rbx, 0x0F

    cmp rbx, 10
    jl .low_digit
    add rbx, 'A' - 10
    jmp .low_store

.low_digit:
    add rbx, '0'

.low_store:
    mov [r13], bl
    inc r13

    inc r14
    jmp .loop

.done:
    mov byte [r13], 0

    pop r13
    pop r12
    pop rbp
    ret

section .bss
    hex_uri_buffer resb 1024
    newline db 0xA

; String functions
strcpy:
    push rax
.loop:
    lodsb
    stosb
    test al, al
    jnz .loop
    dec rdi
    pop rax
    ret

strcat:
    push rax
    push rdi
.find_end:
    cmp byte [rdi], 0
    je .found_end
    inc rdi
    jmp .find_end
.found_end:
.copy:
    lodsb
    stosb
    test al, al
    jnz .copy
    pop rdi
    pop rax
    ret

; Find substring
strstr:
    push rbx
    push rcx
    push rdx

    mov rbx, rdi                    ; Haystack
    mov rcx, rsi                    ; Needle

.outer:
    mov al, [rbx]
    test al, al
    jz .not_found

    mov rdx, rcx
    mov rdi, rbx

.inner:
    mov al, [rdi]
    mov ah, [rdx]

    test ah, ah
    jz .found

    cmp al, ah
    jne .next_outer

    inc rdi
    inc rdx
    jmp .inner

.next_outer:
    inc rbx
    jmp .outer

.found:
    mov rax, rbx
    pop rdx
    pop rcx
    pop rbx
    ret

.not_found:
    xor rax, rax
    pop rdx
    pop rcx
    pop rbx
    ret

; Simple number parser (decimal)
parse_number:
    push rbx
    push rcx

    mov rdi, rax
    xor rax, rax
    xor rbx, rbx

.loop:
    movzx rcx, byte [rdi]
    cmp rcx, '0'
    jl .done
    cmp rcx, '9'
    jg .done

    imul rax, 10
    sub rcx, '0'
    add rax, rcx

    inc rdi
    jmp .loop

.done:
    pop rcx
    pop rbx
    ret

; Print string to stdout
print_string:
    push rax
    push rdi
    push rdx
    push rsi

    mov rdi, rsi
    call strlen
    mov rdx, rax

    mov rax, 1
    mov rdi, 1
    syscall

    pop rsi
    pop rdx
    pop rdi
    pop rax
    ret

; ========== EXTERNAL DEPENDENCIES ==========
extern crypto_bridge_init
extern crypto_generate_keypair
extern crypto_sha256
extern crypto_sign_transaction
extern xrpl_init
extern xrpl_close
extern send_http_post
extern receive_http_response
extern find_json_value
extern extract_quoted_value
extern serialize_nftoken_mint
extern sign_transaction
extern signed_tx_blob
extern transaction_signature
extern wallet_public_key
extern wallet_private_key
extern xrpl_encode_address
extern strlen

; ========== EXPORTS ==========
global mint_quigzimon_to_xrpl
global load_wallet
global generate_new_wallet
global get_account_info
