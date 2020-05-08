/*
 ``````````````````````````````````````````````````````````````````````````````
 ` Starbot_main
 `
 ` Launches Starbot and configures the hotkeys.
 `
 ` Author: CoeJoder
 ``````````````````````````````````````````````````````````````````````````````
 */
#Warn All, StdOut
#Warn LocalSameAsGlobal, Off
#NoEnv
#SingleInstance Force
#Include <Starbot>
#Include <HtmlUtils>
#Include <QuickSort>
#Include %A_LineFile%\..\Strategies
;---------------------------------
; Strategy files:
;---------------------------------
#Include NewGodsLand\NewGodsLand.ahk
#Include PhantomAttackbot\PhantomAttackbot.ahk
#Include ZagaraCoop\ZagaraCoop.ahk
#Include DirectStrike\DirectStrike.ahk
#Include DummyStrat\DummyStrat.ahk

; settings
SetWorkingDir %A_ScriptDir%
CoordMode, Pixel, Window
CoordMode, Mouse, Window
SendMode, Input	; no delay
SetMouseDelay, 50
SetDefaultMouseSpeed, 1

; toggled by Pause/Break hotkey
global hotkeysEnabled:=true

; full screen console on 2nd monitor with 200/255 opacity
global sb := new Starbot(-3207, 0, 1598, 828, 200)

;---------------------------------
; Hotkeys:
;---------------------------------
^!+q::ExitApp
Pause::hotkeysEnabled:=!hotkeysEnabled

#If hotkeysEnabled && (!sb.handler || sb.handler.IsDone())
^+c::sb.ListenForCommand()

#If hotkeysEnabled && sb.handler && !sb.handler.IsDone()
;~ #If hotkeysEnabled && sb.handler && !sb.handler.IsDone() && WinActive(Starbot.STARCRAFT2_WIN_TITLE)
~LButton Up::sb.handler.Handle_LClick()
+~LButton Up::sb.handler.Handle_LClick()	; allow for holding shift
~RButton Up::sb.handler.Handle_RClick()
~`::sb.handler.Handle_Backtick()
+~`::sb.handler.Handle_Backtick()			; allow for holding shift
~^`::sb.handler.Handle_CtrlBacktick()
~^z::sb.handler.Handle_CtrlZ()

; if-expression for strategy-created hotkeys (must update Starbot.Action.AhkHotkey() if changed)
#If hotkeysEnabled && WinActive(Starbot.STARCRAFT2_WIN_TITLE)
