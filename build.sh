#!/bin/bash
# Build script for Linux/WSL

echo "Building QUIGZIMON Battle System..."

# Assemble with NASM
nasm -f elf64 game.asm -o game.o

# Link
ld game.o -o game

if [ $? -eq 0 ]; then
    echo "Build successful! Run ./game to play."
    chmod +x game
else
    echo "Build failed. Make sure NASM is installed."
fi
