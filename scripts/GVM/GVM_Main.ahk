/*
 ``````````````````````````````````````````````````````````````````````````````
 ` GVM_main
 `
 ` Launches GVM and configures the hotkeys.
 `
 ` Author: CoeJoder
 ``````````````````````````````````````````````````````````````````````````````
 */
#Warn All, StdOut
#Warn LocalSameAsGlobal, Off
#NoEnv
#SingleInstance Force
#Include <GVM>

SetWorkingDir %A_ScriptDir%
CoordMode, Pixel, Window
CoordMode, Mouse, Window
SetKeyDelay, 30, 2
SetMouseDelay, 50
SetDefaultMouseSpeed, 1

MACRO_SNIPPETS := "C:\Users\Joe\Documents\AutoHotkey\scripts\GVM\vm_script.txt"
SHUTDOWN_CPP := "C:\Users\Joe\Documents\AutoHotkey\scripts\GVM\system_shutdown.cpp"

; 2nd monitor with 200/255 opacity
global gv = new GVM(-3000, 58, 1165, 725, 255)
gv.SetSleepDelay(500)
gv.SetTargetWindowTitle("*Untitled - Notepad")
;~ gv.SetTargetWindowTitle("SeaFour - Google Chrome")
;~ gv.SetTargetWindowTitle("QEMU (winnt) - noVNC - Mozilla Firefox")
gv.SetVmScript(SHUTDOWN_CPP)
gv.EnableRawSend(False)

global start := 1
global last := 43

;~ ^+a::
	;~ gv.console.Append("Running single line...")
	;~ gv.singleLine(start)
	;~ start := start + 1
;~ return

^+!a::
	gv.console.Append("Running line range...")
	Sleep, 1000
	gv.lineRange(start, last)
return

;~ ^+d::
	;~ gv.send("^!{Delete}")
;~ return

;~ ^space::
	;~ gv.startMenu()
;~ return

;~ ^+c::gv.ListenForCommand()
^+!q::ExitApp
