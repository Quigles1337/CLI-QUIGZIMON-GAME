; QUIGZIMON AI - Q-Learning Reinforcement Learning
; Intelligent wild QUIGZIMON that learn and adapt during battles!
; Pure assembly implementation of Q-Learning algorithm

section .data
    ; ========== Q-Learning Parameters ==========

    ; Learning rate (α) - how much new info overrides old (0.0 - 1.0)
    ; Using fixed-point: 0x0CCC = 0.8 in 16-bit fixed point (multiply by 4096)
    learning_rate dw 3277        ; 0.8 * 4096

    ; Discount factor (γ) - importance of future rewards (0.0 - 1.0)
    discount_factor dw 3686      ; 0.9 * 4096

    ; Exploration rate (ε) - chance of random action (starts high, decays)
    epsilon dw 4096              ; 1.0 * 4096 (100% exploration initially)
    epsilon_decay dw 3993        ; 0.975 * 4096 (decay per episode)
    epsilon_min dw 410           ; 0.1 * 4096 (minimum exploration)

    ; Fixed point scale
    fixed_point_scale dw 4096

    ; ========== State Space ==========
    ; State = (HP_bucket, Type_advantage, Status, Move_used)
    ; HP buckets: 0=Critical(<25%), 1=Low(25-50%), 2=Med(50-75%), 3=High(>75%)
    ; Type advantage: 0=Weak, 1=Neutral, 2=Strong
    ; Status: 0=None, 1=Poisoned, 2=Asleep, 3=Paralyzed
    ; Last move: 0-3 (Attack, Special, Item, Run)

    state_space_size dw 192      ; 4 * 3 * 4 * 4 = 192 states

    ; ========== Action Space ==========
    ; Actions: 0=Attack, 1=Special, 2=Defend, 3=Status_Move
    action_space_size dw 4

    ; ========== Rewards ==========
    reward_damage_dealt dw 10
    reward_damage_taken dw -15
    reward_victory dw 100
    reward_defeat dw -100
    reward_status_inflict dw 20
    reward_status_receive dw -25
    reward_type_advantage dw 5

    ; ========== AI Messages ==========
    ai_learning_msg db "Wild QUIGZIMON is learning...", 0xA, 0
    ai_learning_msg_len equ $ - ai_learning_msg

    ai_smart_msg db "Wild QUIGZIMON is getting smarter! IQ: ", 0
    ai_smart_msg_len equ $ - ai_smart_msg

    ai_evolved_msg db "Wild QUIGZIMON's AI has evolved!", 0xA, 0
    ai_evolved_msg_len equ $ - ai_evolved_msg

    ai_difficulty_msg db "AI Difficulty: ", 0
    ai_difficulty_msg_len equ $ - ai_difficulty_msg

    difficulty_novice db "Novice", 0xA, 0
    difficulty_intermediate db "Intermediate", 0xA, 0
    difficulty_advanced db "Advanced", 0xA, 0
    difficulty_expert db "Expert", 0xA, 0
    difficulty_master db "MASTER", 0xA, 0

section .bss
    ; ========== Q-Table ==========
    ; Q[state][action] = expected reward
    ; 192 states * 4 actions * 2 bytes = 1536 bytes
    q_table resw 768             ; 192 * 4 = 768 words

    ; ========== Experience Replay Buffer ==========
    ; Store (state, action, reward, next_state) tuples
    replay_buffer_size equ 1000
    replay_buffer:
        .states resw 1000        ; Previous states
        .actions resb 1000       ; Actions taken
        .rewards resw 1000       ; Rewards received
        .next_states resw 1000   ; Resulting states
        .count resw 1             ; Number of experiences
        .index resw 1             ; Current write position

    ; ========== Current Battle State ==========
    current_state resw 1
    previous_state resw 1
    chosen_action resb 1
    last_reward resw 1

    ; ========== AI Statistics ==========
    total_battles resw 1
    total_victories resw 1
    total_defeats resw 1
    average_q_value resw 1
    ai_intelligence_level resb 1  ; 0-5 (Novice to Master)

    ; ========== Training Progress ==========
    episodes_trained resw 1
    cumulative_reward resw 1

section .text

; ========== INITIALIZATION ==========

; Initialize Q-Learning AI
; Call this when game starts or loads
ai_init:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx

    ; Zero out Q-table
    lea rdi, [q_table]
    xor rax, rax
    mov rcx, 768
    rep stosw

    ; Initialize epsilon to 100%
    mov word [epsilon], 4096

    ; Reset statistics
    mov word [total_battles], 0
    mov word [total_victories], 0
    mov word [total_defeats], 0
    mov word [episodes_trained], 0
    mov byte [ai_intelligence_level], 0

    ; Clear replay buffer
    mov word [replay_buffer.count], 0
    mov word [replay_buffer.index], 0

    pop rcx
    pop rbx
    pop rbp
    ret

; ========== STATE REPRESENTATION ==========

; Compute current state from battle situation
; Input: rdi = player QUIGZIMON, rsi = enemy QUIGZIMON
; Output: rax = state index (0-191)
ai_compute_state:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13

    mov r12, rdi    ; Player
    mov r13, rsi    ; Enemy

    ; Compute HP bucket for enemy
    ; HP% = current_hp * 100 / max_hp
    movzx rax, word [r13 + 2]   ; Current HP
    imul rax, 100
    movzx rbx, word [r13 + 4]   ; Max HP
    xor rdx, rdx
    div rbx

    ; Bucket: 0=<25%, 1=25-50%, 2=50-75%, 3=>75%
    xor rbx, rbx
    cmp rax, 25
    jl .hp_bucket_done
    inc rbx
    cmp rax, 50
    jl .hp_bucket_done
    inc rbx
    cmp rax, 75
    jl .hp_bucket_done
    inc rbx

.hp_bucket_done:
    ; rbx = HP bucket (0-3)
    mov r8, rbx

    ; Compute type advantage
    ; Get both types
    movzx rax, byte [r12]       ; Player species
    imul rax, 33
    lea rcx, [quigzimon_db]
    add rcx, rax
    movzx r9, byte [rcx + 8]    ; Player type

    movzx rax, byte [r13]       ; Enemy species
    imul rax, 33
    lea rcx, [quigzimon_db]
    add rcx, rax
    movzx r10, byte [rcx + 8]   ; Enemy type

    ; Get type effectiveness
    mov rdi, r9
    mov rsi, r10
    call get_type_effectiveness
    ; rax = 0 (not effective), 1 (neutral), 2 (super effective)
    mov r9, rax

    ; Get status
    movzx r10, byte [r13 + 8]   ; Enemy status (0-3)

    ; Get last move (for now, use 0)
    xor r11, r11

    ; Compute state index
    ; state = hp_bucket * 48 + type_adv * 16 + status * 4 + last_move
    mov rax, r8
    imul rax, 48

    mov rbx, r9
    imul rbx, 16
    add rax, rbx

    mov rbx, r10
    imul rbx, 4
    add rax, rbx

    add rax, r11

    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; ========== ACTION SELECTION ==========

; Select action using epsilon-greedy policy
; Input: rax = current state
; Output: rax = selected action (0-3)
ai_select_action:
    push rbp
    mov rbp, rsp
    push rbx
    push r12

    mov r12, rax    ; Save state

    ; Generate random number 0-4095
    call get_random
    and rax, 0xFFF

    ; Compare with epsilon
    movzx rbx, word [epsilon]
    cmp rax, rbx
    jl .explore

    ; Exploit: choose best action from Q-table
    mov rdi, r12
    call ai_get_best_action
    jmp .done

.explore:
    ; Explore: choose random action
    call get_random
    and rax, 3      ; 0-3

.done:
    pop r12
    pop rbx
    pop rbp
    ret

; Get best action for a state from Q-table
; Input: rdi = state index
; Output: rax = best action
ai_get_best_action:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    push r12
    push r13

    mov r12, rdi

    ; Find action with highest Q-value
    xor r13, r13        ; Best action
    mov rbx, -32768     ; Best Q-value (start with min)

    xor rcx, rcx        ; Action index
.check_action:
    cmp rcx, 4
    jge .done

    ; Get Q[state][action]
    mov rax, r12
    imul rax, 4
    add rax, rcx

    lea rdi, [q_table]
    movsx rax, word [rdi + rax * 2]

    ; Compare with best
    cmp rax, rbx
    jle .next_action

    mov rbx, rax
    mov r13, rcx

.next_action:
    inc rcx
    jmp .check_action

.done:
    mov rax, r13

    pop r13
    pop r12
    pop rcx
    pop rbx
    pop rbp
    ret

; ========== Q-VALUE UPDATE ==========

; Update Q-value based on experience
; Input: rdi = state, rsi = action, rdx = reward, rcx = next_state
ai_update_q_value:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi    ; state
    mov r13, rsi    ; action
    mov r14, rdx    ; reward
    mov r15, rcx    ; next_state

    ; Q(s,a) = Q(s,a) + α * [r + γ * max(Q(s',a')) - Q(s,a)]

    ; 1. Get current Q(s,a)
    mov rax, r12
    imul rax, 4
    add rax, r13
    lea rdi, [q_table]
    movsx rbx, word [rdi + rax * 2]  ; rbx = Q(s,a)
    mov r8, rax                       ; Save index

    ; 2. Get max Q(s',a')
    mov rdi, r15
    call ai_get_max_q_value
    mov rcx, rax    ; rcx = max Q(s',a')

    ; 3. Calculate: r + γ * max(Q(s',a'))
    movsx rax, word [discount_factor]
    imul rax, rcx
    sar rax, 12     ; Divide by 4096 (fixed point)
    add rax, r14    ; Add reward

    ; 4. Calculate: [r + γ * max(Q(s',a'))] - Q(s,a)
    sub rax, rbx

    ; 5. Calculate: α * temporal_difference
    movsx rbx, word [learning_rate]
    imul rax, rbx
    sar rax, 12     ; Divide by 4096

    ; 6. Update: Q(s,a) = Q(s,a) + α * TD
    lea rdi, [q_table]
    movsx rbx, word [rdi + r8 * 2]
    add rbx, rax

    ; Clamp to prevent overflow
    cmp rbx, 32767
    jle .check_min
    mov rbx, 32767
    jmp .store

.check_min:
    cmp rbx, -32768
    jge .store
    mov rbx, -32768

.store:
    mov word [rdi + r8 * 2], bx

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Get maximum Q-value for a state
; Input: rdi = state
; Output: rax = max Q-value
ai_get_max_q_value:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx

    mov rbx, -32768     ; Start with minimum

    xor rcx, rcx
.check_action:
    cmp rcx, 4
    jge .done

    ; Get Q[state][action]
    mov rax, rdi
    imul rax, 4
    add rax, rcx

    push rdi
    lea rdi, [q_table]
    movsx rax, word [rdi + rax * 2]
    pop rdi

    cmp rax, rbx
    jle .next
    mov rbx, rax

.next:
    inc rcx
    jmp .check_action

.done:
    mov rax, rbx

    pop rcx
    pop rbx
    pop rbp
    ret

; ========== EXPERIENCE REPLAY ==========

; Store experience in replay buffer
; Input: rdi = state, rsi = action, rdx = reward, rcx = next_state
ai_store_experience:
    push rbp
    mov rbp, rsp
    push rbx

    ; Get current index
    movzx rbx, word [replay_buffer.index]

    ; Store experience
    lea rax, [replay_buffer.states]
    mov word [rax + rbx * 2], di

    lea rax, [replay_buffer.actions]
    mov byte [rax + rbx], sil

    lea rax, [replay_buffer.rewards]
    mov word [rax + rbx * 2], dx

    lea rax, [replay_buffer.next_states]
    mov word [rax + rbx * 2], cx

    ; Increment index (circular buffer)
    inc rbx
    cmp rbx, replay_buffer_size
    jl .no_wrap
    xor rbx, rbx

.no_wrap:
    mov word [replay_buffer.index], bx

    ; Update count (max = buffer size)
    movzx rax, word [replay_buffer.count]
    cmp rax, replay_buffer_size
    jge .done
    inc rax
    mov word [replay_buffer.count], ax

.done:
    pop rbx
    pop rbp
    ret

; Train on random batch from replay buffer
; This improves learning stability
ai_replay_training:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    ; Train on 10 random experiences
    mov r13, 10

.train_loop:
    cmp r13, 0
    jle .done

    ; Get random experience
    call get_random
    xor rdx, rdx
    movzx rcx, word [replay_buffer.count]
    cmp rcx, 0
    je .done
    div rcx

    ; rdx = random index
    mov r12, rdx

    ; Load experience
    lea rax, [replay_buffer.states]
    movzx rdi, word [rax + r12 * 2]

    lea rax, [replay_buffer.actions]
    movzx rsi, byte [rax + r12]

    lea rax, [replay_buffer.rewards]
    movsx rdx, word [rax + r12 * 2]

    lea rax, [replay_buffer.next_states]
    movzx rcx, word [rax + r12 * 2]

    ; Update Q-value
    call ai_update_q_value

    dec r13
    jmp .train_loop

.done:
    pop r13
    pop r12
    pop rbp
    ret

; ========== BATTLE INTEGRATION ==========

; Called when battle starts
ai_battle_start:
    push rbp
    mov rbp, rsp

    ; Compute initial state
    lea rdi, [player_party]
    lea rsi, [enemy_instance]
    call ai_compute_state

    mov word [current_state], ax
    mov word [previous_state], ax

    ; Display AI message
    mov rax, 1
    mov rdi, 1
    mov rsi, ai_learning_msg
    mov rdx, ai_learning_msg_len
    syscall

    pop rbp
    ret

; Called each turn to get AI action
; Output: rax = action (0=Attack, 1=Special, 2=Defend, 3=Status)
ai_get_action:
    push rbp
    mov rbp, rsp

    ; Get current state
    lea rdi, [player_party]
    lea rsi, [enemy_instance]
    call ai_compute_state

    mov word [current_state], ax

    ; Select action
    call ai_select_action

    mov byte [chosen_action], al

    pop rbp
    ret

; Called after action is executed
; Input: rdi = reward for this step
ai_step_update:
    push rbp
    mov rbp, rsp
    push rbx

    mov rbx, rdi    ; Save reward

    ; Get new state
    lea rdi, [player_party]
    lea rsi, [enemy_instance]
    call ai_compute_state

    ; Update Q-value
    movzx rdi, word [previous_state]
    movzx rsi, byte [chosen_action]
    mov rdx, rbx
    movzx rcx, word [current_state]
    call ai_update_q_value

    ; Store experience
    movzx rdi, word [previous_state]
    movzx rsi, byte [chosen_action]
    mov rdx, rbx
    movzx rcx, word [current_state]
    call ai_store_experience

    ; Update state
    mov ax, word [current_state]
    mov word [previous_state], ax

    ; Occasional replay training
    call get_random
    and rax, 7
    cmp rax, 0
    jne .no_replay

    call ai_replay_training

.no_replay:
    pop rbx
    pop rbp
    ret

; Called when battle ends
; Input: rdi = 1 if AI won, 0 if lost
ai_battle_end:
    push rbp
    mov rbp, rsp
    push rbx

    mov rbx, rdi

    ; Increment battle count
    inc word [total_battles]

    ; Update victory/defeat count
    cmp rbx, 1
    jne .defeat

    inc word [total_victories]
    movsx rdi, word [reward_victory]
    jmp .update

.defeat:
    inc word [total_defeats]
    movsx rdi, word [reward_defeat]

.update:
    ; Final reward update
    call ai_step_update

    ; Decay epsilon
    movzx rax, word [epsilon]
    movzx rbx, word [epsilon_decay]
    imul rax, rbx
    shr rax, 12

    movzx rbx, word [epsilon_min]
    cmp rax, rbx
    jge .store_epsilon
    mov rax, rbx

.store_epsilon:
    mov word [epsilon], ax

    ; Increment episodes
    inc word [episodes_trained]

    ; Update AI intelligence level
    call ai_update_intelligence

    ; Replay training
    call ai_replay_training
    call ai_replay_training  ; Extra training at episode end

    pop rbx
    pop rbp
    ret

; ========== AI INTELLIGENCE SYSTEM ==========

; Update AI intelligence level based on performance
ai_update_intelligence:
    push rbp
    mov rbp, rsp
    push rbx

    ; Calculate win rate
    movzx rax, word [total_victories]
    cmp rax, 0
    je .novice

    imul rax, 100
    movzx rbx, word [total_battles]
    cmp rbx, 0
    je .novice
    xor rdx, rdx
    div rbx

    ; rax = win rate percentage

    ; Level based on win rate
    cmp rax, 20
    jl .novice
    cmp rax, 40
    jl .intermediate
    cmp rax, 60
    jl .advanced
    cmp rax, 80
    jl .expert

    ; Master level
    mov byte [ai_intelligence_level], 5
    jmp .done

.expert:
    mov byte [ai_intelligence_level], 4
    jmp .done

.advanced:
    mov byte [ai_intelligence_level], 3
    jmp .done

.intermediate:
    mov byte [ai_intelligence_level], 2
    jmp .done

.novice:
    mov byte [ai_intelligence_level], 1

.done:
    pop rbx
    pop rbp
    ret

; Display AI intelligence
ai_display_intelligence:
    push rbp
    mov rbp, rsp

    mov rax, 1
    mov rdi, 1
    mov rsi, ai_difficulty_msg
    mov rdx, ai_difficulty_msg_len
    syscall

    movzx rax, byte [ai_intelligence_level]

    cmp rax, 1
    je .novice
    cmp rax, 2
    je .intermediate
    cmp rax, 3
    je .advanced
    cmp rax, 4
    je .expert

    mov rsi, difficulty_master
    jmp .display

.expert:
    mov rsi, difficulty_expert
    jmp .display

.advanced:
    mov rsi, difficulty_advanced
    jmp .display

.intermediate:
    mov rsi, difficulty_intermediate
    jmp .display

.novice:
    mov rsi, difficulty_novice

.display:
    ; Find string length
    mov rdi, rsi
    call strlen
    mov rdx, rax

    mov rax, 1
    mov rdi, 1
    syscall

    pop rbp
    ret

; Get string length
strlen:
    push rbx
    xor rax, rax
.loop:
    cmp byte [rdi + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    pop rbx
    ret

; ========== SAVE/LOAD Q-TABLE ==========

; Save Q-table to file
ai_save_qtable:
    push rbp
    mov rbp, rsp

    ; Open file for writing
    mov rax, 2      ; sys_open
    lea rdi, [qtable_filename]
    mov rsi, 0x241  ; O_CREAT | O_WRONLY | O_TRUNC
    mov rdx, 0644o
    syscall

    cmp rax, 0
    jl .error

    mov r12, rax    ; Save file descriptor

    ; Write Q-table
    mov rax, 1      ; sys_write
    mov rdi, r12
    lea rsi, [q_table]
    mov rdx, 1536   ; 768 words * 2 bytes
    syscall

    ; Close file
    mov rax, 3
    mov rdi, r12
    syscall

    xor rax, rax
    pop rbp
    ret

.error:
    mov rax, -1
    pop rbp
    ret

; Load Q-table from file
ai_load_qtable:
    push rbp
    mov rbp, rsp

    ; Open file for reading
    mov rax, 2
    lea rdi, [qtable_filename]
    mov rsi, 0      ; O_RDONLY
    syscall

    cmp rax, 0
    jl .error

    mov r12, rax

    ; Read Q-table
    mov rax, 0      ; sys_read
    mov rdi, r12
    lea rsi, [q_table]
    mov rdx, 1536
    syscall

    ; Close file
    mov rax, 3
    mov rdi, r12
    syscall

    xor rax, rax
    pop rbp
    ret

.error:
    mov rax, -1
    pop rbp
    ret

section .data
    qtable_filename db "quigzimon_ai.qtable", 0

; ========== EXPORTS ==========
global ai_init
global ai_compute_state
global ai_select_action
global ai_get_best_action
global ai_update_q_value
global ai_battle_start
global ai_get_action
global ai_step_update
global ai_battle_end
global ai_display_intelligence
global ai_save_qtable
global ai_load_qtable
global q_table
global ai_intelligence_level
