; QUIGZIMON AI Tournament Demo
; Showcases multi-agent battles with different personalities

%include "game_enhanced.asm"
%include "ai_qlearning.asm"
%include "ai_dqn.asm"
%include "ai_tournament.asm"

section .data
    ; ========== DEMO MENU ==========
    demo_title db 0xA
    db "╔════════════════════════════════════════╗", 0xA
    db "║  QUIGZIMON AI TOURNAMENT SIMULATOR     ║", 0xA
    db "║  Multi-Agent Battle Championship       ║", 0xA
    db "╚════════════════════════════════════════╝", 0xA, 0xA, 0
    demo_title_len equ $ - demo_title

    menu_options db "Select Demo Mode:", 0xA, 0xA
    db "1. Quick Match (2 agents)", 0xA
    db "2. 4-Agent Tournament", 0xA
    db "3. Full 8-Agent Championship", 0xA
    db "4. Personality Showcase", 0xA
    db "5. Training Mode (watch AI improve)", 0xA
    db "6. Statistics Dashboard", 0xA
    db "Q. Quit", 0xA, 0xA
    db "Choice: ", 0
    menu_options_len equ $ - menu_options

    ; ========== PERSONALITY SHOWCASE ==========
    showcase_title db 0xA, "=== PERSONALITY ARCHETYPE SHOWCASE ===", 0xA, 0xA, 0
    showcase_title_len equ $ - showcase_title

    aggressive_desc db "AGGRESSIVE: Favors attack moves (+50% attack, -25% defense)", 0xA
    db "  - High risk, high reward strategy", 0xA
    db "  - Prefers head-on confrontation", 0xA, 0xA, 0
    aggressive_desc_len equ $ - aggressive_desc

    defensive_desc db "DEFENSIVE: Favors defensive moves (+50% defense, -12.5% attack)", 0xA
    db "  - Conservative, outlasts opponents", 0xA
    db "  - Wins through attrition", 0xA, 0xA, 0
    defensive_desc_len equ $ - defensive_desc

    balanced_desc db "BALANCED: Pure Q-learning, no biases", 0xA
    db "  - Adapts to all situations equally", 0xA
    db "  - Jack of all trades", 0xA, 0xA, 0
    balanced_desc_len equ $ - balanced_desc

    strategic_desc db "STRATEGIC: Exploits type advantages (+75% w/ advantage)", 0xA
    db "  - Maximizes type effectiveness", 0xA
    db "  - Intelligent matchup analysis", 0xA, 0xA, 0
    strategic_desc_len equ $ - strategic_desc

    ; ========== TRAINING MODE ==========
    training_title db 0xA, "=== TRAINING MODE ===", 0xA
    db "Watching agents improve through reinforcement learning...", 0xA, 0xA, 0
    training_title_len equ $ - training_title

    epoch_msg db "Epoch ", 0
    epoch_msg_len equ $ - epoch_msg

    improvement_msg db "  -> Win rate improved: ", 0
    improvement_msg_len equ $ - improvement_msg

    epsilon_msg db "  -> Exploration rate: ", 0
    epsilon_msg_len equ $ - epsilon_msg

    ; ========== STATISTICS ==========
    stats_title db 0xA, "╔════════════════════════════════════════╗", 0xA
    db "║       TOURNAMENT STATISTICS            ║", 0xA
    db "╚════════════════════════════════════════╝", 0xA, 0xA, 0
    stats_title_len equ $ - stats_title

    total_matches_label db "Total Matches: ", 0
    total_matches_label_len equ $ - total_matches_label

    total_turns_label db "Total Turns: ", 0
    total_turns_label_len equ $ - total_turns_label

    avg_turns_label db "Average Turns per Match: ", 0
    avg_turns_label_len equ $ - avg_turns_label

    agent_stats_header db 0xA, "Agent Performance:", 0xA
    db "ID | Personality  | Wins | Battles | Win %", 0xA
    db "---|--------------|------|---------|-------", 0xA, 0
    agent_stats_header_len equ $ - agent_stats_header

    ; ========== QUICK MATCH ==========
    quick_match_title db 0xA, "=== QUICK MATCH ===", 0xA, 0xA, 0
    quick_match_title_len equ $ - quick_match_title

    select_agent_msg db "Agent personalities:", 0xA
    db "  Agent 0: AGGRESSIVE", 0xA
    db "  Agent 1: DEFENSIVE", 0xA, 0xA, 0
    select_agent_msg_len equ $ - select_agent_msg

    press_enter_msg db 0xA, "Press ENTER to start battle...", 0xA, 0
    press_enter_msg_len equ $ - press_enter_msg

section .bss
    user_input resb 2
    current_mode resb 1
    training_epochs resb 1

    ; Statistics tracking
    agent_win_rates resw 8

section .text
global _start

_start:
    ; Initialize random seed
    call init_random

    ; Initialize AI systems
    call ai_init
    call dqn_init

.main_loop:
    ; Display title
    mov rax, 1
    mov rdi, 1
    mov rsi, demo_title
    mov rdx, demo_title_len
    syscall

    ; Display menu
    mov rax, 1
    mov rdi, 1
    mov rsi, menu_options
    mov rdx, menu_options_len
    syscall

    ; Get user choice
    mov rax, 0
    mov rdi, 0
    lea rsi, [user_input]
    mov rdx, 2
    syscall

    ; Parse choice
    movzx rax, byte [user_input]

    cmp al, 'q'
    je .quit
    cmp al, 'Q'
    je .quit

    cmp al, '1'
    je .quick_match
    cmp al, '2'
    je .tournament_4
    cmp al, '3'
    je .tournament_8
    cmp al, '4'
    je .personality_showcase
    cmp al, '5'
    je .training_mode
    cmp al, '6'
    je .statistics

    jmp .main_loop

; ========== MODE 1: QUICK MATCH ==========
.quick_match:
    mov rax, 1
    mov rdi, 1
    mov rsi, quick_match_title
    mov rdx, quick_match_title_len
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, select_agent_msg
    mov rdx, select_agent_msg_len
    syscall

    ; Initialize 2 agents
    mov rdi, 2
    call tournament_init

    mov rax, 1
    mov rdi, 1
    mov rsi, press_enter_msg
    mov rdx, press_enter_msg_len
    syscall

    ; Wait for enter
    mov rax, 0
    mov rdi, 0
    lea rsi, [user_input]
    mov rdx, 2
    syscall

    ; Run single match
    mov rdi, 0
    mov rsi, 1
    call agent_vs_agent

    jmp .main_loop

; ========== MODE 2: 4-AGENT TOURNAMENT ==========
.tournament_4:
    mov rdi, 4
    call tournament_init

    ; Run tournament (will do 2 semifinals + 1 final)
    call run_4_agent_tournament

    jmp .main_loop

; ========== MODE 3: 8-AGENT CHAMPIONSHIP ==========
.tournament_8:
    mov rdi, 8
    call tournament_init

    call tournament_run

    jmp .main_loop

; ========== MODE 4: PERSONALITY SHOWCASE ==========
.personality_showcase:
    mov rax, 1
    mov rdi, 1
    mov rsi, showcase_title
    mov rdx, showcase_title_len
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, aggressive_desc
    mov rdx, aggressive_desc_len
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, defensive_desc
    mov rdx, defensive_desc_len
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, balanced_desc
    mov rdx, balanced_desc_len
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, strategic_desc
    mov rdx, strategic_desc_len
    syscall

    ; Run demonstration battles
    mov rdi, 4
    call tournament_init

    ; Aggressive vs Defensive
    mov rdi, 0
    mov rsi, 1
    call agent_vs_agent

    ; Balanced vs Strategic
    mov rdi, 2
    mov rsi, 3
    call agent_vs_agent

    mov rax, 1
    mov rdi, 1
    mov rsi, press_enter_msg
    mov rdx, press_enter_msg_len
    syscall

    mov rax, 0
    mov rdi, 0
    lea rsi, [user_input]
    mov rdx, 2
    syscall

    jmp .main_loop

; ========== MODE 5: TRAINING MODE ==========
.training_mode:
    mov rax, 1
    mov rdi, 1
    mov rsi, training_title
    mov rdx, training_title_len
    syscall

    mov rdi, 2
    call tournament_init

    ; Run 10 training epochs
    mov byte [training_epochs], 10

.training_loop:
    dec byte [training_epochs]
    cmp byte [training_epochs], 0
    jle .training_done

    ; Display epoch
    mov rax, 1
    mov rdi, 1
    mov rsi, epoch_msg
    mov rdx, epoch_msg_len
    syscall

    movzx rax, byte [training_epochs]
    call print_number

    ; Run multiple battles
    mov r12, 5
.epoch_battles:
    mov rdi, 0
    mov rsi, 1
    call agent_vs_agent

    dec r12
    cmp r12, 0
    jg .epoch_battles

    ; Show improvement
    ; (Simplified - would track actual metrics)

    jmp .training_loop

.training_done:
    mov rax, 1
    mov rdi, 1
    mov rsi, press_enter_msg
    mov rdx, press_enter_msg_len
    syscall

    mov rax, 0
    mov rdi, 0
    lea rsi, [user_input]
    mov rdx, 2
    syscall

    jmp .main_loop

; ========== MODE 6: STATISTICS ==========
.statistics:
    mov rax, 1
    mov rdi, 1
    mov rsi, stats_title
    mov rdx, stats_title_len
    syscall

    ; Total matches
    mov rax, 1
    mov rdi, 1
    mov rsi, total_matches_label
    mov rdx, total_matches_label_len
    syscall

    movzx rax, word [total_matches]
    call print_number

    ; Newline
    mov byte [user_input], 0xA
    mov rax, 1
    mov rdi, 1
    lea rsi, [user_input]
    mov rdx, 1
    syscall

    ; Total turns
    mov rax, 1
    mov rdi, 1
    mov rsi, total_turns_label
    mov rdx, total_turns_label_len
    syscall

    movzx rax, word [total_turns]
    call print_number

    ; Newline
    mov byte [user_input], 0xA
    mov rax, 1
    mov rdi, 1
    lea rsi, [user_input]
    mov rdx, 1
    syscall

    ; Agent statistics header
    mov rax, 1
    mov rdi, 1
    mov rsi, agent_stats_header
    mov rdx, agent_stats_header_len
    syscall

    ; Display each agent
    movzx r12, byte [num_agents]
    xor r13, r13

.stats_loop:
    cmp r13, r12
    jge .stats_done

    ; Display agent stats (simplified)
    mov rax, r13
    call print_number

    mov byte [user_input], 0xA
    mov rax, 1
    mov rdi, 1
    lea rsi, [user_input]
    mov rdx, 1
    syscall

    inc r13
    jmp .stats_loop

.stats_done:
    mov rax, 1
    mov rdi, 1
    mov rsi, press_enter_msg
    mov rdx, press_enter_msg_len
    syscall

    mov rax, 0
    mov rdi, 0
    lea rsi, [user_input]
    mov rdx, 2
    syscall

    jmp .main_loop

; ========== QUIT ==========
.quit:
    mov rax, 60
    xor rdi, rdi
    syscall

; ========== HELPER FUNCTIONS ==========

; Run 4-agent tournament
run_4_agent_tournament:
    push rbp
    mov rbp, rsp

    ; Semifinals
    mov byte [current_round], 1
    call display_round_header

    ; Match 1: Agent 0 vs Agent 1
    mov rdi, 0
    mov rsi, 1
    call agent_vs_agent
    mov byte [bracket_round2], al

    ; Match 2: Agent 2 vs Agent 3
    mov rdi, 2
    mov rsi, 3
    call agent_vs_agent
    mov byte [bracket_round2 + 1], al

    ; Finals
    mov byte [current_round], 2
    call display_round_header

    movzx rdi, byte [bracket_round2]
    movzx rsi, byte [bracket_round2 + 1]
    call agent_vs_agent
    mov byte [champion], al

    call display_champion

    pop rbp
    ret

; Initialize random seed
init_random:
    push rbp
    mov rbp, rsp

    ; Use timestamp for seed
    mov rax, 201    ; sys_time
    xor rdi, rdi
    syscall

    pop rbp
    ret

; Simple random number generator
get_random:
    push rbp
    mov rbp, rsp

    ; Linear congruential generator
    mov rax, [random_seed]
    imul rax, 1103515245
    add rax, 12345
    mov [random_seed], rax

    shr rax, 16
    and rax, 0x7FFF

    pop rbp
    ret

section .data
    random_seed dq 123456789

; External symbols
extern num_agents
extern current_round
extern bracket_round2
extern champion
extern total_matches
extern total_turns
extern display_round_header
extern display_champion
extern print_number
