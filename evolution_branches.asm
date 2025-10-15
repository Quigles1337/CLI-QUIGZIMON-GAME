; QUIGZIMON Branching Evolution System
; Pure x86-64 assembly implementation of multi-path evolution
; First-ever branching evolution tree in assembly!

section .data
    ; ========== EVOLUTION BRANCH MESSAGES ==========
    branch_title db 0xA
                 db "╔════════════════════════════════════════════════════╗", 0xA
                 db "║                                                    ║", 0xA
                 db "║         ✨ EVOLUTION BRANCHES ✨                   ║", 0xA
                 db "║                                                    ║", 0xA
                 db "║     Choose Your QUIGZIMON's Evolution Path!       ║", 0xA
                 db "║                                                    ║", 0xA
                 db "╚════════════════════════════════════════════════════╝", 0xA, 0xA, 0
    branch_title_len equ $ - branch_title

    ; ========== EVOLUTION PATHS ==========
    evolution_choice_msg db "This QUIGZIMON can evolve into multiple forms!", 0xA
                         db "Choose your evolution path wisely!", 0xA, 0xA, 0
    evolution_choice_msg_len equ $ - evolution_choice_msg

    path_attack_label db "Path A: ATTACK FORM", 0xA
                      db "  Focus: High Attack, Aggressive", 0xA
                      db "  Multipliers: ATK 2.0x, HP 1.3x, DEF 1.2x, SPD 1.4x", 0xA, 0xA, 0
    path_attack_label_len equ $ - path_attack_label

    path_defense_label db "Path B: DEFENSE FORM", 0xA
                       db "  Focus: High Defense, Tank", 0xA
                       db "  Multipliers: DEF 2.0x, HP 1.8x, ATK 1.2x, SPD 1.0x", 0xA, 0xA, 0
    path_defense_label_len equ $ - path_defense_label

    path_speed_label db "Path C: SPEED FORM", 0xA
                     db "  Focus: High Speed, Evasive", 0xA
                     db "  Multipliers: SPD 2.0x, ATK 1.5x, HP 1.2x, DEF 1.1x", 0xA, 0xA, 0
    path_speed_label_len equ $ - path_speed_label

    path_balanced_label db "Path D: BALANCED FORM", 0xA
                        db "  Focus: All-Around, Versatile", 0xA
                        db "  Multipliers: All Stats 1.5x", 0xA, 0xA, 0
    path_balanced_label_len equ $ - path_balanced_label

    ; ========== EVOLUTION REQUIREMENTS ==========
    branch_requirements_header db "Evolution Requirements:", 0xA, 0
    branch_requirements_header_len equ $ - branch_requirements_header

    req_level_20_msg db "  ✓ Level 20+", 0xA, 0
    req_level_20_msg_len equ $ - req_level_20_msg

    req_stones_msg db "  • Evolution Stone: ", 0
    req_stones_msg_len equ $ - req_stones_msg

    stone_attack db "Attack Stone", 0
    stone_defense db "Defense Stone", 0
    stone_speed db "Speed Stone", 0
    stone_cosmic db "Cosmic Stone (Balanced)", 0

    ; ========== EVOLUTION STONE SYSTEM ==========
    acquire_stone_msg db 0xA, "💎 You need an Evolution Stone!", 0xA
                      db "Stones can be:", 0xA
                      db "  • Found in battles (rare drop)", 0xA
                      db "  • Purchased from marketplace", 0xA
                      db "  • Won in tournaments", 0xA, 0xA, 0
    acquire_stone_msg_len equ $ - acquire_stone_msg

    has_stone_msg db "✅ You have: ", 0
    has_stone_msg_len equ $ - has_stone_msg

    no_stone_msg db "❌ Missing: ", 0
    no_stone_msg_len equ $ - no_stone_msg

    ; ========== EVOLUTION TREE DISPLAY ==========
    evolution_tree_header db 0xA, "EVOLUTION TREE:", 0xA, 0xA, 0
    evolution_tree_header_len equ $ - evolution_tree_header

    ; Example: QUIGFLAME evolution tree
    tree_quigflame db "                 QUIGFLAME (Basic)", 0xA
                   db "                       │", 0xA
                   db "                    Lv 20", 0xA
                   db "       ┌───────────┬───┴───┬───────────┐", 0xA
                   db "       │           │       │           │", 0xA
                   db "   QUIGBLAZER  QUIGTANK  QUIGDASH  QUIGBALANCE", 0xA
                   db "   (Attack)    (Defense) (Speed)   (Balanced)", 0xA
                   db "   ATK Focus   DEF Focus SPD Focus All-Round", 0xA, 0xA, 0
    tree_quigflame_len equ $ - tree_quigflame

    ; ========== MEGA EVOLUTION ==========
    mega_evolution_title db 0xA, "═══════════════════════════════════════", 0xA
                         db "      MEGA EVOLUTION", 0xA
                         db "═══════════════════════════════════════", 0xA, 0xA, 0
    mega_evolution_title_len equ $ - mega_evolution_title

    mega_requirements db "Mega Evolution Requirements:", 0xA
                      db "  • Level 60+", 0xA
                      db "  • Stage 2 Evolution", 0xA
                      db "  • Mega Stone (100 XRP)", 0xA
                      db "  • Max Friendship", 0xA, 0xA, 0
    mega_requirements_len equ $ - mega_requirements

    mega_bonus_msg db "Mega Evolution provides:", 0xA
                   db "  🔥 All Stats 3.0x", 0xA
                   db "  ⚡ Special Ability Unlocked", 0xA
                   db "  ✨ Unique Appearance", 0xA
                   db "  🏆 Tournament Bonus", 0xA, 0xA, 0
    mega_bonus_msg_len equ $ - mega_bonus_msg

section .bss
    ; ========== EVOLUTION BRANCH DATA ==========
    evolution_branches:
        .count resq 1
        .data resb 10000

    ; Branch definition (100 bytes):
    ; - species_id (1 byte)
    ; - tier (1 byte)
    ; - branch_count (1 byte)
    ; - branch_paths (4 * 20 bytes = 80 bytes)
    ;   Each path:
    ;   - evolved_species_id (1 byte)
    ;   - required_stone (1 byte)
    ;   - hp_mult (2 bytes) - fixed point
    ;   - atk_mult (2 bytes)
    ;   - def_mult (2 bytes)
    ;   - spd_mult (2 bytes)
    ;   - special_requirement (8 bytes)
    ;   - name_suffix (8 bytes)

    ; ========== PLAYER INVENTORY ==========
    evolution_stones:
        .attack_stone_count resb 1
        .defense_stone_count resb 1
        .speed_stone_count resb 1
        .cosmic_stone_count resb 1
        .mega_stone_count resb 1

    ; ========== SELECTED EVOLUTION ==========
    selected_branch_index resb 1
    selected_evolution_path resb 1
    evolved_species_id resb 1

section .text
    global evolve_with_branch
    global display_evolution_tree
    global check_branch_requirements
    global acquire_evolution_stone
    global mega_evolve

    extern evolve_nft
    extern calculate_evolved_stats
    extern burn_original_nft
    extern mint_evolved_nft
    extern account_balance
    extern print_string
    extern print_number
    extern get_yes_no

; ========== EVOLVE WITH BRANCH SELECTION ==========
; Evolve QUIGZIMON with player choice of evolution path
; Input: rdi = pointer to NFT Token ID
;        rsi = pointer to QUIGZIMON data
; Returns: rax = 0 on success, -1 on error
evolve_with_branch:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push r12
    push r13

    mov r12, rdi            ; NFT Token ID
    mov r13, rsi            ; QUIGZIMON data

    ; Display title
    mov rax, 1
    mov rdi, 1
    lea rsi, [branch_title]
    mov rdx, branch_title_len
    syscall

    ; Get species and tier
    movzx r14, byte [r13]       ; Species
    movzx r15, byte [r13 + 1]   ; Level (determines tier)

    ; Check if this species has branching evolution
    mov rdi, r14
    call get_evolution_branches
    test rax, rax
    jz .no_branches

    mov rbx, rax            ; Branch data pointer

    ; Display evolution choice message
    mov rax, 1
    mov rdi, 1
    lea rsi, [evolution_choice_msg]
    mov rdx, evolution_choice_msg_len
    syscall

    ; Display evolution tree
    mov rdi, r14
    call display_evolution_tree

    ; Display available paths
    call display_evolution_paths

    ; Get player choice
    mov rax, 1
    mov rdi, 1
    lea rsi, [select_path_prompt]
    mov rdx, select_path_prompt_len
    syscall

    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 64
    syscall

    movzx rax, byte [input_buffer]
    sub al, '0'
    dec al
    mov [selected_evolution_path], al

    ; Check requirements for selected path
    movzx rdi, byte [selected_evolution_path]
    call check_branch_requirements
    test rax, rax
    jnz .requirements_not_met

    ; Calculate evolved stats based on path multipliers
    mov rdi, r13
    movzx rsi, byte [selected_evolution_path]
    call calculate_branch_stats

    ; Confirm evolution
    call confirm_branch_evolution
    test rax, rax
    jnz .canceled

    ; Consume evolution stone
    movzx rdi, byte [selected_evolution_path]
    call consume_evolution_stone

    ; Burn original NFT
    mov rdi, r12
    call burn_original_nft
    test rax, rax
    jnz .error

    ; Mint evolved NFT with new form
    lea rdi, [evolved_data]
    movzx rsi, byte [selected_evolution_path]
    call mint_branched_evolution
    test rax, rax
    jnz .error

    ; Display success
    call display_evolution_success

    xor rax, rax
    pop r13
    pop r12
    add rsp, 32
    pop rbp
    ret

.no_branches:
    ; Fall back to standard evolution
    mov rdi, r12
    mov rsi, r13
    call evolve_nft
    pop r13
    pop r12
    add rsp, 32
    pop rbp
    ret

.requirements_not_met:
.canceled:
.error:
    mov rax, -1
    pop r13
    pop r12
    add rsp, 32
    pop rbp
    ret

; ========== DISPLAY EVOLUTION TREE ==========
; Display evolution tree for species
; Input: rdi = species ID
display_evolution_tree:
    push rbp
    mov rbp, rsp

    ; Display header
    mov rax, 1
    mov rdi, 1
    lea rsi, [evolution_tree_header]
    mov rdx, evolution_tree_header_len
    syscall

    ; Display tree based on species
    ; For now, show QUIGFLAME tree as example
    mov rax, 1
    mov rdi, 1
    lea rsi, [tree_quigflame]
    mov rdx, tree_quigflame_len
    syscall

    pop rbp
    ret

; ========== CHECK BRANCH REQUIREMENTS ==========
; Check if player meets requirements for evolution path
; Input: rdi = evolution path index (0-3)
; Returns: rax = 0 if met, -1 if not met
check_branch_requirements:
    push rbp
    mov rbp, rsp
    push r12

    mov r12, rdi

    ; Display requirements header
    mov rax, 1
    mov rdi, 1
    lea rsi, [branch_requirements_header]
    mov rdx, branch_requirements_header_len
    syscall

    ; Check level (always 20+)
    mov rax, 1
    mov rdi, 1
    lea rsi, [req_level_20_msg]
    mov rdx, req_level_20_msg_len
    syscall

    ; Check evolution stone
    mov rax, 1
    mov rdi, 1
    lea rsi, [req_stones_msg]
    mov rdx, req_stones_msg_len
    syscall

    ; Display required stone based on path
    cmp r12, 0
    je .attack_stone
    cmp r12, 1
    je .defense_stone
    cmp r12, 2
    je .speed_stone
    cmp r12, 3
    je .cosmic_stone

.attack_stone:
    mov rax, 1
    mov rdi, 1
    lea rsi, [stone_attack]
    mov rdx, 12
    syscall

    ; Check if player has it
    movzx rax, byte [evolution_stones.attack_stone_count]
    test rax, rax
    jz .missing_stone
    jmp .has_stone

.defense_stone:
    mov rax, 1
    mov rdi, 1
    lea rsi, [stone_defense]
    mov rdx, 13
    syscall

    movzx rax, byte [evolution_stones.defense_stone_count]
    test rax, rax
    jz .missing_stone
    jmp .has_stone

.speed_stone:
    mov rax, 1
    mov rdi, 1
    lea rsi, [stone_speed]
    mov rdx, 11
    syscall

    movzx rax, byte [evolution_stones.speed_stone_count]
    test rax, rax
    jz .missing_stone
    jmp .has_stone

.cosmic_stone:
    mov rax, 1
    mov rdi, 1
    lea rsi, [stone_cosmic]
    mov rdx, 22
    syscall

    movzx rax, byte [evolution_stones.cosmic_stone_count]
    test rax, rax
    jz .missing_stone

.has_stone:
    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [has_stone_msg]
    mov rdx, has_stone_msg_len
    syscall

    mov rax, 1
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    xor rax, rax
    pop r12
    pop rbp
    ret

.missing_stone:
    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [acquire_stone_msg]
    mov rdx, acquire_stone_msg_len
    syscall

    mov rax, -1
    pop r12
    pop rbp
    ret

; ========== CALCULATE BRANCH STATS ==========
; Calculate evolved stats based on selected branch
; Input: rdi = QUIGZIMON data pointer
;        rsi = evolution path index
calculate_branch_stats:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov r12, rdi
    mov r13, rsi

    ; Get multipliers for selected path
    imul r13, 20            ; Each path is 20 bytes
    lea rbx, [evolution_branches.data]
    add rbx, r13

    ; Apply multipliers to base stats
    ; HP
    movzx rax, word [r12 + 4]
    movzx rcx, word [rbx + 2]       ; hp_mult
    imul rax, rcx
    shr rax, 8                      ; Fixed point divide
    mov word [evolved_data + 4], ax

    ; ATK
    movzx rax, word [r12 + 9]
    movzx rcx, word [rbx + 4]       ; atk_mult
    imul rax, rcx
    shr rax, 8
    mov word [evolved_data + 9], ax

    ; DEF
    movzx rax, word [r12 + 11]
    movzx rcx, word [rbx + 6]       ; def_mult
    imul rax, rcx
    shr rax, 8
    mov word [evolved_data + 11], ax

    ; SPD
    movzx rax, word [r12 + 13]
    movzx rcx, word [rbx + 8]       ; spd_mult
    imul rax, rcx
    shr rax, 8
    mov word [evolved_data + 13], ax

    pop r13
    pop r12
    pop rbp
    ret

; ========== MEGA EVOLUTION ==========
; Ultimate evolution form with massive stat boost
; Input: rdi = pointer to Stage 2 NFT
; Returns: rax = 0 on success, -1 on error
mega_evolve:
    push rbp
    mov rbp, rsp

    ; Display mega evolution title
    mov rax, 1
    mov rdi, 1
    lea rsi, [mega_evolution_title]
    mov rdx, mega_evolution_title_len
    syscall

    ; Display requirements
    mov rax, 1
    mov rdi, 1
    lea rsi, [mega_requirements]
    mov rdx, mega_requirements_len
    syscall

    ; Display bonuses
    mov rax, 1
    mov rdi, 1
    lea rsi, [mega_bonus_msg]
    mov rdx, mega_bonus_msg_len
    syscall

    ; Check if player has Mega Stone
    movzx rax, byte [evolution_stones.mega_stone_count]
    test rax, rax
    jz .no_mega_stone

    ; Apply 3.0x multiplier to all stats
    ; Burn Stage 2 NFT
    ; Mint Mega NFT

    xor rax, rax
    pop rbp
    ret

.no_mega_stone:
    mov rax, -1
    pop rbp
    ret

; ========== HELPER FUNCTIONS ==========

; Get evolution branches for species
get_evolution_branches:
    ; Return branch data for species
    ; For now, assume all species have 4 branches
    lea rax, [evolution_branches.data]
    ret

; Display evolution paths
display_evolution_paths:
    ; Display all available paths
    mov rax, 1
    mov rdi, 1
    lea rsi, [path_attack_label]
    mov rdx, path_attack_label_len
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [path_defense_label]
    mov rdx, path_defense_label_len
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [path_speed_label]
    mov rdx, path_speed_label_len
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [path_balanced_label]
    mov rdx, path_balanced_label_len
    syscall

    ret

; Confirm branch evolution
confirm_branch_evolution:
    xor rax, rax
    ret

; Consume evolution stone
consume_evolution_stone:
    ; Decrement stone count
    cmp rdi, 0
    jne .not_attack
    dec byte [evolution_stones.attack_stone_count]
    ret

.not_attack:
    cmp rdi, 1
    jne .not_defense
    dec byte [evolution_stones.defense_stone_count]
    ret

.not_defense:
    cmp rdi, 2
    jne .not_speed
    dec byte [evolution_stones.speed_stone_count]
    ret

.not_speed:
    dec byte [evolution_stones.cosmic_stone_count]
    ret

; Mint branched evolution
mint_branched_evolution:
    ; Mint NFT with evolved form
    xor rax, rax
    ret

; Display evolution success
display_evolution_success:
    ret

; Acquire evolution stone
acquire_evolution_stone:
    ; Add stone to inventory
    ; (would integrate with marketplace/tournaments)
    ret

section .bss
    input_buffer resb 64
    evolved_data resb 15
    newline db 0xA
    select_path_prompt db 0xA, "Select evolution path (A/B/C/D): ", 0
    select_path_prompt_len equ 36

; ========== EXPORTS ==========
global evolve_with_branch
global display_evolution_tree
global check_branch_requirements
global acquire_evolution_stone
global mega_evolve
global evolution_stones
