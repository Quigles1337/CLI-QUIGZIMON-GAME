# QUIGZIMON - Complete Feature List

## Game Overview
QUIGZIMON is a complete monster-catching RPG written entirely in x86-64 assembly language, featuring all the classic mechanics from Pokemon Red/Green.

---

## 🎮 Core Features

### 1. Multiple QUIGZIMON Species

**Starter QUIGZIMON** (Choose one at game start):
- **QUIGFLAME** (Fire Type)
  - Base Stats: 45 HP / 12 ATK / 8 DEF / 10 SPD
  - Moves: Ember, Flamethrower
  - Best against: Grass types

- **QUIGWAVE** (Water Type)
  - Base Stats: 50 HP / 10 ATK / 12 DEF / 8 SPD
  - Moves: Water Gun, Hydro Pump
  - Best against: Fire types

- **QUIGLEAF** (Grass Type)
  - Base Stats: 42 HP / 11 ATK / 9 DEF / 12 SPD
  - Moves: Vine Whip, Solar Beam
  - Best against: Water types

**Wild QUIGZIMON** (Encounter in exploration):
- **QUIGBOLT** (Normal Type) - Fast attacker
- **QUIGROCK** (Normal Type) - Defensive tank
- **QUIGFROST** (Water Type) - Balanced wild encounter

---

### 2. Type Effectiveness System

Full type chart implementation:

```
Fire > Grass (2x damage - Super Effective!)
Grass > Water (2x damage - Super Effective!)
Water > Fire (2x damage - Super Effective!)

Fire < Water (0.5x damage - Not very effective...)
Grass < Fire (0.5x damage - Not very effective...)
Water < Grass (0.5x damage - Not very effective...)

Normal = 1x damage (neutral)
```

Strategic battles depend on choosing the right type matchup!

---

### 3. Battle System

**Turn-Based Combat** with multiple options:

1. **Attack** - Basic attack using your QUIGZIMON's ATK stat
   - Damage formula: `ATK - DEF` (minimum 1)
   - Modified by type effectiveness

2. **Special Move** - Powerful signature moves
   - 1.5x damage multiplier
   - Each QUIGZIMON has 2 unique moves

3. **Catch** - Attempt to catch wild QUIGZIMON
   - Success rate based on target's remaining HP
   - Lower HP = higher catch rate
   - Cannot catch if party is full (max 6)

4. **Run** - Escape from battle
   - 100% success rate (for now)

**Battle Flow:**
- Speed stat determines turn order
- Status effects apply each turn
- Critical hits possible (random chance)
- Victory gives EXP to level up!

---

### 4. Status Effects

Three status conditions that persist throughout battle:

**POISON** 🧪
- Deals 1/16 max HP damage each turn
- Applied by: Toxic move
- Weakens opponent over time

**SLEEP** 😴
- 25% chance to wake up each turn
- Cannot attack while asleep
- Applied by: Sleep Powder move
- Leaves opponent vulnerable

**PARALYSIS** ⚡
- 25% chance to be fully paralyzed each turn
- Reduces speed by 50%
- Applied by: Thunder Wave move
- Makes slower QUIGZIMON easier to outspeed

---

### 5. Experience & Leveling

**EXP System:**
- Gain EXP from defeating wild QUIGZIMON
- EXP earned = `Enemy Level × 10 + 20`
- Level up every 100 EXP

**Stat Growth on Level Up:**
- Max HP: +5
- Attack: +2
- Defense: +2
- Speed: +1
- HP fully restored

**Starting Level:** All starters begin at Level 5
**Wild QUIGZIMON:** Appear at random levels 3-7

---

### 6. Catching System

**QUIGZIBALL Mechanics:**
- Throw during battle to attempt capture
- Catch rate calculation:
  ```
  Catch Rate = 100 - (Current HP / Max HP × 100)
  Example: 20/40 HP = 50% remaining = 50% catch rate
           5/40 HP = 12.5% remaining = 87.5% catch rate
  ```
- Successfully caught QUIGZIMON join your party
- Can catch up to 6 in active party
- Total collection tracked

**Strategic Catching:**
- Weaken the QUIGZIMON first (lower HP)
- Use status effects to keep them weak
- Don't defeat them accidentally!

---

### 7. World Map Navigation

**Overworld System:**
- Explore different locations
- Random wild encounters
- Menu-driven navigation

**Available Actions:**
1. **Explore** - Search for wild QUIGZIMON
   - Random encounter generation
   - Random species (from wild pool)
   - Random level (3-7)

2. **View Party** - See your collected QUIGZIMON
   - Display all party members
   - Check stats and levels
   - View HP and status

3. **Save Game** - Save your progress
   - Saves to `quigzimon.sav`
   - Preserves party, stats, progress

4. **Quit** - Exit the game

**Locations** (Future expansion):
- Starting Town
- Quig Forest
- Route 1

---

### 8. Party Management

**Party System:**
- Carry up to 6 QUIGZIMON
- First QUIGZIMON is used in battle
- Party size tracked
- Total caught tracked separately

**Party Display Shows:**
- QUIGZIMON name and species
- Current level
- HP (current/max)
- Status condition
- EXP progress

---

### 9. Save/Load System

**Save File Format:**
```
Byte 0: Player party count (0-6)
Byte 1: Total QUIGZIMON caught
Byte 2: Current location ID
Bytes 3-92: Party data (6 × 15 bytes)
```

**Each QUIGZIMON Saved:**
- Species ID (1 byte)
- Level (1 byte)
- Current HP (2 bytes)
- Max HP (2 bytes)
- EXP (2 bytes)
- Status (1 byte)
- ATK (2 bytes)
- DEF (2 bytes)
- SPD (2 bytes)

**File Operations:**
- Save: Creates/overwrites `quigzimon.sav`
- Load: Restores from `quigzimon.sav`
- Portable save file (93 bytes)

---

### 10. Special Moves & Abilities

**Move Database:**

**Fire Moves:**
- **Ember** - Basic fire attack
- **Flamethrower** - Powerful fire blast (1.5x damage)

**Water Moves:**
- **Water Gun** - Basic water attack
- **Hydro Pump** - Massive water cannon (1.5x damage)

**Grass Moves:**
- **Vine Whip** - Basic grass attack
- **Solar Beam** - Concentrated solar energy (1.5x damage)

**Status Moves:**
- **Toxic** - Badly poisons the target
- **Sleep Powder** - Puts target to sleep
- **Thunder Wave** - Paralyzes the target

**Normal Moves:**
- **Tackle** - Basic physical attack

---

## 🎯 Gameplay Loop

```
1. Choose Starter QUIGZIMON
   ↓
2. Enter World Map
   ↓
3. Explore for Wild Encounters
   ↓
4. Battle Wild QUIGZIMON
   ├─→ Defeat for EXP
   └─→ Catch to add to party
   ↓
5. Level Up & Get Stronger
   ↓
6. Build Your Team (up to 6)
   ↓
7. Save Progress
   ↓
8. Repeat!
```

---

## 🔧 Technical Implementation

**Assembly Features:**
- Pure x86-64 NASM assembly
- ~1200 lines of code
- No external libraries
- Direct syscall usage
- Custom random number generator (LCG)
- Manual string/number conversion
- Efficient data structures

**Algorithms:**
- Type effectiveness lookup table
- Stat calculation formulas
- Catch rate probability
- Status effect timing
- EXP curve calculation
- Random encounter generation

---

## 📊 Statistics

**Code Breakdown:**
- Game constants: ~30 definitions
- Messages/strings: ~50 text blocks
- QUIGZIMON data: 6 species defined
- Move data: 10 moves implemented
- Functions: ~25 major routines
- Total size: ~1200 lines pure assembly

**Data Structures:**
- 15 bytes per QUIGZIMON instance
- 33 bytes per species definition
- 93 bytes per save file
- Minimal memory footprint

---

## 🚀 Future Enhancements

Planned features for future versions:

- [ ] More QUIGZIMON species (20+ total)
- [ ] Evolution system
- [ ] Breeding mechanics
- [ ] Multiple save slots
- [ ] Trainer battles (NPC opponents)
- [ ] Items and inventory system
- [ ] QUIGZIMON Centers for healing
- [ ] Shops to buy items
- [ ] More locations to explore
- [ ] Quest/story system
- [ ] Abilities and natures
- [ ] Shiny QUIGZIMON (rare variants)
- [ ] Sound effects (beep codes)
- [ ] Leaderboards/Hall of Fame

---

## 🎓 Educational Value

This project demonstrates:

1. **Low-level programming** - Direct hardware interaction
2. **Memory management** - Manual data structure handling
3. **Algorithm implementation** - From scratch in assembly
4. **Game design** - Complete gameplay loop
5. **File I/O** - Saving/loading data
6. **Random number generation** - Custom RNG
7. **String manipulation** - Without standard library
8. **Control flow** - Complex game state management

Perfect for learning:
- Assembly language
- Computer architecture
- Game programming fundamentals
- Data structure design
- Algorithm optimization

---

## 🏆 Achievements

Try to accomplish these goals:

- **Collector** - Catch all 6 QUIGZIMON species
- **Champion** - Reach level 20 with any QUIGZIMON
- **Type Master** - Have one of each starter type
- **Full Party** - Maintain 6 QUIGZIMON in party
- **Survivor** - Win 10 consecutive battles
- **Lucky Catch** - Catch a QUIGZIMON at >50% HP

---

Made with ❤️ in pure x86-64 assembly
