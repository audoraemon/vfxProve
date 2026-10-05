@echo off
rem Try a power in the VFX sandbox: the fantasy castle with 40 orcs, opened on the Divine set (Light of Solaris,
rem Mirrorfold Passage). Keys 1-7 pick a power, LMB casts it (drag powers: press, drag, release), Tab switches set,
rem R respawns the map, Space is slow-mo, WASD pans.
rem   vfx.bat          the Divine set
rem   vfx.bat 1        another set (0 sci-fi, 1 fantasy, 2 divine)
rem Override the engine path with: set GODOT=C:\path\to\Godot.exe
setlocal
if "%GODOT%"=="" set "GODOT=F:\Godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT%" set "GODOT=C:\BURIN_NITRO\Godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT%" (
	echo Godot not found at "%GODOT%".
	echo Set the GODOT environment variable to your Godot 4.7.2 executable.
	pause
	exit /b 1
)
set "SET=2"
if not "%~1"=="" set "SET=%~1"
start "" "%GODOT%" --path "%~dp0." --scene res://scenes/sandbox.tscn -- --set=%SET%
