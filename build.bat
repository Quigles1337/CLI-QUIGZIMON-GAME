@echo off
echo Building QUIGZIMON Battle System...

REM Assemble with NASM
nasm -f win64 game.asm -o game.obj

REM Link with GoLink (lightweight) or you can use link.exe from Visual Studio
REM Using link.exe (MSVC linker):
link game.obj /subsystem:console /entry:_start /out:game.exe

if %ERRORLEVEL% EQU 0 (
    echo Build successful! Run game.exe to play.
) else (
    echo Build failed. Make sure NASM and MSVC linker are installed.
)

pause
