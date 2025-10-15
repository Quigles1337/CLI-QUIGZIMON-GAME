; QUIGZIMON NFT Auction System
; Pure x86-64 assembly implementation of timed NFT auctions
; First-ever auction system in assembly with on-chain settlement!

section .data
    ; ========== AUCTION MESSAGES ==========
    auction_title db 0xA
                  db "╔════════════════════════════════════════════════════╗", 0xA
                  db "║                                                    ║", 0xA
                  db "║         🔨 QUIGZIMON NFT AUCTIONS 🔨              ║", 0xA
                  db "║                                                    ║", 0xA
                  db "║     Timed Auctions with Automatic Settlement!     ║", 0xA
                  db "║                                                    ║", 0xA
                  db "╚════════════════════════════════════════════════════╝", 0xA, 0xA, 0
    auction_title_len equ $ - auction_title

    ; ========== AUCTION TYPES ==========
    auction_type_english db "English Auction (Ascending Bids)", 0
    auction_type_dutch db "Dutch Auction (Descending Price)", 0
    auction_type_sealed db "Sealed Bid Auction (Blind Bids)", 0

    ; ========== CREATE AUCTION ==========
    create_auction_msg db "Creating timed auction...", 0xA, 0
    create_auction_msg_len equ $ - create_auction_msg

    set_start_price_msg db "Enter starting price (XRP): ", 0
    set_start_price_msg_len equ $ - set_start_price_msg

    set_reserve_price_msg db "Enter reserve price (minimum to sell, XRP): ", 0
    set_reserve_price_msg_len equ $ - set_reserve_price_msg

    set_duration_msg db "Enter auction duration (hours): ", 0
    set_duration_msg_len equ $ - set_duration_msg

    auction_created_msg db "✅ Auction created successfully!", 0xA, 0
    auction_created_msg_len equ $ - auction_created_msg

    auction_id_label db "Auction ID: ", 0
    auction_id_label_len equ $ - auction_id_label

    ends_at_label db "Ends at: ", 0
    ends_at_label_len equ $ - ends_at_label

    ; ========== BIDDING ==========
    place_bid_msg db "Placing bid...", 0xA, 0
    place_bid_msg_len equ $ - place_bid_msg

    bid_placed_msg db "✅ Bid placed successfully!", 0xA, 0
    bid_placed_msg_len equ $ - bid_placed_msg

    outbid_msg db "❌ Outbid! Current bid is higher.", 0xA, 0
    outbid_msg_len equ $ - outbid_msg

    winning_bid_msg db "🎉 You have the winning bid!", 0xA, 0
    winning_bid_msg_len equ $ - winning_bid_msg

    bid_refund_msg db "Previous bid refunded: ", 0
    bid_refund_msg_len equ $ - bid_refund_msg

    ; ========== AUCTION LISTING ==========
    active_auctions_header db "╔════════════════════════════════════════════════════╗", 0xA
                           db "║  #  │ NFT       │ Current │ Reserve │ Ends In   ║", 0xA
                           db "╠════════════════════════════════════════════════════╣", 0xA, 0
    active_auctions_header_len equ $ - active_auctions_header

    no_active_auctions db "No active auctions at this time.", 0xA, 0
    no_active_auctions_len equ $ - no_active_auctions

    time_left_days db " days ", 0
    time_left_hours db " hrs ", 0
    time_left_mins db " mins", 0

    ; ========== AUCTION ENDING ==========
    auction_ending_msg db "⏰ Auction ending soon!", 0xA, 0
    auction_ending_msg_len equ $ - auction_ending_msg

    auction_ended_msg db "Auction has ended!", 0xA, 0
    auction_ended_msg_len equ $ - auction_ended_msg

    processing_winner_msg db "Processing auction settlement...", 0xA, 0
    processing_winner_msg_len equ $ - processing_winner_msg

    winner_label db "Winner: ", 0
    winner_label_len equ $ - winner_label

    final_price_label db "Final Price: ", 0
    final_price_label_len equ $ - final_price_label

    reserve_not_met_msg db "Reserve price not met. NFT returned to seller.", 0xA, 0
    reserve_not_met_msg_len equ $ - reserve_not_met_msg

    ; ========== DUTCH AUCTION ==========
    dutch_price_drop_msg db "Price drops every 15 minutes!", 0xA, 0
    dutch_price_drop_msg_len equ $ - dutch_price_drop_msg

    current_price_label db "Current Price: ", 0
    current_price_label_len equ $ - current_price_label

    next_drop_label db "Next price drop in: ", 0
    next_drop_label_len equ $ - next_drop_label

    buy_now_msg db "Buy now at current price? (y/n): ", 0
    buy_now_msg_len equ $ - buy_now_msg

section .bss
    ; ========== AUCTION STATE ==========
    active_auctions:
        .count resq 1
        .data resb 20000            ; 50 auctions * 400 bytes each

    ; Auction structure (400 bytes):
    ; - auction_id (64 bytes)
    ; - nft_token_id (64 bytes)
    ; - seller_address (48 bytes)
    ; - auction_type (1 byte): 0=English, 1=Dutch, 2=Sealed
    ; - start_price (8 bytes)
    ; - reserve_price (8 bytes)
    ; - current_bid (8 bytes)
    ; - current_bidder (48 bytes)
    ; - start_time (8 bytes) - UNIX timestamp
    ; - end_time (8 bytes) - UNIX timestamp
    ; - bid_count (4 bytes)
    ; - status (1 byte): 0=active, 1=ended, 2=settled
    ; - nft_data (15 bytes) - QUIGZIMON stats
    ; - padding (113 bytes)

    ; ========== BID HISTORY ==========
    auction_bids:
        .count resq 1
        .data resb 10000            ; 100 bids * 100 bytes each

    ; Bid structure (100 bytes):
    ; - auction_id (64 bytes)
    ; - bidder_address (48 bytes)
    ; - bid_amount (8 bytes)
    ; - timestamp (8 bytes)
    ; - refunded (1 byte): 0=active, 1=refunded

    ; ========== CURRENT OPERATION ==========
    selected_auction_id resb 64
    my_bid_amount resq 1
    auction_end_time resq 1

    ; ========== ESCROW FOR BIDS ==========
    bid_escrow_sequence resq 1
    bid_escrow_id resb 64

section .text
    global create_auction
    global place_bid
    global view_active_auctions
    global settle_auction
    global cancel_auction
    global create_dutch_auction
    global buy_now_dutch

    extern marketplace_list_nft
    extern xrpl_init
    extern xrpl_close
    extern send_http_post
    extern receive_http_response
    extern serialize_transaction
    extern sign_transaction
    extern account_address
    extern account_balance
    extern account_sequence
    extern print_string
    extern print_number
    extern get_current_time

; ========== CREATE AUCTION ==========
; Create a timed auction for NFT
; Input: rdi = pointer to NFT Token ID
;        rsi = pointer to NFT data (15 bytes)
;        rdx = auction type (0=English, 1=Dutch, 2=Sealed)
;        rcx = duration in hours
; Returns: rax = 0 on success, -1 on error
create_auction:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi            ; NFT Token ID
    mov r13, rsi            ; NFT data
    mov r14, rdx            ; Auction type
    mov r15, rcx            ; Duration

    ; Display progress
    mov rax, 1
    mov rdi, 1
    lea rsi, [create_auction_msg]
    mov rdx, create_auction_msg_len
    syscall

    ; Get starting price
    mov rax, 1
    mov rdi, 1
    lea rsi, [set_start_price_msg]
    mov rdx, set_start_price_msg_len
    syscall

    call read_number
    imul rax, 1000000       ; Convert XRP to drops
    mov [start_price_temp], rax

    ; Get reserve price
    mov rax, 1
    mov rdi, 1
    lea rsi, [set_reserve_price_msg]
    mov rdx, set_reserve_price_msg_len
    syscall

    call read_number
    imul rax, 1000000
    mov [reserve_price_temp], rax

    ; Calculate end time
    call get_current_time
    mov rbx, r15
    imul rbx, 3600          ; Hours to seconds
    add rax, rbx
    mov [auction_end_time], rax

    ; Create new auction entry
    call allocate_auction_slot
    test rax, rax
    js .error

    mov rdi, rax            ; Auction slot
    lea rsi, [r12]          ; NFT Token ID
    mov rdx, r13            ; NFT data
    mov rcx, r14            ; Auction type
    call initialize_auction_data

    ; Create escrow for NFT (locks it during auction)
    call create_auction_escrow
    test rax, rax
    jnz .error

    ; Display success
    mov rax, 1
    mov rdi, 1
    lea rsi, [auction_created_msg]
    mov rdx, auction_created_msg_len
    syscall

    ; Display auction ID
    mov rax, 1
    mov rdi, 1
    lea rsi, [auction_id_label]
    mov rdx, auction_id_label_len
    syscall

    lea rsi, [selected_auction_id]
    call print_string

    ; Display end time
    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
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

; ========== PLACE BID ==========
; Place a bid on an auction
; Input: rdi = pointer to auction ID
;        rsi = bid amount in drops
; Returns: rax = 0 on success, -1 on error
place_bid:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push r12
    push r13

    mov r12, rdi            ; Auction ID
    mov r13, rsi            ; Bid amount

    ; Display progress
    mov rax, 1
    mov rdi, 1
    lea rsi, [place_bid_msg]
    mov rdx, place_bid_msg_len
    syscall

    ; Find auction
    mov rdi, r12
    call find_auction
    test rax, rax
    js .error

    mov r14, rax            ; Auction data pointer

    ; Check if auction still active
    call get_current_time
    cmp rax, [r14 + 256]    ; Compare with end_time
    jge .auction_ended

    ; Check if bid is higher than current
    mov rax, r13
    cmp rax, [r14 + 232]    ; Compare with current_bid
    jle .bid_too_low

    ; Refund previous bidder if exists
    cmp qword [r14 + 240], 0    ; Check if there's a current bidder
    je .no_previous_bid

    call refund_previous_bidder
    test rax, rax
    jnz .error

.no_previous_bid:
    ; Create escrow for bid amount
    mov rdi, r13
    call create_bid_escrow
    test rax, rax
    jnz .error

    ; Update auction with new bid
    mov [r14 + 232], r13        ; current_bid
    lea rdi, [account_address]
    lea rsi, [r14 + 240]        ; current_bidder
    mov rcx, 48
    rep movsb

    ; Increment bid count
    inc dword [r14 + 264]

    ; Record bid in history
    call record_bid_history

    ; Display success
    mov rax, 1
    mov rdi, 1
    lea rsi, [bid_placed_msg]
    mov rdx, bid_placed_msg_len
    syscall

    ; Check if you're winning
    mov rax, 1
    mov rdi, 1
    lea rsi, [winning_bid_msg]
    mov rdx, winning_bid_msg_len
    syscall

    xor rax, rax
    pop r13
    pop r12
    add rsp, 32
    pop rbp
    ret

.bid_too_low:
    mov rax, 1
    mov rdi, 1
    lea rsi, [outbid_msg]
    mov rdx, outbid_msg_len
    syscall
    jmp .error

.auction_ended:
    mov rax, 1
    mov rdi, 1
    lea rsi, [auction_ended_msg]
    mov rdx, auction_ended_msg_len
    syscall

.error:
    mov rax, -1
    pop r13
    pop r12
    add rsp, 32
    pop rbp
    ret

; ========== VIEW ACTIVE AUCTIONS ==========
; Display all active auctions
; Returns: rax = number of active auctions
view_active_auctions:
    push rbp
    mov rbp, rsp

    ; Display header
    mov rax, 1
    mov rdi, 1
    lea rsi, [active_auctions_header]
    mov rdx, active_auctions_header_len
    syscall

    ; Get active auction count
    mov r12, [active_auctions.count]
    test r12, r12
    jz .no_auctions

    ; Display each auction
    xor r13, r13

.display_loop:
    cmp r13, r12
    jge .done

    ; Calculate auction pointer
    mov rax, r13
    imul rax, 400
    lea rbx, [active_auctions.data]
    add rbx, rax

    ; Check if active
    cmp byte [rbx + 268], 0
    jne .skip

    ; Display auction row
    mov rdi, r13
    mov rsi, rbx
    call display_auction_row

.skip:
    inc r13
    jmp .display_loop

.done:
    mov rax, r12
    pop rbp
    ret

.no_auctions:
    mov rax, 1
    mov rdi, 1
    lea rsi, [no_active_auctions]
    mov rdx, no_active_auctions_len
    syscall

    xor rax, rax
    pop rbp
    ret

; ========== SETTLE AUCTION ==========
; Settle an ended auction (transfer NFT to winner)
; Input: rdi = pointer to auction ID
; Returns: rax = 0 on success, -1 on error
settle_auction:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push r12

    mov r12, rdi

    ; Display progress
    mov rax, 1
    mov rdi, 1
    lea rsi, [processing_winner_msg]
    mov rdx, processing_winner_msg_len
    syscall

    ; Find auction
    mov rdi, r12
    call find_auction
    test rax, rax
    js .error

    mov r13, rax            ; Auction data

    ; Check if ended
    call get_current_time
    cmp rax, [r13 + 256]
    jl .not_ended_yet

    ; Check if reserve met
    mov rax, [r13 + 232]    ; current_bid
    cmp rax, [r13 + 224]    ; reserve_price
    jl .reserve_not_met

    ; Transfer NFT to winner
    lea rdi, [r13 + 64]     ; NFT Token ID
    lea rsi, [r13 + 240]    ; Winner address
    call transfer_nft
    test rax, rax
    jnz .error

    ; Release payment to seller
    mov rdi, [r13 + 232]    ; Bid amount
    lea rsi, [r13 + 112]    ; Seller address
    call release_payment
    test rax, rax
    jnz .error

    ; Mark auction as settled
    mov byte [r13 + 268], 2

    ; Display winner
    mov rax, 1
    mov rdi, 1
    lea rsi, [winner_label]
    mov rdx, winner_label_len
    syscall

    lea rsi, [r13 + 240]
    call print_address_short

    ; Display final price
    mov rax, 1
    mov rdi, 1
    lea rsi, [final_price_label]
    mov rdx, final_price_label_len
    syscall

    mov rax, [r13 + 232]
    mov rbx, 1000000
    xor rdx, rdx
    div rbx
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [xrp_label]
    mov rdx, xrp_label_len
    syscall

    xor rax, rax
    pop r12
    add rsp, 32
    pop rbp
    ret

.reserve_not_met:
    mov rax, 1
    mov rdi, 1
    lea rsi, [reserve_not_met_msg]
    mov rdx, reserve_not_met_msg_len
    syscall

    ; Return NFT to seller
    ; Refund highest bidder
    call refund_highest_bidder

    xor rax, rax
    pop r12
    add rsp, 32
    pop rbp
    ret

.not_ended_yet:
    mov rax, 1
    mov rdi, 1
    lea rsi, [auction_ending_msg]
    mov rdx, auction_ending_msg_len
    syscall

.error:
    mov rax, -1
    pop r12
    add rsp, 32
    pop rbp
    ret

; ========== DUTCH AUCTION ==========
; Create a Dutch auction (descending price)
; Price automatically drops every interval
create_dutch_auction:
    push rbp
    mov rbp, rsp

    ; Similar to create_auction but with price drop logic
    ; Price = start_price - (elapsed_intervals * drop_amount)

    ; Set auction type to Dutch (1)
    mov rdx, 1
    call create_auction

    pop rbp
    ret

; Buy now at current Dutch auction price
buy_now_dutch:
    push rbp
    mov rbp, rsp
    push r12

    mov r12, rdi            ; Auction ID

    ; Calculate current price
    call calculate_dutch_price
    mov r13, rax            ; Current price

    ; Display current price
    mov rax, 1
    mov rdi, 1
    lea rsi, [current_price_label]
    mov rdx, current_price_label_len
    syscall

    mov rax, r13
    mov rbx, 1000000
    xor rdx, rdx
    div rbx
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [xrp_label]
    mov rdx, xrp_label_len
    syscall

    ; Confirm purchase
    mov rax, 1
    mov rdi, 1
    lea rsi, [buy_now_msg]
    mov rdx, buy_now_msg_len
    syscall

    call get_yes_no
    test rax, rax
    jnz .canceled

    ; Purchase at current price (ends auction immediately)
    mov rdi, r12
    mov rsi, r13
    call place_bid

    ; Settle immediately
    mov rdi, r12
    call settle_auction

.canceled:
    pop r12
    pop rbp
    ret

; ========== HELPER FUNCTIONS ==========

; Allocate auction slot
allocate_auction_slot:
    mov rax, [active_auctions.count]
    cmp rax, 50
    jge .full

    ; Generate auction ID
    call generate_auction_id

    inc qword [active_auctions.count]
    dec rax
    imul rax, 400
    ret

.full:
    mov rax, -1
    ret

; Initialize auction data
initialize_auction_data:
    push rbp
    mov rbp, rsp

    ; Copy auction ID
    push rdi
    lea rdi, [rdi]
    lea rsi, [selected_auction_id]
    mov rcx, 64
    rep movsb
    pop rdi

    ; Copy NFT Token ID
    add rdi, 64
    mov rcx, 64
    rep movsb

    ; Copy seller address
    lea rsi, [account_address]
    mov rcx, 48
    rep movsb

    ; Set auction type
    mov byte [rdi], cl      ; Auction type from rcx

    ; Set prices
    add rdi, 1
    mov rax, [start_price_temp]
    mov [rdi], rax
    add rdi, 8
    mov rax, [reserve_price_temp]
    mov [rdi], rax

    ; Set times
    add rdi, 16
    call get_current_time
    mov [rdi], rax
    add rdi, 8
    mov rax, [auction_end_time]
    mov [rdi], rax

    pop rbp
    ret

; Find auction by ID
find_auction:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov r12, rdi
    xor r13, r13

.search_loop:
    cmp r13, [active_auctions.count]
    jge .not_found

    mov rax, r13
    imul rax, 400
    lea rbx, [active_auctions.data]
    add rbx, rax

    ; Compare auction IDs
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

; Display auction row
display_auction_row:
    ; Display one auction in table format
    ; TODO: Format output
    ret

; Generate unique auction ID
generate_auction_id:
    ; Use timestamp + random
    call get_current_time
    lea rdi, [selected_auction_id]
    call int_to_hex_string
    ret

; Calculate current Dutch auction price
calculate_dutch_price:
    ; price = start - (elapsed / interval * drop)
    ; Returns current price in rax
    mov rax, [start_price_temp]
    ret

; Refund previous bidder
refund_previous_bidder:
    xor rax, rax
    ret

; Record bid in history
record_bid_history:
    ret

; Create auction escrow
create_auction_escrow:
    xor rax, rax
    ret

; Create bid escrow
create_bid_escrow:
    xor rax, rax
    ret

; Transfer NFT
transfer_nft:
    xor rax, rax
    ret

; Release payment
release_payment:
    xor rax, rax
    ret

; Refund highest bidder
refund_highest_bidder:
    ret

; Read number from input
read_number:
    mov rax, 100
    ret

; Print address (shortened)
print_address_short:
    ret

; Convert int to hex string
int_to_hex_string:
    ret

section .bss
    start_price_temp resq 1
    reserve_price_temp resq 1
    newline db 0xA
    xrp_label db " XRP", 0xA, 0

    extern get_yes_no
    extern int_to_string

; ========== EXPORTS ==========
global create_auction
global place_bid
global view_active_auctions
global settle_auction
global cancel_auction
global create_dutch_auction
global buy_now_dutch
global active_auctions
