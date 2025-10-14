# QUIGZIMON

```
╔════════════════════════════════╗
║   QUIGZIMON ADVENTURE          ║
║   Written in Pure Assembly     ║
╚════════════════════════════════╝
```

A complete monster-catching RPG written entirely in x86-64 assembly (NASM), inspired by Pokemon Red/Green.

## 🎮 Game Versions

### Classic Version (`game.asm`)
Simple battle demo with basic mechanics - great for learning!

### Enhanced Version (`game_enhanced.asm`) ⭐
**Full RPG experience with ALL features implemented:**

✅ **6 Unique QUIGZIMON Species**
✅ **Type Effectiveness System** (Fire/Water/Grass)
✅ **Starter Selection** (Choose your first QUIGZIMON!)
✅ **Wild Encounters** (Random battles)
✅ **Catching System** (Build your party!)
✅ **Experience & Leveling** (Grow stronger!)
✅ **Status Effects** (Poison, Sleep, Paralysis)
✅ **Special Moves** (Unique abilities per species)
✅ **World Map Navigation** (Explore & adventure)
✅ **Save/Load System** (Keep your progress!)
✅ **Party Management** (Collect up to 6 QUIGZIMON)

### XRPL Blockchain Version 🚀 **NEWEST!**
**First blockchain-enabled game in pure assembly!**

⛓️ **QUIGZIMON as NFTs** - Mint your catches on XRP Ledger
💰 **XRP Integration** - Check balances, send transactions
🎨 **NFT Metadata** - Full attribute encoding
🔐 **Ed25519 Signing** - Transaction signatures via libsodium
📊 **Trading System** (Coming Soon) - Buy/sell QUIGZIMON
⚔️ **PvP Battles** (Coming Soon) - Wager XRP on battles

**See [SETUP_XRPL.md](SETUP_XRPL.md) for installation!**

## 🌟 QUIGZIMON Species

### Starters (Choose One!)
- **QUIGFLAME** 🔥 - Fire - Balanced offensive starter
- **QUIGWAVE** 💧 - Water - Defensive tank starter
- **QUIGLEAF** 🍃 - Grass - Speed-focused starter

### Wild QUIGZIMON
- **QUIGBOLT** ⚡ - Normal - Fast attacker
- **QUIGROCK** 🪨 - Normal - Defensive wall
- **QUIGFROST** ❄️ - Water - Balanced encounter

## 🛠️ Building

### Enhanced Version (Recommended)

**Windows:**
```batch
build_enhanced.bat
```

**Linux/WSL:**
```bash
chmod +x build_enhanced.sh
./build_enhanced.sh
```

### Classic Version

**Windows:**
```batch
build.bat
```

**Linux/WSL:**
```bash
chmod +x build.sh
./build.sh
```

### Requirements
- **NASM assembler** (v2.14+)
- **Linker:** MSVC (Windows) or GNU ld (Linux)

## Installing NASM

### Windows
Download from: https://www.nasm.us/
Or use chocolatey: `choco install nasm`

### Linux
```bash
sudo apt-get install nasm
```

## 🎯 Running

### Enhanced Version
**Windows:** `quigzimon.exe`
**Linux/WSL:** `./quigzimon`

### Classic Version
**Windows:** `game.exe`
**Linux/WSL:** `./game`

## 📖 How to Play (Enhanced Version)

### Getting Started
1. **Choose your starter** - Pick QUIGFLAME, QUIGWAVE, or QUIGLEAF
2. **Explore** - Navigate the world map to find wild QUIGZIMON
3. **Battle** - Engage in strategic turn-based combat

### In Battle
```
1) Attack      - Use basic attack (affected by type matchup)
2) Special     - Powerful signature move (1.5x damage)
3) Catch       - Throw QUIGZIBALL (easier when HP is low)
4) Run         - Escape from battle
```

### Type Matchups
- 🔥 Fire > 🍃 Grass > 💧 Water > 🔥 Fire
- Super effective = 2x damage
- Not very effective = 0.5x damage

### Status Effects
- **Poison** 🧪 - Damages each turn (1/16 max HP)
- **Sleep** 😴 - Can't move (25% wake chance)
- **Paralysis** ⚡ - 25% chance to be fully paralyzed

### Leveling Up
- Defeat wild QUIGZIMON to gain EXP
- Level up every 100 EXP
- Stats increase on level up
- HP fully restored!

### Building Your Team
- Catch up to 6 QUIGZIMON
- Lower enemy HP for better catch rates
- Use status effects strategically
- Save your progress anytime!

## 🔧 Technical Details

### Enhanced Version
- **~1200 lines** of pure x86-64 NASM assembly
- **6 species** with full data structures
- **10+ functions** for game logic
- **Save system** with file I/O
- **Custom RNG** (Linear Congruential Generator)
- **Zero external libraries** - all from scratch!

### Features Implemented in Assembly
- Type effectiveness calculations
- Stat growth formulas
- Catch rate probability
- Status effect timers
- EXP curve system
- Random encounter generation
- String/number conversion
- Menu navigation
- Party management

### System Calls Used
- `sys_read` - User input
- `sys_write` - Display output
- `sys_open` - Open save file
- `sys_close` - Close file descriptor
- `sys_exit` - Program termination
- `sys_time` - Random seed generation

## 📁 Project Structure

```
pocket-monsters-asm/
├── game.asm              # Classic simple battle demo
├── game_enhanced.asm     # Full RPG with all features ⭐
├── save_load.asm         # Save/load system implementation
├── build.bat             # Windows build (classic)
├── build.sh              # Linux build (classic)
├── build_enhanced.bat    # Windows build (enhanced)
├── build_enhanced.sh     # Linux build (enhanced)
├── README.md             # This file
├── FEATURES.md           # Complete feature documentation
└── .gitignore           # Git ignore file
```

## 📚 Documentation

- **[FEATURES.md](FEATURES.md)** - Complete feature list and game mechanics
- **[README.md](README.md)** - Quick start and building guide

## 🎓 Learning Value

Perfect for learning:
- x86-64 Assembly programming
- Low-level game development
- Manual memory management
- Algorithm implementation
- Data structure design
- File I/O operations
- Random number generation
- String manipulation without stdlib

## 🤝 Contributing

This is an educational project showcasing assembly programming. Feel free to:
- Study the code
- Learn from the implementations
- Build upon it for your own projects
- Share improvements

## 📜 License

Created by Quigles1337
Open source - feel free to learn and adapt!

## 🎮 About QUIGZIMON

QUIGZIMON is a complete monster-catching RPG written entirely in x86-64 assembly language - no high-level code, no libraries, just pure assembly from the ground up. Every feature, from random number generation to save file management, is implemented manually using syscalls and bit manipulation.

This project demonstrates that even modern game mechanics like type effectiveness, status effects, and party management can be implemented at the lowest level of programming!
