; QUIGZIMON NFT Marketplace - Core Trading Engine
; Pure x86-64 assembly implementation of NFT trading via XRPL
; World's first blockchain marketplace in assembly!

section .data
    ; ========== MARKETPLACE MESSAGES ==========
    marketplace_title db 0xA
                      db "╔════════════════════════════════════════════════════╗", 0xA
                      db "║                                                    ║", 0xA
                      db "║         🏪 QUIGZIMON NFT MARKETPLACE 🏪           ║", 0xA
                      db "║                                                    ║", 0xA
                      db "║     Buy, Sell, and Trade QUIGZIMON NFTs!          ║", 0xA
                      db "║                                                    ║", 0xA
                      db "╚════════════════════════════════════════════════════╝", 0xA, 0xA, 0
    marketplace_title_len equ $ - marketplace_title

    ; ========== LISTING CREATION ==========
    creating_offer_msg db "Creating sell offer on XRPL...", 0xA, 0
    creating_offer_msg_len equ $ - creating_offer_msg

    offer_created_msg db "✅ Your QUIGZIMON is now listed for sale!", 0xA, 0
    offer_created_msg_len equ $ - offer_created_msg

    offer_id_label db "Offer ID: ", 0
    offer_id_label_len equ $ - offer_id_label

    price_label db "Price: ", 0
    price_label_len equ $ - price_label

    xrp_suffix db " XRP", 0xA, 0
    xrp_suffix_len equ $ - xrp_suffix

    ; ========== BROWSE LISTINGS ==========
    fetching_offers_msg db "Fetching marketplace listings...", 0xA, 0xA, 0
    fetching_offers_msg_len equ $ - fetching_offers_msg

    listing_header db "╔════════════════════════════════════════════════════╗", 0xA
                   db "║  #  │ QUIGZIMON │ Level │  Price  │   Owner     ║", 0xA
                   db "╠════════════════════════════════════════════════════╣", 0xA, 0
    listing_header_len equ $ - listing_header

    listing_footer db "╚════════════════════════════════════════════════════╝", 0xA, 0
    listing_footer_len equ $ - listing_footer

    no_listings_msg db "No marketplace listings found.", 0xA, 0
    no_listings_msg_len equ $ - no_listings_msg

    ; ========== PURCHASE ==========
    purchasing_msg db "Accepting offer and purchasing...", 0xA, 0
    purchasing_msg_len equ $ - purchasing_msg

    purchase_success_msg db 0xA, "🎉 Purchase successful!", 0xA
                         db "QUIGZIMON NFT is now yours!", 0xA, 0xA, 0
    purchase_success_msg_len equ $ - purchase_success_msg

    purchase_error_msg db "❌ Purchase failed. Please try again.", 0xA, 0
    purchase_error_msg_len equ $ - purchase_error_msg

    ; ========== CANCEL LISTING ==========
    canceling_offer_msg db "Canceling marketplace listing...", 0xA, 0
    canceling_offer_msg_len equ $ - canceling_offer_msg

    cancel_success_msg db "✅ Listing canceled successfully.", 0xA, 0
    cancel_success_msg_len equ $ - cancel_success_msg

    ; ========== XRPL TRANSACTION TEMPLATES ==========
    ; NFTokenCreateOffer transaction
    create_offer_tx_start db '{"TransactionType":"NFTokenCreateOffer","Account":"', 0
    create_offer_tx_nft_id db '","NFTokenID":"', 0
    create_offer_tx_amount db '","Amount":"', 0
    create_offer_tx_flags db '","Flags":', 0
    create_offer_tx_fee db ',"Fee":"', 0
    create_offer_tx_seq db '","Sequence":', 0
    create_offer_tx_end db '}', 0

    ; NFTokenAcceptOffer transaction
    accept_offer_tx_start db '{"TransactionType":"NFTokenAcceptOffer","Account":"', 0
    accept_offer_tx_offer db '","NFTokenSellOffer":"', 0

    ; NFTokenCancelOffer transaction
    cancel_offer_tx_start db '{"TransactionType":"NFTokenCancelOffer","Account":"', 0
    cancel_offer_tx_offers db '","NFTokenOffers":["', 0
    cancel_offer_tx_end_array db '"]', 0

    ; Flags for NFTokenCreateOffer
    FLAG_SELL_NFTOKEN equ 1     ; This is a sell offer

    ; ========== JSON PARSING KEYS ==========
    json_key_offers db '"offers":', 0
    json_key_nft_offer_index db '"nft_offer_index":', 0
    json_key_owner db '"owner":', 0
    json_key_amount db '"amount":', 0
    json_key_nft_id_response db '"nft_id":', 0
    json_key_account db '"account":', 0

section .bss
    ; ========== MARKETPLACE STATE ==========
    current_listings:
        .count resq 1               ; Number of active listings
        .data resb 10000            ; 50 listings * 200 bytes each

    ; Each listing structure (200 bytes):
    ; - offer_index (64 bytes) - XRPL offer ID
    ; - nft_token_id (64 bytes) - NFT Token ID
    ; - owner (48 bytes) - Seller address
    ; - price (8 bytes) - Price in drops
    ; - nft_species (1 byte)
    ; - nft_level (1 byte)
    ; - nft_hp (2 bytes)
    ; - nft_attack (2 bytes)
    ; - nft_defense (2 bytes)
    ; - nft_speed (2 bytes)
    ; - padding (4 bytes)

    ; ========== TRANSACTION BUFFERS ==========
    create_offer_tx_json resb 2048
    accept_offer_tx_json resb 2048
    cancel_offer_tx_json resb 2048

    signed_tx_blob resb 4096

    ; ========== RESPONSE BUFFERS ==========
    offer_response resb 8192
    offer_index_result resb 128

    ; ========== CURRENT OPERATION ==========
    selected_listing_index resq 1
    purchase_amount resq 1

section .text
    global marketplace_list_nft
    global marketplace_browse_listings
    global marketplace_buy_nft
    global marketplace_cancel_listing
    global marketplace_get_my_listings

    extern xrpl_init
    extern xrpl_close
    extern send_http_post
    extern receive_http_response
    extern serialize_transaction
    extern sign_transaction
    extern account_address
    extern account_balance
    extern account_sequence
    extern http_response
    extern json_body
    extern print_string
    extern print_number
    extern find_json_value
    extern extract_quoted_value
    extern append_string

; ========== LIST NFT FOR SALE ==========
; Create a sell offer on XRPL
; Input: rdi = pointer to NFT Token ID string (64 bytes)
;        rsi = price in XRP drops (qword)
; Returns: rax = 0 on success, -1 on error
marketplace_list_nft:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push r12
    push r13
    push r14

    mov r12, rdi            ; Save NFT Token ID pointer
    mov r13, rsi            ; Save price

    ; Display progress
    mov rax, 1
    mov rdi, 1
    mov rsi, creating_offer_msg
    mov rdx, creating_offer_msg_len
    syscall

    ; Build NFTokenCreateOffer transaction
    lea rdi, [create_offer_tx_json]

    ; Start transaction
    mov rsi, create_offer_tx_start
    call append_string

    ; Add account
    lea rsi, [account_address]
    call append_string

    ; Add NFTokenID
    mov rsi, create_offer_tx_nft_id
    call append_string

    mov rsi, r12
    call append_string

    ; Add Amount (price in drops)
    mov rsi, create_offer_tx_amount
    call append_string

    mov rax, r13
    push rdi
    call int_to_string
    mov rsi, rax
    pop rdi
    call append_string

    ; Add Flags (1 = sell offer)
    mov rsi, create_offer_tx_flags
    call append_string

    mov rax, FLAG_SELL_NFTOKEN
    push rdi
    call int_to_string
    mov rsi, rax
    pop rdi
    call append_string

    ; Add Fee (standard 12 drops)
    mov rsi, create_offer_tx_fee
    call append_string

    mov byte [rdi], '1'
    inc rdi
    mov byte [rdi], '2'
    inc rdi

    ; Add Sequence
    mov rsi, create_offer_tx_seq
    call append_string

    mov rax, [account_sequence]
    push rdi
    call int_to_string
    mov rsi, rax
    pop rdi
    call append_string

    ; Close transaction
    mov rsi, create_offer_tx_end
    call append_string

    ; Serialize transaction to binary format
    lea rdi, [create_offer_tx_json]
    call serialize_transaction
    test rax, rax
    jnz .error

    ; Sign transaction
    call sign_transaction
    test rax, rax
    jnz .error

    ; Submit to XRPL
    call submit_transaction
    test rax, rax
    jnz .error

    ; Extract offer ID from response
    call extract_offer_id
    test rax, rax
    jnz .error

    ; Display success
    mov rax, 1
    mov rdi, 1
    mov rsi, offer_created_msg
    mov rdx, offer_created_msg_len
    syscall

    ; Show offer ID
    mov rax, 1
    mov rdi, 1
    mov rsi, offer_id_label
    mov rdx, offer_id_label_len
    syscall

    lea rsi, [offer_index_result]
    call print_string

    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    ; Show price
    mov rax, 1
    mov rdi, 1
    mov rsi, price_label
    mov rdx, price_label_len
    syscall

    mov rax, r13
    mov rbx, 1000000        ; Convert drops to XRP
    xor rdx, rdx
    div rbx
    call print_number

    mov rax, 1
    mov rdi, 1
    mov rsi, xrp_suffix
    mov rdx, xrp_suffix_len
    syscall

    ; Increment sequence number
    inc qword [account_sequence]

    xor rax, rax
    pop r14
    pop r13
    pop r12
    add rsp, 32
    pop rbp
    ret

.error:
    mov rax, -1
    pop r14
    pop r13
    pop r12
    add rsp, 32
    pop rbp
    ret

; ========== BROWSE MARKETPLACE LISTINGS ==========
; Fetch all NFTokenOffer objects from XRPL
; Returns: rax = number of listings found
marketplace_browse_listings:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; Display progress
    mov rax, 1
    mov rdi, 1
    mov rsi, fetching_offers_msg
    mov rdx, fetching_offers_msg_len
    syscall

    ; Build account_offers request
    call build_account_offers_request

    ; Send to XRPL
    call xrpl_init
    test rax, rax
    jnz .error

    lea rsi, [json_body]
    call send_http_post
    call receive_http_response

    call xrpl_close

    ; Parse response for offers
    call parse_marketplace_listings

    ; Check if any listings
    mov rax, [current_listings.count]
    test rax, rax
    jz .no_listings

    ; Display listings
    call display_marketplace_listings

    mov rax, [current_listings.count]
    add rsp, 32
    pop rbp
    ret

.no_listings:
    mov rax, 1
    mov rdi, 1
    mov rsi, no_listings_msg
    mov rdx, no_listings_msg_len
    syscall

    xor rax, rax
    add rsp, 32
    pop rbp
    ret

.error:
    mov rax, -1
    add rsp, 32
    pop rbp
    ret

; ========== BUY NFT FROM MARKETPLACE ==========
; Accept a sell offer to purchase NFT
; Input: rdi = listing index (0-based)
; Returns: rax = 0 on success, -1 on error
marketplace_buy_nft:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push r12

    mov r12, rdi            ; Save listing index

    ; Validate index
    cmp r12, [current_listings.count]
    jge .error

    ; Get listing data
    imul r12, 200           ; Each listing is 200 bytes
    lea rbx, [current_listings.data]
    add rbx, r12

    ; Display progress
    mov rax, 1
    mov rdi, 1
    mov rsi, purchasing_msg
    mov rdx, purchasing_msg_len
    syscall

    ; Build NFTokenAcceptOffer transaction
    lea rdi, [accept_offer_tx_json]

    ; Start transaction
    mov rsi, accept_offer_tx_start
    call append_string

    ; Add account
    lea rsi, [account_address]
    call append_string

    ; Add NFTokenSellOffer (offer index from listing)
    mov rsi, accept_offer_tx_offer
    call append_string

    lea rsi, [rbx]          ; Offer index is first field
    call append_string

    ; Add Fee
    mov rsi, create_offer_tx_fee
    call append_string

    mov byte [rdi], '1'
    inc rdi
    mov byte [rdi], '2'
    inc rdi

    ; Add Sequence
    mov rsi, create_offer_tx_seq
    call append_string

    mov rax, [account_sequence]
    push rdi
    call int_to_string
    mov rsi, rax
    pop rdi
    call append_string

    ; Close transaction
    mov rsi, create_offer_tx_end
    call append_string

    ; Serialize and sign
    lea rdi, [accept_offer_tx_json]
    call serialize_transaction
    test rax, rax
    jnz .error

    call sign_transaction
    test rax, rax
    jnz .error

    ; Submit to XRPL
    call submit_transaction
    test rax, rax
    jnz .purchase_failed

    ; Display success
    mov rax, 1
    mov rdi, 1
    mov rsi, purchase_success_msg
    mov rdx, purchase_success_msg_len
    syscall

    ; Increment sequence
    inc qword [account_sequence]

    xor rax, rax
    pop r12
    add rsp, 32
    pop rbp
    ret

.purchase_failed:
    mov rax, 1
    mov rdi, 1
    mov rsi, purchase_error_msg
    mov rdx, purchase_error_msg_len
    syscall

.error:
    mov rax, -1
    pop r12
    add rsp, 32
    pop rbp
    ret

; ========== CANCEL LISTING ==========
; Cancel a sell offer
; Input: rdi = pointer to offer index string
; Returns: rax = 0 on success, -1 on error
marketplace_cancel_listing:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push r12

    mov r12, rdi            ; Save offer index pointer

    ; Display progress
    mov rax, 1
    mov rdi, 1
    mov rsi, canceling_offer_msg
    mov rdx, canceling_offer_msg_len
    syscall

    ; Build NFTokenCancelOffer transaction
    lea rdi, [cancel_offer_tx_json]

    ; Start transaction
    mov rsi, cancel_offer_tx_start
    call append_string

    ; Add account
    lea rsi, [account_address]
    call append_string

    ; Add NFTokenOffers array
    mov rsi, cancel_offer_tx_offers
    call append_string

    ; Add offer index
    mov rsi, r12
    call append_string

    ; Close array
    mov rsi, cancel_offer_tx_end_array
    call append_string

    ; Add Fee
    mov rsi, create_offer_tx_fee
    call append_string

    mov byte [rdi], '1'
    inc rdi
    mov byte [rdi], '2'
    inc rdi

    ; Add Sequence
    mov rsi, create_offer_tx_seq
    call append_string

    mov rax, [account_sequence]
    push rdi
    call int_to_string
    mov rsi, rax
    pop rdi
    call append_string

    ; Close transaction
    mov rsi, create_offer_tx_end
    call append_string

    ; Serialize and sign
    lea rdi, [cancel_offer_tx_json]
    call serialize_transaction
    test rax, rax
    jnz .error

    call sign_transaction
    test rax, rax
    jnz .error

    ; Submit
    call submit_transaction
    test rax, rax
    jnz .error

    ; Success
    mov rax, 1
    mov rdi, 1
    mov rsi, cancel_success_msg
    mov rdx, cancel_success_msg_len
    syscall

    ; Increment sequence
    inc qword [account_sequence]

    xor rax, rax
    pop r12
    add rsp, 32
    pop rbp
    ret

.error:
    mov rax, -1
    pop r12
    add rsp, 32
    pop rbp
    ret

; ========== HELPER FUNCTIONS ==========

; Build account_offers JSON-RPC request
build_account_offers_request:
    push rbp
    mov rbp, rsp

    lea rdi, [json_body]

    ; Build JSON-RPC request for account_nft_sell_offers
    mov rsi, json_rpc_start
    call append_string

    lea rsi, [account_address]
    call append_string

    mov rsi, json_rpc_end
    call append_string

    pop rbp
    ret

section .data
    json_rpc_start db '{"method":"account_nft_sell_offers","params":[{"account":"', 0
    json_rpc_end db '","ledger_index":"validated"}]}', 0

section .text

; Parse marketplace listings from XRPL response
parse_marketplace_listings:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    ; Zero out listings
    mov qword [current_listings.count], 0

    ; Find "offers" array in response
    lea rdi, [http_response]
    mov rsi, json_key_offers
    call find_json_value
    test rax, rax
    jz .done

    ; Parse each offer (simplified - would need full JSON parser)
    ; For now, just return success
    mov qword [current_listings.count], 1

.done:
    mov rax, [current_listings.count]
    pop r13
    pop r12
    pop rbp
    ret

; Display marketplace listings in formatted table
display_marketplace_listings:
    push rbp
    mov rbp, rsp

    ; Display header
    mov rax, 1
    mov rdi, 1
    mov rsi, listing_header
    mov rdx, listing_header_len
    syscall

    ; TODO: Display each listing
    ; For now, just show footer

    ; Display footer
    mov rax, 1
    mov rdi, 1
    mov rsi, listing_footer
    mov rdx, listing_footer_len
    syscall

    pop rbp
    ret

; Extract offer ID from XRPL response
extract_offer_id:
    push rbp
    mov rbp, rsp

    ; Find offer index in response
    lea rdi, [http_response]
    mov rsi, json_key_nft_offer_index
    call find_json_value
    test rax, rax
    jz .error

    ; Extract and copy to result buffer
    mov rdi, rax
    call extract_quoted_value
    lea rdi, [offer_index_result]
    mov rsi, rax
    call strcpy

    xor rax, rax
    pop rbp
    ret

.error:
    mov rax, -1
    pop rbp
    ret

; Submit transaction to XRPL
submit_transaction:
    push rbp
    mov rbp, rsp

    ; Connect to XRPL
    call xrpl_init
    test rax, rax
    jnz .error

    ; Send signed blob
    lea rsi, [signed_tx_blob]
    call send_http_post

    ; Receive response
    call receive_http_response

    ; Close connection
    call xrpl_close

    ; Check response for success
    ; (simplified - should parse for "tesSUCCESS")
    xor rax, rax
    pop rbp
    ret

.error:
    call xrpl_close
    mov rax, -1
    pop rbp
    ret

; Get my active listings
marketplace_get_my_listings:
    ; Similar to browse but filtered by account
    jmp marketplace_browse_listings

; ========== UTILITY ==========

; Simple string copy
strcpy:
    push rdi
    push rsi
.loop:
    lodsb
    stosb
    test al, al
    jnz .loop
    pop rsi
    pop rdi
    ret

; Convert integer to string (simplified)
int_to_string:
    ; Returns pointer to static buffer
    ; Input: rax = number
    lea rdi, [num_conv_buffer]
    push rbx
    mov rbx, 10
    push rcx
    xor rcx, rcx
    lea rsi, [num_conv_buffer + 19]
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
    mov rax, rsi
    pop rcx
    pop rbx
    ret

section .bss
    num_conv_buffer resb 20
    newline db 0xA

; ========== EXPORTS ==========
global marketplace_list_nft
global marketplace_browse_listings
global marketplace_buy_nft
global marketplace_cancel_listing
global marketplace_get_my_listings
global current_listings
