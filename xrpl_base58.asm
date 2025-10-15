; QUIGZIMON XRPL Base58 Encoding/Decoding
; Pure assembly implementation of Base58Check encoding used by XRPL
; Base58 uses Bitcoin alphabet: 123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz

section .data
    ; Base58 alphabet (no 0, O, I, l to avoid confusion)
    base58_alphabet db "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz", 0

    ; Test vectors for verification
    test_input_1 db "Hello World!", 0
    test_output_1 db "2NEpo7TZRRrLZSi2U", 0

    msg_base58_test db "Testing Base58...", 0xA, 0
    msg_base58_test_len equ $ - msg_base58_test

    msg_base58_pass db "Base58 test PASSED!", 0xA, 0
    msg_base58_pass_len equ $ - msg_base58_pass

    msg_base58_fail db "Base58 test FAILED!", 0xA, 0
    msg_base58_fail_len equ $ - msg_base58_fail

section .bss
    ; Working buffers for big number arithmetic
    bignum_buffer resb 512      ; Large enough for any reasonable input
    bignum_result resb 512
    base58_output resb 256      ; Base58 encoded output
    base58_temp resb 256        ; Temporary buffer

    ; Division state
    quotient resb 256
    remainder resb 1

section .text

; ========== BASE58 ENCODING ==========

; Encode binary data to Base58
; Input: rsi = pointer to binary data
;        rdx = length of binary data
;        rdi = output buffer for Base58 string
; Output: rax = length of Base58 string (including null terminator)
base58_encode:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r12, rsi        ; Save input pointer
    mov r13, rdx        ; Save input length
    mov r14, rdi        ; Save output pointer

    ; Handle empty input
    test rdx, rdx
    jz .empty

    ; Count leading zero bytes (encoded as '1' in Base58)
    xor r15, r15        ; Leading zero count

.count_zeros:
    cmp r15, r13
    jge .all_zeros
    cmp byte [r12 + r15], 0
    jne .done_counting_zeros
    inc r15
    jmp .count_zeros

.done_counting_zeros:
    ; Copy input to bignum buffer (we'll modify it)
    lea rdi, [bignum_buffer]
    mov rsi, r12
    mov rcx, r13
    rep movsb

    ; Initialize result buffer
    lea rdi, [bignum_result]
    xor al, al
    mov rcx, 256
    rep stosb

    ; Point to end of result buffer (we build backwards)
    lea r8, [bignum_result]
    add r8, 255
    xor r9, r9          ; Result length

.encode_loop:
    ; Check if bignum is zero
    lea rsi, [bignum_buffer]
    mov rcx, r13
    xor al, al

.check_zero:
    or al, [rsi]
    inc rsi
    loop .check_zero

    test al, al
    jz .done_encoding   ; All zeros, we're done

    ; Divide bignum by 58, get remainder
    lea rdi, [bignum_buffer]
    mov rdx, r13
    mov rbx, 58
    call bignum_divide_58

    ; rax contains remainder (0-57)
    ; Look up character in alphabet
    lea rsi, [base58_alphabet]
    add rsi, rax
    mov al, [rsi]

    ; Store in result (building backwards)
    mov [r8], al
    dec r8
    inc r9

    jmp .encode_loop

.done_encoding:
    ; Now copy leading zeros as '1' characters
    mov rdi, r14        ; Output buffer
    mov rcx, r15        ; Number of leading zeros
    test rcx, rcx
    jz .skip_leading

    mov al, '1'
.add_leading:
    stosb
    loop .add_leading

.skip_leading:
    ; Copy the encoded result
    inc r8              ; Move back to first character
    mov rsi, r8
    mov rcx, r9
    rep movsb

    ; Null terminate
    mov byte [rdi], 0

    ; Calculate total length
    mov rax, r15
    add rax, r9
    inc rax             ; Include null terminator

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

.empty:
    mov byte [rdi], 0
    mov rax, 1
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

.all_zeros:
    ; All zeros, encode as all '1's
    mov rdi, r14
    mov rcx, r15
    mov al, '1'
    rep stosb
    mov byte [rdi], 0
    mov rax, r15
    inc rax
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Divide big number by 58 (in-place)
; Input: rdi = bignum buffer, rdx = length
; Output: rax = remainder, bignum buffer = quotient
bignum_divide_58:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    push rdx
    push rsi

    xor rax, rax        ; Accumulator for division
    xor rsi, rsi        ; Index

.div_loop:
    cmp rsi, rdx
    jge .done_div

    ; Load next byte
    movzx rbx, byte [rdi + rsi]

    ; Shift accumulator and add current byte
    shl rax, 8
    or rax, rbx

    ; Divide by 58
    xor rdx, rdx
    mov rcx, 58
    div rcx
    ; rax = quotient, rdx = remainder

    ; Store quotient
    mov [rdi + rsi], al

    ; Remainder becomes new accumulator
    mov rax, rdx

    inc rsi
    jmp .div_loop

.done_div:
    ; rax contains final remainder

    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rbp
    ret

; ========== BASE58 DECODING ==========

; Decode Base58 string to binary
; Input: rsi = pointer to Base58 string (null-terminated)
;        rdi = output buffer for binary data
; Output: rax = length of binary data, or -1 on error
base58_decode:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r12, rsi        ; Save input pointer
    mov r13, rdi        ; Save output pointer

    ; Calculate input length
    xor rcx, rcx
.strlen:
    cmp byte [rsi], 0
    je .strlen_done
    inc rcx
    inc rsi
    jmp .strlen

.strlen_done:
    mov r14, rcx        ; Input length
    test r14, r14
    jz .error           ; Empty string

    ; Count leading '1' characters (will become leading zero bytes)
    xor r15, r15
    mov rsi, r12

.count_ones:
    cmp r15, r14
    jge .all_ones
    cmp byte [rsi], '1'
    jne .done_counting_ones
    inc r15
    inc rsi
    jmp .count_ones

.done_counting_ones:
    ; Initialize bignum to zero
    lea rdi, [bignum_buffer]
    xor al, al
    mov rcx, 512
    rep stosb

    ; Process each character
    mov rsi, r12
    xor r8, r8          ; Current position

.decode_loop:
    cmp r8, r14
    jge .done_decoding

    ; Get next character
    movzx rax, byte [rsi]

    ; Find position in alphabet
    push rsi
    lea rsi, [base58_alphabet]
    xor rbx, rbx

.find_char:
    cmp rbx, 58
    jge .invalid_char
    cmp byte [rsi + rbx], al
    je .found_char
    inc rbx
    jmp .find_char

.found_char:
    pop rsi

    ; Multiply bignum by 58 and add rbx
    lea rdi, [bignum_buffer]
    mov rcx, 256
    call bignum_multiply_add_58

    inc rsi
    inc r8
    jmp .decode_loop

.done_decoding:
    ; Find first non-zero byte in bignum
    lea rsi, [bignum_buffer]
    xor rcx, rcx

.find_first:
    cmp rcx, 256
    jge .all_zero_result
    cmp byte [rsi], 0
    jne .found_first
    inc rsi
    inc rcx
    jmp .find_first

.found_first:
    ; Copy leading zeros
    mov rdi, r13
    mov rcx, r15
    test rcx, rcx
    jz .skip_leading_zeros

    xor al, al
.write_zeros:
    stosb
    loop .write_zeros

.skip_leading_zeros:
    ; Copy bignum result
    lea rax, [bignum_buffer]
    add rax, 256
    sub rax, rsi
    mov rcx, rax
    rep movsb

    ; Return total length
    add rax, r15

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

.invalid_char:
    pop rsi
.error:
    mov rax, -1
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

.all_ones:
    ; All '1's, result is all zeros
    mov rdi, r13
    mov rcx, r15
    xor al, al
    rep stosb
    mov rax, r15
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

.all_zero_result:
    xor rax, rax
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Multiply bignum by 58 and add value
; Input: rdi = bignum buffer, rcx = buffer size, rbx = value to add (0-57)
; Output: bignum buffer modified
bignum_multiply_add_58:
    push rbp
    mov rbp, rsp
    push r8
    push r9
    push r10
    push r11

    mov r10, rdi
    mov r11, rcx

    ; Start from least significant byte (end of buffer)
    add r10, r11
    dec r10

    mov r8, rbx         ; Value to add

.mult_loop:
    ; Get current byte
    movzx rax, byte [r10]

    ; Multiply by 58
    mov r9, 58
    mul r9
    ; Result in rax, check for overflow in rdx

    ; Add carry from previous operation
    add rax, r8

    ; Store low byte
    mov [r10], al

    ; Carry is high byte
    shr rax, 8
    mov r8, rax

    ; Move to next byte
    dec r10
    dec r11
    jnz .mult_loop

    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    ret

; ========== BASE58CHECK (with checksum) ==========

; Encode with Base58Check (includes 4-byte checksum)
; Input: rsi = data, rdx = length, rdi = output buffer
; Output: rax = length of Base58 string
base58check_encode:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14

    mov r12, rsi
    mov r13, rdx
    mov r14, rdi

    ; Copy data to temp buffer
    lea rdi, [base58_temp]
    mov rcx, r13
    rep movsb

    ; Compute double SHA-256 for checksum
    mov rsi, r12
    mov rdx, r13
    call sha256_double

    ; Append first 4 bytes of hash as checksum
    lea rdi, [base58_temp]
    add rdi, r13
    lea rsi, [sha256_result]
    movsd               ; Copy 4 bytes

    ; Encode with regular Base58
    lea rsi, [base58_temp]
    mov rdx, r13
    add rdx, 4          ; Include checksum
    mov rdi, r14
    call base58_encode

    pop r14
    pop r13
    pop r12
    pop rbp
    ret

; Decode Base58Check (verifies checksum)
; Input: rsi = Base58 string, rdi = output buffer
; Output: rax = length of data (without checksum), or -1 on error
base58check_decode:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov r12, rdi        ; Save output buffer

    ; Decode to temp buffer
    lea rdi, [base58_temp]
    call base58_decode

    cmp rax, 5          ; Must be at least 5 bytes (1 data + 4 checksum)
    jl .checksum_error

    mov r13, rax        ; Save total length

    ; Compute checksum of data portion
    lea rsi, [base58_temp]
    mov rdx, r13
    sub rdx, 4          ; Exclude checksum
    call sha256_double

    ; Compare checksums
    lea rsi, [sha256_result]
    lea rdi, [base58_temp]
    add rdi, r13
    sub rdi, 4

    mov ecx, [rsi]
    cmp ecx, [rdi]
    jne .checksum_error

    ; Checksum valid, copy data to output
    lea rsi, [base58_temp]
    mov rdi, r12
    mov rcx, r13
    sub rcx, 4
    rep movsb

    mov rax, r13
    sub rax, 4

    pop r13
    pop r12
    pop rbp
    ret

.checksum_error:
    mov rax, -1
    pop r13
    pop r12
    pop rbp
    ret

; ========== HELPER FUNCTIONS ==========

; Compute double SHA-256 (used for checksums)
; Input: rsi = data, rdx = length
; Output: sha256_result contains hash
sha256_double:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov r12, rsi
    mov r13, rdx

    ; First SHA-256
    lea rdi, [sha256_result]
    call crypto_sha256

    ; Second SHA-256
    lea rsi, [sha256_result]
    mov rdx, 32
    lea rdi, [sha256_result]
    call crypto_sha256

    pop r13
    pop r12
    pop rbp
    ret

; ========== XRPL-SPECIFIC FUNCTIONS ==========

; Encode XRPL account ID to classic address (rXXX...)
; Input: rsi = 20-byte account ID
;        rdi = output buffer for address string
; Output: rax = length of address string
xrpl_encode_address:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov r12, rsi
    mov r13, rdi

    ; Build versioned payload: 0x00 || account_id
    lea rdi, [base58_temp]
    mov byte [rdi], 0x00        ; Version byte for classic address
    inc rdi

    ; Copy account ID
    mov rsi, r12
    mov rcx, 20
    rep movsb

    ; Encode with Base58Check
    lea rsi, [base58_temp]
    mov rdx, 21                 ; 1 version + 20 account ID
    mov rdi, r13
    call base58check_encode

    pop r13
    pop r12
    pop rbp
    ret

; Decode XRPL classic address to account ID
; Input: rsi = classic address string (rXXX...)
;        rdi = output buffer for 20-byte account ID
; Output: rax = 20 on success, -1 on error
xrpl_decode_address:
    push rbp
    mov rbp, rsp
    push r12

    mov r12, rdi

    ; Decode Base58Check
    lea rdi, [base58_temp]
    call base58check_decode

    cmp rax, 21                 ; Should be 21 bytes (1 version + 20 account)
    jne .decode_error

    ; Verify version byte is 0x00
    cmp byte [base58_temp], 0x00
    jne .decode_error

    ; Copy account ID (skip version byte)
    lea rsi, [base58_temp + 1]
    mov rdi, r12
    mov rcx, 20
    rep movsb

    mov rax, 20
    pop r12
    pop rbp
    ret

.decode_error:
    mov rax, -1
    pop r12
    pop rbp
    ret

; ========== TESTING ==========

; Test Base58 encoding/decoding
test_base58:
    push rbp
    mov rbp, rsp

    ; Display test message
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_base58_test
    mov rdx, msg_base58_test_len
    syscall

    ; Test encode
    lea rsi, [test_input_1]
    mov rdx, 12
    lea rdi, [base58_output]
    call base58_encode

    ; Compare with expected
    lea rsi, [base58_output]
    lea rdi, [test_output_1]
    call strcmp
    test rax, rax
    jnz .fail

    ; Test decode
    lea rsi, [test_output_1]
    lea rdi, [bignum_buffer]
    call base58_decode

    cmp rax, 12
    jne .fail

    ; Compare with original
    lea rsi, [bignum_buffer]
    lea rdi, [test_input_1]
    mov rcx, 12
    call memcmp
    test rax, rax
    jnz .fail

    ; Success!
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_base58_pass
    mov rdx, msg_base58_pass_len
    syscall

    xor rax, rax
    pop rbp
    ret

.fail:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_base58_fail
    mov rdx, msg_base58_fail_len
    syscall

    mov rax, -1
    pop rbp
    ret

; String compare
; Input: rsi, rdi = strings
; Output: rax = 0 if equal
strcmp:
    push rcx
    xor rax, rax

.loop:
    mov al, [rsi]
    mov cl, [rdi]
    cmp al, cl
    jne .not_equal

    test al, al
    jz .equal

    inc rsi
    inc rdi
    jmp .loop

.equal:
    xor rax, rax
    pop rcx
    ret

.not_equal:
    mov rax, 1
    pop rcx
    ret

; Memory compare
; Input: rsi, rdi = buffers, rcx = length
; Output: rax = 0 if equal
memcmp:
    push rcx
    xor rax, rax

.loop:
    test rcx, rcx
    jz .equal

    mov al, [rsi]
    cmp al, [rdi]
    jne .not_equal

    inc rsi
    inc rdi
    dec rcx
    jmp .loop

.equal:
    xor rax, rax
    pop rcx
    ret

.not_equal:
    mov rax, 1
    pop rcx
    ret

section .bss
    sha256_result resb 32

; ========== EXTERNAL DEPENDENCIES ==========
extern crypto_sha256

; ========== EXPORTS ==========
global base58_encode
global base58_decode
global base58check_encode
global base58check_decode
global xrpl_encode_address
global xrpl_decode_address
global test_base58
