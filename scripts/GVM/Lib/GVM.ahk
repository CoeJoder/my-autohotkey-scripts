/*
 ``````````````````````````````````````````````````````````````````````````````
 ` GVM
 ` Macro console for collaborative VMs.
 `
 ` Author: CoeJoder
 ``````````````````````````````````````````````````````````````````````````````
 */
#Include <ConsoleLogger>
#Include <JSON>
#Include <HtmlUtils>
#Include <MacroManager>

class GVM {
	static _WIN_TITLE := "GVM Client"
	static _CONSOLE_HEADER := "GVM Console"
	static _AHK_LIB_FOLDER := RelToAbs(A_ScriptDir, "..\..\Lib")
	static _CONSOLE_STYLESHEET := A_ScriptDir "\Assets\gvm.css"
	static _CONSOLE_JS := A_ScriptDir "\Assets\gvm.js"
	static _CONSOLE_TIMESTAMP := true
	static _CONSOLE_FONT := "Consolas"
	static _CONSOLE_FONT_SIZE := 14
	static _CONSOLE_INPUT_HEIGHT := 30
	static _SECRETS_JSON := A_ScriptDir "\secrets.json"
	static _MACRO_PARAM_ASSIGNMENT_REGEXP := "O)(\w+)\s*=\s*(\S+)"
	static _DEFAULT_SCREEN_RES := [640, 480]
	
	_macroManager := ""
	_vmScript := ""
	_targetWindowTitle := ""
	_sleepDelay := ""
	_rawSend := false
	
	; params for macro strings, configurable via console
	_macroParamKeys := ["hdd", "screenRes", "ftpUsername", "ftpPassword", "ftpServer", "ftpPath"]
	_macroParamValues := { this._macroParamKeys[1]: "C"
					, this._macroParamKeys[2]: StrJoin("x", GVM._DEFAULT_SCREEN_RES)
					, this._macroParamKeys[3]: "Anon"
					, this._macroParamKeys[4]: ""
					, this._macroParamKeys[5]: "ftp.server.com"
					, this._macroParamKeys[6]: "/" }
	
	__New(x, y, w, h, opacity:=0) {
		this.console := new ConsoleLogger(GVM._WIN_TITLE, GVM._AHK_LIB_FOLDER, x, y, w, h, opacity
				, GVM._CONSOLE_TIMESTAMP, GVM._CONSOLE_FONT, GVM._CONSOLE_FONT_SIZE, GVM._CONSOLE_INPUT_HEIGHT)
		this._macroManager := new MacroManager()
		this._LoadSecrets()
		this._PopulateMacros()
		this._RefreshPage()
		this.console.Show()
		this.console.EnableExceptionHandling(true)
		this.console.OnInput(ObjBindMethod(this, "_OnTextInput"), true)
		this.console.OnResize(ObjBindMethod(this, "_OnConsoleResize"), true)
	}
	
	_RefreshPage() {
		this.console.Clear()
		this.console.AddStylesheetElement(GVM._CONSOLE_STYLESHEET)
		this.console.AppendHtml(HtmlUtils.CenteredHeader(GVM._CONSOLE_HEADER))
		this._AppendMainSections()
	}
	
	_OnTextInput(str) {
		passThru := true
		if (str = "clear") {
			this._RefreshPage()
			passThru := false
		}
		else {
			; check if a macro param is being assigned
			RegExMatch(str, GVM._MACRO_PARAM_ASSIGNMENT_REGEXP, matches)
			if (matches.Count() = 2 && this._macroParamValues.HasKey(matches[1])) {
				this._macroParamValues[matches[1]] := matches[2]
				this._PopulateMacros()
				this._RefreshPage()
				passThru := false
			}
		}
		return passThru
	}
	
	_OnConsoleResize() {
		this.console.GetDocument().parentWindow.GVM.onConsoleResize()
	}
	
	_PopulateMacros() {
		mm := this._macroManager
		mm.ClearMacros()
		
		; parse the params
		screenRes := StrSplit(this._macroParamValues["screenRes"], "x")
		if (screenRes.MaxIndex() != 2) {
			this.console.AppendError("Expected format is ""screenRes = 1024x768"".")
			screenRes := GVM._DEFAULT_SCREEN_RES
			this._macroParamValues["screenRes"] := StrJoin("x", screenRes)
			Sleep, 3000
		}
		hdd := this._macroParamValues["hdd"]
		ftpUsername := this._macroParamValues["ftpUsername"]
		ftpPassword := this._macroParamValues["ftpPassword"]
		ftpServer := this._macroParamValues["ftpServer"]
		ftpPath := this._macroParamValues["ftpPath"]
		
		; add the formatted macros
		mm.AddMacro("cr.reg", "notepad", Format("
			(LTrim
			REGEDIT4
			
			[HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Hardware Profiles\0001\System\CurrentControlSet\Services\vmx\svga\Device0]
			""DefaultSettings.XResolution""=dword:{1:08x}
			""DefaultSettings.YResolution""=dword:{2:08x}
			)", screenRes*))
			
		mm.AddMacro("Create cr.reg", "cmd", Format("
			(LTrim
			echo REGEDIT4 >> {1}:\cr.reg & cls
			echo >> {1}:\cr.reg & cls
			echo [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Hardware Profiles\0001\System\CurrentControlSet\Services\vmx\svga\Device0] >> {1}:\cr.reg & cls
			echo ""DefaultSettings.XResolution""=dword:{2:08x} >> {1}:\cr.reg & cls
			echo ""DefaultSettings.YResolution""=dword:{3:08x} >> {1}:\cr.reg & cls
			exit
			)", hdd, screenRes*))
			
		mm.AddMacro("Run cr.reg", "run", Format("
			(LTrim
			regedit /S {1}:\cr.reg
			RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters
			exit
			)", hdd))
			
		mm.AddMacro("Download CoreFTP installer", "run", "iexplore ""http://www.coreftp.com/download/coreftplite.exe""")
		
		mm.AddMacro("Download files via FTP", "cmd", Format("
			(LTrim
			mkdir {1}:\g
			""{1}:\Program Files\CoreFTP\corecmd.exe"" -s -O -d ftp://{2}:{3}@{4}{5} -p {1}:\g\ & exit
			)", hdd, ftpUsername, ftpPassword, ftpServer, ftpPath))
			
		mm.AddMacro("Run config.reg", "cmd", Format("
			(LTrim
			regedit /S {1}:\g\config.reg
			RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters
			exit
			)", hdd))
			
		mm.AddMacro("Install Notepad++", "run", Format("{1}:\g\4.6.0_npp.4.6.Installer.exe", hdd))
		
		mm.AddMacro("Set dark theme for Notepad++", "cmd", Format("
			(LTrim
			copy {1}:\g\VS2015-Dark.xml ""{1}:\Program Files\Notepad{+}{+}\stylers.xml""
			copy {1}:\g\VS2015-Dark.xml ""%USERPROFILE%\Application Data\Notepad{+}{+}\stylers.xml""
			)", hdd))
			
		mm.AddMacro("Install AutoHotkey", "cmd", Format("{1}:\g\unzip {1}:\g\AutoHotkey104805.zip -d {1}:\AutoHotkey\ & exit", hdd))
		
		mm.AddMacro("Run FizzBuzz.ahk", "cmd", Format("{1}:\AutoHotkey\AutoHotkey.exe {1}:\g\fizzbuzz.ahk & exit", hdd))
		
		mm.AddMacro("Install emacs", "cmd", Format("
			(LTrim
			""{1}:\Program Files\CoreFTP\corecmd.exe"" -s -O -d ftp://ftp.gnu.org/gnu/windows/emacs/emacs-22/emacs-22.3-bin-i386.zip -p %USERPROFILE%\Desktop\
			{1}:\g\unzip %USERPROFILE%\Desktop\emacs-23.1-bin-i386.zip -d %USERPROFILE%\Desktop\emacs
			)", hdd))
	}
	
	_AppendMainSections() {
		static ROW_FMT2 := "<tr><td>{:s}</td><td>&nbsp;&nbsp;{:s}</td></tr>"
		static ROW_FMT3 := "<tr><td>{:s}</td><td>&nbsp;&nbsp;{:s} <span style=""color:peru;"">({:})</span></td></tr>"
		static HOTKEY_FMT1 := "<kbd>ctrl</kbd> + <kbd>shift</kbd> <kbd>c</kbd>, <kbd>{:s}</kbd>"
		static ROW_PARAM_FMT2 := "<tr><td>{}</td><td>&nbsp;= {}</td></h2></td></tr>"
		
		; macros
		html := "<div id=""container""><div class=""section""><h2>Macros: </h2><table cellspacing=""1"">"
		for index, macro in this._macroManager.GetMacros() {
			html .= Format(ROW_FMT3, Format(HOTKEY_FMT1, macro.commandKey), macro.title, macro.subtitle)
		}
		html .= "</table></div>"
		
		; macro params
		html .= "<div class=""section""><h2>Macro params: </h2><table cellspacing=""1"">"
		html .= "<tr><td></td></tr>"
		for index, paramKey in this._macroParamKeys {
			html .= Format(ROW_PARAM_FMT2, paramKey, HtmlUtils.SpanWithColor(this._macroParamValues[paramKey], "yellow"))
		}
		html .= "</table></div></div>"
		
		this.console.AppendHtml(html)
		this.console.AddScriptElement(GVM._CONSOLE_JS)
	}
	
	ListenForCommand() {
		this.console.Append("Listening for command...")
		Input, commandKey, L1 T5, {Esc}
		if (commandKey = "") {
			errorMsg := (InStr(ErrorLevel, ":Escape")) ? "Cancelled." : "Timed out."
			this.console.AppendWithColor("red", errorMsg)
		}
		else {
			macro := this._macroManager.GetMacroByCommandKey(commandKey)
			if (macro != "") {
				Loop, Parse, % macro.body, `n
				{
					this.Send(A_LoopField "{Enter}")
				}
			}
			else {
				this.console.AppendError(Format("Invalid command: ""{:s}""", commandKey))
			}
		}
	}
	
	_LoadSecrets() {
		file := GVM._SECRETS_JSON
		if (FileExist(file)) {
			strJson := ""
			if (FileExist(file)) {
				FileRead, strJson, %file%
				if (ErrorLevel) {
					throw Exception("Unable to open file.", file)
				}
			}
			obj := JSON.Load(strJson)
			for paramKey, paramVal in this._macroParamValues {
				if (obj.HasKey(paramKey)) {
					this._macroParamValues[paramKey] := obj[paramKey]
				}
			}
		}
	}
	
	;;;;; SETTERS ;;;;;
	
	SetSleepDelay(delayMs) {
		this._sleepDelay := delayMs
	}
	
	SetTargetWindowTitle(title) {
		this._targetWindowTitle := title
	}
	
	SetVmScript(script) {
		this._vmScript := script
	}
	
	EnableRawSend(isRaw) {
		this._rawSend := isRaw
	}
	
	;;;;; UTILITY METHODS ;;;;;
	
	Send(text) {
		if (this._rawSend) {
			Send, %text%
		}
		else {
			ControlSend, , %text%, % this._targetWindowTitle
		}
	}
	
	Sleep(override:="") {
		ms := (override != "") ? override : this._sleepDelay
		Sleep, %ms%
	}
	
	StartMenu() {
		this.Send("^{Esc}")
		this.Sleep()
	}
	
	RunWindow(command:="") {
		this.StartMenu()
		this.Send("r")
		this.Sleep()
		if (command != "") {
			this.Send(command "{ENTER}")
			this.Sleep()
		}
	}

	SingleLine(line) {
		Loop, Read, % this._vmScript
		{
			if (A_Index = line) {
				this.Send(A_LoopReadLine "{Enter}")
			}
		}
	}

	LineRange(start, last) {
		line := start
		Loop, Read, % this._vmScript
		{
			if (line > last)
				break
			if (A_Index = line) {
				this.Send(A_LoopReadLine "{Enter}")
				line := line + 1
			}
		}
	}
}
