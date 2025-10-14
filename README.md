# QUIGZIMON Battle System

A CLI-based battle system written in pure x86-64 assembly (NASM), inspired by Pokemon Red/Green.

## Features

- Turn-based battle system
- QUIGZIMON stats (HP, Attack, Defense)
- Damage calculation with type effectiveness
- Simple menu-driven combat
- Victory/defeat conditions

## Current QUIGZIMON

- **QUIGFLAME** (Player) - 45 HP, 12 ATK, 8 DEF - Fire type
- **QUIGLEAF** (Enemy) - 38 HP, 10 ATK, 6 DEF - Grass type

## Building

### Windows
```batch
build.bat
```

Requirements:
- NASM assembler
- MSVC linker (from Visual Studio) or GoLink

### Linux/WSL
```bash
chmod +x build.sh
./build.sh
```

Requirements:
- NASM assembler
- GNU ld linker

## Installing NASM

### Windows
Download from: https://www.nasm.us/
Or use chocolatey: `choco install nasm`

### Linux
```bash
sudo apt-get install nasm
```

## Running

### Windows
```batch
game.exe
```

### Linux/WSL
```bash
./game
```

## How to Play

1. Choose your action:
   - Press `1` to Attack
   - Press `2` to Run away

2. Battle continues until one QUIGZIMON's HP reaches 0

3. Damage formula: `Attack - Defense` (minimum 1 damage)

## Future Enhancements

- Multiple QUIGZIMON to choose from
- Type effectiveness system (Fire > Grass > Water > Fire)
- Special moves and abilities
- Catching wild QUIGZIMON
- World map navigation
- Save/load system
- Experience and leveling
- Status effects (poison, sleep, etc.)

## Technical Details

- Written in x86-64 NASM assembly
- Uses Linux syscalls (sys_write, sys_read, sys_exit)
- No external libraries - pure assembly
- Approximately 400 lines of code

## Code Structure

- QUIGZIMON data structures with stats
- Battle loop with turn management
- Player input handling
- Damage calculation system
- Number to string conversion for display
- HP tracking and display

## About QUIGZIMON

QUIGZIMON is a unique monster-battling game created in pure assembly language. Each QUIGZIMON has unique stats and abilities, making every battle strategic and exciting!
