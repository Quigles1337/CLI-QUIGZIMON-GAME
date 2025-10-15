; QUIGZIMON AI Tournament System
; Multi-agent battles with personality archetypes
; First-ever AI vs AI Pokemon-style battle system in assembly!

section .data
    ; ========== TOURNAMENT PARAMETERS ==========
    max_agents equ 8
    tournament_rounds equ 3     ; 8 -> 4 -> 2 -> 1 (winner)

    ; ========== PERSONALITY ARCHETYPES ==========
    ; Each archetype modifies action selection probabilities

    personality_aggressive equ 0
    personality_defensive equ 1
    personality_balanced equ 2
    personality_strategic equ 3

    ; Aggressive: Favors attack moves
    aggressive_attack_bonus dw 2048     ; +50% to attack
    aggressive_defense_penalty dw -1024 ; -25% to defense

    ; Defensive: Favors defensive moves
    defensive_defense_bonus dw 2048
    defensive_attack_penalty dw -512

    ; Balanced: No bonuses, pure Q-learning
    balanced_bonus dw 0

    ; Strategic: Favors type advantage exploitation
    strategic_type_bonus dw 3072        ; +75% when type advantage
    strategic_type_penalty dw -2048     ; -50% when disadvantage

    ; ========== AGENT STRUCTURE ==========
    ; Each agent has:
    ; - ID (1 byte)
    ; - Personality (1 byte)
    ; - Q-table (1536 bytes)
    ; - Win count (2 bytes)
    ; - Total battles (2 bytes)
    ; - QUIGZIMON roster (6 * 33 bytes)
    ; Total: 1740 bytes per agent

    agent_size equ 1740

    ; ========== TOURNAMENT MESSAGES ==========
    tournament_banner db 0xA
    db "========================================", 0xA
    db "   QUIGZIMON AI CHAMPIONSHIP TOURNAMENT", 0xA
    db "========================================", 0xA, 0xA, 0
    tournament_banner_len equ $ - tournament_banner

    round_msg db 0xA, ">>> ROUND ", 0
    round_msg_len equ $ - round_msg

    match_msg db 0xA, "MATCH: Agent ", 0
    match_msg_len equ $ - match_msg

    vs_msg db " VS Agent ", 0
    vs_msg_len equ $ - vs_msg

    personality_msg db "Personality: ", 0
    personality_msg_len equ $ - personality_msg

    aggressive_name db "AGGRESSIVE", 0xA, 0
    defensive_name db "DEFENSIVE", 0xA, 0
    balanced_name db "BALANCED", 0xA, 0
    strategic_name db "STRATEGIC", 0xA, 0

    winner_msg db 0xA, "*** WINNER: Agent ", 0
    winner_msg_len equ $ - winner_msg

    champion_msg db 0xA, 0xA
    db "========================================", 0xA
    db "         TOURNAMENT CHAMPION!", 0xA
    db "              Agent ", 0
    champion_msg_len equ $ - champion_msg

    spectator_msg db "[SPECTATOR MODE] Turn ", 0
    spectator_msg_len equ $ - spectator_msg

    action_names:
        db "ATTACK  ", 0
        db "SPECIAL ", 0
        db "DEFEND  ", 0
        db "STATUS  ", 0

section .bss
    ; ========== TOURNAMENT STATE ==========
    num_agents resb 1
    current_round resb 1

    ; Agent pool (8 agents max)
    agents resb 13920           ; 8 * 1740 bytes

    ; Tournament bracket
    bracket_round1 resb 8       ; Agent IDs for round 1
    bracket_round2 resb 4       ; Winners advance
    bracket_finals resb 2       ; Final two
    champion resb 1

    ; Current match state
    agent1_id resb 1
    agent2_id resb 1
    agent1_personality resb 1
    agent2_personality resb 1

    ; Battle state for AI vs AI
    agent1_quigzimon resb 33    ; Current fighter
    agent2_quigzimon resb 33

    turn_counter resw 1
    max_turns equ 100           ; Prevent infinite battles

    ; Statistics
    total_matches resw 1
    total_turns resw 1

section .text

; ========== INITIALIZATION ==========

; Initialize tournament with N agents
; Input: rdi = number of agents (2-8)
tournament_init:
    push rbp
    mov rbp, rsp
    push rbx
    push r12

    ; Validate agent count
    cmp rdi, 2
    jl .error
    cmp rdi, 8
    jg .error

    mov byte [num_agents], dil
    mov byte [current_round], 0
    mov word [total_matches], 0
    mov word [total_turns], 0

    ; Initialize each agent
    xor r12, r12
.init_loop:
    cmp r12b, byte [num_agents]
    jge .done

    mov rdi, r12
    call agent_init

    inc r12
    jmp .init_loop

.done:
    ; Display banner
    mov rax, 1
    mov rdi, 1
    mov rsi, tournament_banner
    mov rdx, tournament_banner_len
    syscall

    xor rax, rax
    pop r12
    pop rbx
    pop rbp
    ret

.error:
    mov rax, -1
    pop r12
    pop rbx
    pop rbp
    ret

; Initialize a single agent
; Input: rdi = agent ID (0-7)
agent_init:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13

    mov r12, rdi    ; Agent ID

    ; Get agent base address
    mov rax, r12
    imul rax, agent_size
    lea rbx, [agents]
    add rbx, rax
    mov r13, rbx    ; r13 = agent base

    ; Set ID
    mov byte [r13], r12b

    ; Assign personality (cycling pattern)
    mov rax, r12
    and rax, 3      ; 0-3
    mov byte [r13 + 1], al

    ; Initialize Q-table (zero)
    lea rdi, [r13 + 2]
    xor rax, rax
    mov rcx, 768
    rep stosw

    ; Reset statistics
    mov word [r13 + 1538], 0    ; Win count
    mov word [r13 + 1540], 0    ; Total battles

    ; Initialize QUIGZIMON roster
    mov rdi, r12
    call agent_init_roster

    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Initialize agent's QUIGZIMON roster
; Input: rdi = agent ID
agent_init_roster:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13

    mov r12, rdi

    ; Get roster base
    mov rax, r12
    imul rax, agent_size
    lea rbx, [agents]
    add rbx, rax
    add rbx, 1542   ; Offset to roster
    mov r13, rbx

    ; Create 6 random QUIGZIMON
    xor r12, r12
.roster_loop:
    cmp r12, 6
    jge .done

    ; Random species (0-5)
    call get_random
    xor rdx, rdx
    mov rcx, 6
    div rcx
    mov byte [r13], dl  ; Species

    ; Set level (50-100)
    call get_random
    and rax, 0x3F
    add rax, 50
    mov byte [r13 + 1], al

    ; Set HP (based on species)
    movzx rax, byte [r13]
    imul rax, 33
    lea rcx, [quigzimon_db]
    add rcx, rax
    movzx rax, byte [rcx + 4]   ; Base HP
    movzx rbx, byte [r13 + 1]   ; Level
    imul rax, rbx
    shr rax, 2
    add rax, 50
    mov word [r13 + 2], ax      ; Current HP
    mov word [r13 + 4], ax      ; Max HP

    ; Clear status
    mov byte [r13 + 8], 0

    add r13, 33
    inc r12
    jmp .roster_loop

.done:
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; ========== PERSONALITY SYSTEM ==========

; Apply personality modifier to Q-value
; Input: rdi = base Q-value, rsi = action, rdx = personality, rcx = state
; Output: rax = modified Q-value
apply_personality:
    push rbp
    mov rbp, rsp
    push rbx

    mov rax, rdi    ; Start with base Q-value

    ; Check personality type
    cmp rdx, personality_aggressive
    je .aggressive
    cmp rdx, personality_defensive
    je .defensive
    cmp rdx, personality_strategic
    je .strategic
    jmp .balanced   ; Default: no modification

.aggressive:
    ; Boost attack (action 0), penalize defense (action 2)
    cmp rsi, 0
    je .aggressive_attack
    cmp rsi, 2
    je .aggressive_defense
    jmp .done

.aggressive_attack:
    movsx rbx, word [aggressive_attack_bonus]
    add rax, rbx
    jmp .done

.aggressive_defense:
    movsx rbx, word [aggressive_defense_penalty]
    add rax, rbx
    jmp .done

.defensive:
    ; Boost defense (action 2), penalize attack (action 0)
    cmp rsi, 2
    je .defensive_defense
    cmp rsi, 0
    je .defensive_attack
    jmp .done

.defensive_defense:
    movsx rbx, word [defensive_defense_bonus]
    add rax, rbx
    jmp .done

.defensive_attack:
    movsx rbx, word [defensive_attack_penalty]
    add rax, rbx
    jmp .done

.strategic:
    ; Check type advantage from state
    ; State encoding includes type advantage
    ; Extract it (bits 4-5 of state / 16)
    mov rbx, rcx
    shr rbx, 4
    and rbx, 3      ; Type advantage: 0=weak, 1=neutral, 2=strong

    cmp rbx, 2      ; Strong advantage
    je .strategic_advantage
    cmp rbx, 0      ; Weak disadvantage
    je .strategic_disadvantage
    jmp .done

.strategic_advantage:
    ; Boost attack when we have advantage
    cmp rsi, 0
    jne .done
    movsx rbx, word [strategic_type_bonus]
    add rax, rbx
    jmp .done

.strategic_disadvantage:
    ; Avoid attack when disadvantaged
    cmp rsi, 0
    jne .done
    movsx rbx, word [strategic_type_penalty]
    add rax, rbx
    jmp .done

.balanced:
.done:
    ; Clamp result
    cmp rax, 32767
    jle .check_min
    mov rax, 32767
    jmp .exit

.check_min:
    cmp rax, -32768
    jge .exit
    mov rax, -32768

.exit:
    pop rbx
    pop rbp
    ret

; Select action with personality
; Input: rdi = agent ID, rsi = state
; Output: rax = action
agent_select_action:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14

    mov r12, rdi    ; Agent ID
    mov r13, rsi    ; State

    ; Get agent personality
    mov rax, r12
    imul rax, agent_size
    lea rbx, [agents]
    add rbx, rax
    movzx r14, byte [rbx + 1]   ; Personality

    ; Find best action with personality modifiers
    mov rbx, -32768     ; Best Q-value
    xor r12, r12        ; Best action

    xor rcx, rcx        ; Action loop
.action_loop:
    cmp rcx, 4
    jge .done

    ; Get base Q[state][action]
    mov rax, r13
    imul rax, 4
    add rax, rcx

    ; Get agent Q-table
    mov rdi, r12
    imul rdi, agent_size
    lea r8, [agents]
    add r8, rdi
    add r8, 2           ; Q-table offset

    movsx rdi, word [r8 + rax * 2]

    ; Apply personality
    mov rsi, rcx        ; Action
    mov rdx, r14        ; Personality
    mov rcx, r13        ; State
    call apply_personality

    ; Check if better
    cmp rax, rbx
    jle .next_action
    mov rbx, rax
    mov r12, rcx

.next_action:
    inc rcx
    jmp .action_loop

.done:
    mov rax, r12

    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; ========== AI VS AI BATTLE ENGINE ==========

; Battle between two agents
; Input: rdi = agent1 ID, rsi = agent2 ID
; Output: rax = winner ID
agent_vs_agent:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13

    mov r12, rdi    ; Agent 1
    mov r13, rsi    ; Agent 2

    mov byte [agent1_id], r12b
    mov byte [agent2_id], r13b

    ; Load personalities
    mov rax, r12
    imul rax, agent_size
    lea rbx, [agents]
    add rbx, rax
    movzx rax, byte [rbx + 1]
    mov byte [agent1_personality], al

    mov rax, r13
    imul rax, agent_size
    lea rbx, [agents]
    add rbx, rax
    movzx rax, byte [rbx + 1]
    mov byte [agent2_personality], al

    ; Display match
    call display_match_header

    ; Select lead QUIGZIMON
    mov rdi, r12
    call agent_get_lead_quigzimon
    lea rdi, [agent1_quigzimon]
    mov rcx, 33
    rep movsb

    mov rdi, r13
    call agent_get_lead_quigzimon
    lea rdi, [agent2_quigzimon]
    mov rcx, 33
    rep movsb

    ; Battle loop
    mov word [turn_counter], 0

.battle_loop:
    inc word [turn_counter]
    inc word [total_turns]

    ; Check turn limit
    movzx rax, word [turn_counter]
    cmp rax, max_turns
    jge .timeout

    ; Display turn
    call display_turn

    ; Agent 1 selects action
    lea rdi, [agent1_quigzimon]
    lea rsi, [agent2_quigzimon]
    call ai_compute_state
    mov rdi, r12
    mov rsi, rax
    call agent_select_action
    mov r8, rax     ; Agent 1 action

    ; Agent 2 selects action
    lea rdi, [agent2_quigzimon]
    lea rsi, [agent1_quigzimon]
    call ai_compute_state
    mov rdi, r13
    mov rsi, rax
    call agent_select_action
    mov r9, rax     ; Agent 2 action

    ; Execute actions
    mov rdi, r8
    mov rsi, r9
    call execute_battle_turn

    ; Check for knockout
    movzx rax, word [agent1_quigzimon + 2]  ; HP
    cmp rax, 0
    jle .agent2_wins

    movzx rax, word [agent2_quigzimon + 2]
    cmp rax, 0
    jle .agent1_wins

    jmp .battle_loop

.agent1_wins:
    mov rax, r12
    jmp .battle_end

.agent2_wins:
    mov rax, r13
    jmp .battle_end

.timeout:
    ; Decide by HP percentage
    movzx rax, word [agent1_quigzimon + 2]
    movzx rbx, word [agent1_quigzimon + 4]
    imul rax, 100
    xor rdx, rdx
    div rbx
    mov r8, rax

    movzx rax, word [agent2_quigzimon + 2]
    movzx rbx, word [agent2_quigzimon + 4]
    imul rax, 100
    xor rdx, rdx
    div rbx

    cmp r8, rax
    jg .agent1_wins
    jmp .agent2_wins

.battle_end:
    ; Update statistics
    mov rdi, rax
    call agent_record_win

    ; Display winner
    mov rdi, rax
    call display_winner

    inc word [total_matches]

    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Get lead QUIGZIMON for agent
; Input: rdi = agent ID
; Output: rsi = pointer to QUIGZIMON data
agent_get_lead_quigzimon:
    push rbp
    mov rbp, rsp

    mov rax, rdi
    imul rax, agent_size
    lea rsi, [agents]
    add rsi, rax
    add rsi, 1542   ; Roster offset

    pop rbp
    ret

; Execute battle turn
; Input: rdi = agent1 action, rsi = agent2 action
execute_battle_turn:
    push rbp
    mov rbp, rsp
    push rbx

    ; Simplified battle: both deal damage based on action
    ; Attack = 30 damage, Special = 40, Defend = 15, Status = 20

    ; Agent 1 attacks Agent 2
    mov rax, rdi
    call get_action_damage
    movzx rbx, word [agent2_quigzimon + 2]
    sub rbx, rax
    cmp rbx, 0
    jge .store_a2_hp
    xor rbx, rbx
.store_a2_hp:
    mov word [agent2_quigzimon + 2], bx

    ; Agent 2 attacks Agent 1
    mov rax, rsi
    call get_action_damage
    movzx rbx, word [agent1_quigzimon + 2]
    sub rbx, rax
    cmp rbx, 0
    jge .store_a1_hp
    xor rbx, rbx
.store_a1_hp:
    mov word [agent1_quigzimon + 2], bx

    pop rbx
    pop rbp
    ret

; Get damage for action
; Input: rax = action
; Output: rax = damage
get_action_damage:
    cmp rax, 0
    je .attack
    cmp rax, 1
    je .special
    cmp rax, 2
    je .defend
    mov rax, 20
    ret
.attack:
    mov rax, 30
    ret
.special:
    mov rax, 40
    ret
.defend:
    mov rax, 15
    ret

; Record win for agent
; Input: rdi = agent ID
agent_record_win:
    push rbp
    mov rbp, rsp

    mov rax, rdi
    imul rax, agent_size
    lea rbx, [agents]
    add rbx, rax
    inc word [rbx + 1538]   ; Win count
    inc word [rbx + 1540]   ; Battle count

    pop rbp
    ret

; ========== TOURNAMENT EXECUTION ==========

; Run full tournament
tournament_run:
    push rbp
    mov rbp, rsp
    push r12

    ; Setup initial bracket
    call setup_bracket

    ; Round 1: 8 -> 4
    mov byte [current_round], 1
    call display_round_header
    call run_round
    ; Winners in bracket_round2

    ; Round 2: 4 -> 2
    mov byte [current_round], 2
    call display_round_header
    call run_semifinals
    ; Winners in bracket_finals

    ; Finals: 2 -> 1
    mov byte [current_round], 3
    call display_round_header
    call run_finals

    ; Display champion
    call display_champion

    pop r12
    pop rbp
    ret

; Setup initial bracket
setup_bracket:
    push rbp
    mov rbp, rsp
    push rbx

    ; Copy agent IDs to bracket
    movzx rcx, byte [num_agents]
    xor rbx, rbx
.copy_loop:
    cmp rbx, rcx
    jge .done
    mov byte [bracket_round1 + rbx], bl
    inc rbx
    jmp .copy_loop

.done:
    pop rbx
    pop rbp
    ret

; Run round 1 (quarterfinals)
run_round:
    push rbp
    mov rbp, rsp
    push r12

    xor r12, r12
.match_loop:
    cmp r12, 4
    jge .done

    ; Match i: bracket[i*2] vs bracket[i*2+1]
    mov rax, r12
    shl rax, 1
    movzx rdi, byte [bracket_round1 + rax]
    inc rax
    movzx rsi, byte [bracket_round1 + rax]

    call agent_vs_agent
    mov byte [bracket_round2 + r12], al

    inc r12
    jmp .match_loop

.done:
    pop r12
    pop rbp
    ret

; Run semifinals
run_semifinals:
    push rbp
    mov rbp, rsp

    ; Match 1
    movzx rdi, byte [bracket_round2]
    movzx rsi, byte [bracket_round2 + 1]
    call agent_vs_agent
    mov byte [bracket_finals], al

    ; Match 2
    movzx rdi, byte [bracket_round2 + 2]
    movzx rsi, byte [bracket_round2 + 3]
    call agent_vs_agent
    mov byte [bracket_finals + 1], al

    pop rbp
    ret

; Run finals
run_finals:
    push rbp
    mov rbp, rsp

    movzx rdi, byte [bracket_finals]
    movzx rsi, byte [bracket_finals + 1]
    call agent_vs_agent
    mov byte [champion], al

    pop rbp
    ret

; ========== DISPLAY FUNCTIONS ==========

display_round_header:
    push rbp
    mov rbp, rsp

    mov rax, 1
    mov rdi, 1
    mov rsi, round_msg
    mov rdx, round_msg_len
    syscall

    movzx rax, byte [current_round]
    add rax, '0'
    mov byte [temp_char], al
    mov rax, 1
    mov rdi, 1
    lea rsi, [temp_char]
    mov rdx, 1
    syscall

    pop rbp
    ret

display_match_header:
    push rbp
    mov rbp, rsp

    mov rax, 1
    mov rdi, 1
    mov rsi, match_msg
    mov rdx, match_msg_len
    syscall

    movzx rax, byte [agent1_id]
    add rax, '0'
    mov byte [temp_char], al
    mov rax, 1
    mov rdi, 1
    lea rsi, [temp_char]
    mov rdx, 1
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, vs_msg
    mov rdx, vs_msg_len
    syscall

    movzx rax, byte [agent2_id]
    add rax, '0'
    mov byte [temp_char], al
    mov rax, 1
    mov rdi, 1
    lea rsi, [temp_char]
    mov rdx, 1
    syscall

    ; Newline
    mov byte [temp_char], 0xA
    mov rax, 1
    mov rdi, 1
    lea rsi, [temp_char]
    mov rdx, 1
    syscall

    pop rbp
    ret

display_turn:
    push rbp
    mov rbp, rsp

    mov rax, 1
    mov rdi, 1
    mov rsi, spectator_msg
    mov rdx, spectator_msg_len
    syscall

    ; Display turn number
    movzx rax, word [turn_counter]
    call print_number

    ; Newline
    mov byte [temp_char], 0xA
    mov rax, 1
    mov rdi, 1
    lea rsi, [temp_char]
    mov rdx, 1
    syscall

    pop rbp
    ret

display_winner:
    push rbp
    mov rbp, rsp
    push rbx

    mov rbx, rdi

    mov rax, 1
    mov rdi, 1
    mov rsi, winner_msg
    mov rdx, winner_msg_len
    syscall

    mov rax, rbx
    add rax, '0'
    mov byte [temp_char], al
    mov rax, 1
    mov rdi, 1
    lea rsi, [temp_char]
    mov rdx, 1
    syscall

    ; Newline
    mov byte [temp_char], 0xA
    mov rax, 1
    mov rdi, 1
    lea rsi, [temp_char]
    mov rdx, 1
    syscall

    pop rbx
    pop rbp
    ret

display_champion:
    push rbp
    mov rbp, rsp

    mov rax, 1
    mov rdi, 1
    mov rsi, champion_msg
    mov rdx, champion_msg_len
    syscall

    movzx rax, byte [champion]
    add rax, '0'
    mov byte [temp_char], al
    mov rax, 1
    mov rdi, 1
    lea rsi, [temp_char]
    mov rdx, 1
    syscall

    ; Newlines
    mov byte [temp_char], 0xA
    mov rax, 1
    mov rdi, 1
    lea rsi, [temp_char]
    mov rdx, 3
    syscall

    pop rbp
    ret

; Print number utility
; Input: rax = number
print_number:
    push rbp
    mov rbp, rsp
    push rbx

    ; Simple digit printing (0-99)
    xor rdx, rdx
    mov rbx, 10
    div rbx

    add rax, '0'
    mov byte [temp_char], al
    push rdx

    mov rax, 1
    mov rdi, 1
    lea rsi, [temp_char]
    mov rdx, 1
    syscall

    pop rax
    add rax, '0'
    mov byte [temp_char], al
    mov rax, 1
    mov rdi, 1
    lea rsi, [temp_char]
    mov rdx, 1
    syscall

    pop rbx
    pop rbp
    ret

section .bss
    temp_char resb 1

; ========== EXTERNAL DEPENDENCIES ==========
extern get_random
extern ai_compute_state
extern quigzimon_db
extern get_type_effectiveness

; ========== EXPORTS ==========
global tournament_init
global tournament_run
global agent_vs_agent
global agent_select_action
global apply_personality
