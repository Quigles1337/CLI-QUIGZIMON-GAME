; QUIGZIMON Auction UI
; Pure x86-64 assembly implementation of auction interface
; Beautiful bidding experience with live countdown timers!

section .data
    ; ========== AUCTION MENU ==========
    auction_menu_title db 0xA, "═══════════════════════════════════════", 0xA
                       db "      NFT AUCTION HOUSE", 0xA
                       db "═══════════════════════════════════════", 0xA, 0xA, 0
    auction_menu_title_len equ $ - auction_menu_title

    auction_menu db "1) 🔨 Create New Auction", 0xA
                 db "2) 📋 Browse Active Auctions", 0xA
                 db "3) 💰 Place Bid", 0xA
                 db "4) 🏆 My Winning Bids", 0xA
                 db "5) 📊 My Active Auctions", 0xA
                 db "6) ⚡ Buy Now (Dutch Auctions)", 0xA
                 db "0) 🚪 Exit", 0xA, 0xA
                 db "Enter choice: ", 0
    auction_menu_len equ $ - auction_menu

    ; ========== AUCTION CREATION ==========
    create_auction_title db 0xA, "═══════════════════════════════════════", 0xA
                         db "      CREATE NEW AUCTION", 0xA
                         db "═══════════════════════════════════════", 0xA, 0xA, 0
    create_auction_title_len equ $ - create_auction_title

    select_auction_type_msg db "Select Auction Type:", 0xA
                            db "1) English (Ascending Bids)", 0xA
                            db "2) Dutch (Descending Price)", 0xA
                            db "3) Sealed Bid (Blind)", 0xA
                            db "Choice: ", 0
    select_auction_type_msg_len equ $ - select_auction_type_msg

    ; ========== LIVE AUCTION DISPLAY ==========
    live_auction_display db 0xA
                         db "╔════════════════════════════════════════════════════╗", 0xA
                         db "║              LIVE AUCTION                          ║", 0xA
                         db "╠════════════════════════════════════════════════════╣", 0xA, 0
    live_auction_display_len equ $ - live_auction_display

    auction_nft_label db "║  NFT: ", 0
    auction_nft_label_len equ $ - auction_nft_label

    auction_seller_label db "║  Seller: ", 0
    auction_seller_label_len equ $ - auction_seller_label

    auction_type_label db "║  Type: ", 0
    auction_type_label_len equ $ - auction_type_label

    auction_current_bid_label db "║  Current Bid: ", 0
    auction_current_bid_label_len equ $ - auction_current_bid_label

    auction_reserve_label db "║  Reserve Price: ", 0
    auction_reserve_label_len equ $ - auction_reserve_label

    auction_time_left_label db "║  Time Remaining: ", 0
    auction_time_left_label_len equ $ - auction_time_left_label

    auction_bid_count_label db "║  Total Bids: ", 0
    auction_bid_count_label_len equ $ - auction_bid_count_label

    auction_footer db "╚════════════════════════════════════════════════════╝", 0xA, 0
    auction_footer_len equ $ - auction_footer

    ; ========== BIDDING INTERFACE ==========
    place_bid_title db 0xA, "═══════════════════════════════════════", 0xA
                    db "      PLACE YOUR BID", 0xA
                    db "═══════════════════════════════════════", 0xA, 0xA, 0
    place_bid_title_len equ $ - place_bid_title

    minimum_bid_label db "Minimum Bid: ", 0
    minimum_bid_label_len equ $ - minimum_bid_label

    enter_bid_amount_msg db "Enter your bid (XRP): ", 0
    enter_bid_amount_msg_len equ $ - enter_bid_amount_msg

    confirm_bid_msg db 0xA, "Confirm bid of ", 0
    confirm_bid_msg_len equ $ - confirm_bid_msg

    xrp_confirm db " XRP? (y/n): ", 0
    xrp_confirm_len equ $ - xrp_confirm

    bid_increment_msg db "Your bid must be at least ", 0
    bid_increment_msg_len equ $ - bid_increment_msg

    higher_than_current_msg db " XRP higher than current bid.", 0xA, 0
    higher_than_current_msg_len equ $ - higher_than_current_msg

    ; ========== COUNTDOWN TIMER ==========
    timer_days db "d ", 0
    timer_hours db "h ", 0
    timer_minutes db "m ", 0
    timer_seconds db "s", 0

    ending_soon_msg db " ⏰ ENDING SOON!", 0xA, 0
    ending_soon_msg_len equ $ - ending_soon_msg

    ended_msg db " ⏰ ENDED", 0xA, 0
    ended_msg_len equ $ - ended_msg

    ; ========== BID HISTORY ==========
    bid_history_title db 0xA, "═══════════════════════════════════════", 0xA
                      db "      BID HISTORY", 0xA
                      db "═══════════════════════════════════════", 0xA, 0xA, 0
    bid_history_title_len equ $ - bid_history_title

    bid_history_header db "Time      │ Bidder      │ Amount (XRP)", 0xA
                       db "──────────┼─────────────┼─────────────", 0xA, 0
    bid_history_header_len equ $ - bid_history_header

    ; ========== MY AUCTIONS ==========
    my_auctions_title db 0xA, "═══════════════════════════════════════", 0xA
                      db "      MY ACTIVE AUCTIONS", 0xA
                      db "═══════════════════════════════════════", 0xA, 0xA, 0
    my_auctions_title_len equ $ - my_auctions_title

    no_my_auctions_msg db "You have no active auctions.", 0xA, 0
    no_my_auctions_msg_len equ $ - no_my_auctions_msg

    ; ========== WINNING BIDS ==========
    winning_bids_title db 0xA, "═══════════════════════════════════════", 0xA
                       db "      MY WINNING BIDS", 0xA
                       db "═══════════════════════════════════════", 0xA, 0xA, 0
    winning_bids_title_len equ $ - winning_bids_title

    winning_status db "🏆 YOU ARE WINNING!", 0xA, 0
    winning_status_len equ $ - winning_status

    outbid_status db "❌ OUTBID", 0xA, 0
    outbid_status_len equ $ - outbid_status

section .bss
    input_buffer resb 64
    selected_auction_idx resq 1
    bid_amount_input resq 1

section .text
    global auction_ui_main
    global display_auction_details
    global display_countdown_timer
    global ui_create_auction
    global ui_browse_auctions
    global ui_place_bid

    extern create_auction
    extern place_bid
    extern view_active_auctions
    extern settle_auction
    extern buy_now_dutch
    extern active_auctions
    extern account_address
    extern print_string
    extern print_number
    extern get_yes_no
    extern get_current_time

; ========== MAIN AUCTION UI ==========
auction_ui_main:
    push rbp
    mov rbp, rsp

.main_loop:
    ; Display title
    mov rax, 1
    mov rdi, 1
    lea rsi, [auction_menu_title]
    mov rdx, auction_menu_title_len
    syscall

    ; Display menu
    mov rax, 1
    mov rdi, 1
    lea rsi, [auction_menu]
    mov rdx, auction_menu_len
    syscall

    ; Get input
    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 64
    syscall

    ; Parse choice
    movzx rax, byte [input_buffer]
    sub al, '0'

    cmp al, 0
    je .exit
    cmp al, 1
    je .create_auction
    cmp al, 2
    je .browse_auctions
    cmp al, 3
    je .place_bid
    cmp al, 4
    je .winning_bids
    cmp al, 5
    je .my_auctions
    cmp al, 6
    je .dutch_buy_now

    jmp .main_loop

.create_auction:
    call ui_create_auction
    jmp .main_loop

.browse_auctions:
    call ui_browse_auctions
    jmp .main_loop

.place_bid:
    call ui_place_bid
    jmp .main_loop

.winning_bids:
    call ui_winning_bids
    jmp .main_loop

.my_auctions:
    call ui_my_auctions
    jmp .main_loop

.dutch_buy_now:
    call ui_dutch_buy_now
    jmp .main_loop

.exit:
    pop rbp
    ret

; ========== CREATE AUCTION UI ==========
ui_create_auction:
    push rbp
    mov rbp, rsp

    ; Display title
    mov rax, 1
    mov rdi, 1
    lea rsi, [create_auction_title]
    mov rdx, create_auction_title_len
    syscall

    ; Select NFT to auction
    ; TODO: Display user's NFTs

    ; Select auction type
    mov rax, 1
    mov rdi, 1
    lea rsi, [select_auction_type_msg]
    mov rdx, select_auction_type_msg_len
    syscall

    ; Get type
    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 64
    syscall

    movzx rax, byte [input_buffer]
    sub al, '0'
    dec al
    mov r12, rax            ; Auction type (0-2)

    ; Get NFT Token ID (mock for now)
    lea rdi, [mock_nft_id]
    lea rsi, [mock_nft_data]
    mov rdx, r12
    mov rcx, 24             ; 24 hours default
    call create_auction

    call wait_for_enter
    pop rbp
    ret

; ========== BROWSE AUCTIONS UI ==========
ui_browse_auctions:
    push rbp
    mov rbp, rsp

    ; Get active auctions
    call view_active_auctions
    mov r12, rax            ; Auction count

    test r12, r12
    jz .no_auctions

    ; Display each auction with details
    xor r13, r13

.display_loop:
    cmp r13, r12
    jge .done

    ; Get auction data
    mov rax, r13
    imul rax, 400
    lea rbx, [active_auctions.data]
    add rbx, rax

    ; Display auction details
    mov rdi, r13
    mov rsi, rbx
    call display_auction_details

    inc r13
    jmp .display_loop

.done:
.no_auctions:
    call wait_for_enter
    pop rbp
    ret

; ========== PLACE BID UI ==========
ui_place_bid:
    push rbp
    mov rbp, rsp

    ; Display title
    mov rax, 1
    mov rdi, 1
    lea rsi, [place_bid_title]
    mov rdx, place_bid_title_len
    syscall

    ; Browse and select auction
    call ui_browse_auctions

    ; Select auction
    mov rax, 1
    mov rdi, 1
    lea rsi, [select_auction_prompt]
    mov rdx, select_auction_prompt_len
    syscall

    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 64
    syscall

    lea rdi, [input_buffer]
    call parse_number
    test rax, rax
    jz .done

    dec rax
    mov [selected_auction_idx], rax

    ; Get auction data
    imul rax, 400
    lea rbx, [active_auctions.data]
    add rbx, rax

    ; Display current bid
    mov rax, 1
    mov rdi, 1
    lea rsi, [minimum_bid_label]
    mov rdx, minimum_bid_label_len
    syscall

    ; Calculate minimum (current + increment)
    mov rax, [rbx + 232]    ; current_bid
    add rax, 1000000        ; Add 1 XRP increment
    mov rbx, 1000000
    xor rdx, rdx
    div rbx
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [xrp_label]
    mov rdx, xrp_label_len
    syscall

    ; Get bid amount
    mov rax, 1
    mov rdi, 1
    lea rsi, [enter_bid_amount_msg]
    mov rdx, enter_bid_amount_msg_len
    syscall

    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 64
    syscall

    lea rdi, [input_buffer]
    call parse_number
    imul rax, 1000000       ; Convert to drops
    mov [bid_amount_input], rax

    ; Confirm bid
    mov rax, 1
    mov rdi, 1
    lea rsi, [confirm_bid_msg]
    mov rdx, confirm_bid_msg_len
    syscall

    mov rax, [bid_amount_input]
    mov rbx, 1000000
    xor rdx, rdx
    div rbx
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [xrp_confirm]
    mov rdx, xrp_confirm_len
    syscall

    call get_yes_no
    test rax, rax
    jnz .done

    ; Place bid
    lea rdi, [selected_auction_id]
    mov rsi, [bid_amount_input]
    call place_bid

.done:
    call wait_for_enter
    pop rbp
    ret

; ========== DISPLAY AUCTION DETAILS ==========
; Input: rdi = auction index, rsi = auction data pointer
display_auction_details:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov r12, rdi
    mov r13, rsi

    ; Display header
    mov rax, 1
    mov rdi, 1
    lea rsi, [live_auction_display]
    mov rdx, live_auction_display_len
    syscall

    ; Display auction number
    mov rax, 1
    mov rdi, 1
    lea rsi, [auction_nft_label]
    mov rdx, auction_nft_label_len
    syscall

    ; NFT name (simplified)
    mov rax, r12
    inc rax
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    ; Display current bid
    mov rax, 1
    mov rdi, 1
    lea rsi, [auction_current_bid_label]
    mov rdx, auction_current_bid_label_len
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

    ; Display time remaining
    mov rax, 1
    mov rdi, 1
    lea rsi, [auction_time_left_label]
    mov rdx, auction_time_left_label_len
    syscall

    mov rdi, [r13 + 256]    ; end_time
    call display_countdown_timer

    ; Display footer
    mov rax, 1
    mov rdi, 1
    lea rsi, [auction_footer]
    mov rdx, auction_footer_len
    syscall

    pop r13
    pop r12
    pop rbp
    ret

; ========== DISPLAY COUNTDOWN TIMER ==========
; Input: rdi = end time (UNIX timestamp)
display_countdown_timer:
    push rbp
    mov rbp, rsp

    ; Get current time
    call get_current_time

    ; Calculate time remaining
    mov rbx, rdi
    sub rbx, rax

    ; Check if ended
    cmp rbx, 0
    jle .ended

    ; Check if ending soon (< 1 hour)
    cmp rbx, 3600
    jl .ending_soon

    ; Calculate days, hours, minutes
    mov rax, rbx
    mov rcx, 86400
    xor rdx, rdx
    div rcx
    mov r12, rax            ; Days
    mov rax, rdx

    mov rcx, 3600
    xor rdx, rdx
    div rcx
    mov r13, rax            ; Hours
    mov rax, rdx

    mov rcx, 60
    xor rdx, rdx
    div rcx
    mov r14, rax            ; Minutes

    ; Display days if > 0
    test r12, r12
    jz .no_days

    mov rax, r12
    call print_number
    mov rax, 1
    mov rdi, 1
    lea rsi, [timer_days]
    mov rdx, 2
    syscall

.no_days:
    ; Display hours
    mov rax, r13
    call print_number
    mov rax, 1
    mov rdi, 1
    lea rsi, [timer_hours]
    mov rdx, 2
    syscall

    ; Display minutes
    mov rax, r14
    call print_number
    mov rax, 1
    mov rdi, 1
    lea rsi, [timer_minutes]
    mov rdx, 2
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    pop rbp
    ret

.ending_soon:
    mov rax, rbx
    mov rcx, 60
    xor rdx, rdx
    div rcx
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [timer_minutes]
    mov rdx, 2
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [ending_soon_msg]
    mov rdx, ending_soon_msg_len
    syscall

    pop rbp
    ret

.ended:
    mov rax, 1
    mov rdi, 1
    lea rsi, [ended_msg]
    mov rdx, ended_msg_len
    syscall

    pop rbp
    ret

; ========== MY WINNING BIDS UI ==========
ui_winning_bids:
    push rbp
    mov rbp, rsp

    ; Display title
    mov rax, 1
    mov rdi, 1
    lea rsi, [winning_bids_title]
    mov rdx, winning_bids_title_len
    syscall

    ; Find auctions where I'm winning
    ; TODO: Filter by current_bidder == account_address

    call wait_for_enter
    pop rbp
    ret

; ========== MY AUCTIONS UI ==========
ui_my_auctions:
    push rbp
    mov rbp, rsp

    ; Display title
    mov rax, 1
    mov rdi, 1
    lea rsi, [my_auctions_title]
    mov rdx, my_auctions_title_len
    syscall

    ; Find auctions I created
    ; TODO: Filter by seller == account_address

    call wait_for_enter
    pop rbp
    ret

; ========== DUTCH BUY NOW UI ==========
ui_dutch_buy_now:
    push rbp
    mov rbp, rsp

    ; Show Dutch auctions only
    ; Allow immediate purchase at current price

    call wait_for_enter
    pop rbp
    ret

; ========== HELPER FUNCTIONS ==========

; Parse number from string
parse_number:
    push rbp
    mov rbp, rsp
    xor rax, rax
    mov rcx, 10

.loop:
    movzx rdx, byte [rdi]
    cmp dl, '0'
    jl .done
    cmp dl, '9'
    jg .done

    sub dl, '0'
    imul rax, rcx
    add rax, rdx
    inc rdi
    jmp .loop

.done:
    pop rbp
    ret

; Wait for Enter
wait_for_enter:
    push rbp
    mov rbp, rsp

    mov rax, 1
    mov rdi, 1
    lea rsi, [press_enter]
    mov rdx, press_enter_len
    syscall

    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 64
    syscall

    pop rbp
    ret

section .bss
    mock_nft_id resb 128
    mock_nft_data resb 15
    selected_auction_id resb 64
    newline db 0xA
    xrp_label db " XRP", 0xA, 0
    select_auction_prompt db "Select auction (number): ", 0
    select_auction_prompt_len equ 26
    press_enter db 0xA, "Press Enter to continue...", 0
    press_enter_len equ 28

; ========== EXPORTS ==========
global auction_ui_main
global display_auction_details
global display_countdown_timer
global ui_create_auction
global ui_browse_auctions
global ui_place_bid
