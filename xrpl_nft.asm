; QUIGZIMON XRPL NFT Module - NFT Minting and Trading
; Pure assembly implementation of XRPL NFToken operations

section .data
    ; ========== NFT Metadata Template ==========
    nft_metadata_start db '{"name":"', 0
    nft_metadata_species db '","description":"A ', 0
    nft_metadata_type db ' type QUIGZIMON","image":"ipfs://Qm', 0
    nft_metadata_attrs db '","attributes":[', 0
    nft_metadata_trait_start db '{"trait_type":"', 0
    nft_metadata_trait_value db '","value":', 0
    nft_metadata_trait_end db '},', 0
    nft_metadata_end db ']}', 0

    ; Attribute names
    attr_species db "Species", 0
    attr_type db "Type", 0
    attr_level db "Level", 0
    attr_hp db "HP", 0
    attr_attack db "Attack", 0
    attr_defense db "Defense", 0
    attr_speed db "Speed", 0
    attr_move1 db "Move 1", 0
    attr_move2 db "Move 2", 0
    attr_exp db "Experience", 0
    attr_status db "Status", 0
    attr_trainer db "Original Trainer", 0

    ; Type names (from main game)
    type_name_fire db "Fire", 0
    type_name_water db "Water", 0
    type_name_grass db "Grass", 0
    type_name_normal db "Normal", 0

    ; Status names
    status_healthy db "Healthy", 0
    status_poisoned db "Poisoned", 0
    status_asleep db "Asleep", 0
    status_paralyzed db "Paralyzed", 0

    ; ========== NFT Messages ==========
    msg_generating_metadata db "Generating NFT metadata...", 0xA, 0
    msg_generating_metadata_len equ $ - msg_generating_metadata

    msg_uploading_ipfs db "Uploading to IPFS...", 0xA, 0
    msg_uploading_ipfs_len equ $ - msg_uploading_ipfs

    msg_minting_nft db "Minting NFT on XRPL...", 0xA, 0
    msg_minting_nft_len equ $ - msg_minting_nft

    msg_nft_success db "Success! QUIGZIMON is now an NFT!", 0xA, 0
    msg_nft_success_len equ $ - msg_nft_success

    msg_nft_token_id db "NFT Token ID: ", 0
    msg_nft_token_id_len equ $ - msg_nft_token_id

    msg_listing_for_sale db "Creating marketplace listing...", 0xA, 0
    msg_listing_for_sale_len equ $ - msg_listing_for_sale

    msg_listed_success db "Listed for sale!", 0xA, 0
    msg_listed_success_len equ $ - msg_listed_success

    msg_buying_nft db "Purchasing QUIGZIMON...", 0xA, 0
    msg_buying_nft_len equ $ - msg_buying_nft

    msg_purchase_success db "Purchase complete! QUIGZIMON added to party!", 0xA, 0
    msg_purchase_success_len equ $ - msg_purchase_success

section .bss
    ; ========== NFT Metadata Buffer ==========
    nft_metadata_json resb 2048
    nft_metadata_len resq 1

    ; ========== IPFS Data ==========
    ipfs_cid resb 128           ; CID hash
    ipfs_uri resb 256           ; Full IPFS URI

    ; ========== Minting Data ==========
    nft_mint_tx_json resb 1024
    nft_mint_signed_blob resb 2048
    nft_token_id resb 128

    ; ========== Offer Data ==========
    nft_offer_id resb 128
    nft_sell_price resq 1

    ; ========== Marketplace ==========
    marketplace_listings:
        .count resq 1
        .items resb 10000       ; 50 listings * 200 bytes each

    current_listing:
        .token_id resb 128
        .owner resb 64
        .price resq 1
        .species resb 1
        .level resb 1
        .hp resw 1
        .attack resw 1
        .defense resw 1

section .text

; ========== NFT MINTING ==========

; Mint QUIGZIMON as NFT
; Input: rdi = pointer to QUIGZIMON instance (15 bytes)
; Returns: rax = 0 on success, -1 on error
mint_quigzimon_nft:
    push rbp
    mov rbp, rsp
    push r12

    mov r12, rdi        ; Save QUIGZIMON pointer

    ; Display progress
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_generating_metadata
    mov rdx, msg_generating_metadata_len
    syscall

    ; Generate metadata JSON
    mov rdi, r12
    call generate_nft_metadata
    cmp rax, 0
    jl .error

    ; Upload to IPFS (simplified - could use local metadata)
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_uploading_ipfs
    mov rdx, msg_uploading_ipfs_len
    syscall

    call upload_metadata_to_ipfs
    ; For now, use placeholder IPFS CID

    ; Create NFTokenMint transaction
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_minting_nft
    mov rdx, msg_minting_nft_len
    syscall

    call create_nft_mint_transaction
    cmp rax, 0
    jl .error

    ; Sign transaction
    call sign_nft_transaction
    cmp rax, 0
    jl .error

    ; Submit to XRPL
    call submit_nft_mint
    cmp rax, 0
    jl .error

    ; Parse response for TokenID
    call extract_token_id_from_response

    ; Store TokenID in QUIGZIMON data
    ; (Assume offset for NFT ID in enhanced structure)

    ; Display success
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_nft_success
    mov rdx, msg_nft_success_len
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_nft_token_id
    mov rdx, msg_nft_token_id_len
    syscall

    lea rsi, [nft_token_id]
    call print_string

    xor rax, rax
    pop r12
    pop rbp
    ret

.error:
    mov rax, -1
    pop r12
    pop rbp
    ret

; Generate NFT metadata JSON from QUIGZIMON
; Input: rdi = QUIGZIMON instance pointer
; Returns: rax = metadata length
generate_nft_metadata:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov r12, rdi        ; Save QUIGZIMON pointer

    ; Start building JSON
    lea r13, [nft_metadata_json]
    mov rdi, r13

    ; {"name":"QUIGFLAME #1234"
    mov rsi, nft_metadata_start
    call append_string

    ; Get species name
    movzx rbx, byte [r12]       ; Species ID
    imul rbx, 33                 ; Species data size
    lea rcx, [quigzimon_db]
    add rcx, rbx
    mov rsi, [rcx]              ; Name pointer
    call append_string

    ; Add #ID (could be based on total caught)
    mov al, ' '
    stosb
    mov al, '#'
    stosb

    ; Get caught number (simplified)
    movzx rax, byte [total_caught]
    push rdi
    call int_to_string
    mov rsi, rax
    pop rdi
    call append_string

    ; ,"description":"A Fire type QUIGZIMON"
    mov rsi, nft_metadata_species
    call append_string

    ; Get type name
    movzx rbx, byte [r12]
    imul rbx, 33
    lea rcx, [quigzimon_db]
    add rcx, rbx
    movzx rbx, byte [rcx + 8]    ; Type

    ; Map type to name
    cmp rbx, 0
    je .type_fire
    cmp rbx, 1
    je .type_water
    cmp rbx, 2
    je .type_grass
    jmp .type_normal

.type_fire:
    mov rsi, type_name_fire
    jmp .add_type

.type_water:
    mov rsi, type_name_water
    jmp .add_type

.type_grass:
    mov rsi, type_name_grass
    jmp .add_type

.type_normal:
    mov rsi, type_name_normal

.add_type:
    call append_string

    ; ,"image":"ipfs://Qm..."
    mov rsi, nft_metadata_type
    call append_string

    ; Add placeholder IPFS CID
    mov rsi, ipfs_cid
    call append_string

    ; ,"attributes":[
    mov rsi, nft_metadata_attrs
    call append_string

    ; Add all attributes
    ; Species
    mov rsi, attr_species
    mov rdx, r12
    call add_nft_attribute_string

    ; Type
    mov rsi, attr_type
    cmp rbx, 0
    je .attr_type_fire
    cmp rbx, 1
    je .attr_type_water
    cmp rbx, 2
    je .attr_type_grass
    mov rdx, type_name_normal
    jmp .add_type_attr

.attr_type_fire:
    mov rdx, type_name_fire
    jmp .add_type_attr

.attr_type_water:
    mov rdx, type_name_water
    jmp .add_type_attr

.attr_type_grass:
    mov rdx, type_name_grass

.add_type_attr:
    call add_nft_attribute_string

    ; Level (numeric)
    mov rsi, attr_level
    movzx rdx, byte [r12 + 1]
    call add_nft_attribute_number

    ; HP
    mov rsi, attr_hp
    movzx rdx, word [r12 + 4]    ; Max HP
    call add_nft_attribute_number

    ; Attack
    mov rsi, attr_attack
    movzx rdx, word [r12 + 9]
    call add_nft_attribute_number

    ; Defense
    mov rsi, attr_defense
    movzx rdx, word [r12 + 11]
    call add_nft_attribute_number

    ; Speed
    mov rsi, attr_speed
    movzx rdx, word [r12 + 13]
    call add_nft_attribute_number

    ; EXP
    mov rsi, attr_exp
    movzx rdx, word [r12 + 6]
    call add_nft_attribute_number

    ; Status
    mov rsi, attr_status
    movzx rbx, byte [r12 + 8]
    cmp rbx, 0
    je .status_healthy
    cmp rbx, 1
    je .status_poison
    cmp rbx, 2
    je .status_sleep
    mov rdx, status_paralyzed
    jmp .add_status

.status_healthy:
    mov rdx, status_healthy
    jmp .add_status

.status_poison:
    mov rdx, status_poisoned
    jmp .add_status

.status_sleep:
    mov rdx, status_asleep

.add_status:
    call add_nft_attribute_string

    ; Original Trainer
    mov rsi, attr_trainer
    lea rdx, [player_wallet.address]
    call add_nft_attribute_string_final  ; Last attribute (no comma)

    ; Close attributes array and object
    mov rsi, nft_metadata_end
    call append_string

    ; Calculate total length
    sub rdi, r13
    mov rax, rdi
    mov [nft_metadata_len], rax

    pop r13
    pop r12
    pop rbp
    ret

; Add NFT attribute (string value)
; Input: rsi = attribute name, rdx = value, rdi = buffer position
add_nft_attribute_string:
    push rax

    ; {"trait_type":"
    push rsi
    push rdx
    mov rsi, nft_metadata_trait_start
    call append_string
    pop rdx
    pop rsi

    ; Attribute name
    push rdx
    call append_string
    pop rdx

    ; ","value":"
    push rdx
    mov rsi, nft_metadata_trait_value
    call append_string
    mov al, '"'
    stosb
    pop rdx

    ; Value
    mov rsi, rdx
    call append_string

    ; "},
    mov al, '"'
    stosb
    mov rsi, nft_metadata_trait_end
    call append_string

    pop rax
    ret

; Add NFT attribute (numeric value)
add_nft_attribute_number:
    push rax
    push rdx

    ; {"trait_type":"
    push rsi
    mov rsi, nft_metadata_trait_start
    call append_string
    pop rsi

    ; Attribute name
    call append_string

    ; ","value":
    mov rsi, nft_metadata_trait_value
    call append_string

    ; Numeric value
    pop rax
    push rdi
    call int_to_string
    mov rsi, rax
    pop rdi
    call append_string

    ; },
    mov rsi, nft_metadata_trait_end
    call append_string

    pop rax
    ret

; Add final NFT attribute (no trailing comma)
add_nft_attribute_string_final:
    push rax

    ; Same as regular but without comma at end
    push rsi
    push rdx
    mov rsi, nft_metadata_trait_start
    call append_string
    pop rdx
    pop rsi

    push rdx
    call append_string
    pop rdx

    push rdx
    mov rsi, nft_metadata_trait_value
    call append_string
    mov al, '"'
    stosb
    pop rdx

    mov rsi, rdx
    call append_string

    ; "}  (no comma)
    mov al, '"'
    stosb
    mov al, '}'
    stosb

    pop rax
    ret

; Upload metadata to IPFS (simplified - uses placeholder)
upload_metadata_to_ipfs:
    push rbp
    mov rbp, rsp

    ; For now, generate a fake CID based on QUIGZIMON ID
    ; Real implementation would POST to IPFS node
    lea rdi, [ipfs_cid]
    mov rsi, fake_ipfs_cid
    call strcpy

    pop rbp
    ret

section .data
    fake_ipfs_cid db "QmYourMetadataHashHere", 0

section .text

; Create NFTokenMint transaction JSON
create_nft_mint_transaction:
    push rbp
    mov rbp, rsp

    lea rdi, [nft_mint_tx_json]

    ; Build transaction
    mov rsi, nft_mint_tx_start
    call append_string

    ; Account
    lea rsi, [player_wallet.address]
    call append_string

    ; URI
    mov rsi, nft_mint_tx_uri
    call append_string

    ; Convert metadata to hex
    lea rsi, [ipfs_uri]
    call string_to_hex
    call append_string

    ; Flags and fee
    mov rsi, nft_mint_tx_flags
    call append_string

    ; Sequence number
    mov rax, [player_wallet.sequence]
    push rdi
    call int_to_string
    mov rsi, rax
    pop rdi
    call append_string

    ; Close transaction
    mov rsi, nft_mint_tx_end
    call append_string

    xor rax, rax
    pop rbp
    ret

; Sign NFT transaction (simplified - needs crypto implementation)
sign_nft_transaction:
    push rbp
    mov rbp, rsp

    ; This would normally:
    ; 1. Serialize transaction to canonical form
    ; 2. Hash with SHA-512Half
    ; 3. Sign with Ed25519 using private key
    ; 4. Encode signature
    ; 5. Build signed blob

    ; For now, placeholder
    xor rax, rax

    pop rbp
    ret

; Submit NFT mint to XRPL
submit_nft_mint:
    push rbp
    mov rbp, rsp

    ; Build submit request
    lea rdi, [json_body]

    mov rsi, json_submit_start
    call append_string

    ; Add signed blob
    lea rsi, [nft_mint_signed_blob]
    call append_string

    mov rsi, json_submit_end
    call append_string

    ; Calculate length
    lea rax, [json_body]
    sub rdi, rax
    mov rdx, rdi

    ; Send to XRPL
    lea rsi, [json_body]
    call send_http_post

    ; Receive response
    call receive_http_response

    xor rax, rax
    pop rbp
    ret

; Extract TokenID from mint response
extract_token_id_from_response:
    push rbp
    mov rbp, rsp

    ; Parse JSON for NFTokenID field
    lea rdi, [http_response]
    mov rsi, json_key_token_id
    call find_json_value

    cmp rax, 0
    je .error

    ; Extract the token ID
    mov rdi, rax
    call extract_quoted_value

    ; Copy to nft_token_id buffer
    lea rdi, [nft_token_id]
    mov rcx, rax
    rep movsb

    xor rax, rax
    pop rbp
    ret

.error:
    mov rax, -1
    pop rbp
    ret

; ========== UTILITY ==========

; Convert string to hex encoding
; Input: rsi = string
; Output: hex_buffer filled
string_to_hex:
    push rbp
    mov rbp, rsp
    push rbx

    lea rdi, [hex_buffer]

.loop:
    lodsb
    test al, al
    jz .done

    ; High nibble
    mov bl, al
    shr bl, 4
    cmp bl, 10
    jl .high_digit
    add bl, 'A' - 10
    jmp .high_store

.high_digit:
    add bl, '0'

.high_store:
    mov [rdi], bl
    inc rdi

    ; Low nibble
    mov bl, al
    and bl, 0x0F
    cmp bl, 10
    jl .low_digit
    add bl, 'A' - 10
    jmp .low_store

.low_digit:
    add bl, '0'

.low_store:
    mov [rdi], bl
    inc rdi

    jmp .loop

.done:
    mov byte [rdi], 0

    pop rbx
    pop rbp
    ret

section .bss
    hex_buffer resb 1024

; ========== EXPORTS ==========
global mint_quigzimon_nft
global generate_nft_metadata
global upload_metadata_to_ipfs
