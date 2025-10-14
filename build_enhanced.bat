@echo off
echo ========================================
echo Building QUIGZIMON Enhanced Edition
echo ========================================
echo.

REM Check if NASM is installed
where nasm >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: NASM not found!
    echo Please install NASM from https://www.nasm.us/
    echo Or install via chocolatey: choco install nasm
    pause
    exit /b 1
)

echo [1/2] Assembling with NASM...
nasm -f win64 game_enhanced.asm -o game_enhanced.obj

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Assembly failed!
    pause
    exit /b 1
)

echo [2/2] Linking...
REM Try to use MSVC linker first
where link.exe >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    link game_enhanced.obj /subsystem:console /entry:_start /out:quigzimon.exe
) else (
    echo WARNING: MSVC linker not found. Trying GoLink...
    where golink.exe >nul 2>nul
    if %ERRORLEVEL% EQU 0 (
        golink /console /entry _start game_enhanced.obj
    ) else (
        echo ERROR: No linker found!
        echo Please install Visual Studio or GoLink
        pause
        exit /b 1
    )
)

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo Build successful!
    echo ========================================
    echo.
    echo Run: quigzimon.exe
    echo.
) else (
    echo.
    echo ERROR: Linking failed!
    pause
    exit /b 1
)

pause
