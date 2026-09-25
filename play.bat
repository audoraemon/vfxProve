@echo off
rem Play Kingdoms Amid Kataclysm from its title screen. Override the engine path with: set GODOT=C:\path\to\Godot.exe
setlocal
if "%GODOT%"=="" set "GODOT=F:\Godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT%" (
	echo Godot not found at "%GODOT%".
	echo Set the GODOT environment variable to your Godot 4.7.2 executable.
	pause
	exit /b 1
)
start "" "%GODOT%" --path "%~dp0." --scene res://scenes/game.tscn
