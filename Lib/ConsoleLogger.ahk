/*
 ``````````````````````````````````````````````````````````````````````````````
 ` ConsoleLogger
 ` Wrapper class for the AfterLemon `console` class.
 `
 ` *** TODO *** remove the AfterLemon dependency and make this standalone.
 ` 
 ` @author CoeJoder
 ``````````````````````````````````````````````````````````````````````````````
 */
#Include <Class_Console\Class_Console>
#include <AutoXYWH>

Class ConsoleLogger {
	static INSTANCE := "" ; lazy singleton
	static CONSOLE_INSTANCE_VARNAME := "ConsoleLogger_ConsoleObj"
	static JS_JQUERY := "\js\jquery-1.12.4.js"
	static JS_SHCORE := "\js\shCore.js"
	static JS_AHKBRUSH := "\js\shBrushAhk.js"
	static JS_ACTIVATE_SYNTAX_HIGHLIGHTER := "\js\activateSyntaxHighlighter.js"
	static CSS_SHCORE := "\css\shCore.css"
	static CSS_SHTHEME_ZENBURN := "\css\shThemeZenburn-A.css"
	
	_ahkLibDir := ""
	_guiTitle := ""
	_console := ""
	_document := ""
	_jqueryPath := ""
	_hwndDocument := ""
	_hwndEdit := ""
	_prevWaitCommand := ""
	_prevWaitImage := ""
	_logWaitRow := 0
	_onInput := "" ; null
	_onResize := "" ; null
	_enableExceptionHandling := True
	_persistentInputCallback := False
	
	__New(guiTitle, ahkLibDir, x, y, w, h, opacity:=200, timestamp:=true, font:="Consolas", fontSize:=10, inputH:=22) {
		ConsoleLogger.INSTANCE := this
		this._guiTitle := guiTitle
		this._ahkLibDir := ahkLibDir
		_name := ConsoleLogger.CONSOLE_INSTANCE_VARNAME
		Class_Console(_name, x, y, w, h, guiTitle, timestamp, "", font, fontSize, inputH, this)
		
		this._console := %_name%
		varDocument := this._console.edit
		this._document := %varDocument%
		this._hwndDocument := hwndDocument%_name%
		this._hwndEdit := hwndEdit%_name%
		
		this._console.show()
		
		; jQuery required for some methods
		this.AddJquery()
		
		; enable clipboard copying
		ComObjConnect(this._document, new this.Event())
		
		; opacity: 255 max
		if (opacity > 0) {
			WinSet, Transparent, %opacity%, % guiTitle
		}
		
		if (this._enableExceptionHandling) {
			OnError(ConsoleLogger._ExceptionHandler.bind(this))
		}
		return this
		
		ConsoleLogger_ConsoleObjGuiSize:
			if (A_EventInfo != 1) {	; if not minimized
				ConsoleLogger.INSTANCE._OnGuiSize()
			}
			return
		
		ConsoleLogger_ConsoleObjGuiClose:
			ExitApp
			return
	}
		
	__Delete() {
		; unhook the exception handler
		this.EnableExceptionHandling(False)
		this._console.Destroy()
	}
	
	; passed to OnError()
	_ExceptionHandler(e) {
		this.AppendException(e)
		return true	; exit current thread
	}
	
	EnableExceptionHandling(enableIt) {
		if (this._enableExceptionHandling != enableIt) {
			this._enableExceptionHandling := enableIt
			handler := ConsoleLogger._ExceptionHandler.bind(this)
			if (this._enableExceptionHandling) {
				OnError(handler)
			}
			else {
				OnError(handler, 0)
			}
		}
	}
	
	class Event {
		OnKeyPress(doc) {
			;~ static keys := {1:"selectall", 3:"copy", 22:"paste", 24:"cut"}
			static keys := {1: "selectall", 3: "copy"}
			keyCode := doc.parentWindow.event.keyCode
			if keys.HasKey(keyCode)
				doc.ExecCommand(keys[keyCode])
		}
	}
	
	Activate() {
		WinActivate, % this._guiTitle
	}
	
	FocusInput() {
		_hwnd := this._hwndEdit
		ControlFocus, , ahk_id %_hwnd%
	}
	
	AddScriptElement(src) {
		s := this._document.createElement("script")
		s.type := "text/javascript"
		s.src := src
		this._document.getElementsByTagName("head")[0].appendChild(s)
	}
	
	AddStylesheetElement(href) {
		s := this._document.createElement("link")
		s.type := "text/css"
		s.rel := "stylesheet"
		s.href := href
		this._document.getElementsByTagName("head")[0].appendChild(s)
	}
	
	AddJquery() {
		this.AddScriptElement(this._ahkLibDir . this.JS_JQUERY)
	}
	
	GetDocument() {
		return this._document
	}
	
	Debug(params*) {
		this._ResetLogWait()
		if (this._console) {
			this._console.Debug(params*)
		}
	}		
	
	StdOut(str, nl:=True) {
		this._ResetLogWait()
		this._StdOutImpl(str, nl)
	}
	
	Clear() {
		this._ResetLogWait()
		if (this._console) {
			this._console.Clear()
			this.AddJquery()
		}
	}
	
	SetColor(color) {
		this._console.color(color)
	}
		
	Log(params*) {
		this._ResetLogWait()
		if (this._console) {
			this._console.Log(params*)
		}
	}
	
	LogError(str) {
		this._ResetLogWait()
		if (this._console) {
			this._console.color("red")
			this._console.log("[ERROR] " . str)
			this._console.color("white")
		}
	}
	
	AppendError(str) {
		this._ResetLogWait()
		if (this._console) {
			this._console.color("red")
			this._console.Append("[ERROR] " . str)
			this._console.color("white")
		}
	}
	
	LogException(e) {
		this._ResetLogWait()
		;~ _errstr := "Exception thrown!`n`twhat: " e.what "`n`tfile: " e.file "`n`tline: " e.line "`n`tmessage: " e.message "`n`textra: " e.extra
		this.LogError(this._exceptionToString(e))
	}
	
	AppendException(e) {
		this._ResetLogWait()
		;~ _errstr := "Exception thrown!`n`twhat: " e.what "`n`tfile: " e.file "`n`tline: " e.line "`n`tmessage: " e.message "`n`textra: " e.extra
		this.AppendError(this._exceptionToString(e))
	}
	
	_exceptionToString(e) {
		static NL_TAB := "`n" "&nbsp;&nbsp;&nbsp;&nbsp;"
		return "Exception thrown!`n" NL_TAB "what: " e.what NL_TAB "file: " e.file NL_TAB "line: " e.line NL_TAB "message: " e.message NL_TAB "extra: " e.extra "`n"
	}
		
	Prepend(params*) {
		this._ResetLogWait()
		if (this._console) {
			this._console.Prepend(params*)
		}
	}
	
	Append(params*) {
		this._ResetLogWait()
		if (this._console) {
			this._console.Append(params*)
		}
	}
	
	AppendWithColor(color, params*) {
		this._ResetLogWait()
		this._console.color(color)
		this.Append(params*)
		this._console.color()	; default
	}
	
	AppendHtml(html) {
		this._ResetLogWait()
		if (this._console) {
			this._document.write(html)
			this._document.getElementById("bod").scrollIntoView(False)
		}
	}
	
	AppendImage(command, image:=0) {
		waitDivPrefix := "waitDiv_"
		if (this._prevWaitCommand = command 
				&& this._prevWaitImage = image) {
			
			this._StdOutImpl(".", False)
			if (this._console) {
				waitDiv := waitDivPrefix . this._logWaitRow
				this.GetDocument().parentWindow.jQuery("#" waitDiv).append("<span>.</span>")
			}
		}
		Else {
			this._StdOutImpl(command . (image ? " (" . image . ")" : ""))
			this._prevWaitCommand := command
			this._prevWaitImage := image
			if (this._console) {
				this._logWaitRow := this._console.line
				waitDiv := waitDivPrefix . this._logWaitRow
				
				html := "<div id=""" waitDiv """>"
				divClose := "</div>"
				if (image) {
					html .= "<img style=""vertical-align:middle"" src=""" . image . """ alt=""" . image . """>"
				}
				html .= "<span>" command "</span>" . divClose
				this._console.Append(html)
			}
		}
	}
	
	SetHtml(html) {
		this._ResetLogWait()
		if (this._console) {
			this._document.open()
			this._document.write(html)
			this._document.close()
		}
	}
	
	ExecuteJavaScript(js) {
		this._document.parentWindow.execScript(js)
	}
	
	; when text is entered into the console, callback will be passed the text as an argument
	; will be single-use unless `persistent` is set to true
	OnInput(callback, persistent:=False) {
		this._onInput := callback
		this._persistentInputCallback := persistent
	}
	
	CancelInput() {
		this._onInput := ""
	}
	
	; called by wrapped console obj
 	_OnConsoleInput(text) {
		this._ResetLogWait()
		_passThru := True
		if (this._onInput) {
			_passThru := this._onInput.Call(text)
		}
		if (!this._persistentInputCallback) {
			this._onInput := "" ; null
		}
		if (_passThru) {
			if (text = "clear") {
				this.Clear()
				_passThru := False
			}
		}
		return _passThru
	}
	
	; callback will run after the window is resized
	OnResize(callback) {
		this._onResize := callback
	}
	
	; called by GuiSize subroutine
	_OnGuiSize() {
		if (this._console) {
			AutoXYWH("*wh", this._hwndDocument)
			AutoXYWH("*yw", this._hwndEdit)
		}
		if (this._onResize) {
			this._onResize.Call()
		}
	}
	
	_ResetLogWait() {
		this._prevWaitCommand := 0
		this._prevWaitImage := 0
	}
	
	_StdOutImpl(str, nl:=True) {
		FileAppend, % (nl ? "`n" : "") . str, *
	}
	
	; test driver
	_Main() {
		obj := {a : "apple", b : "nom noms", c : ["hip", "hip", "hooray!"]}
		winTitle := "Test title"
		inst := new ConsoleLogger(winTitle, A_ScriptDir, 0, 0, 800, 500)
		
		inst.Log("log statement")
		inst.Log("log statement #2")
		inst.Append("append statement")
		inst.Append("append statement #2")
		
		inst.AppendImage("", "C:\Users\Joe\Downloads\Scv.png")
		inst.AppendImage("", "C:\Users\Joe\Documents\TEMPY\eyes.png")
		inst.AppendImage("", "C:\Users\Joe\Downloads\Scv.png")
		inst.AppendImage("", "C:\Users\Joe\Documents\TEMPY\eyes.png")

		inst._document.parentWindow.jQuery("body").append("<span>hello from jquery</span>")
		
		Loop, 10
		{
			inst.AppendImage("tester", "C:\Users\Joe\Downloads\Scv.png")
			Sleep 500
		}
		inst.Clear()
		Loop, 10
		{
			inst.AppendImage("tester", "C:\Users\Joe\Downloads\Scv.png")
			Sleep 500
		}
		Sleep, 1000
		;~ inst.AppendImage("tester", "")
		;~ inst.AppendImage("tester", "")
		;~ inst.AppendImage("tester", "")
		;~ inst.AppendImage("tester", "")
		;~ inst.AppendImage("tester", "")
		
		;~ inst.AppendImage("foster", "C:\Users\Joe\Downloads\Scv.png")
		;~ Sleep 500
		;~ inst.AppendImage("foster", "C:\Users\Joe\Downloads\Scv.png")
		;~ Sleep 500
		;~ inst.AppendImage("tester", "C:\Users\Joe\Downloads\Scv.png")
		;~ Sleep 500
		;~ inst.AppendImage("tester", "C:\Users\Joe\Downloads\Scv.png")
		;~ Sleep 500
		;~ html := "<pre><code>outterGoldBases := [""applesauce""`n`t, new Starbot_Point(12, 30)`n`t, A_Index]</code></pre>"
		;~ inst.AppendHtml(html)
		
		;~ inst.AddStylesheetElement("C:\Users\Joe\Documents\AutoHotkey\scripts\Starbot\Assets\webfontkit\stylesheet.css")
		
		;~ html := "<center><span style=""font-family: 'starcraftregular', sans-serif; font-size: 3em; color: yellow;"">OUCH!</span></center>"
		;~ inst.AppendHtml(html)
		
		WinWaitClose, % winTitle
		ExitApp
	}
}

; debugging
if (A_ScriptName="ConsoleLogger.ahk") {
	ConsoleLogger._Main()
}
