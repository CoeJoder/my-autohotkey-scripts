/*
 ``````````````````````````````````````````````````````````````````````````````
 ` starcraft2_lobby_tools.ahk
 ` Defines a keep-alive function and a cyclic lobby advertiser.  Both are set
 ` on a pseudo-random timer to avoid bot detection.
 `
 ` Author: CoeJoder
 ``````````````````````````````````````````````````````````````````````````````
 */
#NoEnv
#Warn LocalSameAsGlobal, Off
#SingleInstance Force
#Persistent
#Include <RandomTimer>
#Include <WinAPI>

SetKeyDelay, 50, 1

global winApi := new WinApi()
global title := "StarCraft II"
; coordinates of the chat box
global x := 1681 * 2		; graphics scaling = 200%
global y := 1407 * 2		; ditto
global interval := 5000	; milliseconds

sendKeys(title, keys) {
	ControlSend, , %keys%, %title%
}

advertiseLobby() {
	keys := "[lobby] {Enter}"
	fn := Func("sendKeys").Bind(title, keys)
	timer := new RandomTimer(fn, interval, 0, 10000)	; interval + [0-10] seconds
	timer.Start()
}

keepAlive() {
	fn := ObjBindMethod(winApi, "leftClick", title, x, y)
	timer := new RandomTimer(fn, interval, 0, 10000)	; interval + [0-10] seconds
	timer.Start()
}


keepAlive()
;~ advertiseLobby()

^!+q::ExitApp
