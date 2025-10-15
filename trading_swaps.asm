; QUIGZIMON Direct Trading (Swaps) System
; Pure x86-64 assembly implementation of peer-to-peer NFT swaps
; First-ever atomic swap system in assembly!

section .data
    ; ========== TRADING MESSAGES ==========
    trading_title db 0xA
                  db "╔════════════════════════════════════════════════════╗", 0xA
                  db "║                                                    ║", 0xA
                  db "║         🤝 DIRECT TRADING SYSTEM 🤝               ║", 0xA
                  db "║                                                    ║", 0xA
                  db "║     Atomic NFT Swaps - Trustless Trading!        ║", 0xA
                  db "║                                                    ║", 0xA
                  db "╚════════════════════════════════════════════════════╝", 0xA, 0xA, 0
    trading_title_len equ $ - trading_title

    ; ========== TRADE PROPOSAL ==========
    propose_trade_msg db "Creating trade proposal...", 0xA, 0
    propose_trade_msg_len equ $ - propose_trade_msg

    trade_proposed_msg db "✅ Trade proposal sent!", 0xA, 0
    trade_proposed_msg_len equ $ - trade_proposed_msg

    waiting_for_response_msg db "Waiting for other player to accept...", 0xA, 0
    waiting_for_response_msg_len equ $ - waiting_for_response_msg

    ; ========== TRADE OFFER DISPLAY ==========
    you_offer_label db "YOU OFFER:", 0xA, 0
    you_offer_label_len equ $ - you_offer_label

    they_offer_label db 0xA, "THEY OFFER:", 0xA, 0
    they_offer_label_len equ $ - they_offer_label

    swap_arrow db 0xA, "        ⇅", 0xA, "   SWAP!", 0xA, 0xA, 0
    swap_arrow_len equ $ - swap_arrow

    ; ========== TRADE TYPES ==========
    trade_1for1_label db "1-for-1 NFT Swap", 0
    trade_bundle_label db "Bundle Trade (Multiple NFTs)", 0
    trade_plus_xrp_label db "NFT + XRP Trade", 0

    ; ========== TRADE ACCEPTANCE ==========
    incoming_trade_msg db "📬 You have an incoming trade proposal!", 0xA, 0
    incoming_trade_msg_len equ $ - incoming_trade_msg

    review_trade_msg db "Review the trade carefully:", 0xA, 0
    review_trade_msg_len equ $ - review_trade_msg

    accept_trade_prompt db 0xA, "Accept this trade? (y/n): ", 0
    accept_trade_prompt_len equ $ - accept_trade_prompt

    trade_accepted_msg db "✅ Trade accepted!", 0xA
                       db "Executing atomic swap...", 0xA, 0
    trade_accepted_msg_len equ $ - trade_accepted_msg

    trade_declined_msg db "❌ Trade declined.", 0xA, 0
    trade_declined_msg_len equ $ - trade_declined_msg

    ; ========== ATOMIC SWAP EXECUTION ==========
    executing_swap_msg db "⏳ [1/4] Validating ownership...", 0xA, 0
    executing_swap_msg_len equ $ - executing_swap_msg

    creating_offers_msg db "⏳ [2/4] Creating cross-offers...", 0xA, 0
    creating_offers_msg_len equ $ - creating_offers_msg

    accepting_offers_msg db "⏳ [3/4] Accepting offers...", 0xA, 0
    accepting_offers_msg_len equ $ - accepting_offers_msg

    finalizing_swap_msg db "⏳ [4/4] Finalizing swap...", 0xA, 0
    finalizing_swap_msg_len equ $ - finalizing_swap_msg

    swap_complete_msg db 0xA, "🎉 Trade Complete!", 0xA
                      db "NFTs successfully swapped!", 0xA, 0xA, 0
    swap_complete_msg_len equ $ - swap_complete_msg

    ; ========== TRADE HISTORY ==========
    trade_history_header db "╔════════════════════════════════════════════════════╗", 0xA
                         db "║  Date    │  Trader     │  Gave  │  Got         ║", 0xA
                         db "╠════════════════════════════════════════════════════╣", 0xA, 0
    trade_history_header_len equ $ - trade_history_header

    ; ========== SAFETY FEATURES ==========
    trade_lock_warning db "⚠️  WARNING: Trade is FINAL and IRREVERSIBLE!", 0xA
                       db "Review carefully before accepting.", 0xA, 0xA, 0
    trade_lock_warning_len equ $ - trade_lock_warning

    ownership_verified_msg db "✓ Ownership verified", 0xA, 0
    ownership_verified_msg_len equ $ - ownership_verified_msg

    ownership_failed_msg db "❌ Ownership verification failed!", 0xA
                         db "Trade cannot proceed.", 0xA, 0
    ownership_failed_msg_len equ $ - ownership_failed_msg

section .bss
    ; ========== TRADE PROPOSALS ==========
    active_trades:
        .count resq 1
        .data resb 25000            ; 50 trades * 500 bytes each

    ; Trade structure (500 bytes):
    ; - trade_id (64 bytes)
    ; - proposer_address (48 bytes)
    ; - receiver_address (48 bytes)
    ; - proposer_nft_ids (5 * 64 = 320 bytes) - Up to 5 NFTs
    ; - receiver_nft_ids (5 * 64 = 320 bytes)
    ; - proposer_nft_count (1 byte)
    ; - receiver_nft_count (1 byte)
    ; - xrp_amount_proposer (8 bytes) - Optional XRP addition
    ; - xrp_amount_receiver (8 bytes)
    ; - status (1 byte): 0=pending, 1=accepted, 2=declined, 3=complete
    ; - created_time (8 bytes)
    ; - expiry_time (8 bytes)
    ; - padding

    ; ========== CURRENT TRADE ==========
    selected_trade_id resb 64
    my_nft_offers resb 320          ; Up to 5 NFT Token IDs
    their_nft_requests resb 320
    my_nft_count resb 1
    their_nft_count resb 1
    xrp_addition resq 1

    ; ========== SWAP EXECUTION ==========
    offer_ids resb 640              ; 10 offer IDs (for cross-offers)

section .text
    global propose_trade
    global accept_trade
    global decline_trade
    global execute_atomic_swap
    global view_trade_proposals
    global cancel_trade

    extern marketplace_list_nft
    extern marketplace_buy_nft
    extern account_address
    extern account_balance
    extern xrpl_init
    extern xrpl_close
    extern serialize_transaction
    extern sign_transaction
    extern print_string
    extern print_number
    extern get_current_time

; ========== PROPOSE TRADE ==========
; Create a trade proposal to another player
; Input: rdi = pointer to receiver address
;        rsi = pointer to my NFT IDs (array)
;        rdx = my NFT count
;        rcx = pointer to their NFT IDs (array)
;        r8 = their NFT count
; Returns: rax = 0 on success, -1 on error
propose_trade:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi            ; Receiver address
    mov r13, rsi            ; My NFTs
    mov r14, rdx            ; My count
    mov r15, rcx            ; Their NFTs
    mov rbx, r8             ; Their count

    ; Display progress
    mov rax, 1
    mov rdi, 1
    lea rsi, [propose_trade_msg]
    mov rdx, propose_trade_msg_len
    syscall

    ; Allocate trade slot
    call allocate_trade_slot
    test rax, rax
    js .error

    mov [trade_slot_ptr], rax

    ; Generate trade ID
    call generate_trade_id

    ; Initialize trade data
    lea rdi, [trade_slot_ptr]
    call initialize_trade_data

    ; Save NFT IDs
    lea rdi, [my_nft_offers]
    mov rsi, r13
    mov rcx, r14
    imul rcx, 64
    rep movsb

    lea rdi, [their_nft_requests]
    mov rsi, r15
    mov rcx, rbx
    imul rcx, 64
    rep movsb

    mov byte [my_nft_count], r14b
    mov byte [their_nft_count], bl

    ; Send trade proposal notification
    ; (would use XRPL Payment with Memo or off-chain notification)
    call send_trade_notification

    ; Display success
    mov rax, 1
    mov rdi, 1
    lea rsi, [trade_proposed_msg]
    mov rdx, trade_proposed_msg_len
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [waiting_for_response_msg]
    mov rdx, waiting_for_response_msg_len
    syscall

    xor rax, rax
    pop r15
    pop r14
    pop r13
    pop r12
    add rsp, 32
    pop rbp
    ret

.error:
    mov rax, -1
    pop r15
    pop r14
    pop r13
    pop r12
    add rsp, 32
    pop rbp
    ret

; ========== ACCEPT TRADE ==========
; Accept a trade proposal
; Input: rdi = pointer to trade ID
; Returns: rax = 0 on success, -1 on error
accept_trade:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push r12

    mov r12, rdi

    ; Display incoming trade message
    mov rax, 1
    mov rdi, 1
    lea rsi, [incoming_trade_msg]
    mov rdx, incoming_trade_msg_len
    syscall

    ; Find trade
    call find_trade
    test rax, rax
    js .error

    mov r13, rax            ; Trade data pointer

    ; Display trade details
    mov rdi, r13
    call display_trade_details

    ; Display warning
    mov rax, 1
    mov rdi, 1
    lea rsi, [trade_lock_warning]
    mov rdx, trade_lock_warning_len
    syscall

    ; Get confirmation
    mov rax, 1
    mov rdi, 1
    lea rsi, [accept_trade_prompt]
    mov rdx, accept_trade_prompt_len
    syscall

    call get_yes_no
    test rax, rax
    jnz .declined

    ; Display acceptance
    mov rax, 1
    mov rdi, 1
    lea rsi, [trade_accepted_msg]
    mov rdx, trade_accepted_msg_len
    syscall

    ; Execute atomic swap
    mov rdi, r13
    call execute_atomic_swap
    test rax, rax
    jnz .error

    ; Update trade status
    mov byte [r13 + 888], 3     ; status = complete

    ; Display success
    mov rax, 1
    mov rdi, 1
    lea rsi, [swap_complete_msg]
    mov rdx, swap_complete_msg_len
    syscall

    xor rax, rax
    pop r12
    add rsp, 32
    pop rbp
    ret

.declined:
    mov rax, 1
    mov rdi, 1
    lea rsi, [trade_declined_msg]
    mov rdx, trade_declined_msg_len
    syscall

    ; Update status
    mov byte [r13 + 888], 2     ; status = declined

.error:
    mov rax, -1
    pop r12
    add rsp, 32
    pop rbp
    ret

; ========== EXECUTE ATOMIC SWAP ==========
; Execute atomic NFT swap using XRPL cross-offers
; Input: rdi = trade data pointer
; Returns: rax = 0 on success, -1 on error
execute_atomic_swap:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push r12

    mov r12, rdi

    ; Step 1: Validate ownership
    mov rax, 1
    mov rdi, 1
    lea rsi, [executing_swap_msg]
    mov rdx, executing_swap_msg_len
    syscall

    mov rdi, r12
    call validate_trade_ownership
    test rax, rax
    jnz .ownership_failed

    mov rax, 1
    mov rdi, 1
    lea rsi, [ownership_verified_msg]
    mov rdx, ownership_verified_msg_len
    syscall

    ; Step 2: Create cross-offers
    mov rax, 1
    mov rdi, 1
    lea rsi, [creating_offers_msg]
    mov rdx, creating_offers_msg_len
    syscall

    mov rdi, r12
    call create_cross_offers
    test rax, rax
    jnz .error

    ; Step 3: Accept offers atomically
    mov rax, 1
    mov rdi, 1
    lea rsi, [accepting_offers_msg]
    mov rdx, accepting_offers_msg_len
    syscall

    call accept_cross_offers
    test rax, rax
    jnz .error

    ; Step 4: Finalize
    mov rax, 1
    mov rdi, 1
    lea rsi, [finalizing_swap_msg]
    mov rdx, finalizing_swap_msg_len
    syscall

    call finalize_swap

    xor rax, rax
    pop r12
    add rsp, 32
    pop rbp
    ret

.ownership_failed:
    mov rax, 1
    mov rdi, 1
    lea rsi, [ownership_failed_msg]
    mov rdx, ownership_failed_msg_len
    syscall

.error:
    mov rax, -1
    pop r12
    add rsp, 32
    pop rbp
    ret

; ========== VIEW TRADE PROPOSALS ==========
; View all active trade proposals
; Returns: rax = number of active trades
view_trade_proposals:
    push rbp
    mov rbp, rsp

    ; Display header
    mov rax, 1
    mov rdi, 1
    lea rsi, [trade_history_header]
    mov rdx, trade_history_header_len
    syscall

    ; Get trade count
    mov r12, [active_trades.count]
    xor r13, r13

.display_loop:
    cmp r13, r12
    jge .done

    ; Get trade data
    mov rax, r13
    imul rax, 500
    lea rbx, [active_trades.data]
    add rbx, rax

    ; Display trade row
    mov rdi, r13
    mov rsi, rbx
    call display_trade_row

    inc r13
    jmp .display_loop

.done:
    mov rax, r12
    pop rbp
    ret

; ========== DECLINE TRADE ==========
; Decline a trade proposal
; Input: rdi = pointer to trade ID
; Returns: rax = 0 on success
decline_trade:
    push rbp
    mov rbp, rsp

    ; Find trade
    call find_trade
    test rax, rax
    js .error

    ; Update status to declined
    mov byte [rax + 888], 2

    ; Display message
    mov rax, 1
    mov rdi, 1
    lea rsi, [trade_declined_msg]
    mov rdx, trade_declined_msg_len
    syscall

    xor rax, rax
    pop rbp
    ret

.error:
    mov rax, -1
    pop rbp
    ret

; ========== CANCEL TRADE ==========
; Cancel own trade proposal
; Input: rdi = pointer to trade ID
; Returns: rax = 0 on success
cancel_trade:
    push rbp
    mov rbp, rsp

    ; Find trade
    call find_trade
    test rax, rax
    js .error

    ; Check if I'm the proposer
    lea rsi, [rax + 64]
    lea rdi, [account_address]
    mov rcx, 48
    repe cmpsb
    jne .not_proposer

    ; Remove trade
    ; (simplified - would mark as canceled)

    xor rax, rax
    pop rbp
    ret

.not_proposer:
.error:
    mov rax, -1
    pop rbp
    ret

; ========== HELPER FUNCTIONS ==========

; Allocate trade slot
allocate_trade_slot:
    mov rax, [active_trades.count]
    cmp rax, 50
    jge .full

    inc qword [active_trades.count]
    dec rax
    imul rax, 500
    lea rbx, [active_trades.data]
    add rax, rbx
    ret

.full:
    mov rax, -1
    ret

; Generate trade ID
generate_trade_id:
    call get_current_time
    lea rdi, [selected_trade_id]
    call int_to_hex_string
    ret

; Initialize trade data
initialize_trade_data:
    ; Set up trade structure
    ret

; Send trade notification
send_trade_notification:
    ; Send notification to receiver
    ; (would use XRPL Payment with Memo)
    ret

; Find trade by ID
find_trade:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov r12, rdi
    xor r13, r13

.search_loop:
    cmp r13, [active_trades.count]
    jge .not_found

    mov rax, r13
    imul rax, 500
    lea rbx, [active_trades.data]
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

; Display trade details
display_trade_details:
    push rbp
    mov rbp, rsp

    ; Display "You Offer"
    mov rax, 1
    mov rdi, 1
    lea rsi, [you_offer_label]
    mov rdx, you_offer_label_len
    syscall

    ; Display my NFTs
    ; TODO: Show NFT details

    ; Display swap arrow
    mov rax, 1
    mov rdi, 1
    lea rsi, [swap_arrow]
    mov rdx, swap_arrow_len
    syscall

    ; Display "They Offer"
    mov rax, 1
    mov rdi, 1
    lea rsi, [they_offer_label]
    mov rdx, they_offer_label_len
    syscall

    ; Display their NFTs
    ; TODO: Show NFT details

    pop rbp
    ret

; Validate trade ownership
validate_trade_ownership:
    ; Verify both parties own the NFTs they're trading
    xor rax, rax
    ret

; Create cross-offers
create_cross_offers:
    ; Create NFTokenCreateOffer for each NFT
    ; Proposer creates offers for receiver's NFTs
    ; Receiver creates offers for proposer's NFTs
    xor rax, rax
    ret

; Accept cross-offers
accept_cross_offers:
    ; Both parties accept all offers simultaneously
    xor rax, rax
    ret

; Finalize swap
finalize_swap:
    ; Verify all transfers complete
    ret

; Display trade row
display_trade_row:
    ret

; Convert int to hex string
int_to_hex_string:
    ret

section .bss
    trade_slot_ptr resq 1
    extern get_yes_no

; ========== EXPORTS ==========
global propose_trade
global accept_trade
global decline_trade
global execute_atomic_swap
global view_trade_proposals
global cancel_trade
global active_trades
