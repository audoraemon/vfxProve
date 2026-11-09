@echo off
rem Play from the title with the dev tools on (--dev): Endless Night, the skill tree, and on the god hub
rem A = dev Awaken (tier + 1, +2 ability points; when a Hunt is due, A starts the Hunt instead).
rem The board also gets its DEV tab (D) and the ENDLESS button. Override the engine path with: set GODOT=C:\path\to\Godot.exe
setlocal
if "%GODOT%"=="" set "GODOT=F:\Godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT%" set "GODOT=C:\BURIN_NITRO\Godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT%" (
	echo Godot not found at "%GODOT%".
	echo Set the GODOT environment variable to your Godot 4.7.2 executable.
	pause
	exit /b 1
)
rem Refresh the class cache first: new class_name scripts are otherwise unknown and game.gd fails to parse.
echo Refreshing the script class cache...
start "" /wait "%GODOT%" --headless --path "%~dp0." --import
start "" "%GODOT%" --path "%~dp0." --scene res://scenes/game.tscn -- --dev
