; QUIGZIMON XRPL Client - Pure Assembly HTTP/JSON-RPC Implementation
; Direct communication with XRP Ledger via sockets and HTTP

section .data
    ; ========== XRPL Configuration ==========
    xrpl_host db "s.altnet.rippletest.net", 0
    xrpl_host_len equ $ - xrpl_host - 1
    xrpl_port dw 51234  ; Testnet WebSocket/JSON-RPC port
    xrpl_port_http dw 51233  ; HTTP port

    ; Resolved IP (will be filled by DNS lookup)
    xrpl_ip dd 0

    ; ========== HTTP Templates ==========
    http_post_template db "POST / HTTP/1.1", 0xD, 0xA
                       db "Host: s.altnet.rippletest.net", 0xD, 0xA
                       db "Content-Type: application/json", 0xD, 0xA
                       db "Content-Length: ", 0
    http_post_template_len equ $ - http_post_template

    http_headers_end db 0xD, 0xA, 0xD, 0xA, 0
    http_newline db 0xD, 0xA, 0

    ; ========== JSON-RPC Templates ==========

    ; Account info request
    json_account_info_start db '{"method":"account_info","params":[{"account":"', 0
    json_account_info_end db '","ledger_index":"current"}]}', 0

    ; NFT info request
    json_account_nfts_start db '{"method":"account_nfts","params":[{"account":"', 0
    json_account_nfts_end db '","ledger_index":"validated"}]}', 0

    ; Submit transaction
    json_submit_start db '{"method":"submit","params":[{"tx_blob":"', 0
    json_submit_end db '"}]}', 0

    ; NFTokenMint transaction template
    nft_mint_tx_start db '{"TransactionType":"NFTokenMint","Account":"', 0
    nft_mint_tx_uri db '","URI":"', 0
    nft_mint_tx_flags db '","Flags":8,"TransferFee":0,"Fee":"12","Sequence":', 0
    nft_mint_tx_end db '}', 0

    ; NFTokenCreateOffer (Sell)
    nft_sell_offer_start db '{"TransactionType":"NFTokenCreateOffer","Account":"', 0
    nft_sell_offer_token db '","NFTokenID":"', 0
    nft_sell_offer_amount db '","Amount":"', 0
    nft_sell_offer_flags db '","Flags":1,"Fee":"12","Sequence":', 0
    nft_sell_offer_end db '}', 0

    ; NFTokenAcceptOffer (Buy)
    nft_accept_offer_start db '{"TransactionType":"NFTokenAcceptOffer","Account":"', 0
    nft_accept_offer_id db '","NFTokenSellOffer":"', 0
    nft_accept_offer_fee db '","Fee":"12","Sequence":', 0
    nft_accept_offer_end db '}', 0

    ; EscrowCreate (for PvP battles)
    escrow_create_start db '{"TransactionType":"EscrowCreate","Account":"', 0
    escrow_create_dest db '","Destination":"', 0
    escrow_create_amount db '","Amount":"', 0
    escrow_create_finish db '","FinishAfter":', 0
    escrow_create_cancel db ',"CancelAfter":', 0
    escrow_create_fee db ',"Fee":"12","Sequence":', 0
    escrow_create_end db '}', 0

    ; EscrowFinish
    escrow_finish_start db '{"TransactionType":"EscrowFinish","Account":"', 0
    escrow_finish_owner db '","Owner":"', 0
    escrow_finish_seq db '","OfferSequence":', 0
    escrow_finish_fee db ',"Fee":"12","Sequence":', 0
    escrow_finish_end db '}', 0

    ; Payment with Memo (for battle moves)
    payment_memo_start db '{"TransactionType":"Payment","Account":"', 0
    payment_memo_dest db '","Destination":"', 0
    payment_memo_amount db '","Amount":"1","Memos":[{"Memo":{"MemoType":"', 0
    payment_memo_data db '","MemoData":"', 0
    payment_memo_end db '"}}],"Fee":"12","Sequence":', 0
    payment_memo_close db '}', 0

    ; Battle memo type (QUIGBATTLE in hex)
    battle_memo_type db "51554947425554544C45", 0

    ; ========== JSON Parse Keys ==========
    json_key_result db '"result":', 0
    json_key_balance db '"Balance":"', 0
    json_key_sequence db '"Sequence":', 0
    json_key_nfts db '"account_nfts":[', 0
    json_key_token_id db '"NFTokenID":"', 0
    json_key_uri db '"URI":"', 0
    json_key_hash db '"hash":"', 0
    json_key_offers db '"offers":[', 0
    json_key_amount db '"Amount":"', 0
    json_key_owner db '"owner":"', 0

    ; ========== Messages ==========
    msg_connecting db "Connecting to XRPL...", 0xA, 0
    msg_connecting_len equ $ - msg_connecting

    msg_connected db "Connected to XRPL Testnet!", 0xA, 0
    msg_connected_len equ $ - msg_connected

    msg_connection_failed db "ERROR: Could not connect to XRPL!", 0xA, 0
    msg_connection_failed_len equ $ - msg_connection_failed

    msg_minting_nft db "Minting QUIGZIMON as NFT...", 0xA, 0
    msg_minting_nft_len equ $ - msg_minting_nft

    msg_nft_minted db "NFT Minted! Token ID: ", 0
    msg_nft_minted_len equ $ - msg_nft_minted

    msg_checking_balance db "Checking XRP balance...", 0xA, 0
    msg_checking_balance_len equ $ - msg_checking_balance

    msg_balance_display db "Balance: ", 0
    msg_balance_display_len equ $ - msg_balance_display

    msg_xrp_drops db " XRP", 0xA, 0
    msg_xrp_drops_len equ $ - msg_xrp_drops

section .bss
    ; ========== Network Buffers ==========
    http_request resb 4096      ; Outgoing HTTP request
    http_response resb 8192     ; Incoming HTTP response
    json_body resb 2048         ; JSON request body
    json_response resb 4096     ; Parsed JSON response

    ; ========== Socket Data ==========
    xrpl_socket resq 1
    sockaddr resb 16

    ; ========== Player Wallet ==========
    player_wallet:
        .address resb 64        ; rXXXXXXX... address
        .public_key resb 66     ; Hex-encoded public key
        .secret resb 64         ; Secret seed (sEd...)
        .sequence resq 1        ; Account sequence number
        .balance resq 1         ; XRP balance in drops

    ; ========== NFT Data ==========
    current_nft_token_id resb 128   ; Last minted/selected NFT
    nft_uri_buffer resb 512         ; IPFS URI or metadata

    ; Party NFT mappings
    party_nft_tokens resb 768       ; 6 QUIGZIMON * 128 bytes

    ; ========== Battle Data ==========
    battle_challenge_id resq 1
    battle_escrow_sequence resq 1
    opponent_address resb 64
    battle_wager_amount resq 1

    ; ========== Marketplace ==========
    marketplace_offers:
        .count resq 1
        .offers resb 5000       ; Up to 25 offers * 200 bytes

section .text

; ========== MAIN XRPL FUNCTIONS ==========

; Initialize XRPL connection
; Returns: rax = 0 on success, -1 on error
xrpl_init:
    push rbp
    mov rbp, rsp

    ; Display connecting message
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_connecting
    mov rdx, msg_connecting_len
    syscall

    ; Resolve hostname to IP
    call resolve_xrpl_hostname
    cmp rax, 0
    jl .error

    ; Create socket
    call create_tcp_socket
    cmp rax, 0
    jl .error

    ; Connect to XRPL server
    call connect_to_xrpl
    cmp rax, 0
    jl .error

    ; Display success
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_connected
    mov rdx, msg_connected_len
    syscall

    xor rax, rax
    pop rbp
    ret

.error:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_connection_failed
    mov rdx, msg_connection_failed_len
    syscall

    mov rax, -1
    pop rbp
    ret

; Close XRPL connection
xrpl_close:
    push rbp
    mov rbp, rsp

    mov rax, 3          ; sys_close
    mov rdi, [xrpl_socket]
    syscall

    pop rbp
    ret

; ========== SOCKET OPERATIONS ==========

; Create TCP socket
; Returns: rax = socket fd or -1 on error
create_tcp_socket:
    push rbp
    mov rbp, rsp

    mov rax, 41         ; sys_socket
    mov rdi, 2          ; AF_INET
    mov rsi, 1          ; SOCK_STREAM
    mov rdx, 0          ; protocol (auto)
    syscall

    ; Save socket
    mov [xrpl_socket], rax

    pop rbp
    ret

; Resolve hostname (simplified - hardcoded IP for now)
; In production, would use getaddrinfo syscall
resolve_xrpl_hostname:
    push rbp
    mov rbp, rsp

    ; For now, use hardcoded IP for s.altnet.rippletest.net
    ; Real implementation would do DNS lookup
    ; Testnet IP: 34.83.125.234 (example - check actual)

    ; Convert IP address: 34.83.125.234
    ; In network byte order (big-endian): 0x22537DEA
    mov dword [xrpl_ip], 0xEA7D5322  ; Little-endian representation

    xor rax, rax
    pop rbp
    ret

; Connect to XRPL server
; Returns: rax = 0 on success, -1 on error
connect_to_xrpl:
    push rbp
    mov rbp, rsp

    ; Setup sockaddr_in structure
    lea rdi, [sockaddr]

    ; sin_family = AF_INET (2)
    mov word [rdi], 2

    ; sin_port = 51233 (HTTP port in network byte order)
    ; 51233 = 0xC821, need to swap bytes
    mov ax, 51233
    xchg al, ah
    mov word [rdi + 2], ax

    ; sin_addr = resolved IP
    mov eax, [xrpl_ip]
    mov dword [rdi + 4], eax

    ; Zero out padding
    xor rax, rax
    mov qword [rdi + 8], rax

    ; Connect
    mov rax, 42         ; sys_connect
    mov rdi, [xrpl_socket]
    lea rsi, [sockaddr]
    mov rdx, 16         ; sizeof(sockaddr_in)
    syscall

    pop rbp
    ret

; ========== HTTP OPERATIONS ==========

; Send HTTP POST request
; Input: rsi = JSON body pointer, rdx = body length
; Returns: rax = bytes sent or -1 on error
send_http_post:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13

    mov r12, rsi        ; Save body pointer
    mov r13, rdx        ; Save body length

    ; Build HTTP request
    lea rdi, [http_request]

    ; Copy POST template
    mov rsi, http_post_template
    mov rcx, http_post_template_len
    rep movsb

    ; Add Content-Length value
    mov rax, r13
    call int_to_string
    ; Append to request (rdi already positioned)
    call append_string

    ; Add header ending
    mov rsi, http_headers_end
    call append_string

    ; Add JSON body
    mov rsi, r12
    mov rcx, r13
    rep movsb

    ; Calculate total request length
    lea rax, [http_request]
    sub rdi, rax
    mov rdx, rdi        ; Request length

    ; Send via socket
    mov rax, 1          ; sys_write
    mov rdi, [xrpl_socket]
    lea rsi, [http_request]
    syscall

    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Receive HTTP response
; Output: http_response buffer filled
; Returns: rax = bytes received or -1 on error
receive_http_response:
    push rbp
    mov rbp, rsp

    mov rax, 0          ; sys_read
    mov rdi, [xrpl_socket]
    lea rsi, [http_response]
    mov rdx, 8192
    syscall

    pop rbp
    ret

; ========== JSON BUILDING ==========

; Build account_info JSON request
; Input: rsi = account address
; Output: json_body filled
; Returns: rax = body length
build_account_info_json:
    push rbp
    mov rbp, rsp
    push r12

    mov r12, rsi        ; Save address

    lea rdi, [json_body]

    ; Add start
    mov rsi, json_account_info_start
    call strcpy_return_end

    ; Add account address
    mov rsi, r12
    call strcpy_return_end

    ; Add end
    mov rsi, json_account_info_end
    call strcpy_return_end

    ; Calculate length
    lea rax, [json_body]
    sub rdi, rax

    pop r12
    pop rbp
    ret

; Build account_nfts JSON request
build_account_nfts_json:
    push rbp
    mov rbp, rsp
    push r12

    mov r12, rsi

    lea rdi, [json_body]

    mov rsi, json_account_nfts_start
    call strcpy_return_end

    mov rsi, r12
    call strcpy_return_end

    mov rsi, json_account_nfts_end
    call strcpy_return_end

    lea rax, [json_body]
    sub rdi, rax

    pop r12
    pop rbp
    ret

; ========== JSON PARSING ==========

; Find JSON key in response
; Input: rsi = key string, rdi = response buffer
; Returns: rax = pointer to value start or 0 if not found
find_json_value:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx

    ; Simple string search
.search_loop:
    mov al, byte [rdi]
    cmp al, 0
    je .not_found

    mov bl, byte [rsi]
    cmp al, bl
    je .check_match

    inc rdi
    jmp .search_loop

.check_match:
    push rdi
    push rsi

.match_loop:
    inc rdi
    inc rsi
    mov al, byte [rsi]
    cmp al, 0
    je .found

    mov bl, byte [rdi]
    cmp al, bl
    jne .no_match

    jmp .match_loop

.found:
    pop rsi
    pop rax
    add rax, [rsi]      ; Length of key
    jmp .done

.no_match:
    pop rsi
    pop rdi
    inc rdi
    jmp .search_loop

.not_found:
    xor rax, rax

.done:
    pop rcx
    pop rbx
    pop rbp
    ret

; Extract quoted string value
; Input: rdi = pointer to opening quote
; Output: rsi = extracted string, rax = length
extract_quoted_value:
    push rbp
    mov rbp, rsp

    inc rdi             ; Skip opening quote
    mov rsi, rdi
    xor rcx, rcx

.find_close:
    mov al, byte [rdi]
    cmp al, '"'
    je .done
    inc rdi
    inc rcx
    jmp .find_close

.done:
    mov byte [rdi], 0   ; Null terminate
    mov rax, rcx

    pop rbp
    ret

; ========== WALLET OPERATIONS ==========

; Get account info (balance and sequence)
; Returns: rax = 0 on success
xrpl_get_account_info:
    push rbp
    mov rbp, rsp

    ; Build JSON request
    lea rsi, [player_wallet.address]
    call build_account_info_json
    mov rdx, rax        ; Body length

    ; Send HTTP POST
    lea rsi, [json_body]
    call send_http_post

    ; Receive response
    call receive_http_response

    ; Parse balance
    lea rdi, [http_response]
    mov rsi, json_key_balance
    call find_json_value
    cmp rax, 0
    je .error

    ; Extract balance value
    mov rdi, rax
    call extract_quoted_value

    ; Convert to integer
    mov rdi, rsi
    call string_to_int
    mov [player_wallet.balance], rax

    ; Parse sequence
    lea rdi, [http_response]
    mov rsi, json_key_sequence
    call find_json_value
    cmp rax, 0
    je .error

    ; Extract sequence
    call string_to_int
    mov [player_wallet.sequence], rax

    xor rax, rax
    pop rbp
    ret

.error:
    mov rax, -1
    pop rbp
    ret

; Display XRP balance
xrpl_display_balance:
    push rbp
    mov rbp, rsp

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_balance_display
    mov rdx, msg_balance_display_len
    syscall

    ; Convert drops to XRP (divide by 1,000,000)
    mov rax, [player_wallet.balance]
    mov rbx, 1000000
    xor rdx, rdx
    div rbx

    ; Display XRP amount
    call print_number

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_xrp_drops
    mov rdx, msg_xrp_drops_len
    syscall

    pop rbp
    ret

; ========== UTILITY FUNCTIONS ==========

; String copy with end pointer return
; Input: rsi = source, rdi = dest
; Output: rdi = pointer to dest end
strcpy_return_end:
    push rax
.loop:
    lodsb
    stosb
    test al, al
    jnz .loop
    dec rdi             ; Back up over null terminator
    pop rax
    ret

; Append string
; Input: rsi = source, rdi = dest (will be updated)
append_string:
    push rax
.loop:
    lodsb
    test al, al
    jz .done
    stosb
    jmp .loop
.done:
    pop rax
    ret

; Convert integer to string
; Input: rax = number
; Output: num_buffer contains string, rax = string pointer
int_to_string:
    push rbx
    push rcx
    push rdx

    mov rbx, 10
    xor rcx, rcx
    lea rdi, [num_buffer + 19]
    mov byte [rdi], 0

.convert:
    dec rdi
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rdi], dl
    inc rcx
    test rax, rax
    jnz .convert

    mov rax, rdi

    pop rdx
    pop rcx
    pop rbx
    ret

; Convert string to integer
; Input: rdi = string pointer
; Output: rax = integer value
string_to_int:
    push rbx
    push rcx

    xor rax, rax
    xor rcx, rcx
    mov rbx, 10

.convert:
    movzx rcx, byte [rdi]
    cmp rcx, '0'
    jb .done
    cmp rcx, '9'
    ja .done

    sub rcx, '0'
    imul rax, rbx
    add rax, rcx
    inc rdi
    jmp .convert

.done:
    pop rcx
    pop rbx
    ret

; Print number (from main game)
print_number:
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

; ========== EXPORTS ==========
global xrpl_init
global xrpl_close
global xrpl_get_account_info
global xrpl_display_balance
global create_tcp_socket
global send_http_post
global receive_http_response
