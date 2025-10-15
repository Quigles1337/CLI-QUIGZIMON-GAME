; QUIGZIMON PvP Matchmaking & Lobby System
; Pure x86-64 assembly implementation of PvP matchmaking
; Find opponents and create wagered battles!

section .data
    ; ========== MATCHMAKING MENU ==========
    matchmaking_title db 0xA
                      db "╔════════════════════════════════════════════════════╗", 0xA
                      db "║                                                    ║", 0xA
                      db "║         ⚔️  PVP MATCHMAKING LOBBY ⚔️               ║", 0xA
                      db "║                                                    ║", 0xA
                      db "║     Find Opponents and Battle for XRP!            ║", 0xA
                      db "║                                                    ║", 0xA
                      db "╚════════════════════════════════════════════════════╝", 0xA, 0xA, 0
    matchmaking_title_len equ $ - matchmaking_title

    matchmaking_menu db "═══════════════════════════════════════", 0xA
                     db "      MATCHMAKING OPTIONS", 0xA
                     db "═══════════════════════════════════════", 0xA, 0xA
                     db "1) 🎯 Quick Match (Auto-match)", 0xA
                     db "2) 🏆 Ranked Match (ELO-based)", 0xA
                     db "3) 📋 Browse Open Battles", 0xA
                     db "4) ✨ Create Custom Battle", 0xA
                     db "5) 📊 View My Stats", 0xA
                     db "0) 🚪 Exit", 0xA, 0xA
                     db "Enter choice: ", 0
    matchmaking_menu_len equ $ - matchmaking_menu

    ; ========== QUICK MATCH ==========
    quick_match_msg db 0xA, "⏳ Searching for opponent...", 0xA, 0
    quick_match_msg_len equ $ - quick_match_msg

    opponent_found_msg db "✅ Opponent found!", 0xA, 0xA, 0
    opponent_found_msg_len equ $ - opponent_found_msg

    opponent_info_label db "Opponent: ", 0
    opponent_info_label_len equ $ - opponent_info_label

    elo_label db " | ELO: ", 0
    elo_label_len equ $ - elo_label

    wins_label db " | Wins: ", 0
    wins_label_len equ $ - wins_label

    ; ========== BATTLE SETUP ==========
    select_quigzimon_msg db 0xA, "Select your QUIGZIMON for battle:", 0xA, 0xA, 0
    select_quigzimon_msg_len equ $ - select_quigzimon_msg

    enter_wager_msg db 0xA, "Enter wager amount (XRP): ", 0
    enter_wager_msg_len equ $ - enter_wager_msg

    confirm_battle_msg db 0xA, "Confirm battle with ", 0
    confirm_battle_msg_len equ $ - confirm_battle_msg

    wager_label db " XRP wager? (y/n): ", 0
    wager_label_len equ $ - wager_label

    ; ========== OPEN BATTLES ==========
    open_battles_header db 0xA, "╔════════════════════════════════════════════════════╗", 0xA
                        db "║  #  │   Player   │  ELO  │  Wager  │  Status   ║", 0xA
                        db "╠════════════════════════════════════════════════════╣", 0xA, 0
    open_battles_header_len equ $ - open_battles_header

    open_battles_footer db "╚════════════════════════════════════════════════════╝", 0xA, 0
    open_battles_footer_len equ $ - open_battles_footer

    no_open_battles_msg db "No open battles available.", 0xA, 0
    no_open_battles_msg_len equ $ - no_open_battles_msg

    join_battle_prompt db 0xA, "Enter battle number to join (or 0 to go back): ", 0
    join_battle_prompt_len equ $ - join_battle_prompt

    ; ========== STATS DISPLAY ==========
    stats_title db 0xA, "═══════════════════════════════════════", 0xA
                db "      YOUR PVP STATISTICS", 0xA
                db "═══════════════════════════════════════", 0xA, 0xA, 0
    stats_title_len equ $ - stats_title

    elo_stat_label db "ELO Rating: ", 0
    elo_stat_label_len equ $ - elo_stat_label

    total_battles_label db "Total Battles: ", 0
    total_battles_label_len equ $ - total_battles_label

    wins_stat_label db "Wins: ", 0
    wins_stat_label_len equ $ - wins_stat_label

    losses_label db "Losses: ", 0
    losses_label_len equ $ - losses_label

    win_rate_label db "Win Rate: ", 0
    win_rate_label_len equ $ - win_rate_label

    percent_sign db "%", 0xA, 0
    percent_sign_len equ $ - percent_sign

    total_earnings_label db "Total Earnings: ", 0
    total_earnings_label_len equ $ - total_earnings_label

section .bss
    ; ========== PLAYER STATS ==========
    player_elo resq 1               ; ELO rating (starts at 1000)
    player_total_battles resq 1
    player_wins resq 1
    player_losses resq 1
    player_earnings resq 1          ; Total XRP won

    ; ========== MATCHMAKING STATE ==========
    matched_opponent_addr resb 48
    matched_opponent_elo resq 1
    matched_opponent_wins resq 1

    ; ========== OPEN BATTLES LIST ==========
    open_battles_count resq 1
    open_battles_list resb 5000     ; 25 battles * 200 bytes each

    ; Battle structure (200 bytes):
    ; - battle_id (64 bytes)
    ; - creator_address (48 bytes)
    ; - creator_elo (8 bytes)
    ; - wager_amount (8 bytes)
    ; - status (1 byte): 0=waiting, 1=in_progress
    ; - padding (71 bytes)

    ; ========== CURRENT BATTLE ==========
    current_battle_id resb 64
    selected_wager resq 1
    selected_quigzimon_index resq 1

section .text
    global matchmaking_main
    global find_quick_match
    global find_ranked_match
    global browse_open_battles
    global create_custom_battle
    global view_player_stats

    extern pvp_create_wager_battle
    extern pvp_join_wager_battle
    extern pvp_submit_move
    extern pvp_resolve_battle
    extern pvp_claim_prize
    extern player_party
    extern player_party_count
    extern print_string
    extern print_number
    extern get_yes_no

; ========== MAIN MATCHMAKING LOBBY ==========
matchmaking_main:
    push rbp
    mov rbp, rsp

    ; Initialize player ELO if needed
    mov rax, [player_elo]
    test rax, rax
    jnz .has_elo
    mov qword [player_elo], 1000    ; Starting ELO

.has_elo:
.main_loop:
    ; Display title
    mov rax, 1
    mov rdi, 1
    lea rsi, [matchmaking_title]
    mov rdx, matchmaking_title_len
    syscall

    ; Display menu
    mov rax, 1
    mov rdi, 1
    lea rsi, [matchmaking_menu]
    mov rdx, matchmaking_menu_len
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
    je .quick_match
    cmp al, 2
    je .ranked_match
    cmp al, 3
    je .browse_battles
    cmp al, 4
    je .create_battle
    cmp al, 5
    je .view_stats

    jmp .main_loop

.quick_match:
    call find_quick_match
    test rax, rax
    jz .start_battle
    jmp .main_loop

.ranked_match:
    call find_ranked_match
    test rax, rax
    jz .start_battle
    jmp .main_loop

.browse_battles:
    call browse_open_battles
    jmp .main_loop

.create_battle:
    call create_custom_battle
    jmp .main_loop

.view_stats:
    call view_player_stats
    jmp .main_loop

.start_battle:
    ; Battle matched - start wagered battle!
    call execute_pvp_battle
    jmp .main_loop

.exit:
    pop rbp
    ret

; ========== FIND QUICK MATCH ==========
; Auto-match with any available opponent
; Returns: rax = 0 if matched, -1 if canceled
find_quick_match:
    push rbp
    mov rbp, rsp

    ; Display searching message
    mov rax, 1
    mov rdi, 1
    lea rsi, [quick_match_msg]
    mov rdx, quick_match_msg_len
    syscall

    ; Search for opponent (simplified - would query XRPL/matchmaking server)
    call search_for_opponent
    test rax, rax
    jnz .not_found

    ; Opponent found!
    mov rax, 1
    mov rdi, 1
    lea rsi, [opponent_found_msg]
    mov rdx, opponent_found_msg_len
    syscall

    ; Display opponent info
    call display_opponent_info

    ; Setup battle
    call setup_battle_parameters
    test rax, rax
    jnz .canceled

    xor rax, rax
    pop rbp
    ret

.not_found:
.canceled:
    mov rax, -1
    pop rbp
    ret

; ========== FIND RANKED MATCH ==========
; Match based on similar ELO
; Returns: rax = 0 if matched, -1 if canceled
find_ranked_match:
    push rbp
    mov rbp, rsp

    ; Display searching message
    mov rax, 1
    mov rdi, 1
    lea rsi, [quick_match_msg]
    mov rdx, quick_match_msg_len
    syscall

    ; Search for opponent within ELO range (+/- 100)
    mov rdi, [player_elo]
    sub rdi, 100
    mov rsi, [player_elo]
    add rsi, 100
    call search_for_opponent_elo_range
    test rax, rax
    jnz .not_found

    ; Opponent found
    mov rax, 1
    mov rdi, 1
    lea rsi, [opponent_found_msg]
    mov rdx, opponent_found_msg_len
    syscall

    call display_opponent_info
    call setup_battle_parameters
    test rax, rax
    jnz .canceled

    xor rax, rax
    pop rbp
    ret

.not_found:
.canceled:
    mov rax, -1
    pop rbp
    ret

; ========== BROWSE OPEN BATTLES ==========
browse_open_battles:
    push rbp
    mov rbp, rsp

    ; Fetch open battles from XRPL
    call fetch_open_battles
    test rax, rax
    jz .no_battles

    ; Display header
    mov rax, 1
    mov rdi, 1
    lea rsi, [open_battles_header]
    mov rdx, open_battles_header_len
    syscall

    ; Display each battle
    mov r12, 0
    mov r13, [open_battles_count]

.display_loop:
    cmp r12, r13
    jge .done_display

    mov rdi, r12
    call display_battle_row

    inc r12
    jmp .display_loop

.done_display:
    ; Display footer
    mov rax, 1
    mov rdi, 1
    lea rsi, [open_battles_footer]
    mov rdx, open_battles_footer_len
    syscall

    ; Prompt to join
    mov rax, 1
    mov rdi, 1
    lea rsi, [join_battle_prompt]
    mov rdx, join_battle_prompt_len
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

    ; Join selected battle
    dec rax
    mov rdi, rax
    call join_selected_battle

.done:
    pop rbp
    ret

.no_battles:
    mov rax, 1
    mov rdi, 1
    lea rsi, [no_open_battles_msg]
    mov rdx, no_open_battles_msg_len
    syscall
    call wait_for_enter
    pop rbp
    ret

; ========== CREATE CUSTOM BATTLE ==========
create_custom_battle:
    push rbp
    mov rbp, rsp

    ; Select QUIGZIMON
    call select_battle_quigzimon
    test rax, rax
    jl .canceled

    mov [selected_quigzimon_index], rax

    ; Enter wager
    mov rax, 1
    mov rdi, 1
    lea rsi, [enter_wager_msg]
    mov rdx, enter_wager_msg_len
    syscall

    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 64
    syscall

    lea rdi, [input_buffer]
    call parse_number
    imul rax, 1000000       ; Convert XRP to drops
    mov [selected_wager], rax

    ; Create battle on blockchain
    mov rax, [selected_quigzimon_index]
    imul rax, 15
    lea rdi, [player_party]
    add rdi, rax
    mov rsi, [selected_wager]
    xor rdx, rdx            ; No specific opponent yet
    call pvp_create_wager_battle

    ; Display waiting message
    ; (handled by pvp_create_wager_battle)

.canceled:
    pop rbp
    ret

; ========== VIEW PLAYER STATS ==========
view_player_stats:
    push rbp
    mov rbp, rsp

    ; Display title
    mov rax, 1
    mov rdi, 1
    lea rsi, [stats_title]
    mov rdx, stats_title_len
    syscall

    ; ELO Rating
    mov rax, 1
    mov rdi, 1
    lea rsi, [elo_stat_label]
    mov rdx, elo_stat_label_len
    syscall

    mov rax, [player_elo]
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    ; Total Battles
    mov rax, 1
    mov rdi, 1
    lea rsi, [total_battles_label]
    mov rdx, total_battles_label_len
    syscall

    mov rax, [player_total_battles]
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    ; Wins
    mov rax, 1
    mov rdi, 1
    lea rsi, [wins_stat_label]
    mov rdx, wins_stat_label_len
    syscall

    mov rax, [player_wins]
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    ; Losses
    mov rax, 1
    mov rdi, 1
    lea rsi, [losses_label]
    mov rdx, losses_label_len
    syscall

    mov rax, [player_losses]
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    ; Win Rate
    mov rax, 1
    mov rdi, 1
    lea rsi, [win_rate_label]
    mov rdx, win_rate_label_len
    syscall

    mov rax, [player_wins]
    imul rax, 100
    mov rbx, [player_total_battles]
    test rbx, rbx
    jz .zero_battles
    xor rdx, rdx
    div rbx
    jmp .display_rate

.zero_battles:
    xor rax, rax

.display_rate:
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [percent_sign]
    mov rdx, percent_sign_len
    syscall

    ; Total Earnings
    mov rax, 1
    mov rdi, 1
    lea rsi, [total_earnings_label]
    mov rdx, total_earnings_label_len
    syscall

    mov rax, [player_earnings]
    mov rbx, 1000000
    xor rdx, rdx
    div rbx
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [xrp_suffix]
    mov rdx, xrp_suffix_len
    syscall

    call wait_for_enter
    pop rbp
    ret

; ========== HELPER FUNCTIONS ==========

; Search for opponent (simplified)
search_for_opponent:
    ; In real implementation, would query matchmaking server
    ; For now, mock opponent
    xor rax, rax
    mov qword [matched_opponent_elo], 1050
    mov qword [matched_opponent_wins], 5
    ret

; Search for opponent in ELO range
search_for_opponent_elo_range:
    ; Similar to search_for_opponent but with ELO filtering
    call search_for_opponent
    ret

; Display opponent info
display_opponent_info:
    push rbp
    mov rbp, rsp

    mov rax, 1
    mov rdi, 1
    lea rsi, [opponent_info_label]
    mov rdx, opponent_info_label_len
    syscall

    ; Display address (shortened)
    lea rsi, [matched_opponent_addr]
    mov rcx, 12
    call print_string_len

    ; Display ELO
    mov rax, 1
    mov rdi, 1
    lea rsi, [elo_label]
    mov rdx, elo_label_len
    syscall

    mov rax, [matched_opponent_elo]
    call print_number

    ; Display wins
    mov rax, 1
    mov rdi, 1
    lea rsi, [wins_label]
    mov rdx, wins_label_len
    syscall

    mov rax, [matched_opponent_wins]
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    pop rbp
    ret

; Setup battle parameters
setup_battle_parameters:
    push rbp
    mov rbp, rsp

    ; Select QUIGZIMON
    call select_battle_quigzimon
    test rax, rax
    jl .canceled

    mov [selected_quigzimon_index], rax

    ; Enter wager
    mov rax, 1
    mov rdi, 1
    lea rsi, [enter_wager_msg]
    mov rdx, enter_wager_msg_len
    syscall

    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 64
    syscall

    lea rdi, [input_buffer]
    call parse_number
    imul rax, 1000000
    mov [selected_wager], rax

    ; Confirm
    mov rax, 1
    mov rdi, 1
    lea rsi, [confirm_battle_msg]
    mov rdx, confirm_battle_msg_len
    syscall

    mov rax, [selected_wager]
    mov rbx, 1000000
    xor rdx, rdx
    div rbx
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [wager_label]
    mov rdx, wager_label_len
    syscall

    call get_yes_no
    test rax, rax
    jnz .canceled

    xor rax, rax
    pop rbp
    ret

.canceled:
    mov rax, -1
    pop rbp
    ret

; Select QUIGZIMON for battle
select_battle_quigzimon:
    push rbp
    mov rbp, rsp

    ; Display party
    mov rax, 1
    mov rdi, 1
    lea rsi, [select_quigzimon_msg]
    mov rdx, select_quigzimon_msg_len
    syscall

    ; TODO: Display party members
    ; For now, return 0 (first QUIGZIMON)

    xor rax, rax
    pop rbp
    ret

; Execute PvP battle
execute_pvp_battle:
    push rbp
    mov rbp, rsp

    ; Start battle loop
    mov qword [battle_turn], 1

.battle_loop:
    ; Player chooses move
    call display_battle_menu
    call get_battle_move_input
    mov rdi, rax
    call pvp_submit_move

    ; Resolve turn
    call pvp_resolve_battle
    cmp rax, 0
    je .i_won
    cmp rax, 1
    je .i_lost
    cmp rax, 2
    je .draw

    ; Battle continues
    jmp .battle_loop

.i_won:
    ; Display victory
    mov rax, 1
    mov rdi, 1
    lea rsi, [you_win_msg]
    mov rdx, you_win_msg_len
    syscall

    ; Claim prize
    xor rdi, rdi
    call pvp_claim_prize

    ; Update stats
    inc qword [player_wins]
    inc qword [player_total_battles]
    mov rax, [selected_wager]
    shl rax, 1
    add [player_earnings], rax

    ; Update ELO (+25 for win)
    add qword [player_elo], 25

    jmp .done

.i_lost:
    ; Display defeat
    mov rax, 1
    mov rdi, 1
    lea rsi, [you_lose_msg]
    mov rdx, you_lose_msg_len
    syscall

    ; Update stats
    inc qword [player_losses]
    inc qword [player_total_battles]

    ; Update ELO (-20 for loss)
    sub qword [player_elo], 20

    jmp .done

.draw:
    ; Handle draw (refund wagers)
    jmp .done

.done:
    call wait_for_enter
    pop rbp
    ret

; Display battle menu
display_battle_menu:
    ; Similar to regular battle menu
    ret

; Get battle move input
get_battle_move_input:
    ; Get move from player (1-4)
    mov rax, 1
    ret

; Fetch open battles
fetch_open_battles:
    ; Query XRPL for open battles
    mov qword [open_battles_count], 0
    xor rax, rax
    ret

; Display battle row
display_battle_row:
    ; Display one row in open battles list
    ret

; Join selected battle
join_selected_battle:
    push rbp
    mov rbp, rsp
    push r12

    mov r12, rdi

    ; Get battle details
    imul r12, 200
    lea rbx, [open_battles_list]
    add rbx, r12

    ; Get battle ID
    lea rdi, [rbx]
    mov rcx, 64
    lea rsi, [current_battle_id]
    rep movsb

    ; Select QUIGZIMON
    call select_battle_quigzimon
    mov [selected_quigzimon_index], rax

    ; Join battle
    imul rax, 15
    lea rsi, [player_party]
    add rsi, rax
    lea rdi, [current_battle_id]
    call pvp_join_wager_battle

    pop r12
    pop rbp
    ret

section .bss
    input_buffer resb 64
    newline db 0xA
    xrp_suffix db " XRP", 0xA, 0

    extern parse_number
    extern wait_for_enter
    extern print_string_len

; ========== EXPORTS ==========
global matchmaking_main
global find_quick_match
global find_ranked_match
global browse_open_battles
global create_custom_battle
global view_player_stats
global player_elo
global player_wins
global player_losses
global player_total_battles
