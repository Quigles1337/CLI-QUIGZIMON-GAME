; QUIGZIMON Tournament UI
; Pure x86-64 assembly implementation of bracket visualization
; Beautiful ASCII art tournament brackets!

section .data
    ; ========== TOURNAMENT MENU ==========
    tournament_menu_title db 0xA, "═══════════════════════════════════════", 0xA
                          db "      TOURNAMENT LOBBY", 0xA
                          db "═══════════════════════════════════════", 0xA, 0xA, 0
    tournament_menu_title_len equ $ - tournament_menu_title

    tournament_menu db "1) 🏆 Create Tournament", 0xA
                    db "2) 📋 Browse Tournaments", 0xA
                    db "3) ✅ Register", 0xA
                    db "4) 👁️  View Bracket", 0xA
                    db "5) ⚔️  Play My Match", 0xA
                    db "6) 📊 Leaderboard", 0xA
                    db "0) 🚪 Exit", 0xA, 0xA
                    db "Enter choice: ", 0
    tournament_menu_len equ $ - tournament_menu

    ; ========== BRACKET VISUALIZATION ==========
    bracket_title db 0xA
                  db "╔════════════════════════════════════════════════════╗", 0xA
                  db "║            TOURNAMENT BRACKET                      ║", 0xA
                  db "╚════════════════════════════════════════════════════╝", 0xA, 0xA, 0
    bracket_title_len equ $ - bracket_title

    ; 8-Player Bracket ASCII Art
    bracket_8_player db 0xA
                     db "    ROUND 1          SEMIFINALS         FINALS", 0xA
                     db "                                                  ", 0xA
                     db "  ┌─────────┐                                     ", 0xA
                     db "  │ Seed 1  │───┐                                 ", 0xA
                     db "  └─────────┘   │                                 ", 0xA
                     db "                ├──────┐                          ", 0xA
                     db "  ┌─────────┐   │      │                          ", 0xA
                     db "  │ Seed 8  │───┘      │                          ", 0xA
                     db "  └─────────┘          │                          ", 0xA
                     db "                       ├─────────┐                ", 0xA
                     db "  ┌─────────┐          │         │                ", 0xA
                     db "  │ Seed 4  │───┐      │         │                ", 0xA
                     db "  └─────────┘   │      │         │                ", 0xA
                     db "                ├──────┘         │                ", 0xA
                     db "  ┌─────────┐   │                │                ", 0xA
                     db "  │ Seed 5  │───┘                │                ", 0xA
                     db "  └─────────┘                    │                ", 0xA
                     db "                                 ├────── CHAMPION!", 0xA
                     db "  ┌─────────┐                    │                ", 0xA
                     db "  │ Seed 2  │───┐                │                ", 0xA
                     db "  └─────────┘   │                │                ", 0xA
                     db "                ├──────┐         │                ", 0xA
                     db "  ┌─────────┐   │      │         │                ", 0xA
                     db "  │ Seed 7  │───┘      │         │                ", 0xA
                     db "  └─────────┘          │         │                ", 0xA
                     db "                       ├─────────┘                ", 0xA
                     db "  ┌─────────┐          │                          ", 0xA
                     db "  │ Seed 3  │───┐      │                          ", 0xA
                     db "  └─────────┘   │      │                          ", 0xA
                     db "                ├──────┘                          ", 0xA
                     db "  ┌─────────┐   │                                 ", 0xA
                     db "  │ Seed 6  │───┘                                 ", 0xA
                     db "  └─────────┘                                     ", 0xA, 0xA, 0
    bracket_8_player_len equ $ - bracket_8_player

    ; Match status indicators
    match_pending_indicator db "[ PENDING ]", 0
    match_complete_indicator db "[  WIN!  ]", 0
    match_eliminated_indicator db "[  OUT   ]", 0

    ; ========== ROUND HEADERS ==========
    round_1_header db 0xA, "═════════════ ROUND 1 ═════════════", 0xA, 0
    round_1_header_len equ $ - round_1_header

    round_2_header db 0xA, "═════════════ SEMIFINALS ═════════════", 0xA, 0
    round_2_header_len equ $ - round_2_header

    round_3_header db 0xA, "═════════════ FINALS ═════════════", 0xA, 0
    round_3_header_len equ $ - round_3_header

    ; ========== MATCH DISPLAY ==========
    match_box_top db "  ┌───────────────────┐", 0xA, 0
    match_box_top_len equ $ - match_box_top

    match_box_p1 db "  │ ", 0
    match_box_p1_len equ $ - match_box_p1

    match_box_vs db "  │       VS          │", 0xA, 0
    match_box_vs_len equ $ - match_box_vs

    match_box_p2 db "  │ ", 0
    match_box_p2_len equ $ - match_box_p2

    match_box_bottom db "  └───────────────────┘", 0xA, 0
    match_box_bottom_len equ $ - match_box_bottom

    match_winner_arrow db "  ───→ ", 0
    match_winner_arrow_len equ $ - match_winner_arrow

    ; ========== TOURNAMENT LIST ==========
    tournament_list_header db "╔════════════════════════════════════════════════════╗", 0xA
                           db "║  #  │  Type  │ Players │ Entry Fee │  Status   ║", 0xA
                           db "╠════════════════════════════════════════════════════╣", 0xA, 0
    tournament_list_header_len equ $ - tournament_list_header

    tournament_list_footer db "╚════════════════════════════════════════════════════╝", 0xA, 0
    tournament_list_footer_len equ $ - tournament_list_footer

    ; ========== REGISTRATION PROMPT ==========
    select_tournament_msg db 0xA, "Enter tournament number to register: ", 0
    select_tournament_msg_len equ $ - select_tournament_msg

    confirm_registration_msg db 0xA, "Register for tournament with ", 0
    confirm_registration_msg_len equ $ - confirm_registration_msg

    entry_fee_confirm db " XRP entry fee? (y/n): ", 0
    entry_fee_confirm_len equ $ - entry_fee_confirm

    ; ========== MY MATCH ==========
    my_match_title db 0xA, "═══════════════════════════════════════", 0xA
                   db "      YOUR TOURNAMENT MATCH", 0xA
                   db "═══════════════════════════════════════", 0xA, 0xA, 0
    my_match_title_len equ $ - my_match_title

    no_match_msg db "You don't have an active match.", 0xA, 0
    no_match_msg_len equ $ - no_match_msg

    ready_to_play_msg db "Ready to play your match? (y/n): ", 0
    ready_to_play_msg_len equ $ - ready_to_play_msg

    ; ========== CHAMPION DISPLAY ==========
    champion_banner db 0xA, 0xA
                    db "╔════════════════════════════════════════════════════╗", 0xA
                    db "║                                                    ║", 0xA
                    db "║           🏆 TOURNAMENT CHAMPION! 🏆              ║", 0xA
                    db "║                                                    ║", 0xA
                    db "╚════════════════════════════════════════════════════╝", 0xA, 0xA, 0
    champion_banner_len equ $ - champion_banner

    winner_label db "Winner: ", 0
    winner_label_len equ $ - winner_label

    prize_won_label db "Prize Won: ", 0
    prize_won_label_len equ $ - prize_won_label

section .bss
    input_buffer resb 64
    selected_tournament_idx resq 1

section .text
    global tournament_ui_main
    global display_bracket_visual
    global display_tournament_list
    global ui_create_tournament
    global ui_register_tournament
    global ui_view_bracket
    global ui_play_match

    extern create_tournament
    extern register_for_tournament
    extern start_tournament
    extern play_tournament_match
    extern view_tournament_bracket
    extern active_tournaments
    extern account_address
    extern print_string
    extern print_number
    extern get_yes_no

; ========== MAIN TOURNAMENT UI ==========
tournament_ui_main:
    push rbp
    mov rbp, rsp

.main_loop:
    ; Display title
    mov rax, 1
    mov rdi, 1
    lea rsi, [tournament_menu_title]
    mov rdx, tournament_menu_title_len
    syscall

    ; Display menu
    mov rax, 1
    mov rdi, 1
    lea rsi, [tournament_menu]
    mov rdx, tournament_menu_len
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
    je .create
    cmp al, 2
    je .browse
    cmp al, 3
    je .register
    cmp al, 4
    je .view_bracket
    cmp al, 5
    je .play_match
    cmp al, 6
    je .leaderboard

    jmp .main_loop

.create:
    call ui_create_tournament
    jmp .main_loop

.browse:
    call display_tournament_list
    call wait_for_enter
    jmp .main_loop

.register:
    call ui_register_tournament
    jmp .main_loop

.view_bracket:
    call ui_view_bracket
    jmp .main_loop

.play_match:
    call ui_play_match
    jmp .main_loop

.leaderboard:
    call ui_leaderboard
    jmp .main_loop

.exit:
    pop rbp
    ret

; ========== CREATE TOURNAMENT UI ==========
ui_create_tournament:
    push rbp
    mov rbp, rsp

    ; Select tournament type
    mov rax, 1
    mov rdi, 1
    lea rsi, [tournament_type_prompt]
    mov rdx, tournament_type_prompt_len
    syscall

    ; Get type
    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 64
    syscall

    movzx rax, byte [input_buffer]
    sub al, '0'
    dec al
    mov r12, rax

    ; Get entry fee
    mov rax, 1
    mov rdi, 1
    lea rsi, [entry_fee_prompt]
    mov rdx, entry_fee_prompt_len
    syscall

    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 64
    syscall

    lea rdi, [input_buffer]
    call parse_number
    imul rax, 1000000
    mov r13, rax

    ; Create tournament
    mov rdi, r12
    mov rsi, r13
    call create_tournament

    call wait_for_enter
    pop rbp
    ret

; ========== DISPLAY TOURNAMENT LIST ==========
display_tournament_list:
    push rbp
    mov rbp, rsp

    ; Display header
    mov rax, 1
    mov rdi, 1
    lea rsi, [tournament_list_header]
    mov rdx, tournament_list_header_len
    syscall

    ; Get tournament count
    mov r12, [active_tournaments.count]
    xor r13, r13

.display_loop:
    cmp r13, r12
    jge .done

    ; Get tournament data
    mov rax, r13
    imul rax, 2000
    lea rbx, [active_tournaments.data]
    add rbx, rax

    ; Display tournament row
    mov rdi, r13
    mov rsi, rbx
    call display_tournament_row

    inc r13
    jmp .display_loop

.done:
    ; Display footer
    mov rax, 1
    mov rdi, 1
    lea rsi, [tournament_list_footer]
    mov rdx, tournament_list_footer_len
    syscall

    pop rbp
    ret

; ========== REGISTER FOR TOURNAMENT UI ==========
ui_register_tournament:
    push rbp
    mov rbp, rsp

    ; Show tournament list
    call display_tournament_list

    ; Select tournament
    mov rax, 1
    mov rdi, 1
    lea rsi, [select_tournament_msg]
    mov rdx, select_tournament_msg_len
    syscall

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
    mov [selected_tournament_idx], rax

    ; Get tournament data
    imul rax, 2000
    lea rbx, [active_tournaments.data]
    add rbx, rax

    ; Display entry fee
    mov rax, 1
    mov rdi, 1
    lea rsi, [confirm_registration_msg]
    mov rdx, confirm_registration_msg_len
    syscall

    mov rax, [rbx + 121]
    mov rbx, 1000000
    xor rdx, rdx
    div rbx
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [entry_fee_confirm]
    mov rdx, entry_fee_confirm_len
    syscall

    ; Confirm
    call get_yes_no
    test rax, rax
    jnz .done

    ; Register
    lea rdi, [rbx]
    call register_for_tournament

.done:
    call wait_for_enter
    pop rbp
    ret

; ========== VIEW BRACKET UI ==========
ui_view_bracket:
    push rbp
    mov rbp, rsp

    ; Select tournament
    call display_tournament_list

    mov rax, 1
    mov rdi, 1
    lea rsi, [select_tournament_msg]
    mov rdx, select_tournament_msg_len
    syscall

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
    imul rax, 2000
    lea rbx, [active_tournaments.data]
    add rbx, rax

    ; Display bracket
    mov rdi, rbx
    call display_bracket_visual

.done:
    call wait_for_enter
    pop rbp
    ret

; ========== DISPLAY BRACKET VISUAL ==========
; Input: rdi = tournament data pointer
display_bracket_visual:
    push rbp
    mov rbp, rsp
    push r12

    mov r12, rdi

    ; Display title
    mov rax, 1
    mov rdi, 1
    lea rsi, [bracket_title]
    mov rdx, bracket_title_len
    syscall

    ; Check tournament type
    movzx rax, byte [r12 + 112]
    cmp rax, 0
    je .display_8_player

    ; 16-player bracket (TODO)
    jmp .done

.display_8_player:
    ; Display 8-player bracket template
    mov rax, 1
    mov rdi, 1
    lea rsi, [bracket_8_player]
    mov rdx, bracket_8_player_len
    syscall

    ; TODO: Overlay actual player names and results

.done:
    ; Display champion if tournament complete
    cmp byte [r12 + 122], 2
    jne .not_complete

    call display_champion

.not_complete:
    pop r12
    pop rbp
    ret

; ========== PLAY MATCH UI ==========
ui_play_match:
    push rbp
    mov rbp, rsp

    ; Display title
    mov rax, 1
    mov rdi, 1
    lea rsi, [my_match_title]
    mov rdx, my_match_title_len
    syscall

    ; Find my active match
    call find_my_match
    test rax, rax
    js .no_match

    ; Display match details
    mov rdi, rax
    call display_match_details

    ; Ready to play?
    mov rax, 1
    mov rdi, 1
    lea rsi, [ready_to_play_msg]
    mov rdx, ready_to_play_msg_len
    syscall

    call get_yes_no
    test rax, rax
    jnz .done

    ; Play match!
    call execute_tournament_match

    jmp .done

.no_match:
    mov rax, 1
    mov rdi, 1
    lea rsi, [no_match_msg]
    mov rdx, no_match_msg_len
    syscall

.done:
    call wait_for_enter
    pop rbp
    ret

; ========== DISPLAY CHAMPION ==========
display_champion:
    push rbp
    mov rbp, rsp

    ; Display champion banner
    mov rax, 1
    mov rdi, 1
    lea rsi, [champion_banner]
    mov rdx, champion_banner_len
    syscall

    ; Display winner name
    ; TODO: Get from final bracket

    ; Display prize
    mov rax, 1
    mov rdi, 1
    lea rsi, [prize_won_label]
    mov rdx, prize_won_label_len
    syscall

    pop rbp
    ret

; ========== HELPER FUNCTIONS ==========

; Display tournament row
display_tournament_row:
    ; Display one row in tournament list
    ; TODO: Format output
    ret

; Find my active match
find_my_match:
    ; Find match where I'm a participant
    mov rax, -1
    ret

; Display match details
display_match_details:
    ret

; Execute tournament match
execute_tournament_match:
    ret

; Leaderboard UI
ui_leaderboard:
    call wait_for_enter
    ret

; Parse number
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
    lea rsi, [press_enter]
    mov rdx, press_enter_len
    syscall

    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 64
    syscall

    pop rbp
    ret

section .bss
    tournament_type_prompt db "Tournament Type (1=8-player, 2=16-player): ", 0
    tournament_type_prompt_len equ 45
    entry_fee_prompt db "Entry Fee (XRP): ", 0
    entry_fee_prompt_len equ 18
    press_enter db 0xA, "Press Enter to continue...", 0
    press_enter_len equ 28

; ========== EXPORTS ==========
global tournament_ui_main
global display_bracket_visual
global display_tournament_list
global ui_create_tournament
global ui_register_tournament
global ui_view_bracket
global ui_play_match
