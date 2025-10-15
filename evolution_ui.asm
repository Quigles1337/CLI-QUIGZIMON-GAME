; QUIGZIMON Evolution UI
; Pure x86-64 assembly implementation of evolution interface
; Beautiful evolution chamber experience!

section .data
    ; ========== EVOLUTION MENU ==========
    evolution_menu_title db 0xA, "═══════════════════════════════════════", 0xA
                         db "      EVOLUTION CHAMBER", 0xA
                         db "═══════════════════════════════════════", 0xA, 0xA, 0
    evolution_menu_title_len equ $ - evolution_menu_title

    evolution_menu db "1) ✨ View Eligible QUIGZIMON", 0xA
                   db "2) 🔮 Check Evolution Requirements", 0xA
                   db "3) ⚡ Begin Evolution", 0xA
                   db "4) 📖 Evolution Guide", 0xA
                   db "0) 🚪 Exit", 0xA, 0xA
                   db "Enter choice: ", 0
    evolution_menu_len equ $ - evolution_menu

    ; ========== ELIGIBLE QUIGZIMON ==========
    eligible_header db 0xA, "Your QUIGZIMON Ready to Evolve:", 0xA, 0xA, 0
    eligible_header_len equ $ - eligible_header

    eligible_table_header db "╔════════════════════════════════════════════════════╗", 0xA
                          db "║  #  │ Name      │ Lv │ Tier  │ Next Lvl │  Cost  ║", 0xA
                          db "╠════════════════════════════════════════════════════╣", 0xA, 0
    eligible_table_header_len equ $ - eligible_table_header

    eligible_table_footer db "╚════════════════════════════════════════════════════╝", 0xA, 0
    eligible_table_footer_len equ $ - eligible_table_footer

    none_eligible_msg db "No QUIGZIMON are currently eligible to evolve.", 0xA
                      db "Level up your QUIGZIMON to unlock evolution!", 0xA, 0
    none_eligible_msg_len equ $ - none_eligible_msg

    ; ========== EVOLUTION DETAILS ==========
    details_title db 0xA, "═══════════════════════════════════════", 0xA
                  db "      EVOLUTION DETAILS", 0xA
                  db "═══════════════════════════════════════", 0xA, 0xA, 0
    details_title_len equ $ - details_title

    current_stats_label db "Current Stats:", 0xA, 0
    current_stats_label_len equ $ - current_stats_label

    predicted_stats_label db 0xA, "Stats After Evolution:", 0xA, 0
    predicted_stats_label_len equ $ - predicted_stats_label

    stat_line_hp db "  HP:     ", 0
    stat_line_hp_len equ $ - stat_line_hp

    stat_line_atk db "  Attack: ", 0
    stat_line_atk_len equ $ - stat_line_atk

    stat_line_def db "  Defense:", 0
    stat_line_def_len equ $ - stat_line_def

    stat_line_spd db "  Speed:  ", 0
    stat_line_spd_len equ $ - stat_line_spd

    boost_indicator db " (+", 0
    boost_indicator_len equ $ - boost_indicator

    boost_end db ")", 0xA, 0
    boost_end_len equ $ - boost_end

    ; ========== EVOLUTION GUIDE ==========
    guide_title db 0xA, "═══════════════════════════════════════", 0xA
                db "      EVOLUTION GUIDE", 0xA
                db "═══════════════════════════════════════", 0xA, 0xA, 0
    guide_title_len equ $ - guide_title

    guide_text db "QUIGZIMON Evolution System:", 0xA, 0xA
               db "🔸 Three Tiers:", 0xA
               db "   • Basic (Starting form)", 0xA
               db "   • Stage 1 (Level 20+, 10 XRP)", 0xA
               db "   • Stage 2 (Level 40+, 50 XRP)", 0xA, 0xA
               db "🔸 Evolution Process:", 0xA
               db "   1. Level up to requirement", 0xA
               db "   2. Burn original NFT", 0xA
               db "   3. Mint evolved NFT", 0xA
               db "   4. Receive stat boosts!", 0xA, 0xA
               db "🔸 Stat Multipliers:", 0xA
               db "   • Stage 1: 1.2x - 1.5x stats", 0xA
               db "   • Stage 2: 1.4x - 2.0x stats", 0xA, 0xA
               db "⚠️  Evolution is PERMANENT!", 0xA
               db "    Original NFT cannot be recovered.", 0xA, 0xA, 0
    guide_text_len equ $ - guide_text

    ; ========== PROMPTS ==========
    select_quigzimon_prompt db 0xA, "Select QUIGZIMON to evolve (enter number): ", 0
    select_quigzimon_prompt_len equ $ - select_quigzimon_prompt

    invalid_selection_msg db "Invalid selection.", 0xA, 0
    invalid_selection_msg_len equ $ - invalid_selection_msg

    press_enter_msg db 0xA, "Press Enter to continue...", 0
    press_enter_msg_len equ $ - press_enter_msg

section .bss
    ; ========== UI STATE ==========
    input_buffer resb 64
    selected_index resq 1

    ; ========== QUIGZIMON LIST ==========
    eligible_count resq 1
    eligible_indices resb 100       ; Indices of eligible QUIGZIMON

    ; ========== DISPLAY BUFFERS ==========
    current_page resq 1

section .text
    global evolution_ui_main
    global display_eligible_quigzimon
    global display_evolution_details
    global display_evolution_guide

    extern evolve_nft
    extern check_evolution_requirements
    extern calculate_evolved_stats
    extern display_evolution_preview
    extern player_party
    extern player_party_count
    extern print_string
    extern print_number
    extern get_yes_no

; ========== MAIN EVOLUTION UI ==========
evolution_ui_main:
    push rbp
    mov rbp, rsp

.main_loop:
    ; Display title
    mov rax, 1
    mov rdi, 1
    lea rsi, [evolution_menu_title]
    mov rdx, evolution_menu_title_len
    syscall

    ; Display menu
    mov rax, 1
    mov rdi, 1
    lea rsi, [evolution_menu]
    mov rdx, evolution_menu_len
    syscall

    ; Get input
    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 64
    syscall

    ; Parse choice
    movzx rax, byte [input_buffer]
    sub al, '0'

    cmp al, 0
    je .exit
    cmp al, 1
    je .view_eligible
    cmp al, 2
    je .check_requirements
    cmp al, 3
    je .begin_evolution
    cmp al, 4
    je .view_guide

    jmp .main_loop

.view_eligible:
    call display_eligible_quigzimon
    call wait_for_enter
    jmp .main_loop

.check_requirements:
    call ui_check_requirements
    jmp .main_loop

.begin_evolution:
    call ui_begin_evolution
    jmp .main_loop

.view_guide:
    call display_evolution_guide
    call wait_for_enter
    jmp .main_loop

.exit:
    pop rbp
    ret

; ========== DISPLAY ELIGIBLE QUIGZIMON ==========
display_eligible_quigzimon:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    ; Display header
    mov rax, 1
    mov rdi, 1
    lea rsi, [eligible_header]
    mov rdx, eligible_header_len
    syscall

    ; Find eligible QUIGZIMON
    call find_eligible_quigzimon
    mov r13, rax            ; Count

    ; Check if any eligible
    test r13, r13
    jz .none_eligible

    ; Display table header
    mov rax, 1
    mov rdi, 1
    lea rsi, [eligible_table_header]
    mov rdx, eligible_table_header_len
    syscall

    ; Display each eligible QUIGZIMON
    xor r12, r12

.display_loop:
    cmp r12, r13
    jge .done_display

    ; Display row
    mov rdi, r12
    call display_eligible_row

    inc r12
    jmp .display_loop

.done_display:
    ; Display footer
    mov rax, 1
    mov rdi, 1
    lea rsi, [eligible_table_footer]
    mov rdx, eligible_table_footer_len
    syscall

    pop r13
    pop r12
    pop rbp
    ret

.none_eligible:
    mov rax, 1
    mov rdi, 1
    lea rsi, [none_eligible_msg]
    mov rdx, none_eligible_msg_len
    syscall

    pop r13
    pop r12
    pop rbp
    ret

; ========== FIND ELIGIBLE QUIGZIMON ==========
; Scan party for QUIGZIMON that meet level requirements
; Returns: rax = count of eligible
find_eligible_quigzimon:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14

    xor r13, r13            ; Eligible count
    xor r12, r12            ; Index

    movzx r14, byte [player_party_count]

.scan_loop:
    cmp r12, r14
    jge .done_scan

    ; Get QUIGZIMON data
    mov rax, r12
    imul rax, 15
    lea rbx, [player_party]
    add rbx, rax

    ; Get level
    movzx rcx, byte [rbx + 1]

    ; Check if meets basic requirement (level 20 for Basic tier)
    ; TODO: Also check current tier from NFT metadata
    cmp rcx, 20
    jl .not_eligible

    ; Add to eligible list
    lea rdi, [eligible_indices]
    add rdi, r13
    mov byte [rdi], r12b
    inc r13

.not_eligible:
    inc r12
    jmp .scan_loop

.done_scan:
    mov [eligible_count], r13
    mov rax, r13
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

; ========== DISPLAY ELIGIBLE ROW ==========
; Display one row in eligible table
; Input: rdi = eligible index (0-based)
display_eligible_row:
    push rbp
    mov rbp, rsp
    push r12

    mov r12, rdi

    ; Get actual party index
    lea rbx, [eligible_indices]
    add rbx, r12
    movzx r12, byte [rbx]

    ; Get QUIGZIMON data
    mov rax, r12
    imul rax, 15
    lea rbx, [player_party]
    add rbx, rax

    ; Display row start
    mov rax, 1
    mov rdi, 1
    lea rsi, [row_start]
    mov rdx, row_start_len
    syscall

    ; Display index (1-based)
    mov rax, r12
    inc rax
    call print_number

    ; Separator
    mov rax, 1
    mov rdi, 1
    lea rsi, [separator]
    mov rdx, separator_len
    syscall

    ; Display name (simplified - would get from species DB)
    ; TODO: Get species name

    ; Display level
    mov rax, 1
    mov rdi, 1
    lea rsi, [separator]
    mov rdx, separator_len
    syscall

    movzx rax, byte [rbx + 1]
    call print_number

    ; Display current tier (TODO)
    mov rax, 1
    mov rdi, 1
    lea rsi, [separator]
    mov rdx, separator_len
    syscall

    ; Display next level requirement
    mov rax, 1
    mov rdi, 1
    lea rsi, [separator]
    mov rdx, separator_len
    syscall

    ; Display cost
    mov rax, 1
    mov rdi, 1
    lea rsi, [separator]
    mov rdx, separator_len
    syscall

    ; Row end
    mov rax, 1
    mov rdi, 1
    lea rsi, [row_end]
    mov rdx, row_end_len
    syscall

    pop r12
    pop rbp
    ret

; ========== UI CHECK REQUIREMENTS ==========
ui_check_requirements:
    push rbp
    mov rbp, rsp

    ; Display eligible QUIGZIMON
    call display_eligible_quigzimon
    mov rax, [eligible_count]
    test rax, rax
    jz .done

    ; Prompt for selection
    mov rax, 1
    mov rdi, 1
    lea rsi, [select_quigzimon_prompt]
    mov rdx, select_quigzimon_prompt_len
    syscall

    ; Get selection
    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 64
    syscall

    lea rdi, [input_buffer]
    call parse_number
    test rax, rax
    jz .done

    dec rax
    cmp rax, [eligible_count]
    jge .invalid

    ; Get party index
    lea rbx, [eligible_indices]
    add rbx, rax
    movzx rax, byte [rbx]
    mov [selected_index], rax

    ; Display details
    call display_evolution_details

    jmp .done

.invalid:
    mov rax, 1
    mov rdi, 1
    lea rsi, [invalid_selection_msg]
    mov rdx, invalid_selection_msg_len
    syscall

.done:
    call wait_for_enter
    pop rbp
    ret

; ========== DISPLAY EVOLUTION DETAILS ==========
display_evolution_details:
    push rbp
    mov rbp, rsp
    push r12

    ; Get QUIGZIMON data
    mov rax, [selected_index]
    imul rax, 15
    lea r12, [player_party]
    add r12, rax

    ; Display title
    mov rax, 1
    mov rdi, 1
    lea rsi, [details_title]
    mov rdx, details_title_len
    syscall

    ; Display current stats
    mov rax, 1
    mov rdi, 1
    lea rsi, [current_stats_label]
    mov rdx, current_stats_label_len
    syscall

    call display_current_stats

    ; Calculate and display predicted stats
    mov rax, 1
    mov rdi, 1
    lea rsi, [predicted_stats_label]
    mov rdx, predicted_stats_label_len
    syscall

    ; Get NFT Token ID (would query from blockchain)
    ; For now, use placeholder
    lea rdi, [mock_token_id]
    mov rsi, r12
    call display_evolution_preview

    pop r12
    pop rbp
    ret

; ========== DISPLAY CURRENT STATS ==========
display_current_stats:
    push rbp
    mov rbp, rsp
    push r12

    mov rax, [selected_index]
    imul rax, 15
    lea r12, [player_party]
    add r12, rax

    ; HP
    mov rax, 1
    mov rdi, 1
    lea rsi, [stat_line_hp]
    mov rdx, stat_line_hp_len
    syscall

    movzx rax, word [r12 + 4]
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    ; ATK
    mov rax, 1
    mov rdi, 1
    lea rsi, [stat_line_atk]
    mov rdx, stat_line_atk_len
    syscall

    movzx rax, word [r12 + 9]
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    ; DEF
    mov rax, 1
    mov rdi, 1
    lea rsi, [stat_line_def]
    mov rdx, stat_line_def_len
    syscall

    movzx rax, word [r12 + 11]
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    ; SPD
    mov rax, 1
    mov rdi, 1
    lea rsi, [stat_line_spd]
    mov rdx, stat_line_spd_len
    syscall

    movzx rax, word [r12 + 13]
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    pop r12
    pop rbp
    ret

; ========== UI BEGIN EVOLUTION ==========
ui_begin_evolution:
    push rbp
    mov rbp, rsp

    ; Display eligible and select
    call display_eligible_quigzimon
    mov rax, [eligible_count]
    test rax, rax
    jz .done

    mov rax, 1
    mov rdi, 1
    lea rsi, [select_quigzimon_prompt]
    mov rdx, select_quigzimon_prompt_len
    syscall

    ; Get selection
    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 64
    syscall

    lea rdi, [input_buffer]
    call parse_number
    test rax, rax
    jz .done

    dec rax
    cmp rax, [eligible_count]
    jge .invalid

    ; Get party index
    lea rbx, [eligible_indices]
    add rbx, rax
    movzx rax, byte [rbx]
    mov [selected_index], rax

    ; Begin evolution!
    imul rax, 15
    lea rsi, [player_party]
    add rsi, rax
    lea rdi, [mock_token_id]
    call evolve_nft

    jmp .done

.invalid:
    mov rax, 1
    mov rdi, 1
    lea rsi, [invalid_selection_msg]
    mov rdx, invalid_selection_msg_len
    syscall

.done:
    pop rbp
    ret

; ========== DISPLAY EVOLUTION GUIDE ==========
display_evolution_guide:
    push rbp
    mov rbp, rsp

    ; Display title
    mov rax, 1
    mov rdi, 1
    lea rsi, [guide_title]
    mov rdx, guide_title_len
    syscall

    ; Display guide text
    mov rax, 1
    mov rdi, 1
    lea rsi, [guide_text]
    mov rdx, guide_text_len
    syscall

    pop rbp
    ret

; ========== HELPER FUNCTIONS ==========

; Parse number from string
parse_number:
    push rbp
    mov rbp, rsp
    xor rax, rax
    mov rcx, 10

.loop:
    movzx rdx, byte [rdi]
    cmp dl, '0'
    jl .done
    cmp dl, '9'
    jg .done

    sub dl, '0'
    imul rax, rcx
    add rax, rdx
    inc rdi
    jmp .loop

.done:
    pop rbp
    ret

; Wait for Enter
wait_for_enter:
    push rbp
    mov rbp, rsp

    mov rax, 1
    mov rdi, 1
    lea rsi, [press_enter_msg]
    mov rdx, press_enter_msg_len
    syscall

    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 64
    syscall

    pop rbp
    ret

section .bss
    newline db 0xA
    row_start db "║ ", 0
    row_start_len equ 3
    separator db " │ ", 0
    separator_len equ 3
    row_end db " ║", 0xA, 0
    row_end_len equ 4
    mock_token_id resb 128

; ========== EXPORTS ==========
global evolution_ui_main
global display_eligible_quigzimon
global display_evolution_details
global display_evolution_guide
