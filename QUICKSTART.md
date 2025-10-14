# QUIGZIMON - Quick Start Guide

## 🚀 Get Playing in 3 Steps

### Step 1: Build
```batch
# Windows
build_enhanced.bat

# Linux/WSL
chmod +x build_enhanced.sh && ./build_enhanced.sh
```

### Step 2: Run
```batch
# Windows
quigzimon.exe

# Linux
./quigzimon
```

### Step 3: Play!
Choose your starter and start your adventure!

---

## 🎮 Controls Cheat Sheet

### Starter Selection
```
1 - QUIGFLAME (Fire)  🔥 Offensive
2 - QUIGWAVE (Water)  💧 Defensive
3 - QUIGLEAF (Grass)  🍃 Fast
```

### World Map
```
1 - Explore (find wild QUIGZIMON)
2 - View Party
3 - Save Game
4 - Quit
```

### Battle Menu
```
1 - Attack (basic move)
2 - Special Move (1.5x damage)
3 - Catch (throw QUIGZIBALL)
4 - Run (escape)
```

---

## ⚡ Quick Tips

### Catching QUIGZIMON
- **Lower HP = Higher catch rate**
- At 50% HP = ~50% catch rate
- At 10% HP = ~90% catch rate
- Max party size: 6

### Type Strategy
```
🔥 Fire beats 🍃 Grass
🍃 Grass beats 💧 Water
💧 Water beats 🔥 Fire
```

### Status Effects
- **Poison** 🧪 = Gradual damage
- **Sleep** 😴 = Can't move (25% wake)
- **Paralysis** ⚡ = 25% can't move

### Leveling
- Need 100 EXP per level
- Beat enemies = gain EXP
- Level up = full HP restore + stat boost

---

## 🎯 Starter Comparison

| QUIGZIMON | Type | HP | ATK | DEF | SPD | Strategy |
|-----------|------|----|----|-----|-----|----------|
| QUIGFLAME | Fire | 45 | 12 | 8 | 10 | Balanced offense |
| QUIGWAVE | Water | 50 | 10 | 12 | 8 | Tank/Defense |
| QUIGLEAF | Grass | 42 | 11 | 9 | 12 | Speed sweeper |

**Recommendation:**
- New players: QUIGWAVE (easiest to keep alive)
- Aggressive: QUIGFLAME (high damage)
- Strategic: QUIGLEAF (outspeeds most enemies)

---

## 📊 Battle Damage Formula

```
Base Damage = ATK - DEF (minimum 1)
Type Modifier = 2.0x (super effective)
               1.0x (neutral)
               0.5x (not very effective)
Final Damage = Base × Type Modifier
```

---

## 🏆 Goals to Achieve

**Beginner:**
- [ ] Choose a starter
- [ ] Win your first battle
- [ ] Catch a wild QUIGZIMON
- [ ] Reach level 10

**Intermediate:**
- [ ] Catch all 3 wild species
- [ ] Build a full party (6 QUIGZIMON)
- [ ] Reach level 15
- [ ] Use a status effect successfully

**Advanced:**
- [ ] Catch one of each type
- [ ] Reach level 20
- [ ] Win 10 battles in a row
- [ ] Save your game

---

## ❓ Common Questions

**Q: How do I save?**
A: From world map, press `3`

**Q: Where's my save file?**
A: `quigzimon.sav` in the same folder

**Q: Can I catch more than 6?**
A: Party limit is 6 (for now)

**Q: What's the best starter?**
A: Depends on playstyle! All are viable.

**Q: How do I heal?**
A: Level up fully restores HP (no healing items yet)

**Q: Can QUIGZIMON evolve?**
A: Not yet - planned for future version!

---

## 🐛 Troubleshooting

**Build fails:**
- Make sure NASM is installed
- Windows: Need MSVC or GoLink
- Linux: Need GNU ld

**Game crashes:**
- Report to GitHub issues
- Include what you were doing when it crashed

**Save won't load:**
- File might be corrupted
- Try starting new game

---

## 🎓 Assembly Learning Path

If you want to learn from the code:

1. **Start with:** `game.asm` (simple battle system)
2. **Study:** Data structures and syscalls
3. **Understand:** Battle loop and input handling
4. **Advanced:** Type system and calculations
5. **Expert:** Save/load and file I/O

---

## 🌟 Pro Tips

1. **Type advantage matters** - Don't fight fire with grass!
2. **Status effects stack** - Poison + low HP = easy catch
3. **Save often** - No auto-save yet
4. **Level your starter first** - It's your strongest
5. **Explore frequently** - More battles = more exp

---

## 📞 Need Help?

- Read [FEATURES.md](FEATURES.md) for detailed mechanics
- Check [README.md](README.md) for technical info
- Report bugs on GitHub
- Study the assembly code to learn!

---

**Now go catch 'em all! 🎮**
