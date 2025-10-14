; QUIGZIMON Save/Load System
; This file contains the save and load implementations for file I/O

; Save game structure:
; - Player party count (1 byte)
; - Total caught (1 byte)
; - Current location (1 byte)
; - Player party data (90 bytes - 6 QUIGZIMON * 15 bytes each)
; Total: 93 bytes

section .data
    save_path db "quigzimon.sav", 0

section .text

; ========== SAVE GAME (Full Implementation) ==========
; This replaces the stub in the main file
save_game_complete:
    push rbp
    mov rbp, rsp

    ; Open file for writing (create if doesn't exist)
    ; syscall: open
    ; rax = 2 (sys_open)
    ; rdi = filename
    ; rsi = flags (O_CREAT | O_WRONLY | O_TRUNC = 0x241)
    ; rdx = mode (0644 = rw-r--r--)
    mov rax, 2
    lea rdi, [save_path]
    mov rsi, 0x241  ; O_CREAT | O_WRONLY | O_TRUNC
    mov rdx, 0644o
    syscall

    ; Check for error
    cmp rax, 0
    jl .error

    ; Save file descriptor
    mov r12, rax

    ; Write player_party_count
    mov rax, 1  ; sys_write
    mov rdi, r12
    lea rsi, [player_party_count]
    mov rdx, 1
    syscall

    ; Write total_caught
    mov rax, 1
    mov rdi, r12
    lea rsi, [total_caught]
    mov rdx, 1
    syscall

    ; Write current_location
    mov rax, 1
    mov rdi, r12
    lea rsi, [current_location]
    mov rdx, 1
    syscall

    ; Write party data (90 bytes)
    mov rax, 1
    mov rdi, r12
    lea rsi, [player_party]
    mov rdx, 90
    syscall

    ; Close file
    mov rax, 3  ; sys_close
    mov rdi, r12
    syscall

    ; Display success message
    mov rax, 1
    mov rdi, 1
    mov rsi, save_msg
    mov rdx, save_msg_len
    syscall

    pop rbp
    ret

.error:
    ; TODO: Display error message
    pop rbp
    ret

; ========== LOAD GAME ==========
load_game_complete:
    push rbp
    mov rbp, rsp

    ; Open file for reading
    ; syscall: open
    ; rax = 2 (sys_open)
    ; rdi = filename
    ; rsi = flags (O_RDONLY = 0)
    mov rax, 2
    lea rdi, [save_path]
    mov rsi, 0  ; O_RDONLY
    syscall

    ; Check for error (file doesn't exist)
    cmp rax, 0
    jl .error

    ; Save file descriptor
    mov r12, rax

    ; Read player_party_count
    mov rax, 0  ; sys_read
    mov rdi, r12
    lea rsi, [player_party_count]
    mov rdx, 1
    syscall

    ; Read total_caught
    mov rax, 0
    mov rdi, r12
    lea rsi, [total_caught]
    mov rdx, 1
    syscall

    ; Read current_location
    mov rax, 0
    mov rdi, r12
    lea rsi, [current_location]
    mov rdx, 1
    syscall

    ; Read party data
    mov rax, 0
    mov rdi, r12
    lea rsi, [player_party]
    mov rdx, 90
    syscall

    ; Close file
    mov rax, 3  ; sys_close
    mov rdi, r12
    syscall

    ; TODO: Display success message

    pop rbp
    ret

.error:
    ; File doesn't exist - this is OK for new game
    pop rbp
    ret
