; QUIGZIMON Battle System - x86-64 NASM Assembly
; CLI-based battle system inspired by Pokemon Red/Green

section .data
    ; Game title and messages
    title db "=== QUIGZIMON BATTLE ===", 0xA, 0
    title_len equ $ - title

    battle_start db 0xA, "A wild QUIGZIMON appeared!", 0xA, 0
    battle_start_len equ $ - battle_start

    player_turn db 0xA, "Your turn! Choose action:", 0xA, 0
    player_turn_len equ $ - player_turn

    action_menu db "1) Attack", 0xA, "2) Run", 0xA, "> ", 0
    action_menu_len equ $ - action_menu

    attack_msg db 0xA, "Your QUIGZIMON attacks!", 0xA, 0
    attack_msg_len equ $ - attack_msg

    enemy_attack_msg db "Enemy QUIGZIMON attacks!", 0xA, 0
    enemy_attack_msg_len equ $ - enemy_attack_msg

    damage_msg db "Damage dealt: ", 0
    damage_msg_len equ $ - damage_msg

    hp_msg db " HP", 0xA, 0
    hp_msg_len equ $ - hp_msg

    player_hp_msg db "Your QUIGZIMON HP: ", 0
    player_hp_msg_len equ $ - player_hp_msg

    enemy_hp_msg db "Enemy QUIGZIMON HP: ", 0
    enemy_hp_msg_len equ $ - enemy_hp_msg

    victory_msg db 0xA, "Victory! Enemy QUIGZIMON fainted!", 0xA, 0
    victory_msg_len equ $ - victory_msg

    defeat_msg db 0xA, "Defeat! Your QUIGZIMON fainted!", 0xA, 0
    defeat_msg_len equ $ - defeat_msg

    run_msg db 0xA, "Got away safely!", 0xA, 0
    run_msg_len equ $ - run_msg

    newline db 0xA, 0

    ; QUIGZIMON stats (Name, HP, Attack, Defense)
    player_monster:
        .name db "QUIGFLAME", 0
        .hp dq 45
        .max_hp dq 45
        .attack dq 12
        .defense dq 8

    enemy_monster:
        .name db "QUIGLEAF", 0
        .hp dq 38
        .max_hp dq 38
        .attack dq 10
        .defense dq 6

section .bss
    input resb 2
    num_buffer resb 20

section .text
    global _start

_start:
    ; Print title
    mov rax, 1
    mov rdi, 1
    mov rsi, title
    mov rdx, title_len
    syscall

    ; Start battle
    call battle_loop

    ; Exit program
    mov rax, 60
    xor rdi, rdi
    syscall

battle_loop:
    ; Print battle start
    mov rax, 1
    mov rdi, 1
    mov rsi, battle_start
    mov rdx, battle_start_len
    syscall

    ; Display initial HP
    call display_hp

.turn_loop:
    ; Check if battle is over
    mov rax, [enemy_monster.hp]
    cmp rax, 0
    jle .player_wins

    mov rax, [player_monster.hp]
    cmp rax, 0
    jle .player_loses

    ; Player turn
    call player_turn_func

    ; Check input (stored in input buffer)
    mov al, byte [input]
    cmp al, '1'
    je .player_attack
    cmp al, '2'
    je .run_away
    jmp .turn_loop

.player_attack:
    ; Player attacks
    mov rax, 1
    mov rdi, 1
    mov rsi, attack_msg
    mov rdx, attack_msg_len
    syscall

    ; Calculate damage: attack - defense (minimum 1)
    mov rax, [player_monster.attack]
    mov rbx, [enemy_monster.defense]
    sub rax, rbx
    cmp rax, 1
    jge .damage_ok
    mov rax, 1

.damage_ok:
    ; Apply damage to enemy
    mov rbx, [enemy_monster.hp]
    sub rbx, rax
    cmp rbx, 0
    jge .store_enemy_hp
    xor rbx, rbx

.store_enemy_hp:
    mov [enemy_monster.hp], rbx

    ; Display damage
    push rax
    call print_damage
    pop rax

    ; Check if enemy fainted
    mov rax, [enemy_monster.hp]
    cmp rax, 0
    jle .player_wins

    ; Enemy turn
    call enemy_turn_func

    ; Display HP after turn
    call display_hp

    jmp .turn_loop

.run_away:
    mov rax, 1
    mov rdi, 1
    mov rsi, run_msg
    mov rdx, run_msg_len
    syscall
    ret

.player_wins:
    mov rax, 1
    mov rdi, 1
    mov rsi, victory_msg
    mov rdx, victory_msg_len
    syscall
    ret

.player_loses:
    mov rax, 1
    mov rdi, 1
    mov rsi, defeat_msg
    mov rdx, defeat_msg_len
    syscall
    ret

player_turn_func:
    ; Display player turn message
    mov rax, 1
    mov rdi, 1
    mov rsi, player_turn
    mov rdx, player_turn_len
    syscall

    ; Display action menu
    mov rax, 1
    mov rdi, 1
    mov rsi, action_menu
    mov rdx, action_menu_len
    syscall

    ; Read input
    mov rax, 0
    mov rdi, 0
    mov rsi, input
    mov rdx, 2
    syscall

    ret

enemy_turn_func:
    ; Enemy attacks
    mov rax, 1
    mov rdi, 1
    mov rsi, enemy_attack_msg
    mov rdx, enemy_attack_msg_len
    syscall

    ; Calculate damage
    mov rax, [enemy_monster.attack]
    mov rbx, [player_monster.defense]
    sub rax, rbx
    cmp rax, 1
    jge .enemy_damage_ok
    mov rax, 1

.enemy_damage_ok:
    ; Apply damage to player
    mov rbx, [player_monster.hp]
    sub rbx, rax
    cmp rbx, 0
    jge .store_player_hp
    xor rbx, rbx

.store_player_hp:
    mov [player_monster.hp], rbx

    ; Display damage
    call print_damage

    ret

display_hp:
    ; Display player HP
    mov rax, 1
    mov rdi, 1
    mov rsi, player_hp_msg
    mov rdx, player_hp_msg_len
    syscall

    mov rax, [player_monster.hp]
    call print_number

    mov rax, 1
    mov rdi, 1
    mov rsi, hp_msg
    mov rdx, hp_msg_len
    syscall

    ; Display enemy HP
    mov rax, 1
    mov rdi, 1
    mov rsi, enemy_hp_msg
    mov rdx, enemy_hp_msg_len
    syscall

    mov rax, [enemy_monster.hp]
    call print_number

    mov rax, 1
    mov rdi, 1
    mov rsi, hp_msg
    mov rdx, hp_msg_len
    syscall

    ret

print_damage:
    push rax

    mov rax, 1
    mov rdi, 1
    mov rsi, damage_msg
    mov rdx, damage_msg_len
    syscall

    pop rax
    call print_number

    mov rax, 1
    mov rdi, 1
    mov rsi, hp_msg
    mov rdx, hp_msg_len
    syscall

    ret

print_number:
    ; Convert number in rax to string and print
    push rbx
    push rcx
    push rdx

    mov rbx, 10
    mov rcx, 0
    lea rsi, [num_buffer + 19]
    mov byte [rsi], 0

.convert_loop:
    dec rsi
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rsi], dl
    inc rcx
    test rax, rax
    jnz .convert_loop

    ; Print the number
    mov rax, 1
    mov rdi, 1
    mov rdx, rcx
    syscall

    pop rdx
    pop rcx
    pop rbx
    ret
