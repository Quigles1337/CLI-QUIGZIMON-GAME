#!/bin/bash

echo "========================================"
echo "Building QUIGZIMON Enhanced Edition"
echo "========================================"
echo

# Check if NASM is installed
if ! command -v nasm &> /dev/null; then
    echo "ERROR: NASM not found!"
    echo "Install with: sudo apt-get install nasm"
    exit 1
fi

echo "[1/2] Assembling with NASM..."
nasm -f elf64 game_enhanced.asm -o game_enhanced.o

if [ $? -ne 0 ]; then
    echo "ERROR: Assembly failed!"
    exit 1
fi

echo "[2/2] Linking..."
ld game_enhanced.o -o quigzimon

if [ $? -eq 0 ]; then
    echo
    echo "========================================"
    echo "Build successful!"
    echo "========================================"
    echo
    echo "Run: ./quigzimon"
    echo
    chmod +x quigzimon
else
    echo
    echo "ERROR: Linking failed!"
    exit 1
fi
