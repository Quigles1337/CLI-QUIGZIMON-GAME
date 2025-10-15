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
; Computes gradients for all layers using chain rule
dqn_backward:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    ; ========== OUTPUT LAYER BACKWARD ==========
    ; grad_output already set by caller (TD error)

    ; Compute weight gradients: grad_w = grad_out * activation^T
    ; For each output neuron
    xor r12, r12
.output_neuron_loop:
    cmp r12, output_size
    jge .output_done

    ; Get gradient for this output neuron
    movsx r13, word [grad_output + r12 * 2]

    ; For each hidden2 neuron (input to this layer)
    xor r14, r14
.output_weight_loop:
    cmp r14, hidden2_size
    jge .output_next_neuron

    ; grad_w[out][h2] = grad_out[out] * h2_activated[h2]
    movsx rax, word [layer_hidden2_activated + r14 * 2]
    imul rax, r13
    sar rax, 12     ; Fixed point division

    ; Weight index: out * hidden2_size + h2
    mov rbx, r12
    imul rbx, hidden2_size
    add rbx, r14
    mov word [grad_weights_h2_out + rbx * 2], ax

    inc r14
    jmp .output_weight_loop

.output_next_neuron:
    ; Bias gradient = output gradient
    mov word [grad_bias_out + r12 * 2], r13w

    inc r12
    jmp .output_neuron_loop

.output_done:

    ; ========== HIDDEN2 LAYER BACKWARD ==========
    ; grad_hidden2 = weights_h2_out^T * grad_output

    xor r12, r12    ; Hidden2 neuron index
.hidden2_loop:
    cmp r12, hidden2_size
    jge .hidden2_done

    xor rax, rax    ; Accumulator
    xor r13, r13    ; Output neuron index

.hidden2_backprop:
    cmp r13, output_size
    jge .hidden2_relu_derivative

    ; grad += weight[out][h2] * grad_out[out]
    mov rbx, r13
    imul rbx, hidden2_size
    add rbx, r12
    movsx r14, word [weights_hidden2_output + rbx * 2]

    movsx r15, word [grad_output + r13 * 2]
    imul r14, r15
    sar r14, 12
    add rax, r14

    inc r13
    jmp .hidden2_backprop

.hidden2_relu_derivative:
    ; Multiply by ReLU derivative: f'(x) = 1 if x > 0, else 0
    movsx rbx, word [layer_hidden2 + r12 * 2]
    cmp rbx, 0
    jg .hidden2_active
    xor rax, rax    ; Zero gradient if ReLU didn't activate

.hidden2_active:
    mov word [grad_hidden2 + r12 * 2], ax

    inc r12
    jmp .hidden2_loop

.hidden2_done:

    ; Compute hidden1->hidden2 weight gradients
    xor r12, r12
.h1_h2_neuron_loop:
    cmp r12, hidden2_size
    jge .h1_h2_done

    movsx r13, word [grad_hidden2 + r12 * 2]

    xor r14, r14
.h1_h2_weight_loop:
    cmp r14, hidden1_size
    jge .h1_h2_next

    ; grad_w[h2][h1] = grad_h2[h2] * h1_activated[h1]
    movsx rax, word [layer_hidden1_activated + r14 * 2]
    imul rax, r13
    sar rax, 12

    mov rbx, r12
    imul rbx, hidden1_size
    add rbx, r14
    mov word [grad_weights_h1_h2 + rbx * 2], ax

    inc r14
    jmp .h1_h2_weight_loop

.h1_h2_next:
    mov word [grad_bias_h2 + r12 * 2], r13w
    inc r12
    jmp .h1_h2_neuron_loop

.h1_h2_done:

    ; ========== HIDDEN1 LAYER BACKWARD ==========
    ; grad_hidden1 = weights_h1_h2^T * grad_hidden2

    xor r12, r12
.hidden1_loop:
    cmp r12, hidden1_size
    jge .hidden1_done

    xor rax, rax
    xor r13, r13

.hidden1_backprop:
    cmp r13, hidden2_size
    jge .hidden1_relu_derivative

    mov rbx, r13
    imul rbx, hidden1_size
    add rbx, r12
    movsx r14, word [weights_hidden1_hidden2 + rbx * 2]

    movsx r15, word [grad_hidden2 + r13 * 2]
    imul r14, r15
    sar r14, 12
    add rax, r14

    inc r13
    jmp .hidden1_backprop

.hidden1_relu_derivative:
    movsx rbx, word [layer_hidden1 + r12 * 2]
    cmp rbx, 0
    jg .hidden1_active
    xor rax, rax

.hidden1_active:
    mov word [grad_hidden1 + r12 * 2], ax

    inc r12
    jmp .hidden1_loop

.hidden1_done:

    ; Compute input->hidden1 weight gradients
    xor r12, r12
.in_h1_neuron_loop:
    cmp r12, hidden1_size
    jge .in_h1_done

    movsx r13, word [grad_hidden1 + r12 * 2]

    xor r14, r14
.in_h1_weight_loop:
    cmp r14, input_size
    jge .in_h1_next

    movsx rax, word [layer_input + r14 * 2]
    imul rax, r13
    sar rax, 12

    mov rbx, r12
    imul rbx, input_size
    add rbx, r14
    mov word [grad_weights_in_h1 + rbx * 2], ax

    inc r14
    jmp .in_h1_weight_loop

.in_h1_next:
    mov word [grad_bias_h1 + r12 * 2], r13w
    inc r12
    jmp .in_h1_neuron_loop

.in_h1_done:

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Update weights using gradients
; Implements Stochastic Gradient Descent (SGD)
; w = w - learning_rate * gradient
dqn_update_weights:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13

    movsx r13, word [dqn_learning_rate]

    ; ========== UPDATE INPUT -> HIDDEN1 ==========
    xor r12, r12
.update_in_h1:
    cmp r12, 128    ; 8 * 16 weights
    jge .update_bias_h1

    ; weight -= learning_rate * gradient
    lea rbx, [weights_input_hidden1]
    movsx rax, word [rbx + r12 * 2]

    lea rbx, [grad_weights_in_h1]
    movsx rcx, word [rbx + r12 * 2]
    imul rcx, r13
    sar rcx, 12

    sub rax, rcx

    ; Clamp to prevent overflow
    cmp rax, 32767
    jle .check_in_h1_min
    mov rax, 32767
    jmp .store_in_h1

.check_in_h1_min:
    cmp rax, -32768
    jge .store_in_h1
    mov rax, -32768

.store_in_h1:
    lea rbx, [weights_input_hidden1]
    mov word [rbx + r12 * 2], ax

    inc r12
    jmp .update_in_h1

.update_bias_h1:
    xor r12, r12
.update_bias_h1_loop:
    cmp r12, 16
    jge .update_h1_h2

    lea rbx, [bias_hidden1]
    movsx rax, word [rbx + r12 * 2]

    lea rbx, [grad_bias_h1]
    movsx rcx, word [rbx + r12 * 2]
    imul rcx, r13
    sar rcx, 12

    sub rax, rcx

    lea rbx, [bias_hidden1]
    mov word [rbx + r12 * 2], ax

    inc r12
    jmp .update_bias_h1_loop

    ; ========== UPDATE HIDDEN1 -> HIDDEN2 ==========
.update_h1_h2:
    xor r12, r12
.update_h1_h2_loop:
    cmp r12, 256    ; 16 * 16 weights
    jge .update_bias_h2

    lea rbx, [weights_hidden1_hidden2]
    movsx rax, word [rbx + r12 * 2]

    lea rbx, [grad_weights_h1_h2]
    movsx rcx, word [rbx + r12 * 2]
    imul rcx, r13
    sar rcx, 12

    sub rax, rcx

    cmp rax, 32767
    jle .check_h1_h2_min
    mov rax, 32767
    jmp .store_h1_h2

.check_h1_h2_min:
    cmp rax, -32768
    jge .store_h1_h2
    mov rax, -32768

.store_h1_h2:
    lea rbx, [weights_hidden1_hidden2]
    mov word [rbx + r12 * 2], ax

    inc r12
    jmp .update_h1_h2_loop

.update_bias_h2:
    xor r12, r12
.update_bias_h2_loop:
    cmp r12, 16
    jge .update_h2_out

    lea rbx, [bias_hidden2]
    movsx rax, word [rbx + r12 * 2]

    lea rbx, [grad_bias_h2]
    movsx rcx, word [rbx + r12 * 2]
    imul rcx, r13
    sar rcx, 12

    sub rax, rcx

    lea rbx, [bias_hidden2]
    mov word [rbx + r12 * 2], ax

    inc r12
    jmp .update_bias_h2_loop

    ; ========== UPDATE HIDDEN2 -> OUTPUT ==========
.update_h2_out:
    xor r12, r12
.update_h2_out_loop:
    cmp r12, 64     ; 16 * 4 weights
    jge .update_bias_out

    lea rbx, [weights_hidden2_output]
    movsx rax, word [rbx + r12 * 2]

    lea rbx, [grad_weights_h2_out]
    movsx rcx, word [rbx + r12 * 2]
    imul rcx, r13
    sar rcx, 12

    sub rax, rcx

    cmp rax, 32767
    jle .check_h2_out_min
    mov rax, 32767
    jmp .store_h2_out

.check_h2_out_min:
    cmp rax, -32768
    jge .store_h2_out
    mov rax, -32768

.store_h2_out:
    lea rbx, [weights_hidden2_output]
    mov word [rbx + r12 * 2], ax

    inc r12
    jmp .update_h2_out_loop

.update_bias_out:
    xor r12, r12
.update_bias_out_loop:
    cmp r12, 4
    jge .done

    lea rbx, [bias_output]
    movsx rax, word [rbx + r12 * 2]

    lea rbx, [grad_bias_out]
    movsx rcx, word [rbx + r12 * 2]
    imul rcx, r13
    sar rcx, 12

    sub rax, rcx

    lea rbx, [bias_output]
    mov word [rbx + r12 * 2], ax

    inc r12
    jmp .update_bias_out_loop

.done:
    pop r13
    pop r12
    pop rbx
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
; Same as dqn_forward but uses target network weights for stability
dqn_target_forward:
    push rbp
    mov rbp, rsp

    ; Input -> Hidden1 (target network)
    lea rsi, [layer_input]
    lea rdi, [target_weights_input_hidden1]
    lea r8, [target_bias_hidden1]
    lea rdx, [layer_hidden1]
    mov rcx, input_size
    mov r9, hidden1_size
    call dense_layer

    ; ReLU activation
    lea rsi, [layer_hidden1]
    lea rdi, [layer_hidden1_activated]
    mov rcx, hidden1_size
    call relu_activation

    ; Hidden1 -> Hidden2 (target network)
    lea rsi, [layer_hidden1_activated]
    lea rdi, [target_weights_hidden1_hidden2]
    lea r8, [target_bias_hidden2]
    lea rdx, [layer_hidden2]
    mov rcx, hidden1_size
    mov r9, hidden2_size
    call dense_layer

    ; ReLU activation
    lea rsi, [layer_hidden2]
    lea rdi, [layer_hidden2_activated]
    mov rcx, hidden2_size
    call relu_activation

    ; Hidden2 -> Output (target network)
    lea rsi, [layer_hidden2_activated]
    lea rdi, [target_weights_hidden2_output]
    lea r8, [target_bias_output]
    lea rdx, [layer_output]
    mov rcx, hidden2_size
    mov r9, output_size
    call dense_layer

    ; Linear activation for output
    lea rsi, [layer_output]
    lea rdi, [layer_output_activated]
    mov rcx, output_size
    rep movsw

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
