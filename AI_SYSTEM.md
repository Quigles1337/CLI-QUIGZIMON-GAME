# QUIGZIMON AI - Q-Learning Reinforcement Learning System

## 🧠 Overview

Wild QUIGZIMON in the game use **Q-Learning** to adapt and improve their battle strategies over time! The AI learns from every battle, becoming increasingly challenging as you play.

**This is the first assembly-language game with reinforcement learning AI!**

---

## 🎯 How It Works

### Q-Learning Basics

**Q-Learning** is a reinforcement learning algorithm that learns the value (Q-value) of taking actions in different states:

```
Q(state, action) = expected cumulative reward
```

The AI:
1. **Observes** the battle state (HP, types, status)
2. **Chooses** an action (attack, special, defend, status move)
3. **Receives** a reward (damage dealt, HP lost, victory/defeat)
4. **Updates** its Q-table to remember what works
5. **Improves** strategy over time!

### Update Formula

```
Q(s,a) ← Q(s,a) + α[r + γ·max Q(s',a') - Q(s,a)]
                    └─────────┬─────────┘
                      temporal difference
```

Where:
- **α** (alpha) = Learning rate (0.8) - how fast to learn
- **γ** (gamma) = Discount factor (0.9) - value of future rewards
- **r** = Immediate reward
- **s** = Current state
- **a** = Action taken
- **s'** = Next state

---

## 📊 State Space (192 states)

### State Representation

Each battle state is encoded as:

```
State = HP_bucket + Type_advantage + Status + Last_move
```

**Components:**

| Component | Values | Description |
|-----------|--------|-------------|
| **HP Bucket** | 0-3 | 0=Critical(<25%), 1=Low(25-50%), 2=Med(50-75%), 3=High(>75%) |
| **Type Advantage** | 0-2 | 0=Weak, 1=Neutral, 2=Strong |
| **Status** | 0-3 | 0=Healthy, 1=Poisoned, 2=Asleep, 3=Paralyzed |
| **Last Move** | 0-3 | Previous action taken |

**Total States:** 4 × 3 × 4 × 4 = **192 discrete states**

### Example States

```
HP=High, Type=Strong, Status=None, Move=Attack → State #141
HP=Critical, Type=Weak, Status=Poisoned, Move=Special → State #25
```

---

## 🎮 Action Space (4 actions)

| Action | ID | Description |
|--------|-----|-------------|
| **Attack** | 0 | Basic attack move |
| **Special** | 1 | Powerful special move (1.5x damage) |
| **Defend** | 2 | Reduce incoming damage (not yet implemented) |
| **Status** | 3 | Inflict status effect (poison/sleep/paralyze) |

---

## 🏆 Reward System

The AI learns by receiving rewards/penalties:

| Event | Reward |
|-------|--------|
| Deal damage | +10 |
| Take damage | -15 |
| Victory | +100 |
| Defeat | -100 |
| Inflict status | +20 |
| Receive status | -25 |
| Type advantage hit | +5 |

**Example Battle:**
```
Turn 1: AI attacks, deals 12 damage → +10 reward
Turn 2: Player attacks, AI takes 15 damage → -15 reward
Turn 3: AI uses special, wins battle → +100 reward

Total: +95 reward → Q-values updated to favor this strategy
```

---

## 🔬 Learning Algorithms

### 1. Epsilon-Greedy Exploration

The AI balances **exploration** vs **exploitation**:

```
if random() < epsilon:
    choose random action (explore)
else:
    choose best action from Q-table (exploit)
```

**Epsilon Decay:**
- Starts at: 100% (fully random)
- Decays by: 2.5% per battle
- Minimum: 10% (always some exploration)

**Progression:**
```
Battles 1-10:   100% → 77%  (Learning)
Battles 11-50:  77% → 30%   (Improving)
Battles 51-100: 30% → 10%   (Optimizing)
Battles 100+:   10%         (Expert with some randomness)
```

### 2. Experience Replay

Stores up to **1000 past experiences** and re-trains on random batches:

**Benefits:**
- Breaks correlation between consecutive experiences
- Stabilizes learning
- Improves sample efficiency
- Prevents catastrophic forgetting

**Buffer Structure:**
```c
Experience {
    state: u16,
    action: u8,
    reward: i16,
    next_state: u16
}

Buffer[1000] experiences (circular)
```

**Training:**
- Store every battle step
- Randomly sample 10 experiences per update
- Re-learn from past successes/failures

### 3. Fixed-Point Arithmetic

All calculations use **16-bit fixed-point** (scale: 4096):

```assembly
; 0.8 = 3277 in fixed-point
learning_rate = 3277

; Multiply and divide by scale
result = (value * learning_rate) >> 12
```

**Why?**
- No floating-point unit needed
- Fast integer operations
- Precise enough for Q-learning

---

## 📈 AI Intelligence Levels

The AI evolves through 5 difficulty levels based on performance:

| Level | Win Rate | Description |
|-------|----------|-------------|
| **Novice** | 0-20% | Learning basics, random moves |
| **Intermediate** | 20-40% | Starting to recognize patterns |
| **Advanced** | 40-60% | Solid strategy, type awareness |
| **Expert** | 60-80% | Challenging opponent, adapts well |
| **MASTER** | 80%+ | Near-optimal play, very difficult! |

**Display:**
```
Wild QUIGZIMON's AI has evolved!
AI Difficulty: MASTER
```

---

## 🔄 Battle Integration

### Flow

```
1. Battle Start:
   ↓
   ai_battle_start() - Initialize state
   ↓
2. Each Turn:
   ↓
   ai_get_action() - Select move
   ↓
   Execute action
   ↓
   ai_step_update(reward) - Update Q-table
   ↓
3. Battle End:
   ↓
   ai_battle_end(won) - Final update, decay epsilon
```

### Code Integration

```assembly
; In enemy turn function:
enemy_battle_turn:
    ; Get AI action
    call ai_get_action
    ; rax = 0 (Attack), 1 (Special), 2 (Defend), 3 (Status)

    cmp rax, 0
    je .do_attack
    cmp rax, 1
    je .do_special
    cmp rax, 2
    je .do_defend
    cmp rax, 3
    je .do_status

.do_attack:
    call execute_attack
    ; Calculate reward based on damage
    mov rdi, [damage_dealt]
    call ai_step_update
    ret

; At battle end:
    cmp [player_hp], 0
    jle .ai_won

    mov rdi, 0  ; AI lost
    jmp .update

.ai_won:
    mov rdi, 1  ; AI won

.update:
    call ai_battle_end
```

---

## 💾 Persistence

### Save/Load Q-Table

The AI's learned knowledge persists across game sessions!

**Save:**
```assembly
call ai_save_qtable
; Writes q_table to "quigzimon_ai.qtable"
; Size: 1536 bytes (192 states × 4 actions × 2 bytes)
```

**Load:**
```assembly
call ai_load_qtable
; Loads previously learned Q-table
; AI retains all battle experience!
```

**File Format:**
```
[Q-value for state 0, action 0] (2 bytes, signed)
[Q-value for state 0, action 1] (2 bytes, signed)
[Q-value for state 0, action 2] (2 bytes, signed)
[Q-value for state 0, action 3] (2 bytes, signed)
...
[Q-value for state 191, action 3] (2 bytes, signed)
```

---

## 📊 Statistics & Monitoring

### Tracked Metrics

```assembly
total_battles          ; Total encounters
total_victories        ; AI wins
total_defeats          ; AI losses
episodes_trained       ; Training episodes
ai_intelligence_level  ; 0-5 difficulty
average_q_value        ; Mean Q-value (optimization indicator)
```

### Display Stats

```assembly
call ai_display_intelligence
; Shows current AI difficulty level

; Get win rate
movzx rax, word [total_victories]
movzx rbx, word [total_battles]
; Calculate win% = (victories * 100) / battles
```

---

## 🎓 Training Strategies

### For Players

**Early Game (Battles 1-20):**
- AI is random, easy to beat
- Good time to learn game mechanics
- AI observing your strategies

**Mid Game (Battles 21-100):**
- AI starts recognizing patterns
- Type advantages become important
- Status effects more strategic

**Late Game (Battles 100+):**
- AI plays near-optimally
- Must use advanced tactics
- Very challenging encounters!

### For Developers

**Accelerate Training:**
```assembly
; Reduce epsilon faster
epsilon_decay = 0.90 * 4096  ; Instead of 0.975

; Increase learning rate
learning_rate = 0.95 * 4096  ; Instead of 0.8
```

**Adjust Difficulty:**
```assembly
; Make AI more exploratory (easier)
epsilon_min = 0.3 * 4096  ; Instead of 0.1

; Make AI pure exploitation (harder)
epsilon_min = 0.0  ; No randomness
```

---

## 🔬 Advanced Features

### 1. Deep Q-Network (DQN) - NOW IMPLEMENTED! ✅

QUIGZIMON now features a **complete Deep Q-Network** with full backpropagation!

**Architecture:**
```
Input (8) → Hidden1 (16) → Hidden2 (16) → Output (4)
            ReLU            ReLU            Linear
```

**Network Details:**
- **Total weights:** 484 (128 + 256 + 64 + 36 biases)
- **Activation:** ReLU for hidden layers
- **Training:** Stochastic Gradient Descent (SGD)
- **Learning rate:** 0.05 (fixed-point: 205)
- **Target network:** Updated every 100 steps

**Key Components:**
```assembly
; Forward pass
call dqn_forward
; → layer_output_activated contains Q-values

; Backpropagation (COMPLETE!)
call dqn_backward
; → Computes all gradients via chain rule

; Weight update
call dqn_update_weights
; → Updates all 484 weights + 36 biases
```

**Gradient Computation:**
- Output layer: `∂L/∂W₃ = ∂L/∂output × layer₂ᵀ`
- Hidden layer 2: `∂L/∂layer₂ = W₃ᵀ × ∂L/∂output × ReLU'(layer₂)`
- Hidden layer 1: `∂L/∂layer₁ = W₂ᵀ × ∂L/∂layer₂ × ReLU'(layer₁)`

All implemented in **pure assembly** with fixed-point math!

See [ai_dqn.asm](ai_dqn.asm) for complete implementation.

---

### 2. Multi-Agent Tournament System - NOW IMPLEMENTED! ✅

**AI vs AI battles** with 4 distinct personality archetypes!

**Personality Archetypes:**

| Archetype | Strategy | Modifiers |
|-----------|----------|-----------|
| **AGGRESSIVE** | High-risk offense | +50% attack, -25% defense |
| **DEFENSIVE** | Conservative endurance | +50% defense, -12.5% attack |
| **BALANCED** | Pure Q-learning | No bias |
| **STRATEGIC** | Type advantage focus | +75% w/ advantage, -50% w/ disadvantage |

**Tournament Modes:**
```assembly
; Quick Match (2 agents)
mov rdi, 0  ; Agent 0: AGGRESSIVE
mov rsi, 1  ; Agent 1: DEFENSIVE
call agent_vs_agent
; → Returns winner ID in rax

; Full Championship (8 agents)
mov rdi, 8
call tournament_init
call tournament_run
; → Runs quarterfinals, semifinals, finals
```

**Agent Structure:**
Each agent has:
- Personal Q-table (1,536 bytes)
- Personality modifier
- 6-QUIGZIMON roster
- Win/loss statistics

**Tournament Features:**
- ✅ Spectator mode (watch AI battles)
- ✅ Bracket management (8→4→2→1)
- ✅ Personality-based action selection
- ✅ Real-time statistics tracking
- ✅ Interactive demo with 6 modes

See [AI_TOURNAMENT.md](AI_TOURNAMENT.md) for complete documentation!

---

### 3. Transfer Learning

**Potential Enhancement:**
- Pre-train on simulated battles
- Transfer knowledge between species
- Meta-learning across game sessions

---

### 4. Curriculum Learning

**Potential Enhancement:**
- Progressive difficulty
- Staged training scenarios
- Guided exploration

---

## 📝 Performance

### Memory Usage

```
Q-Table:           1536 bytes  (192 × 4 × 2)
Replay Buffer:     7000 bytes  (1000 experiences)
State Variables:   ~100 bytes
Total:             ~8.6 KB
```

### Computational Cost

```
Per Turn:
- State computation:  ~50 ops
- Action selection:   ~20 ops
- Q-value update:     ~100 ops
Total:                ~170 ops (microseconds on modern CPU)
```

**Negligible impact on game performance!**

---

## 🐛 Debugging

### Check Q-Table Values

```assembly
; Print Q-values for state 50
mov r12, 50
xor rcx, rcx
.print_loop:
    mov rax, r12
    imul rax, 4
    add rax, rcx

    lea rdi, [q_table]
    movsx rax, word [rdi + rax * 2]

    call print_number
    inc rcx
    cmp rcx, 4
    jl .print_loop
```

### Monitor Learning

```assembly
; Calculate average Q-value
lea rdi, [q_table]
xor rax, rax
mov rcx, 768  ; Total Q-values

.sum_loop:
    movsx rbx, word [rdi]
    add rax, rbx
    add rdi, 2
    loop .sum_loop

; rax = sum, divide by 768
mov rbx, 768
xor rdx, rdx
idiv rbx
; rax = average Q-value
```

### Test Convergence

Q-Learning has converged when:
- Epsilon reaches minimum
- Average Q-value stabilizes
- Win rate plateaus
- Actions become deterministic

---

## 🎮 Example: Training Session

```
Battle 1:
  State: HP=High, Type=Neutral → Chooses random: Special
  Result: Takes damage → Reward: -15
  Q[3][1] updated: 0 → -12

Battle 10:
  State: HP=Med, Type=Strong → Explores: Attack
  Result: Wins! → Reward: +100
  Q[10][0] updated: 5 → 82

Battle 50:
  State: HP=Med, Type=Strong → Exploits best: Attack
  Result: Wins! → Reward: +100
  Q[10][0] updated: 82 → 91

Battle 100:
  AI Intelligence: Expert
  Win Rate: 65%
  Epsilon: 10% (mostly optimal play)
```

---

## 📚 References

**Q-Learning:**
- Watkins & Dayan (1992) - Original Q-Learning paper
- Sutton & Barto - Reinforcement Learning: An Introduction

**Implementation:**
- Pure x86-64 assembly
- Fixed-point arithmetic
- Experience replay (Mnih et al., 2013)

---

**The AI improves with every battle. Can you keep up? 🧠⚔️🎮**
