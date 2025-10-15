; QUIGZIMON NFT Marketplace - User Interface
; Pure x86-64 assembly implementation of marketplace UI
; Beautiful ASCII art interface for trading!

section .data
    ; ========== MAIN MENU ==========
    marketplace_menu db 0xA, "═══════════════════════════════════════", 0xA
                     db "      MARKETPLACE MENU", 0xA
                     db "═══════════════════════════════════════", 0xA, 0xA
                     db "1) 📋 Browse All Listings", 0xA
                     db "2) 🏷️  List My QUIGZIMON for Sale", 0xA
                     db "3) 👁️  View My Active Listings", 0xA
                     db "4) ❌ Cancel a Listing", 0xA
                     db "5) 💰 Check My Balance", 0xA
                     db "0) 🚪 Exit Marketplace", 0xA, 0xA
                     db "Enter choice: ", 0
    marketplace_menu_len equ $ - marketplace_menu

    ; ========== BROWSE INTERFACE ==========
    browse_title db 0xA, "═══════════════════════════════════════", 0xA
                 db "      BROWSE MARKETPLACE", 0xA
                 db "═══════════════════════════════════════", 0xA, 0xA, 0
    browse_title_len equ $ - browse_title

    listing_row_start db "║ ", 0
    listing_row_start_len equ $ - listing_row_start

    listing_separator db " │ ", 0
    listing_separator_len equ $ - listing_separator

    listing_row_end db " ║", 0xA, 0
    listing_row_end_len equ $ - listing_row_end

    buy_prompt db 0xA, "Enter listing number to buy (or 0 to go back): ", 0
    buy_prompt_len equ $ - buy_prompt

    confirm_purchase_msg db 0xA, "Confirm purchase of ", 0
    confirm_purchase_msg_len equ $ - confirm_purchase_msg

    for_msg db " for ", 0
    for_msg_len equ $ - for_msg

    drops_msg db " drops? (y/n): ", 0
    drops_msg_len equ $ - drops_msg

    ; ========== LIST YOUR NFT ==========
    list_nft_title db 0xA, "═══════════════════════════════════════", 0xA
                   db "      LIST YOUR QUIGZIMON", 0xA
                   db "═══════════════════════════════════════", 0xA, 0xA, 0
    list_nft_title_len equ $ - list_nft_title

    my_nfts_header db "Your QUIGZIMON NFTs:", 0xA, 0xA, 0
    my_nfts_header_len equ $ - my_nfts_header

    select_nft_prompt db 0xA, "Select QUIGZIMON to list (enter number): ", 0
    select_nft_prompt_len equ $ - select_nft_prompt

    enter_price_prompt db "Enter price in XRP (e.g., 100 for 100 XRP): ", 0
    enter_price_prompt_len equ $ - enter_price_prompt

    confirm_listing_msg db 0xA, "List ", 0
    confirm_listing_msg_len equ $ - confirm_listing_msg

    xrp_confirm db " XRP? (y/n): ", 0
    xrp_confirm_len equ $ - xrp_confirm

    ; ========== MY LISTINGS ==========
    my_listings_title db 0xA, "═══════════════════════════════════════", 0xA
                      db "      MY ACTIVE LISTINGS", 0xA
                      db "═══════════════════════════════════════", 0xA, 0xA, 0
    my_listings_title_len equ $ - my_listings_title

    no_active_listings db "You have no active listings.", 0xA, 0
    no_active_listings_len equ $ - no_active_listings

    ; ========== CANCEL LISTING ==========
    cancel_listing_title db 0xA, "═══════════════════════════════════════", 0xA
                         db "      CANCEL LISTING", 0xA
                         db "═══════════════════════════════════════", 0xA, 0xA, 0
    cancel_listing_title_len equ $ - cancel_listing_title

    select_cancel_prompt db "Enter listing number to cancel (or 0 to go back): ", 0
    select_cancel_prompt_len equ $ - select_cancel_prompt

    confirm_cancel_msg db "Cancel this listing? (y/n): ", 0
    confirm_cancel_msg_len equ $ - confirm_cancel_msg

    ; ========== BALANCE DISPLAY ==========
    balance_title db 0xA, "═══════════════════════════════════════", 0xA
                  db "      WALLET BALANCE", 0xA
                  db "═══════════════════════════════════════", 0xA, 0xA, 0
    balance_title_len equ $ - balance_title

    current_balance_label db "Current Balance: ", 0
    current_balance_label_len equ $ - current_balance_label

    xrp_label db " XRP (", 0
    xrp_label_len equ $ - xrp_label

    drops_label db " drops)", 0xA, 0
    drops_label_len equ $ - drops_label

    press_enter_continue db 0xA, "Press Enter to continue...", 0
    press_enter_continue_len equ $ - press_enter_continue

    ; ========== ERROR MESSAGES ==========
    invalid_choice_msg db "Invalid choice. Please try again.", 0xA, 0
    invalid_choice_msg_len equ $ - invalid_choice_msg

    invalid_number_msg db "Invalid number. Please try again.", 0xA, 0
    invalid_number_msg_len equ $ - invalid_number_msg

    insufficient_balance_msg db "❌ Insufficient balance for this purchase!", 0xA, 0
    insufficient_balance_msg_len equ $ - insufficient_balance_msg

    no_nfts_msg db "You don't have any QUIGZIMON NFTs to list.", 0xA, 0
    no_nfts_msg_len equ $ - no_nfts_msg

    ; ========== LISTING DISPLAY TEMPLATES ==========
    listing_index_col resb 8
    listing_name_col resb 32
    listing_level_col resb 8
    listing_price_col resb 16
    listing_owner_col resb 16

section .bss
    ; ========== USER INPUT ==========
    input_buffer resb 64
    selected_index resq 1
    entered_price resq 1

    ; ========== MY NFT COLLECTION ==========
    my_nft_count resq 1
    my_nft_list resb 3200      ; 50 NFTs * 64 bytes each (Token ID)

    ; ========== DISPLAY STATE ==========
    current_page resq 1
    items_per_page equ 10

section .text
    global marketplace_ui_main
    global display_listing_row
    global get_user_nft_list

    extern marketplace_list_nft
    extern marketplace_browse_listings
    extern marketplace_buy_nft
    extern marketplace_cancel_listing
    extern marketplace_get_my_listings
    extern current_listings
    extern account_balance
    extern account_address
    extern get_account_info
    extern xrpl_init
    extern xrpl_close
    extern print_string
    extern print_number

; ========== MAIN MARKETPLACE UI ==========
marketplace_ui_main:
    push rbp
    mov rbp, rsp

.main_loop:
    ; Display marketplace banner
    mov rax, 1
    mov rdi, 1
    lea rsi, [marketplace_title]
    mov rdx, marketplace_title_len
    syscall

    ; Display menu
    mov rax, 1
    mov rdi, 1
    lea rsi, [marketplace_menu]
    mov rdx, marketplace_menu_len
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
    je .browse
    cmp al, 2
    je .list_nft
    cmp al, 3
    je .my_listings
    cmp al, 4
    je .cancel
    cmp al, 5
    je .check_balance

    ; Invalid choice
    mov rax, 1
    mov rdi, 1
    lea rsi, [invalid_choice_msg]
    mov rdx, invalid_choice_msg_len
    syscall
    jmp .main_loop

.browse:
    call ui_browse_marketplace
    jmp .main_loop

.list_nft:
    call ui_list_my_nft
    jmp .main_loop

.my_listings:
    call ui_view_my_listings
    jmp .main_loop

.cancel:
    call ui_cancel_listing
    jmp .main_loop

.check_balance:
    call ui_check_balance
    jmp .main_loop

.exit:
    pop rbp
    ret

; ========== BROWSE MARKETPLACE UI ==========
ui_browse_marketplace:
    push rbp
    mov rbp, rsp

    ; Display title
    mov rax, 1
    mov rdi, 1
    lea rsi, [browse_title]
    mov rdx, browse_title_len
    syscall

    ; Fetch listings from blockchain
    call marketplace_browse_listings
    test rax, rax
    jz .no_listings

    ; Display each listing
    mov r12, 0              ; Index counter
    mov r13, [current_listings.count]

.display_loop:
    cmp r12, r13
    jge .done_display

    ; Display listing row
    mov rdi, r12
    call display_listing_row

    inc r12
    jmp .display_loop

.done_display:
    ; Prompt to buy
    mov rax, 1
    mov rdi, 1
    lea rsi, [buy_prompt]
    mov rdx, buy_prompt_len
    syscall

    ; Get selection
    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 64
    syscall

    ; Parse number
    lea rdi, [input_buffer]
    call parse_number
    mov [selected_index], rax

    ; Check if 0 (go back)
    cmp rax, 0
    je .done

    ; Validate index
    dec rax                 ; Convert to 0-based
    cmp rax, r13
    jge .invalid_selection

    ; Confirm purchase
    mov rdi, rax
    call confirm_and_purchase

.done:
    pop rbp
    ret

.no_listings:
    ; Already displayed by browse_listings
    call wait_for_enter
    pop rbp
    ret

.invalid_selection:
    mov rax, 1
    mov rdi, 1
    lea rsi, [invalid_number_msg]
    mov rdx, invalid_number_msg_len
    syscall
    jmp .done

; ========== LIST MY NFT UI ==========
ui_list_my_nft:
    push rbp
    mov rbp, rsp

    ; Display title
    mov rax, 1
    mov rdi, 1
    lea rsi, [list_nft_title]
    mov rdx, list_nft_title_len
    syscall

    ; Get user's NFT collection
    call get_user_nft_list
    test rax, rax
    jz .no_nfts

    ; Display NFTs
    mov rax, 1
    mov rdi, 1
    lea rsi, [my_nfts_header]
    mov rdx, my_nfts_header_len
    syscall

    ; TODO: Display each NFT with details
    ; For now, simplified

    ; Prompt for selection
    mov rax, 1
    mov rdi, 1
    lea rsi, [select_nft_prompt]
    mov rdx, select_nft_prompt_len
    syscall

    ; Get NFT index
    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 64
    syscall

    lea rdi, [input_buffer]
    call parse_number
    mov [selected_index], rax

    ; Validate
    cmp rax, 0
    je .done
    dec rax
    cmp rax, [my_nft_count]
    jge .done

    ; Prompt for price
    mov rax, 1
    mov rdi, 1
    lea rsi, [enter_price_prompt]
    mov rdx, enter_price_prompt_len
    syscall

    ; Get price
    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 64
    syscall

    lea rdi, [input_buffer]
    call parse_number
    mov [entered_price], rax

    ; Convert XRP to drops (multiply by 1,000,000)
    imul rax, 1000000
    mov [entered_price], rax

    ; Confirm
    call confirm_and_list

.done:
    pop rbp
    ret

.no_nfts:
    mov rax, 1
    mov rdi, 1
    lea rsi, [no_nfts_msg]
    mov rdx, no_nfts_msg_len
    syscall
    call wait_for_enter
    pop rbp
    ret

; ========== VIEW MY LISTINGS UI ==========
ui_view_my_listings:
    push rbp
    mov rbp, rsp

    ; Display title
    mov rax, 1
    mov rdi, 1
    lea rsi, [my_listings_title]
    mov rdx, my_listings_title_len
    syscall

    ; Get my listings
    call marketplace_get_my_listings
    test rax, rax
    jz .no_listings

    ; Display listings (similar to browse)
    ; TODO: Filter by my account

    call wait_for_enter
    pop rbp
    ret

.no_listings:
    mov rax, 1
    mov rdi, 1
    lea rsi, [no_active_listings]
    mov rdx, no_active_listings_len
    syscall
    call wait_for_enter
    pop rbp
    ret

; ========== CANCEL LISTING UI ==========
ui_cancel_listing:
    push rbp
    mov rbp, rsp

    ; Display title
    mov rax, 1
    mov rdi, 1
    lea rsi, [cancel_listing_title]
    mov rdx, cancel_listing_title_len
    syscall

    ; Show my listings
    call marketplace_get_my_listings
    test rax, rax
    jz .no_listings

    ; Prompt for selection
    mov rax, 1
    mov rdi, 1
    lea rsi, [select_cancel_prompt]
    mov rdx, select_cancel_prompt_len
    syscall

    ; Get input
    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 64
    syscall

    lea rdi, [input_buffer]
    call parse_number
    cmp rax, 0
    je .done

    ; Confirm and cancel
    mov rdi, rax
    dec rdi                 ; Convert to 0-based
    call confirm_and_cancel

.done:
    pop rbp
    ret

.no_listings:
    call wait_for_enter
    pop rbp
    ret

; ========== CHECK BALANCE UI ==========
ui_check_balance:
    push rbp
    mov rbp, rsp

    ; Display title
    mov rax, 1
    mov rdi, 1
    lea rsi, [balance_title]
    mov rdx, balance_title_len
    syscall

    ; Fetch current balance
    call xrpl_init
    call get_account_info
    call xrpl_close

    ; Display balance label
    mov rax, 1
    mov rdi, 1
    lea rsi, [current_balance_label]
    mov rdx, current_balance_label_len
    syscall

    ; Convert drops to XRP and display
    mov rax, [account_balance]
    mov rbx, 1000000
    xor rdx, rdx
    div rbx
    call print_number

    ; Show XRP label
    mov rax, 1
    mov rdi, 1
    lea rsi, [xrp_label]
    mov rdx, xrp_label_len
    syscall

    ; Show drops in parentheses
    mov rax, [account_balance]
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [drops_label]
    mov rdx, drops_label_len
    syscall

    call wait_for_enter
    pop rbp
    ret

; ========== HELPER FUNCTIONS ==========

; Display a single listing row
; Input: rdi = listing index
display_listing_row:
    push rbp
    mov rbp, rsp
    push r12

    mov r12, rdi

    ; Calculate listing address
    imul r12, 200           ; Each listing is 200 bytes
    lea rbx, [current_listings.data]
    add rbx, r12

    ; Display row start
    mov rax, 1
    mov rdi, 1
    lea rsi, [listing_row_start]
    mov rdx, listing_row_start_len
    syscall

    ; Display index (listing number)
    mov rax, r12
    mov rbx, 200
    xor rdx, rdx
    div rbx
    inc rax                 ; Make 1-based
    call print_number

    ; Separator
    mov rax, 1
    mov rdi, 1
    lea rsi, [listing_separator]
    mov rdx, listing_separator_len
    syscall

    ; TODO: Display QUIGZIMON name, level, price, owner
    ; For now, placeholder

    ; Row end
    mov rax, 1
    mov rdi, 1
    lea rsi, [listing_row_end]
    mov rdx, listing_row_end_len
    syscall

    pop r12
    pop rbp
    ret

; Confirm and execute purchase
confirm_and_purchase:
    push rbp
    mov rbp, rsp
    push r12

    mov r12, rdi            ; Save listing index

    ; Display confirmation prompt
    mov rax, 1
    mov rdi, 1
    lea rsi, [confirm_purchase_msg]
    mov rdx, confirm_purchase_msg_len
    syscall

    ; Get y/n
    call get_yes_no
    test rax, rax
    jnz .canceled

    ; Execute purchase
    mov rdi, r12
    call marketplace_buy_nft

.canceled:
    pop r12
    pop rbp
    ret

; Confirm and execute listing
confirm_and_list:
    push rbp
    mov rbp, rsp

    ; Display confirmation
    mov rax, 1
    mov rdi, 1
    lea rsi, [confirm_listing_msg]
    mov rdx, confirm_listing_msg_len
    syscall

    ; Show price
    mov rax, [entered_price]
    mov rbx, 1000000
    xor rdx, rdx
    div rbx
    call print_number

    mov rax, 1
    mov rdi, 1
    lea rsi, [xrp_confirm]
    mov rdx, xrp_confirm_len
    syscall

    ; Get confirmation
    call get_yes_no
    test rax, rax
    jnz .canceled

    ; Execute listing
    ; Get NFT Token ID from my_nft_list
    mov rax, [selected_index]
    imul rax, 64
    lea rdi, [my_nft_list]
    add rdi, rax
    mov rsi, [entered_price]
    call marketplace_list_nft

.canceled:
    pop rbp
    ret

; Confirm and execute cancel
confirm_and_cancel:
    push rbp
    mov rbp, rsp
    push r12

    mov r12, rdi

    ; Display confirmation
    mov rax, 1
    mov rdi, 1
    lea rsi, [confirm_cancel_msg]
    mov rdx, confirm_cancel_msg_len
    syscall

    ; Get confirmation
    call get_yes_no
    test rax, rax
    jnz .done

    ; Get offer index from listing
    imul r12, 200
    lea rdi, [current_listings.data]
    add rdi, r12

    ; Cancel listing
    call marketplace_cancel_listing

.done:
    pop r12
    pop rbp
    ret

; Get user's NFT collection from XRPL
get_user_nft_list:
    push rbp
    mov rbp, rsp

    ; TODO: Query XRPL for account_nfts
    ; For now, return mock data
    mov qword [my_nft_count], 1
    mov rax, 1

    pop rbp
    ret

; Parse number from string
; Input: rdi = string pointer
; Output: rax = number
parse_number:
    push rbp
    mov rbp, rsp
    xor rax, rax
    xor rbx, rbx
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

; Get yes/no input
; Returns: rax = 0 for yes, -1 for no
get_yes_no:
    push rbp
    mov rbp, rsp

    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 64
    syscall

    movzx rax, byte [input_buffer]
    or al, 0x20             ; Lowercase
    cmp al, 'y'
    je .yes

    mov rax, -1
    pop rbp
    ret

.yes:
    xor rax, rax
    pop rbp
    ret

; Wait for Enter key
wait_for_enter:
    push rbp
    mov rbp, rsp

    mov rax, 1
    mov rdi, 1
    lea rsi, [press_enter_continue]
    mov rdx, press_enter_continue_len
    syscall

    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 64
    syscall

    pop rbp
    ret

section .data
    marketplace_title db 0xA
                      db "╔════════════════════════════════════════════════════╗", 0xA
                      db "║                                                    ║", 0xA
                      db "║         🏪 QUIGZIMON NFT MARKETPLACE 🏪           ║", 0xA
                      db "║                                                    ║", 0xA
                      db "║     The World's First Assembly NFT Market!        ║", 0xA
                      db "║                                                    ║", 0xA
                      db "╚════════════════════════════════════════════════════╝", 0xA, 0xA, 0
    marketplace_title_len equ $ - marketplace_title

; ========== EXPORTS ==========
global marketplace_ui_main
global display_listing_row
global get_user_nft_list
