@echo off
REM QUIGZIMON Complete Blockchain System Build Script
REM Marketplace Trading + PvP Wagers + NFT Evolution
REM Pure x86-64 Assembly Implementation

echo ╔════════════════════════════════════════════════════╗
echo ║                                                    ║
echo ║     QUIGZIMON BLOCKCHAIN BUILD SYSTEM             ║
echo ║                                                    ║
echo ║  Building Marketplace, PvP, and Evolution Systems  ║
echo ║                                                    ║
echo ╚════════════════════════════════════════════════════╝
echo.

REM Clean previous builds
echo Cleaning previous builds...
del /Q *.obj 2>nul
del /Q quigzimon_marketplace.exe 2>nul
echo.

REM ========== CORE XRPL MODULES ==========
echo ╔════════════════════════════════════════════════════╗
echo ║ [1/15] Building XRPL Core Modules...              ║
echo ╚════════════════════════════════════════════════════╝

echo Assembling xrpl_crypto_bridge.asm...
nasm -f win64 xrpl_crypto_bridge.asm -o xrpl_crypto_bridge.obj
if %ERRORLEVEL% NEQ 0 goto :error

echo Compiling xrpl_crypto.c (C wrapper for libsodium)...
cl /c /O2 xrpl_crypto.c
if %ERRORLEVEL% NEQ 0 goto :error

echo Assembling xrpl_client.asm (HTTP/JSON client)...
nasm -f win64 xrpl_client.asm -o xrpl_client.obj
if %ERRORLEVEL% NEQ 0 goto :error

echo Assembling xrpl_base58.asm (Base58 encoding)...
nasm -f win64 xrpl_base58.asm -o xrpl_base58.obj
if %ERRORLEVEL% NEQ 0 goto :error

echo Assembling xrpl_serialization.asm (Transaction serialization)...
nasm -f win64 xrpl_serialization.asm -o xrpl_serialization.obj
if %ERRORLEVEL% NEQ 0 goto :error

echo Assembling xrpl_nft_complete.asm (NFT minting engine)...
nasm -f win64 xrpl_nft_complete.asm -o xrpl_nft_complete.obj
if %ERRORLEVEL% NEQ 0 goto :error

echo.

REM ========== MARKETPLACE MODULES ==========
echo ╔════════════════════════════════════════════════════╗
echo ║ [2/15] Building NFT Marketplace...                ║
echo ╚════════════════════════════════════════════════════╝

echo Assembling marketplace_core.asm (Order book engine)...
nasm -f win64 marketplace_core.asm -o marketplace_core.obj
if %ERRORLEVEL% NEQ 0 goto :error

echo Assembling marketplace_ui.asm (Trading interface)...
nasm -f win64 marketplace_ui.asm -o marketplace_ui.obj
if %ERRORLEVEL% NEQ 0 goto :error

echo.

REM ========== PVP WAGER MODULES ==========
echo ╔════════════════════════════════════════════════════╗
echo ║ [3/15] Building PvP Wager System...               ║
echo ╚════════════════════════════════════════════════════╝

echo Assembling pvp_wager.asm (Escrow battle system)...
nasm -f win64 pvp_wager.asm -o pvp_wager.obj
if %ERRORLEVEL% NEQ 0 goto :error

echo Assembling pvp_matchmaking.asm (Lobby system)...
nasm -f win64 pvp_matchmaking.asm -o pvp_matchmaking.obj
if %ERRORLEVEL% NEQ 0 goto :error

echo.

REM ========== NFT EVOLUTION MODULES ==========
echo ╔════════════════════════════════════════════════════╗
echo ║ [4/15] Building NFT Evolution System...           ║
echo ╚════════════════════════════════════════════════════╝

echo Assembling nft_evolution.asm (Burn & mint engine)...
nasm -f win64 nft_evolution.asm -o nft_evolution.obj
if %ERRORLEVEL% NEQ 0 goto :error

echo Assembling evolution_ui.asm (Evolution chamber UI)...
nasm -f win64 evolution_ui.asm -o evolution_ui.obj
if %ERRORLEVEL% NEQ 0 goto :error

echo.

REM ========== GAME ENGINE MODULES ==========
echo ╔════════════════════════════════════════════════════╗
echo ║ [5/15] Building Game Engine...                    ║
echo ╚════════════════════════════════════════════════════╝

echo Assembling game_enhanced.asm (RPG battle system)...
nasm -f win64 game_enhanced.asm -o game_enhanced.obj
if %ERRORLEVEL% NEQ 0 goto :error

echo Assembling save_load.asm (Save system)...
nasm -f win64 save_load.asm -o save_load.obj
if %ERRORLEVEL% NEQ 0 goto :error

echo.

REM ========== MAIN LAUNCHER ==========
echo ╔════════════════════════════════════════════════════╗
echo ║ [6/15] Building Main Launcher...                  ║
echo ╚════════════════════════════════════════════════════╝

echo Creating marketplace_launcher.asm...
(
echo ; QUIGZIMON Complete Blockchain Game Launcher
echo ; Main entry point for all blockchain features
echo.
echo section .data
echo     main_title db "╔════════════════════════════════════════════════════╗", 0xA
echo                db "║                                                    ║", 0xA
echo                db "║         🎮 QUIGZIMON BLOCKCHAIN GAME 🎮           ║", 0xA
echo                db "║                                                    ║", 0xA
echo                db "╚════════════════════════════════════════════════════╝", 0xA, 0xA, 0
echo     main_title_len equ $ - main_title
echo.
echo     main_menu db "1^) 🎮 Play Game", 0xA
echo              db "2^) 🏪 NFT Marketplace", 0xA
echo              db "3^) ⚔️  PvP Wager Battles", 0xA
echo              db "4^) ✨ Evolution Chamber", 0xA
echo              db "0^) 🚪 Exit", 0xA, 0xA
echo              db "Enter choice: ", 0
echo     main_menu_len equ $ - main_menu
echo.
echo section .bss
echo     input resb 4
echo.
echo section .text
echo     global _start
echo     extern marketplace_ui_main
echo     extern matchmaking_main
echo     extern evolution_ui_main
echo     extern nft_launchpad_start
echo.
echo _start:
echo     mov rax, 1
echo     mov rdi, 1
echo     mov rsi, main_title
echo     mov rdx, main_title_len
echo     syscall
echo.
echo .main_loop:
echo     mov rax, 1
echo     mov rdi, 1
echo     mov rsi, main_menu
echo     mov rdx, main_menu_len
echo     syscall
echo.
echo     mov rax, 0
echo     mov rdi, 0
echo     mov rsi, input
echo     mov rdx, 2
echo     syscall
echo.
echo     mov al, byte [input]
echo     cmp al, '0'
echo     je .exit
echo     cmp al, '1'
echo     je .play_game
echo     cmp al, '2'
echo     je .marketplace
echo     cmp al, '3'
echo     je .pvp
echo     cmp al, '4'
echo     je .evolution
echo     jmp .main_loop
echo.
echo .play_game:
echo     call nft_launchpad_start
echo     jmp .main_loop
echo.
echo .marketplace:
echo     call marketplace_ui_main
echo     jmp .main_loop
echo.
echo .pvp:
echo     call matchmaking_main
echo     jmp .main_loop
echo.
echo .evolution:
echo     call evolution_ui_main
echo     jmp .main_loop
echo.
echo .exit:
echo     mov rax, 60
echo     xor rdi, rdi
echo     syscall
) > marketplace_launcher.asm

echo Assembling marketplace_launcher.asm...
nasm -f win64 marketplace_launcher.asm -o marketplace_launcher.obj
if %ERRORLEVEL% NEQ 0 goto :error

echo.

REM ========== LINKING ==========
echo ╔════════════════════════════════════════════════════╗
echo ║ [7/15] Linking Complete System...                 ║
echo ╚════════════════════════════════════════════════════╝

echo Linking all modules...
link /ENTRY:_start /SUBSYSTEM:CONSOLE /NODEFAULTLIB ^
    marketplace_launcher.obj ^
    xrpl_crypto_bridge.obj ^
    xrpl_crypto.obj ^
    xrpl_client.obj ^
    xrpl_base58.obj ^
    xrpl_serialization.obj ^
    xrpl_nft_complete.obj ^
    marketplace_core.obj ^
    marketplace_ui.obj ^
    pvp_wager.obj ^
    pvp_matchmaking.obj ^
    nft_evolution.obj ^
    evolution_ui.obj ^
    game_enhanced.obj ^
    save_load.obj ^
    kernel32.lib ^
    ws2_32.lib ^
    vcruntime.lib ^
    libsodium.lib ^
    /OUT:quigzimon_marketplace.exe

if %ERRORLEVEL% NEQ 0 goto :error

echo.
echo ╔════════════════════════════════════════════════════╗
echo ║                                                    ║
echo ║          ✅ BUILD SUCCESSFUL! ✅                   ║
echo ║                                                    ║
echo ║  Executable: quigzimon_marketplace.exe            ║
echo ║                                                    ║
echo ║  Features:                                         ║
echo ║    • NFT Marketplace Trading                       ║
echo ║    • PvP Wagered Battles                           ║
echo ║    • NFT Evolution System                          ║
echo ║    • Complete RPG Game                             ║
echo ║                                                    ║
echo ║  All in Pure x86-64 Assembly!                      ║
echo ║                                                    ║
echo ╚════════════════════════════════════════════════════╝
echo.
echo Ready to play! Run: quigzimon_marketplace.exe
echo.
goto :end

:error
echo.
echo ╔════════════════════════════════════════════════════╗
echo ║                                                    ║
echo ║             ❌ BUILD FAILED ❌                     ║
echo ║                                                    ║
echo ║  Please check the error messages above.           ║
echo ║                                                    ║
echo ╚════════════════════════════════════════════════════╝
echo.
exit /b 1

:end
