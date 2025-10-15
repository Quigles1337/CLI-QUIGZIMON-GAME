; QUIGZIMON XRPL Transaction Serialization
; Implementation of XRPL's canonical binary format
; Reference: https://xrpl.org/serialization.html

section .data
    ; ========== XRPL FIELD TYPE CODES ==========
    ; Format: (type << 4) | field_id
    ; If field_id >= 16, use two bytes

    ; Type 1: UInt16
    TYPE_UINT16 equ 1
    FIELD_LEDGER_SEQUENCE equ 0x21      ; Type 1, Field 2

    ; Type 2: UInt32
    TYPE_UINT32 equ 2
    FIELD_FLAGS equ 0x22                ; Type 2, Field 2
    FIELD_SEQUENCE equ 0x24             ; Type 2, Field 4
    FIELD_DEST_TAG equ 0x2E             ; Type 2, Field 14
    FIELD_TRANSFER_FEE equ 0x2A         ; Type 2, Field 10

    ; Type 6: Amount
    TYPE_AMOUNT equ 6
    FIELD_AMOUNT equ 0x61               ; Type 6, Field 1
    FIELD_FEE equ 0x68                  ; Type 6, Field 8

    ; Type 7: VL (Variable Length)
    TYPE_VL equ 7
    FIELD_SIGNING_PUB_KEY equ 0x73      ; Type 7, Field 3
    FIELD_TXN_SIGNATURE equ 0x74        ; Type 7, Field 4
    FIELD_URI equ 0x75                  ; Type 7, Field 5
    FIELD_MEMO_DATA equ 0x7D            ; Type 7, Field 13

    ; Type 8: Account
    TYPE_ACCOUNT equ 8
    FIELD_ACCOUNT equ 0x81              ; Type 8, Field 1
    FIELD_DESTINATION equ 0x83          ; Type 8, Field 3
    FIELD_ISSUER equ 0x8A               ; Type 8, Field 10

    ; Type 14: Object (start of nested object)
    TYPE_OBJECT equ 14
    FIELD_MEMO equ 0xEA                 ; Type 14, Field 10

    ; Type 15: Array
    TYPE_ARRAY equ 15
    FIELD_MEMOS equ 0xF9                ; Type 15, Field 9

    ; End markers
    FIELD_END_OBJECT equ 0xE1           ; Type 14, Field 1
    FIELD_END_ARRAY equ 0xF1            ; Type 15, Field 1

    ; Transaction types
    TXTYPE_PAYMENT equ 0
    TXTYPE_NFTOKEN_MINT equ 25
    TXTYPE_NFTOKEN_CREATE_OFFER equ 27
    TXTYPE_NFTOKEN_ACCEPT_OFFER equ 29

    ; ========== MESSAGES ==========
    msg_serializing db "Serializing transaction...", 0xA, 0
    msg_serializing_len equ $ - msg_serializing

    msg_serialization_complete db "Serialization complete!", 0xA, 0
    msg_serialization_complete_len equ $ - msg_serialization_complete

    msg_signing_tx db "Signing transaction...", 0xA, 0
    msg_signing_tx_len equ $ - msg_signing_tx

    msg_signing_complete db "Transaction signed!", 0xA, 0
    msg_signing_complete_len equ $ - msg_signing_complete

section .bss
    ; Serialization buffers
    tx_buffer resb 4096             ; Serialized transaction
    tx_length resq 1                ; Length of serialized data
    tx_type resw 1                  ; Transaction type

    ; Signing buffers
    tx_hash resb 32                 ; SHA-512Half of transaction
    tx_signature resb 64            ; Ed25519 signature
    signed_tx_blob resb 8192        ; Final signed transaction (hex)

    ; Temporary buffers
    temp_buffer resb 256
    temp_length resq 1

section .text

; ========== HIGH-LEVEL SERIALIZATION ==========

; Serialize NFTokenMint transaction
; Input: rdi = pointer to transaction parameters structure
; Output: rax = length of serialized data, tx_buffer contains binary
serialize_nftoken_mint:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi                    ; Save params pointer

    ; Display message
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_serializing
    mov rdx, msg_serializing_len
    syscall

    ; Initialize buffer
    lea r13, [tx_buffer]            ; Current write position
    xor r14, r14                    ; Bytes written

    ; Field 1: TransactionType (UInt16)
    mov al, 0x12                    ; Type 1, Field 2
    stosb
    inc r14

    mov ax, TXTYPE_NFTOKEN_MINT
    call write_uint16
    add r14, 2

    ; Field 2: Flags (UInt32)
    mov al, FIELD_FLAGS
    stosb
    inc r14

    mov eax, [r12 + 0]              ; Flags from params
    call write_uint32
    add r14, 4

    ; Field 3: Sequence (UInt32)
    mov al, FIELD_SEQUENCE
    stosb
    inc r14

    mov eax, [r12 + 4]              ; Sequence from params
    call write_uint32
    add r14, 4

    ; Field 4: TransferFee (UInt32) - optional, only if non-zero
    mov eax, [r12 + 8]
    test eax, eax
    jz .skip_transfer_fee

    mov al, FIELD_TRANSFER_FEE
    stosb
    inc r14

    mov eax, [r12 + 8]
    call write_uint32
    add r14, 4

.skip_transfer_fee:
    ; Field 5: Fee (Amount - XRP)
    mov al, FIELD_FEE
    stosb
    inc r14

    mov rax, [r12 + 12]             ; Fee in drops
    call write_xrp_amount
    add r14, 8

    ; Field 6: SigningPubKey (VL) - 33 bytes for Ed25519
    mov al, FIELD_SIGNING_PUB_KEY
    stosb
    inc r14

    ; Length (33 bytes)
    mov al, 33
    stosb
    inc r14

    ; Copy public key
    lea rsi, [r12 + 20]             ; Public key in params
    mov rcx, 33
    rep movsb
    add r14, 33

    ; Field 7: URI (VL) - hex-encoded IPFS URI
    mov al, FIELD_URI
    stosb
    inc r14

    ; Get URI length
    lea rsi, [r12 + 60]             ; URI pointer in params
    call strlen
    mov rcx, rax

    ; Write length as VL
    mov rax, rcx
    call write_vl_length
    add r14, rax

    ; Copy URI
    lea rsi, [r12 + 60]
    rep movsb
    add r14, rcx

    ; Field 8: Account (20 bytes)
    mov al, FIELD_ACCOUNT
    stosb
    inc r14

    ; Length (20 bytes) - already implied by type
    mov al, 20
    stosb
    inc r14

    ; Copy account ID
    lea rsi, [r12 + 200]            ; Account ID in params
    mov rcx, 20
    rep movsb
    add r14, 20

    ; NOTE: TxnSignature is added AFTER signing

    ; Update length
    mov [tx_length], r14

    ; Display completion
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_serialization_complete
    mov rdx, msg_serialization_complete_len
    syscall

    mov rax, r14                    ; Return length

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

; Serialize Payment transaction
; Input: rdi = pointer to payment params
; Output: rax = length
serialize_payment:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14

    mov r12, rdi
    lea r13, [tx_buffer]
    xor r14, r14

    ; TransactionType
    mov al, 0x12
    stosb
    inc r14

    mov ax, TXTYPE_PAYMENT
    call write_uint16
    add r14, 2

    ; Flags
    mov al, FIELD_FLAGS
    stosb
    inc r14

    mov eax, [r12 + 0]
    call write_uint32
    add r14, 4

    ; Sequence
    mov al, FIELD_SEQUENCE
    stosb
    inc r14

    mov eax, [r12 + 4]
    call write_uint32
    add r14, 4

    ; Amount
    mov al, FIELD_AMOUNT
    stosb
    inc r14

    mov rax, [r12 + 8]
    call write_xrp_amount
    add r14, 8

    ; Fee
    mov al, FIELD_FEE
    stosb
    inc r14

    mov rax, [r12 + 16]
    call write_xrp_amount
    add r14, 8

    ; SigningPubKey
    mov al, FIELD_SIGNING_PUB_KEY
    stosb
    inc r14

    mov al, 33
    stosb
    inc r14

    lea rsi, [r12 + 24]
    mov rcx, 33
    rep movsb
    add r14, 33

    ; Account
    mov al, FIELD_ACCOUNT
    stosb
    inc r14

    mov al, 20
    stosb
    inc r14

    lea rsi, [r12 + 60]
    mov rcx, 20
    rep movsb
    add r14, 20

    ; Destination
    mov al, FIELD_DESTINATION
    stosb
    inc r14

    mov al, 20
    stosb
    inc r14

    lea rsi, [r12 + 80]
    mov rcx, 20
    rep movsb
    add r14, 20

    mov [tx_length], r14
    mov rax, r14

    pop r14
    pop r13
    pop r12
    pop rbp
    ret

; ========== FIELD WRITERS ==========

; Write UInt16 in big-endian
; Input: ax = value
; Output: written to rdi, rdi advanced
write_uint16:
    push rax
    rol ax, 8                       ; Convert to big-endian
    stosw
    pop rax
    ret

; Write UInt32 in big-endian
; Input: eax = value
; Output: written to rdi, rdi advanced
write_uint32:
    push rax
    bswap eax                       ; Convert to big-endian
    stosd
    pop rax
    ret

; Write UInt64 in big-endian
; Input: rax = value
; Output: written to rdi, rdi advanced
write_uint64:
    push rax
    bswap rax
    stosq
    pop rax
    ret

; Write XRP amount (special format)
; XRP amounts are positive UInt64 with bit 62 set (to indicate XRP, not IOU)
; Input: rax = amount in drops
; Output: 8 bytes written to rdi
write_xrp_amount:
    push rax
    push rbx

    ; Set bit 62 (0x4000000000000000) to indicate XRP
    mov rbx, 0x4000000000000000
    or rax, rbx

    ; Ensure bit 63 is NOT set (positive amount)
    mov rbx, 0x8000000000000000
    not rbx
    and rax, rbx

    ; Write as big-endian UInt64
    bswap rax
    stosq

    pop rbx
    pop rax
    ret

; Write variable length field length
; Input: rax = length
; Output: length encoding written, rax = bytes written
write_vl_length:
    push rcx

    cmp rax, 192
    jl .short_length

    cmp rax, 12480
    jl .medium_length

    ; Long length (3 bytes)
    mov rcx, rax
    sub rcx, 12480

    mov al, 243
    add al, cl
    shr rcx, 8
    stosb

    mov al, cl
    stosb

    mov al, cl
    shr rax, 8
    stosb

    mov rax, 3
    pop rcx
    ret

.medium_length:
    ; Medium length (2 bytes)
    mov rcx, rax
    sub rcx, 192

    mov al, 193
    add al, cl
    shr rcx, 8
    stosb

    mov al, cl
    stosb

    mov rax, 2
    pop rcx
    ret

.short_length:
    ; Short length (1 byte)
    stosb
    mov rax, 1
    pop rcx
    ret

; ========== SIGNING ==========

; Sign serialized transaction
; Input: none (uses tx_buffer and tx_length)
; Output: signed_tx_blob contains hex-encoded signed transaction
sign_transaction:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_signing_tx
    mov rdx, msg_signing_tx_len
    syscall

    ; Hash transaction with SHA-512Half
    lea rsi, [tx_buffer]
    mov rdx, [tx_length]
    lea rdi, [tx_hash]
    call crypto_sha512_half

    ; Sign hash with Ed25519
    lea rsi, [tx_hash]
    mov rdx, 32
    call crypto_sign_transaction

    ; Signature is in transaction_signature (from crypto bridge)

    ; Now we need to add TxnSignature field to the serialized transaction
    ; Find insertion point (before Account field, which is 0x81)
    lea rsi, [tx_buffer]
    mov rcx, [tx_length]
    xor rbx, rbx                    ; Position

.find_account:
    cmp rbx, rcx
    jge .not_found

    cmp byte [rsi + rbx], 0x81
    je .found_account

    inc rbx
    jmp .find_account

.found_account:
    ; Insert TxnSignature before Account field
    ; Move everything from Account onward forward by 1 + 1 + 64 bytes

    lea rdi, [tx_buffer + rbx + 66]
    lea rsi, [tx_buffer + rbx]
    mov rcx, [tx_length]
    sub rcx, rbx

    ; Move backwards to avoid overwriting
    add rsi, rcx
    add rdi, rcx
    std
    rep movsb
    cld

    ; Write TxnSignature field
    lea rdi, [tx_buffer + rbx]
    mov al, FIELD_TXN_SIGNATURE
    stosb

    mov al, 64                      ; Signature length
    stosb

    ; Copy signature
    lea rsi, [transaction_signature]
    mov rcx, 64
    rep movsb

    ; Update length
    add qword [tx_length], 66

.not_found:
    ; Convert to hex
    lea rsi, [tx_buffer]
    mov rdx, [tx_length]
    lea rdi, [signed_tx_blob]
    call crypto_bin_to_hex

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_signing_complete
    mov rdx, msg_signing_complete_len
    syscall

    xor rax, rax

    pop r13
    pop r12
    pop rbp
    ret

; ========== UTILITIES ==========

; Get string length
; Input: rsi = string
; Output: rax = length (not including null terminator)
strlen:
    push rdi
    push rcx

    mov rdi, rsi
    xor rcx, rcx
    xor al, al
    not rcx
    repnz scasb
    not rcx
    dec rcx
    mov rax, rcx

    pop rcx
    pop rdi
    ret

; ========== EXTERNAL DEPENDENCIES ==========
extern crypto_sha512_half
extern crypto_sign_transaction
extern crypto_bin_to_hex
extern transaction_signature

; ========== EXPORTS ==========
global serialize_nftoken_mint
global serialize_payment
global sign_transaction
global tx_buffer
global tx_length
global signed_tx_blob
