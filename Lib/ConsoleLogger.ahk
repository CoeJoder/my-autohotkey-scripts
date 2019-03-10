/*
 ``````````````````````````````````````````````````````````````````````````````
 ` ConsoleLogger
 
 ` Wrapper class for the AfterLemon `console` class.
 `
 ` *** TODO *** remove the AfterLemon dependency and make this standalone.
 ` 
 ` In order for resizing to work, you must define a GuiSize subroutine
 ` to handle resize events, then call OnResize().
 ` e.g.
 `
 ` log := new ConsoleLogger("Foobar", "/absolute/path/to/Lib")
 ` FoobarGuiSize:
 `     If (A_EventInfo = 1)	; window minimized
 `         Return
 `     log.OnResize()
 ` Return
 `
 ` @author jnasca
 ``````````````````````````````````````````````````````````````````````````````
 */
#Include <Class_Console>
#include <AutoXYWH>

Class ConsoleLogger {
	static JS_JQUERY := "\js\jquery-1.12.4.js"
	static JS_SHCORE := "\js\shCore.js"
	static JS_AHKBRUSH := "\js\shBrushAhk.js"
	static JS_ACTIVATE_SYNTAX_HIGHLIGHTER := "\js\activateSyntaxHighlighter.js"
	static CSS_SHCORE := "\css\shCore.css"
	static CSS_SHTHEME_ZENBURN := "\css\shThemeZenburn-A.css"
	
	Name := ""
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
	
	__New(name, libDir) {
		This.Name := name
		This._libDir := libDir
	}
		
	__Delete() {
		This._console.Destroy()
	}
	
	Show(x, y, w, h, guiTitle, timestamp:=true, html:="", font:="Consolas", fontSize:=10, inputH:=22) {
		name := This.Name
		If (!This._console) {
			This._guiTitle := guiTitle
			_conobj := Class_Console(name, x, y, w, h, guiTitle, timestamp, html, font, fontSize, inputH, this)
			
			This._console := %name%
			varDocument := This._console.edit
			This._document := %varDocument%
			This._hwndDocument := hwndDocument%name%
			This._hwndEdit := hwndEdit%name%
			
			This._console.show()

			; jquerify!
			This.AddJquery()
			; autohotkey syntax highlighting
			; TODO not compatible with MSHTML; find replacement
			;~ This._addScriptElement(This._libDir . This.JS_SHCORE)
			;~ This._addScriptElement(This._libDir . This.JS_AHKBRUSH)
			;~ This._addStylesheet(This._libDir . This.CSS_SHCORE)
			;~ This._addStylesheet(This._libDir . This.CSS_SHTHEME_ZENBURN)
			
			; enable clipboard copying
			ComObjConnect(this._document, new this.Event())
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
		WinActivate, % This._guiTitle
	}
	
	FocusInput() {
		_hwnd := This._hwndEdit
		ControlFocus, , ahk_id %_hwnd%
	}
	
	AddScriptElement(src) {
		s := This._document.createElement("script")
		s.type := "text/javascript"
		s.src := src
		This._document.getElementsByTagName("head")[0].appendChild(s)
	}
	
	AddStylesheetElement(href) {
		s := This._document.createElement("link")
		s.type := "text/css"
		s.rel := "stylesheet"
		s.href := href
		This._document.getElementsByTagName("head")[0].appendChild(s)
	}
	
	AddJquery() {
		This.AddScriptElement(This._libDir . This.JS_JQUERY)
	}
	
	GetDocument() {
		return This._document
	}
	
	; highlight AHK syntax in the HTML
	; TODO not compatible
	;~ HighlightSyntax() {
		;~ This._addScriptElement(This.JS_ACTIVATE_SYNTAX_HIGHLIGHTER)
	;~ }
		
	Debug(params*) {
		This._ResetLogWait()
		if (This._console) {
			This._console.Debug(params*)
		}
		;~ This._StdOutImpl(params*)
	}		
	
	StdOut(str, nl:=True) {
		This._ResetLogWait()
		This._StdOutImpl(str, nl)
	}
	
	Clear(params*) {
		This._ResetLogWait()
		if (This._console) {
			This._console.Clear(params*)
		}
	}
	
	SetColor(color) {
		This._console.color(color)
	}
		
	Log(params*) {
		This._ResetLogWait()
		if (This._console) {
			This._console.Log(params*)
		}
		;~ This._StdOutImpl(params*)
	}
	
	LogError(str) {
		This._ResetLogWait()
		If (This._console) {
			This._console.color("red")
			This._console.log("[ERROR] " . str)
			This._console.color("white")
		}
		;~ This._StdOutImpl("[ERROR] " . str)
	}
	
	AppendError(str) {
		This._ResetLogWait()
		If (This._console) {
			This._console.color("red")
			This._console.Append("[ERROR] " . str)
			This._console.color("white")
		}
		;~ This._StdOutImpl("[ERROR] " . str)
	}
	
	LogException(e) {
		This._ResetLogWait()
		;~ _errstr := "Exception thrown!`n`twhat: " e.what "`n`tfile: " e.file "`n`tline: " e.line "`n`tmessage: " e.message "`n`textra: " e.extra
		This.LogError(this._exceptionToString(e))
	}
	
	AppendException(e) {
		This._ResetLogWait()
		;~ _errstr := "Exception thrown!`n`twhat: " e.what "`n`tfile: " e.file "`n`tline: " e.line "`n`tmessage: " e.message "`n`textra: " e.extra
		This.AppendError(this._exceptionToString(e))
	}
	
	_exceptionToString(e) {
		static NL_TAB := "`n" "&nbsp;&nbsp;&nbsp;&nbsp;"
		return "Exception thrown!`n" NL_TAB "what: " e.what NL_TAB "file: " e.file NL_TAB "line: " e.line NL_TAB "message: " e.message NL_TAB "extra: " e.extra "`n"
	}
		
	Prepend(params*) {
		This._ResetLogWait()
		if (This._console) {
			This._console.Prepend(params*)
		}
		;~ This._StdOutImpl(params*)
	}
	
	Append(params*) {
		This._ResetLogWait()
		if (This._console) {
			This._console.Append(params*)
		}
		;~ This._StdOutImpl(params*)
	}
	
	AppendWithColor(color, params*) {
		This._ResetLogWait()
		This._console.color(color)
		This.Append(params*)
		This._console.color()	; default
	}
	
	AppendHtml(html) {
		This._ResetLogWait()
		If (This._console) {
			This._document.write(html)
			This._document.getElementById("bod").scrollIntoView(False)
		}
	}
	
	AppendImage(command, image:=0) {
		waitDivPrefix := "waitDiv_"
		If (This._prevWaitCommand = command 
				&& This._prevWaitImage = image) {
			
			This._StdOutImpl(".", False)
			if (This._console) {
				waitDiv := waitDivPrefix . This._logWaitRow
				js := "jQuery('#" waitDiv "').append('<span>.</span>');"
				This._document.parentWindow.execScript(js)
			}
		}
		Else {
			This._StdOutImpl(command . (image ? " (" . image . ")" : ""))
			This._prevWaitCommand := command
			This._prevWaitImage := image
			if (This._console) {
				This._logWaitRow := This._console.line
				waitDiv := waitDivPrefix . This._logWaitRow
				
				html := "<div id=""" waitDiv """>"
				divClose := "</div>"
				If (image) {
					html .= "<img style=""vertical-align:middle"" src=""" . image . """ alt=""" . image . """>"
				}
				html .= "<span>" command "</span>" . divClose
				This._console.Append(html)
			}
		}
	}
	
	SetHtml(html) {
		This._ResetLogWait()
		If (This._console) {
			This._document.open()
			This._document.write(html)
			This._document.close()
		}
	}
	
	ExecuteJavaScript(js) {
		This._document.parentWindow.execScript(js)
	}
	
	; bound func will be called with the text string as an argument
	GetInput(callback) {
		this._onInput := callback
	}
	
	CancelInput() {
		this._onInput := ""
	}
	
	; called by wrapped console obj
 	OnInput(text) {
		This._ResetLogWait()
		if (this._onInput) {
			try {
				this._onInput.Call(text)
			}
			finally {
				this._onInput := "" ; null
			}
			return 0
		}
		else {
			return 1 ; pass-thru
		}
	}
	
	OnResize() {
		If (This._console) {
			AutoXYWH("*wh", This._hwndDocument)
			AutoXYWH("*yw", This._hwndEdit)
		}
	}
	
	_ResetLogWait() {
		This._prevWaitCommand := 0
		This._prevWaitImage := 0
	}
	
	_StdOutImpl(str, nl:=True) {
		FileAppend, % (nl ? "`n" : "") . str, *
	}
	
	; test driver
	_Main() {
		obj := {a : "apple", b : "nom noms", c : ["hip", "hip", "hooray!"]}
		name := "el_llamador"		; if changed, also change the function name below
		winTitle := "BORG UPRISING"
		inst := new ConsoleLogger(name, A_ScriptDir)
		inst.Show(0, 0, 800, 500, winTitle)
		
		inst.Log("some")
		inst.Log("stuff")
		inst.Append("moar pwease")
		
		inst.AppendImage("", "C:\Users\Joe\Downloads\Scv.png")
		inst.AppendImage("", "C:\Users\Joe\Documents\TEMPY\eyes.png")
		inst.AppendImage("", "C:\Users\Joe\Downloads\Scv.png")
		inst.AppendImage("", "C:\Users\Joe\Documents\TEMPY\eyes.png")
		
		inst._document.parentWindow.jQuery("body").append("<span>holy shit it works...</span>")
		
		;~ inst.AppendImage("tester", "C:\Users\Joe\Downloads\Scv.png")
		;~ Sleep 500
		;~ inst.AppendImage("tester", "C:\Users\Joe\Downloads\Scv.png")
		;~ Sleep 500
		;~ inst.AppendImage("tester", "C:\Users\Joe\Downloads\Scv.png")
		;~ Sleep 500
		;~ inst.AppendImage("tester", "")
		;~ inst.AppendImage("tester", "")
		;~ inst.AppendImage("tester", "")
		;~ inst.AppendImage("tester", "")
		;~ inst.AppendImage("tester", "")
		;~ inst.Append("LOL")
		
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
		
		;~ inst.Append("LOL REALLY BRUH")
		;~ inst.Append("<span>LOL REALLY BRUH</span>")
		
		
		WinWaitClose, % winTitle
		ExitApp
		
		; put here to prevent namespace pollution
el_llamadorGuiSize:
	If (A_EventInfo = 1)	; minimized
		Return
	; `inst` is visible because `_Main` thread is paused
	inst.OnResize()
return

	}
}

; debugging
If (A_ScriptName="ConsoleLogger.ahk") {
	ConsoleLogger._Main()
}
