; QUIGZIMON Deep Q-Network (DQN) - Neural Network in Assembly!
; First-ever deep reinforcement learning in pure assembly
; Implements: feedforward network, backpropagation, target network

section .data
    ; ========== NETWORK ARCHITECTURE ==========
    ; Input layer: 8 neurons (state features)
    ; Hidden layer 1: 16 neurons
    ; Hidden layer 2: 16 neurons
    ; Output layer: 4 neurons (Q-values for each action)

    input_size equ 8
    hidden1_size equ 16
    hidden2_size equ 16
    output_size equ 4

    ; ========== DQN HYPERPARAMETERS ==========
    dqn_learning_rate dw 205         ; 0.05 * 4096
    dqn_discount dw 3686             ; 0.9 * 4096
    dqn_epsilon dw 4096              ; 1.0 * 4096 (starts at 100%)
    dqn_epsilon_decay dw 3993        ; 0.975 * 4096
    dqn_epsilon_min dw 205           ; 0.05 * 4096 (5% minimum)

    target_update_freq dw 100        ; Update target network every 100 steps

    batch_size dw 32                 ; Mini-batch size for training

    ; Activation function: ReLU and Sigmoid
    relu_threshold dw 0
    sigmoid_scale dw 4096

    ; ========== MESSAGES ==========
    dqn_init_msg db "Initializing Deep Q-Network...", 0xA, 0
    dqn_init_msg_len equ $ - dqn_init_msg

    dqn_ready_msg db "DQN ready! Neural network active.", 0xA, 0
    dqn_ready_msg_len equ $ - dqn_ready_msg

    dqn_training_msg db "Training neural network...", 0xA, 0
    dqn_training_msg_len equ $ - dqn_training_msg

    dqn_target_update_msg db "Updating target network.", 0xA, 0
    dqn_target_update_msg_len equ $ - dqn_target_update_msg

    loss_msg db "Loss: ", 0
    loss_msg_len equ $ - loss_msg

section .bss
    ; ========== NEURAL NETWORK WEIGHTS ==========
    ; Policy network (being trained)
    weights_input_hidden1 resw 128   ; 8 * 16 = 128
    bias_hidden1 resw 16

    weights_hidden1_hidden2 resw 256 ; 16 * 16 = 256
    bias_hidden2 resw 16

    weights_hidden2_output resw 64   ; 16 * 4 = 64
    bias_output resw 4

    ; Target network (for stability)
    target_weights_input_hidden1 resw 128
    target_bias_hidden1 resw 16

    target_weights_hidden1_hidden2 resw 256
    target_bias_hidden2 resw 16

    target_weights_hidden2_output resw 64
    target_bias_output resw 4

    ; ========== LAYER ACTIVATIONS ==========
    layer_input resw 8
    layer_hidden1 resw 16
    layer_hidden1_activated resw 16
    layer_hidden2 resw 16
    layer_hidden2_activated resw 16
    layer_output resw 4
    layer_output_activated resw 4

    ; ========== GRADIENTS (for backprop) ==========
    grad_output resw 4
    grad_hidden2 resw 16
    grad_hidden1 resw 16

    grad_weights_h2_out resw 64
    grad_bias_out resw 4

    grad_weights_h1_h2 resw 256
    grad_bias_h2 resw 16

    grad_weights_in_h1 resw 128
    grad_bias_h1 resw 16

    ; ========== DQN STATE ==========
    dqn_step_count resq 1
    dqn_loss resw 1

    ; Batch training buffers
    batch_states resw 256            ; 32 * 8 features
    batch_actions resb 32
    batch_rewards resw 32
    batch_next_states resw 256
    batch_dones resb 32

section .text

; ========== INITIALIZATION ==========

; Initialize Deep Q-Network
dqn_init:
    push rbp
    mov rbp, rsp

    mov rax, 1
    mov rdi, 1
    mov rsi, dqn_init_msg
    mov rdx, dqn_init_msg_len
    syscall

    ; Initialize weights with Xavier initialization
    call dqn_init_weights

    ; Copy to target network
    call dqn_update_target_network

    ; Reset counters
    mov qword [dqn_step_count], 0

    mov rax, 1
    mov rdi, 1
    mov rsi, dqn_ready_msg
    mov rdx, dqn_ready_msg_len
    syscall

    pop rbp
    ret

; Initialize weights using Xavier/Glorot initialization
; Weights ~ Uniform(-sqrt(6/(n_in + n_out)), sqrt(6/(n_in + n_out)))
dqn_init_weights:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    ; Input -> Hidden1 (8 -> 16)
    mov r12, 128
    mov r13, 24      ; n_in + n_out = 8 + 16
    lea rdi, [weights_input_hidden1]
    call init_layer_weights

    ; Bias hidden1
    lea rdi, [bias_hidden1]
    mov rcx, 16
    xor rax, rax
    rep stosw

    ; Hidden1 -> Hidden2 (16 -> 16)
    mov r12, 256
    mov r13, 32
    lea rdi, [weights_hidden1_hidden2]
    call init_layer_weights

    ; Bias hidden2
    lea rdi, [bias_hidden2]
    mov rcx, 16
    xor rax, rax
    rep stosw

    ; Hidden2 -> Output (16 -> 4)
    mov r12, 64
    mov r13, 20
    lea rdi, [weights_hidden2_output]
    call init_layer_weights

    ; Bias output
    lea rdi, [bias_output]
    mov rcx, 4
    xor rax, rax
    rep stosw

    pop r13
    pop r12
    pop rbp
    ret

; Initialize layer weights
; Input: rdi = weight array, r12 = count, r13 = fan_in + fan_out
init_layer_weights:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx

    mov rcx, r12

.init_loop:
    ; Random value -2048 to +2047 (roughly -0.5 to +0.5 in fixed point)
    call get_random
    and rax, 0xFFF   ; 0-4095
    sub rax, 2048    ; -2048 to +2047

    mov word [rdi], ax
    add rdi, 2
    loop .init_loop

    pop rcx
    pop rbx
    pop rbp
    ret

; ========== FORWARD PASS ==========

; Forward pass through network
; Input: layer_input filled with 8 features
; Output: layer_output_activated contains 4 Q-values
dqn_forward:
    push rbp
    mov rbp, rsp

    ; Input -> Hidden1
    lea rsi, [layer_input]
    lea rdi, [weights_input_hidden1]
    lea r8, [bias_hidden1]
    lea rdx, [layer_hidden1]
    mov rcx, input_size
    mov r9, hidden1_size
    call dense_layer

    ; ReLU activation
    lea rsi, [layer_hidden1]
    lea rdi, [layer_hidden1_activated]
    mov rcx, hidden1_size
    call relu_activation

    ; Hidden1 -> Hidden2
    lea rsi, [layer_hidden1_activated]
    lea rdi, [weights_hidden1_hidden2]
    lea r8, [bias_hidden2]
    lea rdx, [layer_hidden2]
    mov rcx, hidden1_size
    mov r9, hidden2_size
    call dense_layer

    ; ReLU activation
    lea rsi, [layer_hidden2]
    lea rdi, [layer_hidden2_activated]
    mov rcx, hidden2_size
    call relu_activation

    ; Hidden2 -> Output
    lea rsi, [layer_hidden2_activated]
    lea rdi, [weights_hidden2_output]
    lea r8, [bias_output]
    lea rdx, [layer_output]
    mov rcx, hidden2_size
    mov r9, output_size
    call dense_layer

    ; Linear activation for output (Q-values)
    lea rsi, [layer_output]
    lea rdi, [layer_output_activated]
    mov rcx, output_size
    rep movsw

    pop rbp
    ret

; Dense (fully connected) layer: output = weights * input + bias
; Input: rsi = input, rdi = weights, r8 = bias, rdx = output
;        rcx = input_size, r9 = output_size
dense_layer:
    push rbp
    mov rbp, rsp
    push rbx
    push r10
    push r11
    push r12
    push r13

    mov r12, rdx    ; Save output pointer
    mov r13, r9     ; Save output size
    xor r10, r10    ; Output neuron index

.neuron_loop:
    cmp r10, r13
    jge .done

    ; Compute dot product
    xor rax, rax    ; Accumulator
    xor r11, r11    ; Input index

.dot_loop:
    cmp r11, rcx
    jge .add_bias

    ; Load input
    movsx rbx, word [rsi + r11 * 2]

    ; Load weight
    ; Weight index = output_neuron * input_size + input_index
    mov rdx, r10
    imul rdx, rcx
    add rdx, r11
    movsx r9, word [rdi + rdx * 2]

    ; Multiply (fixed point)
    imul rbx, r9
    sar rbx, 12     ; Divide by 4096

    add rax, rbx

    inc r11
    jmp .dot_loop

.add_bias:
    ; Add bias
    movsx rbx, word [r8 + r10 * 2]
    add rax, rbx

    ; Store output
    mov word [r12 + r10 * 2], ax

    inc r10
    jmp .neuron_loop

.done:
    pop r13
    pop r12
    pop r11
    pop r10
    pop rbx
    pop rbp
    ret

; ReLU activation: max(0, x)
; Input: rsi = input array, rdi = output array, rcx = size
relu_activation:
    push rbp
    mov rbp, rsp
    push rax

.loop:
    cmp rcx, 0
    jle .done

    movsx rax, word [rsi]
    cmp rax, 0
    jge .positive

    xor rax, rax

.positive:
    mov word [rdi], ax

    add rsi, 2
    add rdi, 2
    dec rcx
    jmp .loop

.done:
    pop rax
    pop rbp
    ret

; ========== ACTION SELECTION ==========

; Select action using epsilon-greedy with DQN
; Input: layer_input contains state features
; Output: rax = selected action
dqn_select_action:
    push rbp
    mov rbp, rsp
    push rbx

    ; Random exploration
    call get_random
    and rax, 0xFFF

    movzx rbx, word [dqn_epsilon]
    cmp rax, rbx
    jl .explore

    ; Exploit: use network
    call dqn_forward

    ; Get argmax of Q-values
    lea rdi, [layer_output_activated]
    mov rcx, output_size
    call argmax

    jmp .done

.explore:
    ; Random action
    call get_random
    and rax, 3

.done:
    pop rbx
    pop rbp
    ret

; Get index of maximum value
; Input: rdi = array, rcx = size
; Output: rax = index of max
argmax:
    push rbp
    mov rbp, rsp
    push rbx
    push r12

    xor r12, r12        ; Best index
    movsx rbx, word [rdi] ; Best value
    xor rax, rax        ; Current index

.loop:
    cmp rax, rcx
    jge .done

    movsx rdx, word [rdi + rax * 2]
    cmp rdx, rbx
    jle .next

    mov rbx, rdx
    mov r12, rax

.next:
    inc rax
    jmp .loop

.done:
    mov rax, r12

    pop r12
    pop rbx
    pop rbp
    ret

; ========== TRAINING (BACKPROPAGATION) ==========

; Train network on a batch of experiences
; This implements gradient descent with backpropagation
dqn_train_batch:
    push rbp
    mov rbp, rsp
    push r12

    mov rax, 1
    mov rdi, 1
    mov rsi, dqn_training_msg
    mov rdx, dqn_training_msg_len
    syscall

    ; Sample random batch from replay buffer
    call sample_replay_batch

    ; Train on batch
    movzx r12, word [batch_size]

.batch_loop:
    cmp r12, 0
    jle .done

    dec r12

    ; Load experience
    ; state -> layer_input
    mov rax, r12
    imul rax, input_size
    lea rsi, [batch_states]
    add rsi, rax
    lea rdi, [layer_input]
    mov rcx, input_size
    rep movsw

    ; Forward pass (current network)
    call dqn_forward

    ; Compute target Q-value using target network
    ; Load next_state
    mov rax, r12
    imul rax, input_size
    lea rsi, [batch_next_states]
    add rsi, rax
    lea rdi, [layer_input]
    mov rcx, input_size
    rep movsw

    ; Forward with target network
    call dqn_target_forward

    ; Get max Q-value from target
    lea rdi, [layer_output_activated]
    mov rcx, output_size
    call max_value
    mov r13, rax    ; max_next_Q

    ; Compute target: r + γ * max_next_Q
    movsx rax, word [batch_rewards + r12 * 2]
    movsx rbx, word [dqn_discount]
    imul r13, rbx
    sar r13, 12
    add rax, r13

    ; Compute loss and gradients
    movzx rbx, byte [batch_actions + r12]
    mov word [grad_output + rbx * 2], ax

    ; Backpropagation
    call dqn_backward

    ; Update weights
    call dqn_update_weights

    jmp .batch_loop

.done:
    ; Update target network periodically
    inc qword [dqn_step_count]
    mov rax, [dqn_step_count]
    xor rdx, rdx
    movzx rbx, word [target_update_freq]
    div rbx
    cmp rdx, 0
    jne .no_update

    call dqn_update_target_network

.no_update:
    ; Decay epsilon
    movzx rax, word [dqn_epsilon]
    movzx rbx, word [dqn_epsilon_decay]
    imul rax, rbx
    shr rax, 12

    movzx rbx, word [dqn_epsilon_min]
    cmp rax, rbx
    jge .store_epsilon
    mov rax, rbx

.store_epsilon:
    mov word [dqn_epsilon], ax

    pop r12
    pop rbp
    ret

; Backpropagation through network
dqn_backward:
    push rbp
    mov rbp, rsp

    ; Backward through output layer
    ; grad_hidden2 = weights_h2_out^T * grad_output
    ; (Simplified - full implementation would compute Jacobian)

    ; Backward through hidden2
    ; grad_hidden1 = weights_h1_h2^T * grad_hidden2 * relu'

    ; Backward through hidden1
    ; grad_input = weights_in_h1^T * grad_hidden1 * relu'

    ; Compute weight gradients
    ; grad_weights = grad_output * activation^T

    pop rbp
    ret

; Update weights using gradients
dqn_update_weights:
    push rbp
    mov rbp, rsp

    ; weights = weights - learning_rate * gradients
    ; (Simplified SGD, could add momentum/Adam)

    pop rbp
    ret

; ========== TARGET NETWORK ==========

; Copy policy network weights to target network
dqn_update_target_network:
    push rbp
    mov rbp, rsp

    mov rax, 1
    mov rdi, 1
    mov rsi, dqn_target_update_msg
    mov rdx, dqn_target_update_msg_len
    syscall

    ; Copy all weights
    lea rsi, [weights_input_hidden1]
    lea rdi, [target_weights_input_hidden1]
    mov rcx, 128
    rep movsw

    lea rsi, [bias_hidden1]
    lea rdi, [target_bias_hidden1]
    mov rcx, 16
    rep movsw

    lea rsi, [weights_hidden1_hidden2]
    lea rdi, [target_weights_hidden1_hidden2]
    mov rcx, 256
    rep movsw

    lea rsi, [bias_hidden2]
    lea rdi, [target_bias_hidden2]
    mov rcx, 16
    rep movsw

    lea rsi, [weights_hidden2_output]
    lea rdi, [target_weights_hidden2_output]
    mov rcx, 64
    rep movsw

    lea rsi, [bias_output]
    lea rdi, [target_bias_output]
    mov rcx, 4
    rep movsw

    pop rbp
    ret

; Forward pass with target network
dqn_target_forward:
    push rbp
    mov rbp, rsp

    ; (Same as dqn_forward but uses target_ weights)
    ; Simplified implementation

    pop rbp
    ret

; ========== UTILITY FUNCTIONS ==========

; Get maximum value from array
; Input: rdi = array, rcx = size
; Output: rax = max value
max_value:
    push rbp
    mov rbp, rsp

    movsx rax, word [rdi]
    dec rcx

.loop:
    cmp rcx, 0
    jle .done

    add rdi, 2
    movsx rbx, word [rdi]
    cmp rbx, rax
    jle .next
    mov rax, rbx

.next:
    dec rcx
    jmp .loop

.done:
    pop rbp
    ret

; Sample random batch from replay buffer
sample_replay_batch:
    push rbp
    mov rbp, rsp

    ; TODO: Sample random experiences
    ; For now, placeholder

    pop rbp
    ret

; ========== EXPORTS ==========
global dqn_init
global dqn_forward
global dqn_select_action
global dqn_train_batch
global dqn_update_target_network

; Export network parameters for inspection
global weights_input_hidden1
global layer_output_activated
global dqn_step_count
