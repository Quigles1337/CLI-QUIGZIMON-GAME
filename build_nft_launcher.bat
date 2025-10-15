@echo off
echo ========================================
echo Building QUIGZIMON NFT LAUNCHPAD
echo The First Blockchain-Gated Game!
echo ========================================
echo.

REM Check for NASM
where nasm >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: NASM not found!
    echo Install from: https://www.nasm.us/
    pause
    exit /b 1
)

REM Check for Visual Studio (need for C compiler)
where cl.exe >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Visual Studio C compiler not found!
    echo Please run from Visual Studio Developer Command Prompt
    echo Or install Visual Studio with C++ tools
    pause
    exit /b 1
)

echo [1/12] Compiling C crypto wrapper...
cl /c /O2 xrpl_crypto_wrapper.c /I"C:\vcpkg\installed\x64-windows\include"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: C compilation failed!
    echo.
    echo Make sure libsodium is installed:
    echo   vcpkg install libsodium:x64-windows
    pause
    exit /b 1
)

echo [2/12] Assembling crypto bridge...
nasm -f win64 xrpl_crypto_bridge.asm -o xrpl_crypto_bridge.obj
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Crypto bridge assembly failed!
    pause
    exit /b 1
)

echo [3/12] Assembling XRPL client...
nasm -f win64 xrpl_client.asm -o xrpl_client.obj
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: XRPL client assembly failed!
    pause
    exit /b 1
)

echo [4/12] Assembling Base58 encoder...
nasm -f win64 xrpl_base58.asm -o xrpl_base58.obj
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Base58 assembly failed!
    pause
    exit /b 1
)

echo [5/12] Assembling XRPL serialization...
nasm -f win64 xrpl_serialization.asm -o xrpl_serialization.obj
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Serialization assembly failed!
    pause
    exit /b 1
)

echo [6/12] Assembling XRPL NFT module...
nasm -f win64 xrpl_nft.asm -o xrpl_nft.obj
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: XRPL NFT assembly failed!
    pause
    exit /b 1
)

echo [7/12] Assembling complete NFT integration...
nasm -f win64 xrpl_nft_complete.asm -o xrpl_nft_complete.obj
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: NFT integration assembly failed!
    pause
    exit /b 1
)

echo [8/12] Assembling NFT Launchpad...
nasm -f win64 nft_launchpad.asm -o nft_launchpad.obj
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: NFT Launchpad assembly failed!
    pause
    exit /b 1
)

echo [9/12] Assembling game utilities...
nasm -f win64 game_enhanced.asm -o game_enhanced.obj
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Game utilities assembly failed!
    pause
    exit /b 1
)

echo [10/12] Assembling NFT launcher main...
nasm -f win64 game_nft_launcher.asm -o game_nft_launcher.obj
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: NFT launcher assembly failed!
    pause
    exit /b 1
)

echo [11/12] Linking with libsodium...
link game_nft_launcher.obj nft_launchpad.obj game_enhanced.obj ^
     xrpl_client.obj xrpl_base58.obj xrpl_serialization.obj ^
     xrpl_nft.obj xrpl_nft_complete.obj ^
     xrpl_crypto_bridge.obj xrpl_crypto_wrapper.obj ^
     /LIBPATH:"C:\vcpkg\installed\x64-windows\lib" ^
     libsodium.lib ^
     ws2_32.lib ^
     /subsystem:console ^
     /entry:_start ^
     /out:quigzimon_nft_launcher.exe

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo Build successful!
    echo ========================================
    echo.
    echo Run: quigzimon_nft_launcher.exe
    echo.
    echo 🎮 FEATURES:
    echo   ✅ NFT-gated game entry
    echo   ✅ Automatic wallet creation
    echo   ✅ Guided NFT minting process
    echo   ✅ Starter QUIGZIMON as NFTs
    echo   ✅ Full XRPL testnet integration
    echo   ✅ Pure assembly blockchain gaming!
    echo.
    echo 🚀 WORLD FIRST:
    echo   First blockchain-gated RPG in pure assembly!
    echo.
) else (
    echo.
    echo ERROR: Linking failed!
    echo.
    echo Make sure libsodium is installed via vcpkg:
    echo   vcpkg install libsodium:x64-windows
    echo.
    pause
    exit /b 1
)

pause
