@echo off
rem Try powers in the real town mission, skipping the title and the draft. The four slots are the power keys given,
rem or the two new ones with Heaven Splitter and Nuclear Nova. In the mission: 1-4 picks a slot, LMB casts (drag
rem powers: press, drag, release), F3 shows the frame rate, F4 the behaviour overlay, Esc pauses.
rem   try.bat                            mirror, solaris, heaven, nova
rem   try.bat voice schism wisp doom     any keys from PowerBook (doom whisper smite ember deathmark noleave wisp discord belllies heaven madness blight
rem                                      thorns tornado pestilence dragon mirror magnify congregation oath echo turncoat
rem                                      hatred priority verdict delusion tsunami gravity laser orbital cinder
rem                                      judgement glacial solaris voice abolition schism nova)
rem Voice of God, Abolition and Divine Schism: Q and E pick the command or the way to divide while the slot is focused.
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
set "LOADOUT=mirror,solaris,heaven,nova"
if not "%~1"=="" set "LOADOUT=%~1"
if not "%~2"=="" set "LOADOUT=%LOADOUT%,%~2"
if not "%~3"=="" set "LOADOUT=%LOADOUT%,%~3"
if not "%~4"=="" set "LOADOUT=%LOADOUT%,%~4"
start "" "%GODOT%" --path "%~dp0." --scene res://scenes/mission.tscn -- --loadout=%LOADOUT%
