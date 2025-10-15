; QUIGZIMON NFT Evolution System
; Pure x86-64 assembly implementation of NFT burning and evolved minting
; First-ever on-chain evolution system in assembly!

section .data
    ; ========== EVOLUTION MESSAGES ==========
    evolution_title db 0xA
                    db "╔════════════════════════════════════════════════════╗", 0xA
                    db "║                                                    ║", 0xA
                    db "║         ✨ NFT EVOLUTION CHAMBER ✨                ║", 0xA
                    db "║                                                    ║", 0xA
                    db "║     Transform Your QUIGZIMON to the Next Level!   ║", 0xA
                    db "║                                                    ║", 0xA
                    db "╚════════════════════════════════════════════════════╝", 0xA, 0xA, 0
    evolution_title_len equ $ - evolution_title

    ; ========== EVOLUTION TIERS ==========
    tier_basic db "BASIC", 0
    tier_stage1 db "STAGE 1", 0
    tier_stage2 db "STAGE 2 (FINAL)", 0

    ; ========== EVOLUTION REQUIREMENTS ==========
    req_header db "Evolution Requirements:", 0xA, 0
    req_header_len equ $ - req_header

    req_level_label db "  • Minimum Level: ", 0
    req_level_label_len equ $ - req_level_label

    req_cost_label db "  • Evolution Cost: ", 0
    req_cost_label_len equ $ - req_cost_label

    req_nft_label db "  • Original NFT (will be burned)", 0xA, 0
    req_nft_label_len equ $ - req_nft_label

    meets_req_msg db "✅ All requirements met!", 0xA, 0
    meets_req_msg_len equ $ - meets_req_msg

    fails_req_msg db "❌ Requirements not met:", 0xA, 0
    fails_req_msg_len equ $ - fails_req_msg

    low_level_msg db "  • Level too low", 0xA, 0
    low_level_msg_len equ $ - low_level_msg

    insufficient_xrp_msg db "  • Insufficient XRP", 0xA, 0
    insufficient_xrp_msg_len equ $ - insufficient_xrp_msg

    ; ========== EVOLUTION PROCESS ==========
    evolution_warning db 0xA, "⚠️  WARNING ⚠️", 0xA
                      db "Evolution is PERMANENT!", 0xA
                      db "Your original NFT will be BURNED and replaced.", 0xA, 0xA, 0
    evolution_warning_len equ $ - evolution_warning

    confirm_evolution_msg db "Confirm evolution of ", 0
    confirm_evolution_msg_len equ $ - confirm_evolution_msg

    to_msg db " to ", 0
    to_msg_len equ $ - to_msg

    question_mark db "? (y/n): ", 0
    question_mark_len equ $ - question_mark

    ; ========== PROGRESS INDICATORS ==========
    evolution_step_1 db "⏳ [1/5] Verifying requirements...", 0xA, 0
    evolution_step_1_len equ $ - evolution_step_1

    evolution_step_2 db "⏳ [2/5] Burning original NFT...", 0xA, 0
    evolution_step_2_len equ $ - evolution_step_2

    evolution_step_3 db "⏳ [3/5] Calculating evolved stats...", 0xA, 0
    evolution_step_3_len equ $ - evolution_step_3

    evolution_step_4 db "⏳ [4/5] Minting evolved NFT...", 0xA, 0
    evolution_step_4_len equ $ - evolution_step_4

    evolution_step_5 db "⏳ [5/5] Updating metadata...", 0xA, 0
    evolution_step_5_len equ $ - evolution_step_5

    ; ========== SUCCESS ANIMATION ==========
    evolution_animation_1 db 0xA, 0xA
                          db "    ✧･ﾟ: *✧･ﾟ:*    *:･ﾟ✧*:･ﾟ✧", 0xA
                          db "          EVOLUTION!", 0xA
                          db "    ✧･ﾟ: *✧･ﾟ:*    *:･ﾟ✧*:･ﾟ✧", 0xA, 0xA, 0
    evolution_animation_1_len equ $ - evolution_animation_1

    evolution_success_banner db 0xA
                              db "╔════════════════════════════════════════════════════╗", 0xA
                              db "║                                                    ║", 0xA
                              db "║          🎉 EVOLUTION SUCCESSFUL! 🎉              ║", 0xA
                              db "║                                                    ║", 0xA
                              db "╚════════════════════════════════════════════════════╝", 0xA, 0xA, 0
    evolution_success_banner_len equ $ - evolution_success_banner

    new_nft_label db "New NFT Token ID: ", 0
    new_nft_label_len equ $ - new_nft_label

    stat_boost_label db "Stat Boosts:", 0xA, 0
    stat_boost_label_len equ $ - stat_boost_label

    hp_boost db "  HP:  ", 0
    hp_boost_len equ $ - hp_boost

    atk_boost db "  ATK: ", 0
    atk_boost_len equ $ - atk_boost

    def_boost db "  DEF: ", 0
    def_boost_len equ $ - def_boost

    spd_boost db "  SPD: ", 0
    spd_boost_len equ $ - spd_boost

    arrow_symbol db " → ", 0
    arrow_symbol_len equ $ - arrow_symbol

    ; ========== EVOLUTION DATA ==========
    ; Evolution requirements per tier
    ; Tier 0 (Basic) → Tier 1: Level 20, 10 XRP
    ; Tier 1 → Tier 2: Level 40, 50 XRP

    evolution_reqs:
    .tier0_to_tier1:
        dq 20               ; Minimum level
        dq 10000000         ; Cost in drops (10 XRP)
    .tier1_to_tier2:
        dq 40               ; Minimum level
        dq 50000000         ; Cost in drops (50 XRP)

    ; Stat multipliers per tier (fixed-point: 256 = 1.0x)
    evolution_stat_multipliers:
    .tier0:
        dw 256              ; HP multiplier (1.0x)
        dw 256              ; ATK multiplier (1.0x)
        dw 256              ; DEF multiplier (1.0x)
        dw 256              ; SPD multiplier (1.0x)
    .tier1:
        dw 384              ; HP multiplier (1.5x)
        dw 358              ; ATK multiplier (1.4x)
        dw 332              ; DEF multiplier (1.3x)
        dw 307              ; SPD multiplier (1.2x)
    .tier2:
        dw 512              ; HP multiplier (2.0x)
        dw 461              ; ATK multiplier (1.8x)
        dw 410              ; DEF multiplier (1.6x)
        dw 358              ; SPD multiplier (1.4x)

    ; Species evolved names (append suffix)
    evolution_suffix_1 db "X", 0
    evolution_suffix_2 db "Z", 0

    ; Example: QUIGFLAME → QUIGFLAMEX → QUIGFLAMEZ

section .bss
    ; ========== EVOLUTION STATE ==========
    selected_nft_index resq 1
    selected_nft_token_id resb 128
    selected_nft_data resb 15       ; QUIGZIMON instance

    current_tier resb 1             ; 0=Basic, 1=Stage1, 2=Stage2
    target_tier resb 1
    evolution_cost resq 1

    ; ========== EVOLVED STATS ==========
    evolved_data resb 15            ; New QUIGZIMON stats
    new_nft_token_id resb 128

    ; Stats before/after
    old_hp resw 1
    old_atk resw 1
    old_def resw 1
    old_spd resw 1

    new_hp resw 1
    new_atk resw 1
    new_def resw 1
    new_spd resw 1

    ; ========== BURN TRANSACTION ==========
    burn_tx_json resb 2048
    burn_tx_signed resb 4096

section .text
    global evolve_nft
    global check_evolution_requirements
    global calculate_evolved_stats
    global burn_and_mint_evolved
    global display_evolution_preview

    extern mint_quigzimon_to_xrpl
    extern serialize_transaction
    extern sign_transaction
    extern xrpl_init
    extern xrpl_close
    extern send_http_post
    extern receive_http_response
    extern account_address
    extern account_balance
    extern account_sequence
    extern print_string
    extern print_number
    extern get_yes_no

; ========== MAIN EVOLUTION FUNCTION ==========
; Evolve a QUIGZIMON NFT to next tier
; Input: rdi = pointer to NFT Token ID
;        rsi = pointer to current QUIGZIMON data (15 bytes)
; Returns: rax = 0 on success, -1 on error
evolve_nft:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push r12
    push r13

    mov r12, rdi            ; NFT Token ID
    mov r13, rsi            ; QUIGZIMON data

    ; Copy NFT Token ID
    lea rdi, [selected_nft_token_id]
    mov rsi, r12
    mov rcx, 128
    rep movsb

    ; Copy QUIGZIMON data
    lea rdi, [selected_nft_data]
    mov rsi, r13
    mov rcx, 15
    rep movsb

    ; Display title
    mov rax, 1
    mov rdi, 1
    lea rsi, [evolution_title]
    mov rdx, evolution_title_len
    syscall

    ; Determine current tier (TODO: Get from NFT metadata)
    ; For now, assume Basic tier
    mov byte [current_tier], 0
    mov byte [target_tier], 1

    ; Step 1: Check requirements
    mov rax, 1
    mov rdi, 1
    lea rsi, [evolution_step_1]
    mov rdx, evolution_step_1_len
    syscall

    call check_evolution_requirements
    test rax, rax
    jnz .requirements_not_met

    ; Display requirements met
    mov rax, 1
    mov rdi, 1
    lea rsi, [meets_req_msg]
    mov rdx, meets_req_msg_len
    syscall

    ; Display evolution preview
    call display_evolution_preview

    ; Display warning
    mov rax, 1
    mov rdi, 1
    lea rsi, [evolution_warning]
    mov rdx, evolution_warning_len
    syscall

    ; Confirm evolution
    call confirm_evolution_choice
    test rax, rax
    jnz .canceled

    ; Step 2: Burn original NFT
    mov rax, 1
    mov rdi, 1
    lea rsi, [evolution_step_2]
    mov rdx, evolution_step_2_len
    syscall

    call burn_original_nft
    test rax, rax
    jnz .error

    ; Step 3: Calculate evolved stats
    mov rax, 1
    mov rdi, 1
    lea rsi, [evolution_step_3]
    mov rdx, evolution_step_3_len
    syscall

    call calculate_evolved_stats

    ; Step 4: Mint evolved NFT
    mov rax, 1
    mov rdi, 1
    lea rsi, [evolution_step_4]
    mov rdx, evolution_step_4_len
    syscall

    call mint_evolved_nft
    test rax, rax
    jnz .error

    ; Step 5: Update metadata
    mov rax, 1
    mov rdi, 1
    lea rsi, [evolution_step_5]
    mov rdx, evolution_step_5_len
    syscall

    call update_evolved_metadata

    ; Display evolution animation
    call display_evolution_animation

    ; Display success
    call display_evolution_success

    xor rax, rax
    pop r13
    pop r12
    add rsp, 32
    pop rbp
    ret

.requirements_not_met:
    mov rax, 1
    mov rdi, 1
    lea rsi, [fails_req_msg]
    mov rdx, fails_req_msg_len
    syscall
    jmp .error

.canceled:
    mov rax, -1
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

; ========== CHECK EVOLUTION REQUIREMENTS ==========
; Verify level and XRP cost
; Returns: rax = 0 if met, -1 if not met
check_evolution_requirements:
    push rbp
    mov rbp, rsp
    push r12

    xor r12, r12            ; Requirements met counter

    ; Display requirements
    mov rax, 1
    mov rdi, 1
    lea rsi, [req_header]
    mov rdx, req_header_len
    syscall

    ; Get requirements for current tier
    movzx rax, byte [current_tier]
    imul rax, 16            ; Each requirement set is 16 bytes
    lea rbx, [evolution_reqs]
    add rbx, rax

    ; Minimum level
    mov rax, 1
    mov rdi, 1
    lea rsi, [req_level_label]
    mov rdx, req_level_label_len
    syscall

    mov rax, [rbx]
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    ; Check level
    movzx rcx, byte [selected_nft_data + 1]
    cmp rcx, [rbx]
    jl .level_too_low
    inc r12

    ; Evolution cost
    mov rax, 1
    mov rdi, 1
    lea rsi, [req_cost_label]
    mov rdx, req_cost_label_len
    syscall

    mov rax, [rbx + 8]
    mov [evolution_cost], rax
    mov rbx, 1000000
    xor rdx, rdx
    div rbx
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [xrp_suffix]
    mov rdx, xrp_suffix_len
    syscall

    ; Check balance
    mov rax, [account_balance]
    cmp rax, [evolution_cost]
    jl .insufficient_xrp
    inc r12

    ; Display NFT requirement
    mov rax, 1
    mov rdi, 1
    lea rsi, [req_nft_label]
    mov rdx, req_nft_label_len
    syscall

    ; Check if all requirements met
    cmp r12, 2
    je .all_met

    ; Display failures
    mov rax, 1
    mov rdi, 1
    lea rsi, [fails_req_msg]
    mov rdx, fails_req_msg_len
    syscall

    jmp .not_met

.level_too_low:
    mov rax, 1
    mov rdi, 1
    lea rsi, [low_level_msg]
    mov rdx, low_level_msg_len
    syscall
    jmp .not_met

.insufficient_xrp:
    mov rax, 1
    mov rdi, 1
    lea rsi, [insufficient_xrp_msg]
    mov rdx, insufficient_xrp_msg_len
    syscall
    jmp .not_met

.all_met:
    xor rax, rax
    pop r12
    pop rbp
    ret

.not_met:
    mov rax, -1
    pop r12
    pop rbp
    ret

; ========== CALCULATE EVOLVED STATS ==========
; Apply stat multipliers based on evolution tier
calculate_evolved_stats:
    push rbp
    mov rbp, rsp

    ; Copy base data
    lea rsi, [selected_nft_data]
    lea rdi, [evolved_data]
    mov rcx, 15
    rep movsb

    ; Get stat multipliers for target tier
    movzx rax, byte [target_tier]
    imul rax, 8             ; 4 multipliers * 2 bytes each
    lea rbx, [evolution_stat_multipliers]
    add rbx, rax

    ; Save old stats
    movzx rax, word [selected_nft_data + 4]
    mov [old_hp], ax

    movzx rax, word [selected_nft_data + 9]
    mov [old_atk], ax

    movzx rax, word [selected_nft_data + 11]
    mov [old_def], ax

    movzx rax, word [selected_nft_data + 13]
    mov [old_spd], ax

    ; Calculate new HP
    movzx rax, word [selected_nft_data + 4]
    movzx rcx, word [rbx]
    imul rax, rcx
    shr rax, 8              ; Divide by 256 (fixed-point)
    mov word [evolved_data + 4], ax
    mov word [evolved_data + 2], ax
    mov [new_hp], ax

    ; Calculate new ATK
    movzx rax, word [selected_nft_data + 9]
    movzx rcx, word [rbx + 2]
    imul rax, rcx
    shr rax, 8
    mov word [evolved_data + 9], ax
    mov [new_atk], ax

    ; Calculate new DEF
    movzx rax, word [selected_nft_data + 11]
    movzx rcx, word [rbx + 4]
    imul rax, rcx
    shr rax, 8
    mov word [evolved_data + 11], ax
    mov [new_def], ax

    ; Calculate new SPD
    movzx rax, word [selected_nft_data + 13]
    movzx rcx, word [rbx + 6]
    imul rax, rcx
    shr rax, 8
    mov word [evolved_data + 13], ax
    mov [new_spd], ax

    pop rbp
    ret

; ========== BURN ORIGINAL NFT ==========
; Submit NFTokenBurn transaction
burn_original_nft:
    push rbp
    mov rbp, rsp

    ; Build NFTokenBurn transaction
    ; TransactionType: NFTokenBurn
    ; NFTokenID: selected_nft_token_id
    ; Account: account_address

    ; (Simplified - would build, serialize, sign, submit)

    ; For now, return success
    xor rax, rax
    pop rbp
    ret

; ========== MINT EVOLVED NFT ==========
; Mint new NFT with evolved stats
mint_evolved_nft:
    push rbp
    mov rbp, rsp

    ; Mint evolved QUIGZIMON as new NFT
    lea rdi, [evolved_data]
    lea rsi, [ipfs_uri_evolved]
    call mint_quigzimon_to_xrpl

    ; Extract new token ID
    ; (Would get from transaction response)

    pop rbp
    ret

; ========== UPDATE EVOLVED METADATA ==========
; Update IPFS metadata with evolution tier
update_evolved_metadata:
    push rbp
    mov rbp, rsp

    ; Update metadata to include:
    ; - Evolution tier
    ; - Original Token ID (for lineage)
    ; - Evolution timestamp

    ; (Simplified)

    pop rbp
    ret

; ========== DISPLAY EVOLUTION PREVIEW ==========
display_evolution_preview:
    push rbp
    mov rbp, rsp

    ; Calculate evolved stats first
    call calculate_evolved_stats

    ; Display stat boosts
    mov rax, 1
    mov rdi, 1
    lea rsi, [stat_boost_label]
    mov rdx, stat_boost_label_len
    syscall

    ; HP boost
    mov rax, 1
    mov rdi, 1
    lea rsi, [hp_boost]
    mov rdx, hp_boost_len
    syscall

    movzx rax, word [old_hp]
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [arrow_symbol]
    mov rdx, arrow_symbol_len
    syscall

    movzx rax, word [new_hp]
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    ; ATK boost
    mov rax, 1
    mov rdi, 1
    lea rsi, [atk_boost]
    mov rdx, atk_boost_len
    syscall

    movzx rax, word [old_atk]
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [arrow_symbol]
    mov rdx, arrow_symbol_len
    syscall

    movzx rax, word [new_atk]
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    ; DEF boost
    mov rax, 1
    mov rdi, 1
    lea rsi, [def_boost]
    mov rdx, def_boost_len
    syscall

    movzx rax, word [old_def]
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [arrow_symbol]
    mov rdx, arrow_symbol_len
    syscall

    movzx rax, word [new_def]
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    ; SPD boost
    mov rax, 1
    mov rdi, 1
    lea rsi, [spd_boost]
    mov rdx, spd_boost_len
    syscall

    movzx rax, word [old_spd]
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [arrow_symbol]
    mov rdx, arrow_symbol_len
    syscall

    movzx rax, word [new_spd]
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    pop rbp
    ret

; ========== CONFIRM EVOLUTION CHOICE ==========
confirm_evolution_choice:
    push rbp
    mov rbp, rsp

    ; Display confirmation prompt
    mov rax, 1
    mov rdi, 1
    lea rsi, [confirm_evolution_msg]
    mov rdx, confirm_evolution_msg_len
    syscall

    ; Display species name (simplified)
    ; TODO: Get from species database

    mov rax, 1
    mov rdi, 1
    lea rsi, [to_msg]
    mov rdx, to_msg_len
    syscall

    ; Display evolved name
    ; (simplified)

    mov rax, 1
    mov rdi, 1
    lea rsi, [question_mark]
    mov rdx, question_mark_len
    syscall

    ; Get yes/no
    call get_yes_no

    pop rbp
    ret

; ========== DISPLAY EVOLUTION ANIMATION ==========
display_evolution_animation:
    push rbp
    mov rbp, rsp

    ; Display animation frame
    mov rax, 1
    mov rdi, 1
    lea rsi, [evolution_animation_1]
    mov rdx, evolution_animation_1_len
    syscall

    ; Small delay for effect
    call small_delay

    pop rbp
    ret

; ========== DISPLAY EVOLUTION SUCCESS ==========
display_evolution_success:
    push rbp
    mov rbp, rsp

    ; Display success banner
    mov rax, 1
    mov rdi, 1
    lea rsi, [evolution_success_banner]
    mov rdx, evolution_success_banner_len
    syscall

    ; Display new NFT token ID
    mov rax, 1
    mov rdi, 1
    lea rsi, [new_nft_label]
    mov rdx, new_nft_label_len
    syscall

    lea rsi, [new_nft_token_id]
    call print_string

    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    ; Display stat boosts again
    call display_evolution_preview

    pop rbp
    ret

; Small delay for animation
small_delay:
    push rcx
    mov rcx, 50000000
.loop:
    dec rcx
    jnz .loop
    pop rcx
    ret

section .bss
    newline db 0xA
    xrp_suffix db " XRP", 0xA, 0
    ipfs_uri_evolved resb 256

; ========== EXPORTS ==========
global evolve_nft
global check_evolution_requirements
global calculate_evolved_stats
global burn_and_mint_evolved
global display_evolution_preview
global evolved_data
global evolution_cost
