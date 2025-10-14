; QUIGZIMON Enhanced Battle System - x86-64 NASM Assembly
; Full-featured RPG with catching, leveling, world map, and more!

section .data
    ; ========== GAME CONSTANTS ==========
    MAX_PARTY_SIZE equ 6
    MAX_CAUGHT equ 20
    TYPE_FIRE equ 0
    TYPE_WATER equ 1
    TYPE_GRASS equ 2
    TYPE_NORMAL equ 3

    STATUS_NONE equ 0
    STATUS_POISON equ 1
    STATUS_SLEEP equ 2
    STATUS_PARALYZE equ 3

    ; ========== TITLE & MENUS ==========
    title db "╔════════════════════════════════╗", 0xA
          db "║     QUIGZIMON ADVENTURE       ║", 0xA
          db "╚════════════════════════════════╝", 0xA, 0
    title_len equ $ - title

    starter_menu db 0xA, "Choose your starter QUIGZIMON:", 0xA
                 db "1) QUIGFLAME  (Fire)   - Balanced attacker", 0xA
                 db "2) QUIGWAVE   (Water)  - High defense", 0xA
                 db "3) QUIGLEAF   (Grass)  - Fast & evasive", 0xA
                 db "> ", 0
    starter_menu_len equ $ - starter_menu

    world_map db 0xA, "╔════════ WORLD MAP ════════╗", 0xA
              db "║  Current Location: ", 0
    world_map_len equ $ - world_map

    world_menu db 0xA, "What will you do?", 0xA
               db "1) Explore (find wild QUIGZIMON)", 0xA
               db "2) View Party", 0xA
               db "3) Save Game", 0xA
               db "4) Quit", 0xA
               db "> ", 0
    world_menu_len equ $ - world_menu

    ; ========== BATTLE MESSAGES ==========
    battle_start db 0xA, "═══════════════════════════", 0xA
                 db "A wild QUIGZIMON appeared!", 0xA
                 db "═══════════════════════════", 0xA, 0
    battle_start_len equ $ - battle_start

    battle_menu db 0xA, "Choose your action:", 0xA
                db "1) Attack", 0xA
                db "2) Special Move", 0xA
                db "3) Catch", 0xA
                db "4) Run", 0xA
                db "> ", 0
    battle_menu_len equ $ - battle_menu

    move_menu db 0xA, "Select move:", 0xA
              db "1) ", 0
    move_menu_len equ $ - move_menu

    ; ========== ATTACK MESSAGES ==========
    attack_msg db 0xA, " attacks!", 0xA, 0
    attack_msg_len equ $ - attack_msg

    super_effective db "It's super effective!", 0xA, 0
    super_effective_len equ $ - super_effective

    not_effective db "It's not very effective...", 0xA, 0
    not_effective_len equ $ - not_effective

    critical_hit db "Critical hit!", 0xA, 0
    critical_hit_len equ $ - critical_hit

    ; ========== STATUS MESSAGES ==========
    poison_msg db " is poisoned!", 0xA, 0
    poison_msg_len equ $ - poison_msg

    sleep_msg db " fell asleep!", 0xA, 0
    sleep_msg_len equ $ - sleep_msg

    paralyze_msg db " is paralyzed!", 0xA, 0
    paralyze_msg_len equ $ - paralyze_msg

    wake_msg db " woke up!", 0xA, 0
    wake_msg_len equ $ - wake_msg

    cant_move_sleep db " is fast asleep!", 0xA, 0
    cant_move_sleep_len equ $ - cant_move_sleep

    cant_move_para db " is paralyzed and can't move!", 0xA, 0
    cant_move_para_len equ $ - cant_move_para

    poison_damage_msg db " takes poison damage!", 0xA, 0
    poison_damage_msg_len equ $ - poison_damage_msg

    ; ========== CATCH MESSAGES ==========
    catch_attempt db 0xA, "You throw a QUIGZIBALL...", 0xA, 0
    catch_attempt_len equ $ - catch_attempt

    catch_success db "Gotcha! QUIGZIMON was caught!", 0xA, 0
    catch_success_len equ $ - catch_success

    catch_fail db "Oh no! The QUIGZIMON broke free!", 0xA, 0
    catch_fail_len equ $ - catch_fail

    party_full db "Your party is full!", 0xA, 0
    party_full_len equ $ - party_full

    ; ========== LEVEL UP MESSAGES ==========
    level_up_msg db 0xA, "Level up! Now level ", 0
    level_up_msg_len equ $ - level_up_msg

    exp_gained_msg db "Gained ", 0
    exp_gained_msg_len equ $ - exp_gained_msg

    exp_suffix db " EXP!", 0xA, 0
    exp_suffix_len equ $ - exp_suffix

    ; ========== GENERAL MESSAGES ==========
    damage_msg db "Damage: ", 0
    damage_msg_len equ $ - damage_msg

    hp_display db " HP: ", 0
    hp_display_len equ $ - hp_display

    level_display db " Lv.", 0
    level_display_len equ $ - level_display

    exp_display db " EXP: ", 0
    exp_display_len equ $ - exp_display

    victory_msg db 0xA, "═══════════════════════════", 0xA
                db "     Victory!", 0xA
                db "═══════════════════════════", 0xA, 0
    victory_msg_len equ $ - victory_msg

    defeat_msg db 0xA, "Your QUIGZIMON fainted!", 0xA, 0
    defeat_msg_len equ $ - defeat_msg

    run_msg db 0xA, "Got away safely!", 0xA, 0
    run_msg_len equ $ - run_msg

    save_msg db 0xA, "Game saved successfully!", 0xA, 0
    save_msg_len equ $ - save_msg

    newline db 0xA, 0
    space db " ", 0
    slash db "/", 0

    ; ========== QUIGZIMON NAMES ==========
    name_quigflame db "QUIGFLAME", 0
    name_quigwave db "QUIGWAVE", 0
    name_quigleaf db "QUIGLEAF", 0
    name_quigbolt db "QUIGBOLT", 0
    name_quigrock db "QUIGROCK", 0
    name_quigfrost db "QUIGFROST", 0

    ; ========== TYPE NAMES ==========
    type_fire db "Fire", 0
    type_water db "Water", 0
    type_grass db "Grass", 0
    type_normal db "Normal", 0

    ; ========== MOVE NAMES ==========
    move_ember db "Ember", 0
    move_flamethrower db "Flamethrower", 0
    move_watergun db "Water Gun", 0
    move_hydropump db "Hydro Pump", 0
    move_vinewhip db "Vine Whip", 0
    move_solarbeam db "Solar Beam", 0
    move_tackle db "Tackle", 0
    move_toxic db "Toxic", 0
    move_sleep_powder db "Sleep Powder", 0
    move_thunderwave db "Thunder Wave", 0

    ; ========== LOCATION NAMES ==========
    loc_start db "Starting Town", 0
    loc_forest db "Quig Forest", 0
    loc_route1 db "Route 1", 0

    ; ========== QUIGZIMON DATABASE ==========
    ; Structure: name_ptr(8), type(1), base_hp(2), base_atk(2), base_def(2), base_spd(2), move1_ptr(8), move2_ptr(8)

    quigzimon_db:
    ; QUIGFLAME - Fire type starter
    .quigflame:
        dq name_quigflame
        db TYPE_FIRE
        dw 45, 12, 8, 10
        dq move_ember
        dq move_flamethrower

    ; QUIGWAVE - Water type starter
    .quigwave:
        dq name_quigwave
        db TYPE_WATER
        dw 50, 10, 12, 8
        dq move_watergun
        dq move_hydropump

    ; QUIGLEAF - Grass type starter
    .quigleaf:
        dq name_quigleaf
        db TYPE_GRASS
        dw 42, 11, 9, 12
        dq move_vinewhip
        dq move_solarbeam

    ; QUIGBOLT - Electric/Normal wild
    .quigbolt:
        dq name_quigbolt
        db TYPE_NORMAL
        dw 40, 13, 7, 11
        dq move_tackle
        dq move_thunderwave

    ; QUIGROCK - Rock/Normal wild
    .quigrock:
        dq name_quigrock
        db TYPE_NORMAL
        dw 55, 9, 14, 6
        dq move_tackle
        dq move_tackle

    ; QUIGFROST - Ice/Water wild
    .quigfrost:
        dq name_quigfrost
        db TYPE_WATER
        dw 44, 11, 10, 9
        dq move_watergun
        dq move_toxic

section .bss
    ; ========== GAME STATE ==========
    input resb 4
    num_buffer resb 20
    current_location resb 1
    player_party_count resb 1
    total_caught resb 1

    ; Random seed
    random_seed resq 1

    ; Current battle state
    player_current resb 1  ; Index of current QUIGZIMON in party
    enemy_species resb 1   ; Species ID of enemy

    ; ========== QUIGZIMON INSTANCE STRUCTURE ==========
    ; Each instance: species(1), level(1), hp(2), max_hp(2), exp(2), status(1), atk(2), def(2), spd(2)
    ; Total: 15 bytes per QUIGZIMON

    player_party resb 90  ; 6 QUIGZIMON * 15 bytes
    enemy_instance resb 15

    ; Saved game data would go here
    save_filename db "quigzimon.sav", 0

section .text
    global _start

_start:
    ; Initialize random seed with timestamp
    mov rax, 201  ; sys_time
    xor rdi, rdi
    syscall
    mov [random_seed], rax

    ; Print title
    mov rax, 1
    mov rdi, 1
    mov rsi, title
    mov rdx, title_len
    syscall

    ; Choose starter
    call choose_starter

    ; Main game loop
    call world_loop

    ; Exit
    mov rax, 60
    xor rdi, rdi
    syscall

; ========== STARTER SELECTION ==========
choose_starter:
    push rbp
    mov rbp, rsp

    ; Display starter menu
    mov rax, 1
    mov rdi, 1
    mov rsi, starter_menu
    mov rdx, starter_menu_len
    syscall

    ; Get input
    mov rax, 0
    mov rdi, 0
    mov rsi, input
    mov rdx, 2
    syscall

    ; Create starter based on choice
    mov al, byte [input]
    sub al, '1'
    cmp al, 2
    ja choose_starter  ; Invalid choice, retry

    ; Initialize first party member
    mov byte [player_party_count], 1
    mov byte [total_caught], 1

    ; Set species
    mov byte [player_party], al

    ; Set level to 5
    mov byte [player_party + 1], 5

    ; Initialize stats based on species
    movzx rbx, al
    imul rbx, 33  ; Size of each species data
    lea rcx, [quigzimon_db]
    add rcx, rbx

    ; Get base stats and calculate for level 5
    movzx rax, word [rcx + 9]   ; base_hp
    mov rdx, 5
    imul rax, rdx
    shr rax, 2
    add rax, 10
    mov word [player_party + 2], ax   ; current HP
    mov word [player_party + 4], ax   ; max HP

    ; Set EXP to 0
    mov word [player_party + 6], 0

    ; Set status to none
    mov byte [player_party + 8], STATUS_NONE

    ; Calculate attack
    movzx rax, word [rcx + 11]  ; base_atk
    mov rdx, 5
    imul rax, rdx
    shr rax, 3
    add rax, 5
    mov word [player_party + 9], ax

    ; Calculate defense
    movzx rax, word [rcx + 13]  ; base_def
    mov rdx, 5
    imul rax, rdx
    shr rax, 3
    add rax, 5
    mov word [player_party + 11], ax

    ; Calculate speed
    movzx rax, word [rcx + 15]  ; base_spd
    mov rdx, 5
    imul rax, rdx
    shr rax, 3
    add rax, 5
    mov word [player_party + 13], ax

    pop rbp
    ret

; ========== WORLD MAP LOOP ==========
world_loop:
    push rbp
    mov rbp, rsp

.loop:
    ; Display world menu
    mov rax, 1
    mov rdi, 1
    mov rsi, world_menu
    mov rdx, world_menu_len
    syscall

    ; Get input
    mov rax, 0
    mov rdi, 0
    mov rsi, input
    mov rdx, 2
    syscall

    mov al, byte [input]
    cmp al, '1'
    je .explore
    cmp al, '2'
    je .view_party
    cmp al, '3'
    je .save_game
    cmp al, '4'
    je .quit
    jmp .loop

.explore:
    call encounter_wild
    jmp .loop

.view_party:
    call display_party
    jmp .loop

.save_game:
    call save_game_func
    jmp .loop

.quit:
    pop rbp
    ret

; ========== WILD ENCOUNTER ==========
encounter_wild:
    push rbp
    mov rbp, rsp

    ; Generate random enemy (species 3-5 for wild)
    call get_random
    mov rdx, 0
    mov rcx, 3
    div rcx
    add rdx, 3  ; Random between 3-5

    mov byte [enemy_species], dl

    ; Initialize enemy at random level 3-7
    call get_random
    mov rdx, 0
    mov rcx, 5
    div rcx
    add rdx, 3

    ; Create enemy instance
    mov al, byte [enemy_species]
    mov byte [enemy_instance], al
    mov byte [enemy_instance + 1], dl  ; level

    ; Calculate enemy stats
    movzx rbx, byte [enemy_species]
    imul rbx, 33
    lea rcx, [quigzimon_db]
    add rcx, rbx

    ; HP
    movzx rax, word [rcx + 9]
    movzx rdx, byte [enemy_instance + 1]
    imul rax, rdx
    shr rax, 2
    add rax, 10
    mov word [enemy_instance + 2], ax
    mov word [enemy_instance + 4], ax

    ; Status
    mov byte [enemy_instance + 8], STATUS_NONE

    ; Attack
    movzx rax, word [rcx + 11]
    movzx rdx, byte [enemy_instance + 1]
    imul rax, rdx
    shr rax, 3
    add rax, 5
    mov word [enemy_instance + 9], ax

    ; Defense
    movzx rax, word [rcx + 13]
    movzx rdx, byte [enemy_instance + 1]
    imul rax, rdx
    shr rax, 3
    add rax, 5
    mov word [enemy_instance + 11], ax

    ; Speed
    movzx rax, word [rcx + 15]
    movzx rdx, byte [enemy_instance + 1]
    imul rax, rdx
    shr rax, 3
    add rax, 5
    mov word [enemy_instance + 13], ax

    ; Start battle
    call battle_loop

    pop rbp
    ret

; ========== BATTLE LOOP ==========
battle_loop:
    push rbp
    mov rbp, rsp

    ; Print battle start
    mov rax, 1
    mov rdi, 1
    mov rsi, battle_start
    mov rdx, battle_start_len
    syscall

    ; Display both QUIGZIMON
    call display_battle_status

.turn_loop:
    ; Check if battle is over
    movzx rax, word [enemy_instance + 2]
    cmp rax, 0
    jle .player_wins

    movzx rax, word [player_party + 2]
    cmp rax, 0
    jle .player_loses

    ; Player turn
    call player_battle_turn

    ; Check result (0 = continue, 1 = caught, 2 = ran)
    cmp rax, 1
    je .caught
    cmp rax, 2
    je .ran_away

    ; Check if enemy fainted
    movzx rax, word [enemy_instance + 2]
    cmp rax, 0
    jle .player_wins

    ; Enemy turn
    call enemy_battle_turn

    ; Apply status effects
    call apply_status_effects

    ; Display status
    call display_battle_status

    jmp .turn_loop

.player_wins:
    mov rax, 1
    mov rdi, 1
    mov rsi, victory_msg
    mov rdx, victory_msg_len
    syscall

    ; Give EXP
    call give_exp

    pop rbp
    ret

.player_loses:
    mov rax, 1
    mov rdi, 1
    mov rsi, defeat_msg
    mov rdx, defeat_msg_len
    syscall
    pop rbp
    ret

.caught:
    pop rbp
    ret

.ran_away:
    pop rbp
    ret

; ========== PLAYER BATTLE TURN ==========
player_battle_turn:
    push rbp
    mov rbp, rsp

    ; Check if can move (sleep/paralyze)
    movzx rax, byte [player_party + 8]
    cmp rax, STATUS_SLEEP
    je .check_wake
    cmp rax, STATUS_PARALYZE
    je .check_paralyze
    jmp .can_move

.check_wake:
    call get_random
    and rax, 3
    cmp rax, 0  ; 25% chance to wake
    jne .cant_move_sleep

    ; Wake up
    mov byte [player_party + 8], STATUS_NONE
    mov rax, 1
    mov rdi, 1
    mov rsi, wake_msg
    mov rdx, wake_msg_len
    syscall
    jmp .can_move

.cant_move_sleep:
    mov rax, 1
    mov rdi, 1
    mov rsi, cant_move_sleep
    mov rdx, cant_move_sleep_len
    syscall
    xor rax, rax
    pop rbp
    ret

.check_paralyze:
    call get_random
    and rax, 3
    cmp rax, 0  ; 25% chance to be fully paralyzed
    je .cant_move_para
    jmp .can_move

.cant_move_para:
    mov rax, 1
    mov rdi, 1
    mov rsi, cant_move_para
    mov rdx, cant_move_para_len
    syscall
    xor rax, rax
    pop rbp
    ret

.can_move:
    ; Display battle menu
    mov rax, 1
    mov rdi, 1
    mov rsi, battle_menu
    mov rdx, battle_menu_len
    syscall

    ; Get input
    mov rax, 0
    mov rdi, 0
    mov rsi, input
    mov rdx, 2
    syscall

    mov al, byte [input]
    cmp al, '1'
    je .attack
    cmp al, '2'
    je .special
    cmp al, '3'
    je .catch
    cmp al, '4'
    je .run

    ; Invalid input
    xor rax, rax
    pop rbp
    ret

.attack:
    call execute_attack
    xor rax, rax
    pop rbp
    ret

.special:
    call execute_special
    xor rax, rax
    pop rbp
    ret

.catch:
    call attempt_catch
    pop rbp
    ret  ; Returns 1 if caught

.run:
    mov rax, 1
    mov rdi, 1
    mov rsi, run_msg
    mov rdx, run_msg_len
    syscall
    mov rax, 2
    pop rbp
    ret

; ========== ATTACK EXECUTION ==========
execute_attack:
    push rbp
    mov rbp, rsp

    ; Calculate damage
    movzx rax, word [player_party + 9]  ; attack
    movzx rbx, word [enemy_instance + 11]  ; defense
    sub rax, rbx
    cmp rax, 1
    jge .damage_ok
    mov rax, 1

.damage_ok:
    ; Apply type effectiveness
    movzx rbx, byte [player_party]  ; player species
    imul rbx, 33
    lea rcx, [quigzimon_db]
    add rcx, rbx
    movzx r8, byte [rcx + 8]  ; player type

    movzx rbx, byte [enemy_instance]  ; enemy species
    imul rbx, 33
    lea rcx, [quigzimon_db]
    add rcx, rbx
    movzx r9, byte [rcx + 8]  ; enemy type

    ; Check effectiveness
    push rax
    mov rdi, r8
    mov rsi, r9
    call get_type_effectiveness
    pop rbx

    ; Multiply damage by effectiveness (0.5x, 1x, or 2x)
    ; rax contains: 0=not effective (0.5x), 1=normal, 2=super effective (2x)
    cmp rax, 0
    je .half_damage
    cmp rax, 2
    je .double_damage
    mov rax, rbx
    jmp .apply_damage

.half_damage:
    mov rax, rbx
    shr rax, 1
    cmp rax, 1
    jge .show_not_effective
    mov rax, 1
.show_not_effective:
    push rax
    mov rax, 1
    mov rdi, 1
    mov rsi, not_effective
    mov rdx, not_effective_len
    syscall
    pop rax
    jmp .apply_damage

.double_damage:
    mov rax, rbx
    shl rax, 1
    push rax
    mov rax, 1
    mov rdi, 1
    mov rsi, super_effective
    mov rdx, super_effective_len
    syscall
    pop rax

.apply_damage:
    ; Subtract from enemy HP
    movzx rbx, word [enemy_instance + 2]
    sub rbx, rax
    cmp rbx, 0
    jge .store_hp
    xor rbx, rbx

.store_hp:
    mov word [enemy_instance + 2], bx

    ; Display damage
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
    mov rsi, newline
    mov rdx, 1
    syscall

    pop rbp
    ret

; ========== TYPE EFFECTIVENESS ==========
; Input: rdi = attacker type, rsi = defender type
; Output: rax = 0 (not effective), 1 (normal), 2 (super effective)
get_type_effectiveness:
    ; Fire > Grass
    cmp rdi, TYPE_FIRE
    jne .not_fire
    cmp rsi, TYPE_GRASS
    je .super
    cmp rsi, TYPE_WATER
    je .not_very
    jmp .normal

.not_fire:
    ; Water > Fire
    cmp rdi, TYPE_WATER
    jne .not_water
    cmp rsi, TYPE_FIRE
    je .super
    cmp rsi, TYPE_GRASS
    je .not_very
    jmp .normal

.not_water:
    ; Grass > Water
    cmp rdi, TYPE_GRASS
    jne .normal
    cmp rsi, TYPE_WATER
    je .super
    cmp rsi, TYPE_FIRE
    je .not_very
    jmp .normal

.super:
    mov rax, 2
    ret

.not_very:
    mov rax, 0
    ret

.normal:
    mov rax, 1
    ret

; ========== SPECIAL MOVE EXECUTION ==========
execute_special:
    push rbp
    mov rbp, rsp

    ; For now, special moves do more damage
    movzx rax, word [player_party + 9]
    imul rax, 15
    mov rbx, 10
    xor rdx, rdx
    div rbx

    ; Apply to enemy
    movzx rbx, word [enemy_instance + 2]
    sub rbx, rax
    cmp rbx, 0
    jge .store
    xor rbx, rbx

.store:
    mov word [enemy_instance + 2], bx

    ; Display
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
    mov rsi, newline
    mov rdx, 1
    syscall

    pop rbp
    ret

; ========== ENEMY BATTLE TURN ==========
enemy_battle_turn:
    push rbp
    mov rbp, rsp

    ; Check status
    movzx rax, byte [enemy_instance + 8]
    cmp rax, STATUS_SLEEP
    je .check_wake
    cmp rax, STATUS_PARALYZE
    je .check_paralyze
    jmp .can_move

.check_wake:
    call get_random
    and rax, 3
    cmp rax, 0
    jne .cant_move
    mov byte [enemy_instance + 8], STATUS_NONE
    jmp .can_move

.cant_move:
    pop rbp
    ret

.check_paralyze:
    call get_random
    and rax, 3
    cmp rax, 0
    je .cant_move

.can_move:
    ; Simple attack
    movzx rax, word [enemy_instance + 9]
    movzx rbx, word [player_party + 11]
    sub rax, rbx
    cmp rax, 1
    jge .damage_ok
    mov rax, 1

.damage_ok:
    movzx rbx, word [player_party + 2]
    sub rbx, rax
    cmp rbx, 0
    jge .store
    xor rbx, rbx

.store:
    mov word [player_party + 2], bx

    pop rbp
    ret

; ========== CATCH ATTEMPT ==========
attempt_catch:
    push rbp
    mov rbp, rsp

    mov rax, 1
    mov rdi, 1
    mov rsi, catch_attempt
    mov rdx, catch_attempt_len
    syscall

    ; Check party size
    movzx rax, byte [player_party_count]
    cmp rax, MAX_PARTY_SIZE
    jge .party_full_error

    ; Calculate catch rate based on HP
    movzx rax, word [enemy_instance + 2]  ; current HP
    imul rax, 100
    movzx rbx, word [enemy_instance + 4]  ; max HP
    xor rdx, rdx
    div rbx  ; rax = HP percentage

    mov rbx, 100
    sub rbx, rax  ; rbx = catch rate (lower HP = higher rate)

    ; Random check
    call get_random
    xor rdx, rdx
    mov rcx, 100
    div rcx  ; rdx = random 0-99

    cmp rdx, rbx
    jl .success

    ; Failed
    mov rax, 1
    mov rdi, 1
    mov rsi, catch_fail
    mov rdx, catch_fail_len
    syscall
    xor rax, rax
    pop rbp
    ret

.success:
    ; Add to party
    movzx rcx, byte [player_party_count]
    imul rcx, 15  ; Size of each instance
    lea rdi, [player_party]
    add rdi, rcx

    ; Copy enemy instance
    lea rsi, [enemy_instance]
    mov rcx, 15
    rep movsb

    ; Increment counters
    inc byte [player_party_count]
    inc byte [total_caught]

    mov rax, 1
    mov rdi, 1
    mov rsi, catch_success
    mov rdx, catch_success_len
    syscall

    mov rax, 1
    pop rbp
    ret

.party_full_error:
    mov rax, 1
    mov rdi, 1
    mov rsi, party_full
    mov rdx, party_full_len
    syscall
    xor rax, rax
    pop rbp
    ret

; ========== STATUS EFFECTS ==========
apply_status_effects:
    push rbp
    mov rbp, rsp

    ; Check player status
    movzx rax, byte [player_party + 8]
    cmp rax, STATUS_POISON
    je .player_poison
    jmp .check_enemy

.player_poison:
    ; Take 1/16 max HP damage
    movzx rax, word [player_party + 4]
    shr rax, 4
    cmp rax, 1
    jge .apply_player_poison
    mov rax, 1

.apply_player_poison:
    movzx rbx, word [player_party + 2]
    sub rbx, rax
    cmp rbx, 0
    jge .store_player_poison
    xor rbx, rbx

.store_player_poison:
    mov word [player_party + 2], bx

    mov rax, 1
    mov rdi, 1
    mov rsi, poison_damage_msg
    mov rdx, poison_damage_msg_len
    syscall

.check_enemy:
    movzx rax, byte [enemy_instance + 8]
    cmp rax, STATUS_POISON
    je .enemy_poison
    jmp .done

.enemy_poison:
    movzx rax, word [enemy_instance + 4]
    shr rax, 4
    cmp rax, 1
    jge .apply_enemy_poison
    mov rax, 1

.apply_enemy_poison:
    movzx rbx, word [enemy_instance + 2]
    sub rbx, rax
    cmp rbx, 0
    jge .store_enemy_poison
    xor rbx, rbx

.store_enemy_poison:
    mov word [enemy_instance + 2], bx

.done:
    pop rbp
    ret

; ========== EXPERIENCE & LEVELING ==========
give_exp:
    push rbp
    mov rbp, rsp

    ; Calculate EXP based on enemy level
    movzx rax, byte [enemy_instance + 1]
    imul rax, 10
    add rax, 20

    ; Display EXP gained
    push rax
    mov rax, 1
    mov rdi, 1
    mov rsi, exp_gained_msg
    mov rdx, exp_gained_msg_len
    syscall
    pop rax

    push rax
    call print_number

    mov rax, 1
    mov rdi, 1
    mov rsi, exp_suffix
    mov rdx, exp_suffix_len
    syscall
    pop rax

    ; Add to player EXP
    movzx rbx, word [player_party + 6]
    add rbx, rax
    mov word [player_party + 6], bx

    ; Check for level up (simple: 100 EXP per level)
    movzx rcx, byte [player_party + 1]  ; current level
    imul rcx, 100
    cmp rbx, rcx
    jl .no_level_up

    ; Level up!
    inc byte [player_party + 1]

    mov rax, 1
    mov rdi, 1
    mov rsi, level_up_msg
    mov rdx, level_up_msg_len
    syscall

    movzx rax, byte [player_party + 1]
    call print_number

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    ; Increase stats
    mov ax, word [player_party + 4]
    add ax, 5
    mov word [player_party + 4], ax
    mov word [player_party + 2], ax

    mov ax, word [player_party + 9]
    add ax, 2
    mov word [player_party + 9], ax

    mov ax, word [player_party + 11]
    add ax, 2
    mov word [player_party + 11], ax

    mov ax, word [player_party + 13]
    add ax, 1
    mov word [player_party + 13], ax

.no_level_up:
    pop rbp
    ret

; ========== DISPLAY FUNCTIONS ==========
display_battle_status:
    push rbp
    mov rbp, rsp

    ; Display player QUIGZIMON
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    ; Get player species name
    movzx rbx, byte [player_party]
    imul rbx, 33
    lea rcx, [quigzimon_db]
    add rcx, rbx
    mov rsi, [rcx]  ; name pointer

    ; Find string length and print
    call print_string

    mov rax, 1
    mov rdi, 1
    mov rsi, level_display
    mov rdx, level_display_len
    syscall

    movzx rax, byte [player_party + 1]
    call print_number

    mov rax, 1
    mov rdi, 1
    mov rsi, hp_display
    mov rdx, hp_display_len
    syscall

    movzx rax, word [player_party + 2]
    call print_number

    mov rax, 1
    mov rdi, 1
    mov rsi, slash
    mov rdx, 1
    syscall

    movzx rax, word [player_party + 4]
    call print_number

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    ; Display enemy QUIGZIMON
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    movzx rbx, byte [enemy_instance]
    imul rbx, 33
    lea rcx, [quigzimon_db]
    add rcx, rbx
    mov rsi, [rcx]

    call print_string

    mov rax, 1
    mov rdi, 1
    mov rsi, level_display
    mov rdx, level_display_len
    syscall

    movzx rax, byte [enemy_instance + 1]
    call print_number

    mov rax, 1
    mov rdi, 1
    mov rsi, hp_display
    mov rdx, hp_display_len
    syscall

    movzx rax, word [enemy_instance + 2]
    call print_number

    mov rax, 1
    mov rdi, 1
    mov rsi, slash
    mov rdx, 1
    syscall

    movzx rax, word [enemy_instance + 4]
    call print_number

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    pop rbp
    ret

display_party:
    push rbp
    mov rbp, rsp

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    ; TODO: Display all party members

    pop rbp
    ret

; ========== SAVE/LOAD ==========
save_game_func:
    push rbp
    mov rbp, rsp

    ; For now, just display message
    mov rax, 1
    mov rdi, 1
    mov rsi, save_msg
    mov rdx, save_msg_len
    syscall

    ; TODO: Implement actual file I/O

    pop rbp
    ret

; ========== UTILITY FUNCTIONS ==========
get_random:
    ; Simple LCG: seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
    mov rax, [random_seed]
    imul rax, 1103515245
    add rax, 12345
    and rax, 0x7FFFFFFF
    mov [random_seed], rax
    ret

print_string:
    ; rsi = string pointer
    push rbp
    mov rbp, rsp
    push rsi

    ; Find length
    xor rcx, rcx
.find_len:
    cmp byte [rsi + rcx], 0
    je .found_len
    inc rcx
    jmp .find_len

.found_len:
    pop rsi
    mov rax, 1
    mov rdi, 1
    mov rdx, rcx
    syscall

    pop rbp
    ret

print_number:
    ; Print number in rax
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    push rdx

    mov rbx, 10
    xor rcx, rcx
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

    mov rax, 1
    mov rdi, 1
    mov rdx, rcx
    syscall

    pop rdx
    pop rcx
    pop rbx
    pop rbp
    ret
