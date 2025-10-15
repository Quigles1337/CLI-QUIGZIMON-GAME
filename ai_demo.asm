; QUIGZIMON AI Demo - Visualize Learning in Real-Time
; Watch the AI improve over multiple battles!

section .data
    demo_title db 0xA, "╔══════════════════════════════════╗", 0xA
               db "║  QUIGZIMON AI TRAINING DEMO      ║", 0xA
               db "╚══════════════════════════════════╝", 0xA, 0xA, 0
    demo_title_len equ $ - demo_title

    demo_menu db "AI Demo Menu:", 0xA
              db "1) Watch AI Learn (10 battles)", 0xA
              db "2) Watch AI Learn (100 battles)", 0xA
              db "3) Show Q-Table Heatmap", 0xA
              db "4) Show AI Statistics", 0xA
              db "5) Reset AI (start fresh)", 0xA
              db "6) Battle Trained AI", 0xA
              db "7) Back to Game", 0xA
              db "> ", 0
    demo_menu_len equ $ - demo_menu

    training_header db 0xA, "Training Progress:", 0xA
                    db "─────────────────────────────────", 0xA, 0
    training_header_len equ $ - training_header

    battle_num_msg db "Battle #", 0
    battle_num_msg_len equ $ - battle_num_msg

    win_rate_msg db " | Win Rate: ", 0
    win_rate_msg_len equ $ - win_rate_msg

    epsilon_msg db "% | Exploration: ", 0
    epsilon_msg_len equ $ - epsilon_msg

    avg_q_msg db "% | Avg Q: ", 0
    avg_q_msg_len equ $ - avg_q_msg

    stats_header db 0xA, "╔══════════════════════════════════╗", 0xA
                 db "║       AI STATISTICS              ║", 0xA
                 db "╚══════════════════════════════════╝", 0xA, 0xA, 0
    stats_header_len equ $ - stats_header

    total_battles_label db "Total Battles:     ", 0
    total_battles_label_len equ $ - total_battles_label

    total_wins_label db "Victories:         ", 0
    total_wins_label_len equ $ - total_wins_label

    total_losses_label db "Defeats:           ", 0
    total_losses_label_len equ $ - total_losses_label

    intelligence_label db "Intelligence:      ", 0
    intelligence_label_len equ $ - intelligence_label

    episodes_label db "Episodes Trained:  ", 0
    episodes_label_len equ $ - episodes_label

    qtable_header db 0xA, "Q-Table Heatmap (Top 20 States):", 0xA
                  db "─────────────────────────────────", 0xA, 0
    qtable_header_len equ $ - qtable_header

    state_label db "State ", 0
    state_label_len equ $ - state_label

    action_labels db " | Atk:", 0
    action_labels_len equ $ - action_labels

    special_label db " Spc:", 0
    special_label_len equ $ - special_label

    defend_label db " Def:", 0
    defend_label_len equ $ - defend_label

    status_label db " Sts:", 0
    status_label_len equ $ - status_label

    reset_confirm db "Reset AI and start fresh training? (y/n): ", 0
    reset_confirm_len equ $ - reset_confirm

    reset_done db "AI has been reset!", 0xA, 0
    reset_done_len equ $ - reset_done

section .text
    global ai_demo_menu

; Main AI demo menu
ai_demo_menu:
    push rbp
    mov rbp, rsp

    ; Display title
    mov rax, 1
    mov rdi, 1
    mov rsi, demo_title
    mov rdx, demo_title_len
    syscall

.menu_loop:
    ; Display menu
    mov rax, 1
    mov rdi, 1
    mov rsi, demo_menu
    mov rdx, demo_menu_len
    syscall

    ; Get input
    mov rax, 0
    mov rdi, 0
    mov rsi, input
    mov rdx, 2
    syscall

    mov al, byte [input]
    cmp al, '1'
    je .train_10
    cmp al, '2'
    je .train_100
    cmp al, '3'
    je .show_heatmap
    cmp al, '4'
    je .show_stats
    cmp al, '5'
    je .reset_ai
    cmp al, '6'
    je .battle_ai
    cmp al, '7'
    je .back
    jmp .menu_loop

.train_10:
    mov r12, 10
    call auto_train_battles
    jmp .menu_loop

.train_100:
    mov r12, 100
    call auto_train_battles
    jmp .menu_loop

.show_heatmap:
    call display_qtable_heatmap
    jmp .menu_loop

.show_stats:
    call display_ai_statistics
    jmp .menu_loop

.reset_ai:
    call reset_ai_confirm
    jmp .menu_loop

.battle_ai:
    call battle_trained_ai
    jmp .menu_loop

.back:
    pop rbp
    ret

; Auto-train AI for multiple battles
; Input: r12 = number of battles
auto_train_battles:
    push rbp
    mov rbp, rsp
    push r13
    push r14

    ; Display header
    mov rax, 1
    mov rdi, 1
    mov rsi, training_header
    mov rdx, training_header_len
    syscall

    xor r13, r13    ; Battle counter

.battle_loop:
    cmp r13, r12
    jge .done

    inc r13

    ; Display battle number
    call display_training_progress

    ; Run simulated battle
    call run_simulated_battle

    ; Show stats every 10 battles
    mov rax, r13
    xor rdx, rdx
    mov rbx, 10
    div rbx
    cmp rdx, 0
    jne .next_battle

    call display_ai_statistics

.next_battle:
    jmp .battle_loop

.done:
    ; Final stats
    call display_ai_statistics

    pop r14
    pop r13
    pop rbp
    ret

; Display training progress for current battle
display_training_progress:
    push rbp
    mov rbp, rsp

    ; Battle #X
    mov rax, 1
    mov rdi, 1
    mov rsi, battle_num_msg
    mov rdx, battle_num_msg_len
    syscall

    mov rax, r13
    call print_number

    ; Win Rate
    mov rax, 1
    mov rdi, 1
    mov rsi, win_rate_msg
    mov rdx, win_rate_msg_len
    syscall

    movzx rax, word [total_victories]
    imul rax, 100
    movzx rbx, word [total_battles]
    cmp rbx, 0
    je .no_battles
    xor rdx, rdx
    div rbx

.no_battles:
    call print_number

    ; Exploration rate
    mov rax, 1
    mov rdi, 1
    mov rsi, epsilon_msg
    mov rdx, epsilon_msg_len
    syscall

    movzx rax, word [epsilon]
    imul rax, 100
    mov rbx, 4096
    xor rdx, rdx
    div rbx
    call print_number

    ; Average Q-value
    mov rax, 1
    mov rdi, 1
    mov rsi, avg_q_msg
    mov rdx, avg_q_msg_len
    syscall

    call calculate_avg_q
    call print_number

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    pop rbp
    ret

; Run a simulated battle for training
run_simulated_battle:
    push rbp
    mov rbp, rsp

    ; Initialize random QUIGZIMON
    call generate_random_enemy

    ; Battle start
    call ai_battle_start

    ; Simulate 10 turns max
    mov r14, 10

.turn_loop:
    cmp r14, 0
    jle .battle_end

    ; AI takes action
    call ai_get_action

    ; Simulate result with random reward
    call get_random
    and rax, 31
    sub rax, 15     ; Random reward -15 to +15
    mov rdi, rax
    call ai_step_update

    dec r14
    jmp .turn_loop

.battle_end:
    ; Random win/loss
    call get_random
    and rax, 1
    mov rdi, rax
    call ai_battle_end

    pop rbp
    ret

; Generate random enemy for training
generate_random_enemy:
    push rbp
    mov rbp, rsp

    ; Random species 0-5
    call get_random
    xor rdx, rdx
    mov rbx, 6
    div rbx
    mov byte [enemy_instance], dl

    ; Random level 5-10
    call get_random
    xor rdx, rdx
    mov rbx, 6
    div rbx
    add rdx, 5
    mov byte [enemy_instance + 1], dl

    ; Calculate stats
    ; (Simplified - in real game would use proper formulas)

    pop rbp
    ret

; Display AI statistics
display_ai_statistics:
    push rbp
    mov rbp, rsp

    ; Header
    mov rax, 1
    mov rdi, 1
    mov rsi, stats_header
    mov rdx, stats_header_len
    syscall

    ; Total battles
    mov rax, 1
    mov rdi, 1
    mov rsi, total_battles_label
    mov rdx, total_battles_label_len
    syscall

    movzx rax, word [total_battles]
    call print_number

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    ; Victories
    mov rax, 1
    mov rdi, 1
    mov rsi, total_wins_label
    mov rdx, total_wins_label_len
    syscall

    movzx rax, word [total_victories]
    call print_number

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    ; Defeats
    mov rax, 1
    mov rdi, 1
    mov rsi, total_losses_label
    mov rdx, total_losses_label_len
    syscall

    movzx rax, word [total_defeats]
    call print_number

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    ; Intelligence level
    mov rax, 1
    mov rdi, 1
    mov rsi, intelligence_label
    mov rdx, intelligence_label_len
    syscall

    call ai_display_intelligence

    ; Episodes
    mov rax, 1
    mov rdi, 1
    mov rsi, episodes_label
    mov rdx, episodes_label_len
    syscall

    movzx rax, word [episodes_trained]
    call print_number

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 2
    syscall

    pop rbp
    ret

; Display Q-table heatmap
display_qtable_heatmap:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    ; Header
    mov rax, 1
    mov rdi, 1
    mov rsi, qtable_header
    mov rdx, qtable_header_len
    syscall

    ; Show top 20 states by max Q-value
    mov r13, 20

.state_loop:
    cmp r13, 0
    jle .done

    ; State label
    mov rax, 1
    mov rdi, 1
    mov rsi, state_label
    mov rdx, state_label_len
    syscall

    mov rax, r13
    call print_number

    ; Show all 4 actions
    mov r12, r13
    imul r12, 4

    ; Attack
    mov rax, 1
    mov rdi, 1
    mov rsi, action_labels
    mov rdx, action_labels_len
    syscall

    lea rdi, [q_table]
    movsx rax, word [rdi + r12 * 2]
    call print_signed_number

    ; Special
    mov rax, 1
    mov rdi, 1
    mov rsi, special_label
    mov rdx, special_label_len
    syscall

    lea rdi, [q_table]
    movsx rax, word [rdi + r12 * 2 + 2]
    call print_signed_number

    ; Defend
    mov rax, 1
    mov rdi, 1
    mov rsi, defend_label
    mov rdx, defend_label_len
    syscall

    lea rdi, [q_table]
    movsx rax, word [rdi + r12 * 2 + 4]
    call print_signed_number

    ; Status
    mov rax, 1
    mov rdi, 1
    mov rsi, status_label
    mov rdx, status_label_len
    syscall

    lea rdi, [q_table]
    movsx rax, word [rdi + r12 * 2 + 6]
    call print_signed_number

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    dec r13
    jmp .state_loop

.done:
    pop r13
    pop r12
    pop rbp
    ret

; Calculate average Q-value
calculate_avg_q:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx

    lea rdi, [q_table]
    xor rax, rax
    mov rcx, 768

.sum_loop:
    movsx rbx, word [rdi]
    add rax, rbx
    add rdi, 2
    loop .sum_loop

    ; Divide by 768
    mov rbx, 768
    cqo
    idiv rbx

    pop rcx
    pop rbx
    pop rbp
    ret

; Print signed number
print_signed_number:
    push rbp
    mov rbp, rsp

    cmp rax, 0
    jge .positive

    ; Negative - print minus sign
    push rax
    mov rax, 1
    mov rdi, 1
    lea rsi, [minus_sign]
    mov rdx, 1
    syscall
    pop rax

    neg rax

.positive:
    call print_number

    pop rbp
    ret

section .data
    minus_sign db "-", 0

; Reset AI with confirmation
reset_ai_confirm:
    push rbp
    mov rbp, rsp

    ; Ask for confirmation
    mov rax, 1
    mov rdi, 1
    mov rsi, reset_confirm
    mov rdx, reset_confirm_len
    syscall

    ; Get input
    mov rax, 0
    mov rdi, 0
    mov rsi, input
    mov rdx, 2
    syscall

    cmp byte [input], 'y'
    jne .cancel

    ; Reset AI
    call ai_init

    ; Confirm
    mov rax, 1
    mov rdi, 1
    mov rsi, reset_done
    mov rdx, reset_done_len
    syscall

.cancel:
    pop rbp
    ret

; Battle against trained AI
battle_trained_ai:
    push rbp
    mov rbp, rsp

    ; Display AI intelligence first
    call ai_display_intelligence

    ; Run normal battle with AI enabled
    call encounter_wild

    pop rbp
    ret
