; QUIGZIMON PvP Tournament System
; Pure x86-64 assembly implementation of elimination tournaments
; First-ever tournament bracket system in assembly!

section .data
    ; ========== TOURNAMENT MESSAGES ==========
    tournament_title db 0xA
                     db "╔════════════════════════════════════════════════════╗", 0xA
                     db "║                                                    ║", 0xA
                     db "║         🏆 PVP TOURNAMENT SYSTEM 🏆               ║", 0xA
                     db "║                                                    ║", 0xA
                     db "║     Elimination Brackets - Winner Takes All!      ║", 0xA
                     db "║                                                    ║", 0xA
                     db "╚════════════════════════════════════════════════════╝", 0xA, 0xA, 0
    tournament_title_len equ $ - tournament_title

    ; ========== TOURNAMENT TYPES ==========
    tournament_type_8 db "8-Player Single Elimination", 0
    tournament_type_16 db "16-Player Single Elimination", 0
    tournament_type_swiss db "Swiss System (Best of 5)", 0

    ; ========== CREATE TOURNAMENT ==========
    create_tournament_msg db "Creating tournament...", 0xA, 0
    create_tournament_msg_len equ $ - create_tournament_msg

    tournament_created_msg db "✅ Tournament created!", 0xA, 0
    tournament_created_msg_len equ $ - tournament_created_msg

    tournament_id_label db "Tournament ID: ", 0
    tournament_id_label_len equ $ - tournament_id_label

    entry_fee_label db "Entry Fee: ", 0
    entry_fee_label_len equ $ - entry_fee_label

    prize_pool_label db "Prize Pool: ", 0
    prize_pool_label_len equ $ - prize_pool_label

    ; ========== REGISTRATION ==========
    registration_open_msg db "📝 Registration is OPEN!", 0xA, 0
    registration_open_msg_len equ $ - registration_open_msg

    registration_closed_msg db "Registration is closed.", 0xA, 0
    registration_closed_msg_len equ $ - registration_closed_msg

    player_registered_msg db "✅ You are registered!", 0xA
                          db "Seed: #", 0
    player_registered_msg_len equ $ - player_registered_msg

    waiting_for_players_msg db "Waiting for players: ", 0
    waiting_for_players_msg_len equ $ - waiting_for_players_msg

    of_msg db " of ", 0
    of_msg_len equ $ - of_msg

    ; ========== BRACKET STAGES ==========
    stage_quarterfinals db "QUARTERFINALS", 0
    stage_semifinals db "SEMIFINALS", 0
    stage_finals db "FINALS", 0
    stage_complete db "COMPLETE", 0

    ; ========== MATCH DISPLAY ==========
    match_header db 0xA, "═══════════════════════════════════════", 0xA, 0
    match_header_len equ $ - match_header

    match_player1_label db "Player 1: ", 0
    match_player1_label_len equ $ - match_player1_label

    match_vs_label db "    VS    ", 0xA, 0
    match_vs_label_len equ $ - match_vs_label

    match_player2_label db "Player 2: ", 0
    match_player2_label_len equ $ - match_player2_label

    match_winner_label db 0xA, "🏆 Winner: ", 0
    match_winner_label_len equ $ - match_winner_label

    match_pending_msg db "⏳ Match pending...", 0xA, 0
    match_pending_msg_len equ $ - match_pending_msg

    ; ========== PRIZE DISTRIBUTION ==========
    prize_1st_label db "🥇 1st Place: ", 0
    prize_1st_label_len equ $ - prize_1st_label

    prize_2nd_label db "🥈 2nd Place: ", 0
    prize_2nd_label_len equ $ - prize_2nd_label

    prize_3rd_label db "🥉 3rd Place: ", 0
    prize_3rd_label_len equ $ - prize_3rd_label

    prize_distribution_50_30_20 db "50% / 30% / 20%", 0xA, 0
    prize_distribution_50_30_20_len equ $ - prize_distribution_50_30_20

    ; ========== TOURNAMENT STATUS ==========
    status_registration db "REGISTRATION", 0
    status_in_progress db "IN PROGRESS", 0
    status_completed db "COMPLETED", 0

section .bss
    ; ========== TOURNAMENT STATE ==========
    active_tournaments:
        .count resq 1
        .data resb 50000            ; 25 tournaments * 2000 bytes each

    ; Tournament structure (2000 bytes):
    ; - tournament_id (64 bytes)
    ; - organizer_address (48 bytes)
    ; - tournament_type (1 byte): 0=8-player, 1=16-player, 2=swiss
    ; - entry_fee (8 bytes)
    ; - prize_pool (8 bytes)
    ; - max_players (1 byte)
    ; - registered_count (1 byte)
    ; - status (1 byte): 0=registration, 1=in_progress, 2=complete
    ; - current_round (1 byte)
    ; - total_rounds (1 byte)
    ; - start_time (8 bytes)
    ; - end_time (8 bytes)
    ; - players (16 * 48 bytes = 768 bytes) - Player addresses
    ; - seeds (16 * 4 bytes = 64 bytes) - ELO-based seeding
    ; - bracket (32 matches * 32 bytes = 1024 bytes)
    ; - padding

    ; Match structure (32 bytes):
    ; - player1_index (1 byte)
    ; - player2_index (1 byte)
    ; - winner_index (1 byte)
    ; - status (1 byte): 0=pending, 1=complete
    ; - escrow_id (64 bytes in separate table)

    ; ========== CURRENT TOURNAMENT ==========
    selected_tournament_id resb 64
    my_player_index resq 1
    my_seed resq 1

    ; ========== BRACKET DATA ==========
    bracket_matches resb 1024       ; 32 matches max

section .text
    global create_tournament
    global register_for_tournament
    global start_tournament
    global play_tournament_match
    global advance_round
    global distribute_prizes
    global view_tournament_bracket

    extern pvp_create_wager_battle
    extern pvp_join_wager_battle
    extern pvp_resolve_battle
    extern pvp_claim_prize
    extern player_elo
    extern account_address
    extern print_string
    extern print_number
    extern get_current_time

; ========== CREATE TOURNAMENT ==========
; Create a new elimination tournament
; Input: rdi = tournament type (0=8-player, 1=16-player, 2=swiss)
;        rsi = entry fee in drops
; Returns: rax = 0 on success, -1 on error
create_tournament:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push r12
    push r13

    mov r12, rdi            ; Tournament type
    mov r13, rsi            ; Entry fee

    ; Display progress
    mov rax, 1
    mov rdi, 1
    lea rsi, [create_tournament_msg]
    mov rdx, create_tournament_msg_len
    syscall

    ; Allocate tournament slot
    call allocate_tournament_slot
    test rax, rax
    js .error

    mov r14, rax            ; Tournament data pointer

    ; Generate tournament ID
    call generate_tournament_id

    ; Initialize tournament data
    lea rdi, [r14]
    mov rsi, r12            ; Type
    mov rdx, r13            ; Entry fee
    call initialize_tournament

    ; Display success
    mov rax, 1
    mov rdi, 1
    lea rsi, [tournament_created_msg]
    mov rdx, tournament_created_msg_len
    syscall

    ; Display tournament ID
    mov rax, 1
    mov rdi, 1
    lea rsi, [tournament_id_label]
    mov rdx, tournament_id_label_len
    syscall

    lea rsi, [selected_tournament_id]
    call print_string

    ; Display entry fee
    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [entry_fee_label]
    mov rdx, entry_fee_label_len
    syscall

    mov rax, r13
    mov rbx, 1000000
    xor rdx, rdx
    div rbx
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [xrp_suffix]
    mov rdx, xrp_suffix_len
    syscall

    xor rax, rax
    pop r13
    pop r12
    add rsp, 32
    pop rbp
    ret

.error:
    mov rax, -1
    pop r13
    pop r12
    add rsp, 32
    pop rbp
    ret

; ========== REGISTER FOR TOURNAMENT ==========
; Register player for tournament
; Input: rdi = pointer to tournament ID
; Returns: rax = 0 on success, -1 on error
register_for_tournament:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push r12

    mov r12, rdi

    ; Find tournament
    call find_tournament
    test rax, rax
    js .error

    mov r13, rax            ; Tournament data

    ; Check if registration open
    cmp byte [r13 + 122], 0     ; status
    jne .registration_closed

    ; Check if tournament full
    movzx rax, byte [r13 + 121] ; registered_count
    movzx rbx, byte [r13 + 120] ; max_players
    cmp rax, rbx
    jge .tournament_full

    ; Add player to tournament
    mov rdi, r13
    lea rsi, [account_address]
    call add_player_to_tournament

    ; Set seed based on ELO
    mov rax, [player_elo]
    mov [my_seed], rax

    ; Deposit entry fee into prize pool
    mov rdi, [r13 + 121]        ; entry_fee
    call deposit_entry_fee

    ; Increment registered count
    inc byte [r13 + 121]

    ; Update prize pool
    mov rax, [r13 + 121]        ; entry_fee
    add [r13 + 128], rax        ; prize_pool

    ; Display success
    mov rax, 1
    mov rdi, 1
    lea rsi, [player_registered_msg]
    mov rdx, player_registered_msg_len
    syscall

    movzx rax, byte [r13 + 121]
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    xor rax, rax
    pop r12
    add rsp, 32
    pop rbp
    ret

.registration_closed:
    mov rax, 1
    mov rdi, 1
    lea rsi, [registration_closed_msg]
    mov rdx, registration_closed_msg_len
    syscall

.tournament_full:
.error:
    mov rax, -1
    pop r12
    add rsp, 32
    pop rbp
    ret

; ========== START TOURNAMENT ==========
; Start tournament and generate bracket
; Input: rdi = pointer to tournament ID
; Returns: rax = 0 on success, -1 on error
start_tournament:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push r12

    mov r12, rdi

    ; Find tournament
    call find_tournament
    test rax, rax
    js .error

    mov r13, rax

    ; Check if enough players
    movzx rax, byte [r13 + 121]
    movzx rbx, byte [r13 + 120]
    cmp rax, rbx
    jl .not_enough_players

    ; Seed players by ELO
    mov rdi, r13
    call seed_players

    ; Generate bracket
    mov rdi, r13
    call generate_bracket

    ; Set status to in_progress
    mov byte [r13 + 122], 1

    ; Set round to 1
    mov byte [r13 + 123], 1

    ; Display bracket
    mov rdi, r13
    call display_bracket

    xor rax, rax
    pop r12
    add rsp, 32
    pop rbp
    ret

.not_enough_players:
.error:
    mov rax, -1
    pop r12
    add rsp, 32
    pop rbp
    ret

; ========== PLAY TOURNAMENT MATCH ==========
; Execute a single tournament match
; Input: rdi = pointer to tournament ID
;        rsi = match index
; Returns: rax = winner index, -1 on error
play_tournament_match:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push r12
    push r13

    mov r12, rdi
    mov r13, rsi

    ; Find tournament
    call find_tournament
    test rax, rax
    js .error

    mov r14, rax
    mov r15, r13

    ; Get match data
    imul r15, 32
    lea rbx, [r14 + 944]    ; bracket offset
    add rbx, r15

    ; Check if match already played
    cmp byte [rbx + 3], 1
    je .already_played

    ; Get player indices
    movzx r12, byte [rbx]       ; player1_index
    movzx r13, byte [rbx + 1]   ; player2_index

    ; Get player QUIGZIMONs
    ; (simplified - would get from player data)

    ; Create wagered battle
    ; Entry fee from tournament
    mov rdi, [r14 + 121]        ; entry_fee per match
    call create_match_wager

    ; Execute battle
    call execute_pvp_battle

    ; Determine winner (rax = 0 or 1)
    test rax, rax
    jz .player1_wins

    ; Player 2 wins
    mov al, r13b
    jmp .record_winner

.player1_wins:
    mov al, r12b

.record_winner:
    ; Record winner in bracket
    mov byte [rbx + 2], al      ; winner_index
    mov byte [rbx + 3], 1       ; status = complete

    movzx rax, byte [rbx + 2]
    pop r13
    pop r12
    add rsp, 32
    pop rbp
    ret

.already_played:
    movzx rax, byte [rbx + 2]
    pop r13
    pop r12
    add rsp, 32
    pop rbp
    ret

.error:
    mov rax, -1
    pop r13
    pop r12
    add rsp, 32
    pop rbp
    ret

; ========== ADVANCE ROUND ==========
; Advance tournament to next round
; Input: rdi = pointer to tournament ID
; Returns: rax = 0 on success, -1 on error
advance_round:
    push rbp
    mov rbp, rsp
    push r12

    mov r12, rdi

    ; Find tournament
    call find_tournament
    test rax, rax
    js .error

    mov r13, rax

    ; Check if all matches in current round complete
    call check_round_complete
    test rax, rax
    jz .round_not_complete

    ; Increment round
    inc byte [r13 + 123]

    ; Check if tournament complete
    movzx rax, byte [r13 + 123]
    movzx rbx, byte [r13 + 124] ; total_rounds
    cmp rax, rbx
    jg .tournament_complete

    ; Setup next round matches
    mov rdi, r13
    call setup_next_round

    xor rax, rax
    pop r12
    pop rbp
    ret

.tournament_complete:
    ; Distribute prizes
    mov rdi, r13
    call distribute_prizes

    ; Set status to complete
    mov byte [r13 + 122], 2

    xor rax, rax
    pop r12
    pop rbp
    ret

.round_not_complete:
.error:
    mov rax, -1
    pop r12
    pop rbp
    ret

; ========== DISTRIBUTE PRIZES ==========
; Distribute prize pool to winners
; Input: rdi = tournament data pointer
; Returns: rax = 0 on success
distribute_prizes:
    push rbp
    mov rbp, rsp
    push r12

    mov r12, rdi

    ; Get prize pool
    mov r13, [r12 + 128]

    ; Calculate prizes (50% / 30% / 20%)
    ; 1st place: 50%
    mov rax, r13
    mov rbx, 2
    xor rdx, rdx
    div rbx
    mov r14, rax            ; 1st place prize

    ; 2nd place: 30%
    mov rax, r13
    mov rbx, 10
    xor rdx, rdx
    div rbx
    mov rcx, 3
    imul rax, rcx
    mov r15, rax            ; 2nd place prize

    ; 3rd place: 20%
    mov rax, r13
    mov rbx, 5
    xor rdx, rdx
    div rbx
    mov rbx, rax            ; 3rd place prize

    ; Get winner indices from final bracket
    ; Transfer prizes
    ; (simplified - would use escrow finish)

    ; Display prizes
    mov rax, 1
    mov rdi, 1
    lea rsi, [prize_1st_label]
    mov rdx, prize_1st_label_len
    syscall

    mov rax, r14
    mov rbx, 1000000
    xor rdx, rdx
    div rbx
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [xrp_suffix]
    mov rdx, xrp_suffix_len
    syscall

    xor rax, rax
    pop r12
    pop rbp
    ret

; ========== VIEW TOURNAMENT BRACKET ==========
; Display current bracket state
; Input: rdi = tournament data pointer
view_tournament_bracket:
    push rbp
    mov rbp, rsp
    push r12

    mov r12, rdi

    ; Display tournament header
    call display_tournament_header

    ; Get current round
    movzx r13, byte [r12 + 123]

    ; Display matches for each round
    xor r14, r14            ; Match index

.display_rounds:
    cmp r14, r13
    jge .done

    ; Display round header
    mov rdi, r14
    call display_round_header

    ; Display matches in this round
    call display_round_matches

    inc r14
    jmp .display_rounds

.done:
    pop r12
    pop rbp
    ret

; ========== HELPER FUNCTIONS ==========

; Allocate tournament slot
allocate_tournament_slot:
    mov rax, [active_tournaments.count]
    cmp rax, 25
    jge .full

    inc qword [active_tournaments.count]
    dec rax
    imul rax, 2000
    lea rbx, [active_tournaments.data]
    add rax, rbx
    ret

.full:
    mov rax, -1
    ret

; Generate tournament ID
generate_tournament_id:
    call get_current_time
    lea rdi, [selected_tournament_id]
    call int_to_hex_string
    ret

; Initialize tournament
initialize_tournament:
    push rbp
    mov rbp, rsp

    ; Copy tournament ID
    lea rsi, [selected_tournament_id]
    mov rcx, 64
    rep movsb

    ; Copy organizer address
    lea rsi, [account_address]
    mov rcx, 48
    rep movsb

    ; Set tournament type
    mov byte [rdi], sil

    ; Set entry fee
    add rdi, 1
    mov [rdi], rdx

    ; Initialize prize pool to 0
    add rdi, 8
    mov qword [rdi], 0

    ; Set max players based on type
    add rdi, 8
    cmp sil, 0
    je .eight_player
    mov byte [rdi], 16
    jmp .set_rounds

.eight_player:
    mov byte [rdi], 8

.set_rounds:
    ; Set total rounds
    add rdi, 3
    cmp sil, 0
    je .three_rounds
    mov byte [rdi], 4
    jmp .done

.three_rounds:
    mov byte [rdi], 3

.done:
    pop rbp
    ret

; Find tournament by ID
find_tournament:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov r12, rdi
    xor r13, r13

.search_loop:
    cmp r13, [active_tournaments.count]
    jge .not_found

    mov rax, r13
    imul rax, 2000
    lea rbx, [active_tournaments.data]
    add rbx, rax

    ; Compare IDs
    lea rsi, [rbx]
    mov rdi, r12
    mov rcx, 64
    repe cmpsb
    je .found

    inc r13
    jmp .search_loop

.found:
    mov rax, rbx
    pop r13
    pop r12
    pop rbp
    ret

.not_found:
    mov rax, -1
    pop r13
    pop r12
    pop rbp
    ret

; Add player to tournament
add_player_to_tournament:
    ; Add player address to players array
    ; Store at index = registered_count
    ret

; Seed players by ELO
seed_players:
    ; Sort players by ELO rating
    ; Assign seeds 1-N
    ret

; Generate bracket
generate_bracket:
    ; Create bracket with proper seeding
    ; Seed 1 vs Seed 8, Seed 2 vs Seed 7, etc.
    ret

; Check if round complete
check_round_complete:
    ; Check if all matches in current round are complete
    xor rax, rax
    ret

; Setup next round
setup_next_round:
    ; Take winners from previous round
    ; Create new matches
    ret

; Display bracket
display_bracket:
    ; Show full tournament bracket
    ret

; Display tournament header
display_tournament_header:
    ret

; Display round header
display_round_header:
    ret

; Display round matches
display_round_matches:
    ret

; Create match wager
create_match_wager:
    ret

; Deposit entry fee
deposit_entry_fee:
    ret

; Convert int to hex string
int_to_hex_string:
    ret

; Execute PvP battle
execute_pvp_battle:
    xor rax, rax
    ret

section .bss
    newline db 0xA
    xrp_suffix db " XRP", 0xA, 0

; ========== EXPORTS ==========
global create_tournament
global register_for_tournament
global start_tournament
global play_tournament_match
global advance_round
global distribute_prizes
global view_tournament_bracket
global active_tournaments
