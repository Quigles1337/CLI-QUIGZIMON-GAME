; QUIGZIMON XRPL Crypto Bridge
; Assembly interface to C crypto functions
; This bridges pure assembly with libsodium via C wrapper

section .data
    crypto_init_msg db "Initializing cryptography...", 0xA, 0
    crypto_init_msg_len equ $ - crypto_init_msg

    crypto_ready_msg db "Crypto ready!", 0xA, 0
    crypto_ready_msg_len equ $ - crypto_ready_msg

    crypto_error_msg db "ERROR: Crypto initialization failed!", 0xA, 0
    crypto_error_msg_len equ $ - crypto_error_msg

section .bss
    ; Crypto state
    crypto_initialized resb 1

    ; Key storage
    wallet_seed resb 32
    wallet_public_key resb 32
    wallet_private_key resb 64

    ; Signature storage
    transaction_hash resb 32
    transaction_signature resb 64

    ; Hex conversion buffers
    hex_buffer resb 256

section .text

; External C functions from crypto wrapper
extern crypto_init
extern ed25519_keypair_from_seed
extern ed25519_sign_message
extern ed25519_verify_signature
extern sha512_hash_data
extern sha512_half_hash
extern sha256_hash_data
extern binary_to_hex
extern hex_to_binary
extern crypto_test

; ========== INITIALIZATION ==========

; Initialize crypto subsystem
; Returns: rax = 0 on success, -1 on error
crypto_bridge_init:
    push rbp
    mov rbp, rsp

    ; Display message
    mov rax, 1
    mov rdi, 1
    mov rsi, crypto_init_msg
    mov rdx, crypto_init_msg_len
    syscall

    ; Call C initialization
    ; Windows x64 calling convention: rcx, rdx, r8, r9, then stack
    ; Linux x64: rdi, rsi, rdx, rcx, r8, r9

    sub rsp, 32     ; Shadow space (Windows requirement)
    call crypto_init
    add rsp, 32

    ; Check result
    cmp rax, 0
    jl .error

    ; Mark as initialized
    mov byte [crypto_initialized], 1

    ; Display success
    mov rax, 1
    mov rdi, 1
    mov rsi, crypto_ready_msg
    mov rdx, crypto_ready_msg_len
    syscall

    xor rax, rax
    pop rbp
    ret

.error:
    mov rax, 1
    mov rdi, 1
    mov rsi, crypto_error_msg
    mov rdx, crypto_error_msg_len
    syscall

    mov rax, -1
    pop rbp
    ret

; ========== KEY MANAGEMENT ==========

; Generate XRPL wallet keypair from seed
; Input: rsi = pointer to 32-byte seed
; Output: wallet_public_key and wallet_private_key filled
; Returns: rax = 0 on success
crypto_generate_keypair:
    push rbp
    mov rbp, rsp
    push rbx

    ; Save seed pointer
    mov rbx, rsi

    ; Copy seed to storage
    lea rdi, [wallet_seed]
    mov rcx, 32
    rep movsb

    ; Call C function: ed25519_keypair_from_seed(seed, public_key, private_key)
    ; Windows: rcx=seed, rdx=public, r8=private
    ; Linux: rdi=seed, rsi=public, rdx=private

    sub rsp, 32     ; Shadow space

    ; Setup parameters (Windows x64)
    lea rcx, [wallet_seed]
    lea rdx, [wallet_public_key]
    lea r8, [wallet_private_key]

    call ed25519_keypair_from_seed

    add rsp, 32

    pop rbx
    pop rbp
    ret

; ========== SIGNING ==========

; Sign transaction with Ed25519
; Input: rsi = transaction data, rdx = length
; Output: transaction_signature contains 64-byte signature
; Returns: rax = 0 on success
crypto_sign_transaction:
    push rbp
    mov rbp, rsp
    push rbx
    push r12

    mov rbx, rsi    ; Save message pointer
    mov r12, rdx    ; Save length

    ; First, hash the transaction with SHA-512Half
    sub rsp, 32

    ; Parameters: (message, length, hash_output)
    mov rcx, rbx
    mov rdx, r12
    lea r8, [transaction_hash]

    call sha512_half_hash

    add rsp, 32

    ; Now sign the hash
    sub rsp, 32

    ; Parameters: ed25519_sign_message(message, len, private_key, signature)
    lea rcx, [transaction_hash]
    mov rdx, 32     ; Hash is always 32 bytes
    lea r8, [wallet_private_key]
    lea r9, [transaction_signature]

    call ed25519_sign_message

    add rsp, 32

    pop r12
    pop rbx
    pop rbp
    ret

; ========== VERIFICATION ==========

; Verify transaction signature
; Input: rsi = message, rdx = length, r8 = signature, r9 = public key
; Returns: rax = 0 if valid, -1 if invalid
crypto_verify_signature:
    push rbp
    mov rbp, rsp

    sub rsp, 32

    ; Parameters: (message, length, signature, public_key)
    mov rcx, rsi
    ; rdx already has length
    mov r8, r8      ; signature
    mov r9, r9      ; public_key

    call ed25519_verify_signature

    add rsp, 32

    pop rbp
    ret

; ========== HASHING ==========

; Compute SHA-512 hash
; Input: rsi = data, rdx = length, rdi = output buffer
; Returns: rax = 0
crypto_sha512:
    push rbp
    mov rbp, rsp
    push r12

    mov r12, rdi    ; Save output buffer

    sub rsp, 32

    ; Parameters: (message, length, hash)
    mov rcx, rsi
    ; rdx already has length
    mov r8, r12

    call sha512_hash_data

    add rsp, 32

    pop r12
    pop rbp
    ret

; Compute SHA-512Half (XRPL specific)
; Input: rsi = data, rdx = length, rdi = output buffer (32 bytes)
; Returns: rax = 0
crypto_sha512_half:
    push rbp
    mov rbp, rsp
    push r12

    mov r12, rdi

    sub rsp, 32

    mov rcx, rsi
    ; rdx already set
    mov r8, r12

    call sha512_half_hash

    add rsp, 32

    pop r12
    pop rbp
    ret

; Compute SHA-256 hash
; Input: rsi = data, rdx = length, rdi = output buffer
; Returns: rax = 0
crypto_sha256:
    push rbp
    mov rbp, rsp
    push r12

    mov r12, rdi

    sub rsp, 32

    mov rcx, rsi
    mov r8, r12

    call sha256_hash_data

    add rsp, 32

    pop r12
    pop rbp
    ret

; ========== ENCODING ==========

; Convert binary to hex string
; Input: rsi = binary data, rdx = length, rdi = hex output buffer
crypto_bin_to_hex:
    push rbp
    mov rbp, rsp
    push r12

    mov r12, rdi

    sub rsp, 32

    ; Parameters: (data, length, hex_output)
    mov rcx, rsi
    ; rdx already set
    mov r8, r12

    call binary_to_hex

    add rsp, 32

    pop r12
    pop rbp
    ret

; Convert hex string to binary
; Input: rsi = hex string, rdi = binary output buffer
; Returns: rax = number of bytes written
crypto_hex_to_bin:
    push rbp
    mov rbp, rsp
    push r12

    mov r12, rdi

    sub rsp, 32

    ; Parameters: (hex_string, binary_output)
    mov rcx, rsi
    mov rdx, r12

    call hex_to_binary

    add rsp, 32

    pop r12
    pop rbp
    ret

; ========== HIGH-LEVEL OPERATIONS ==========

; Complete transaction signing workflow
; Input: rsi = transaction JSON, rdx = length
; Output: hex_buffer contains hex-encoded signed blob
; Returns: rax = length of hex string
sign_xrpl_transaction:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov r12, rsi
    mov r13, rdx

    ; 1. Serialize transaction to binary (canonical form)
    ; For now, assume transaction is already in binary form
    ; Full implementation would parse JSON and serialize

    ; 2. Hash with SHA-512Half
    mov rsi, r12
    mov rdx, r13
    lea rdi, [transaction_hash]
    call crypto_sha512_half

    ; 3. Sign the hash
    lea rsi, [transaction_hash]
    mov rdx, 32
    call crypto_sign_transaction

    ; 4. Construct signed blob (serialized tx + signature)
    ; This would combine the transaction fields with signature

    ; 5. Convert to hex
    lea rsi, [transaction_signature]
    mov rdx, 64
    lea rdi, [hex_buffer]
    call crypto_bin_to_hex

    ; Return hex length (64 bytes * 2 = 128 chars)
    mov rax, 128

    pop r13
    pop r12
    pop rbp
    ret

; ========== TESTING ==========

; Run crypto tests
test_crypto:
    push rbp
    mov rbp, rsp

    sub rsp, 32
    call crypto_test
    add rsp, 32

    pop rbp
    ret

; ========== EXPORTS ==========
global crypto_bridge_init
global crypto_generate_keypair
global crypto_sign_transaction
global crypto_verify_signature
global crypto_sha512
global crypto_sha512_half
global crypto_sha256
global crypto_bin_to_hex
global crypto_hex_to_bin
global sign_xrpl_transaction
global test_crypto

; ========== PUBLIC DATA ACCESS ==========
global wallet_public_key
global wallet_private_key
global transaction_signature
global hex_buffer
