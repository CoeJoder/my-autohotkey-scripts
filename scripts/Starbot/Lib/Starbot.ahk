;**********************************************************************************
; Starbot
; 	Starcraft 2 Automation Tools.  This is the core library.
;
; Author: Joe Nasca
;**********************************************************************************
#Include <ConsoleLogger>
#Include <JSON>
#include <FunctionObject>
#Include <HtmlUtils>
#Include <IsValidFileName>
#Include <QuickSort>
#Include <InputBlocker>
#include <Gdip_All>
#include <Gdip_BitmapFromWindowArea>
#include <Gdip_ImageSearch>
#include <Gdip_GenerateDataUrlFromBitmap>

class Starbot {
	static STRATEGIES := []	; registered strategy classes
	static STARCRAFT2_WIN_TITLE := "StarCraft II"
	static ERROR_ABSTRACT_METHOD := "Abstract method must be implemented in subclass"
	static CONSOLE_INSTANCE := "" ; lazy init
	static CONSOLE_NAME := "StarbotConsole"
	static CONSOLE_WINTITLE := "Starbot Console"
	static CONSOLE_FONT := "Consolas"
	static CONSOLE_FONT_SIZE := 14
	static CONSOLE_INPUT_HEIGHT := 30
	static CONSOLE_STYLESHEET := "Assets\webfontkit\stylesheet.css"
	static MINIMAP_HBAR := "Assets\images\__minimap_hbar.png"
	static MINIMAP_VBAR := "Assets\images\__minimap_vbar.png"
	static CONFIG_FILE := "Starbot.json"
	static JSON_INDENT := 4
	static PAUSE_MS := 300
	static INPUT_BLOCKER_PASSWORD := ["Esc", "Esc"]
	static INPUT_BLOCKER := new InputBlocker(Starbot.INPUT_BLOCKER_PASSWORD)
	
	__New(_x, _y, _w, _h, _opacity:=0) {
		; console
		Starbot.CONSOLE_INSTANCE := new ConsoleLogger(Starbot.CONSOLE_NAME, RelToAbs(A_WorkingDir, "..\..\Lib"))
		this.console := Starbot.CONSOLE_INSTANCE
		this.console.Show(_x, _y, _w, _h, Starbot.CONSOLE_WINTITLE, true, ""
				, Starbot.CONSOLE_FONT, Starbot.CONSOLE_FONT_SIZE, Starbot.CONSOLE_INPUT_HEIGHT)
		if (_opacity > 0) {
			WinSet, Transparent, %_opacity%, % Starbot.CONSOLE_WINTITLE
		}
		this.console.OnResize()
		this.console.Clear()
		this.console.AddJquery()
		this.console.AddStylesheetElement(A_WorkingDir "\" Starbot.CONSOLE_STYLESHEET)
		this.console.AppendHtml(HtmlUtils.CenteredHeader(Format("{:U}", Starbot.__Class)))
		OnError(Starbot.HandleError.Bind(this))	; display Exceptions in the console
		; GDI+
		this.gdipToken := Gdip_Startup()
		OnExit(Starbot.StopGdiPlus.Bind(this))
		; init (global) strategy
		this.globalStrategy := new Starbot.GlobalStrategy(this.console)
		; command handler
		this.handler := ""	; null; set by hotkey
		; current strategy
		this.strategy := "" ; null
		; select first strategy by default, or (global) if none
		this.SelectStrategy(Starbot.STRATEGIES.Count() = 0 ? 1 : 2)
		this.isInstantiated := true
	}
	
	DisplayCommandPrompt() {
		static ROW_FMT2 := "<tr><td>{:s}</td><td>&nbsp;&nbsp;{:s}</td></tr>"
		static ROW_FMT3 := "<tr><td>{:s}</td><td>&nbsp;&nbsp;{:s} <span style=""color:peru;"">({:})</span></td></tr>"
		static HOTKEY_FMT1 := "<kbd>ctrl</kbd> + <kbd>shift</kbd> <kbd>c</kbd>, <kbd>{:s}</kbd>"
		
		_html := Format("<h2>Strategy: {:s}</h2><table cellspacing=""1"">", HtmlUtils.SpanWithColor(this.strategy.name, "yellow"))
		_html .= Format(ROW_FMT2, Format(HOTKEY_FMT1, "s"), "Strategy Picker...")
		_html .= Format(ROW_FMT2, Format(HOTKEY_FMT1, "a"), "Actions...")
		; include collector options if data is missing
		_missing := this.strategy.GetNumberOfMissingPoints()
		if (_missing > 0)
			_html .= Format(ROW_FMT3, Format(HOTKEY_FMT1, "p"), "Point Collector", _missing)
		_missing := this.strategy.GetNumberOfMissingRects()
		if (_missing > 0)
			_html .= Format(ROW_FMT3, Format(HOTKEY_FMT1, "r"), "Rect Collector", _missing)
		_missing := this.strategy.GetNumberOfMissingCoords()
		if (_missing > 0)
			_html .= Format(ROW_FMT3, Format(HOTKEY_FMT1, "c"), "Coords Collector", _missing)
		_missing := this.strategy.GetNumberOfMissingImages()
		if (_missing > 0)
			_html .= Format(ROW_FMT3, Format(HOTKEY_FMT1, "i"), "Image Collector", _missing)
		_html .= "</table>"
		this.console.AppendHtml(_html)
	}
	
	ListenForCommand() {
		this.console.Append("Listening for command...")
		Input, commandKey, L1 T5, {Esc}
		if (commandKey = "") {
			_msg := (InStr(ErrorLevel, ":Escape")) ? "Cancelled." : "Timed out."
			this.console.AppendWithColor("red", _msg)
		}
		else {
			if (commandKey = "s") {
				this.PromptForStrategy()
			}
			else if (commandKey = "a") {
				this.handler := this.strategy
				this.handler.Handle_Trigger()
			}
			else if (commandKey = "p") {
				this.handler := new Starbot.PointCollector(this.console, this.strategy)
				this.handler.Handle_Trigger()
			}
			else if (commandKey = "r") {
				this.handler := new Starbot.RectCollector(this.console, this.strategy)
				this.handler.Handle_Trigger()
			}
			else if (commandKey = "c") {
				this.handler := new Starbot.CoordCollector(this.console, this.strategy)
				this.handler.Handle_Trigger()
			}
			else if (commandKey = "i") {
				this.handler := new Starbot.ImageCollector(this.console, this.strategy)
				this.handler.Handle_Trigger()
			}
			else {
				this.console.AppendError(Format("Invalid command: ""{:s}""", commandKey))
			}
		}
	}
	
	PromptForStrategy() {
		static TAB := "&nbsp;&nbsp;&nbsp;&nbsp;"
		_text := ""
		for _i, _name in this._getStrategyNames() {
			_text .= TAB _i ") " HtmlUtils.SpanWithColor(_name, "lime") "`n"
		}
		_text := SubStr(_text, 1, -1)	; trim last newline
		this.console.Append("Choose a strategy:`n" . _text)
		this.console.Activate()
		this.console.FocusInput()
		this.console.GetInput(ObjBindMethod(this, "SelectStrategy"))
	}
	
	_getStrategyNames() {
		_strategyNames := [Starbot.GlobalStrategy.NAME]
		for _i, _impl in Starbot.STRATEGIES {
			_strategyNames.Push(_impl.__Class)
		}
		return _strategyNames
	}
	
	SelectStrategy(_nameOrIndex) {
		_strategyIndex := ""
		_strategyName := ""
		for _i, _name in this._getStrategyNames() {
			; match by name or index
			if ((_i = _nameOrIndex) || (_name = _nameOrIndex)) {
				_strategyIndex := _i
				_strategyName := _name
				break
			}
		}
		if (!_strategyName) {
			this.console.AppendError(Format("Invalid strategy: ""{:s}""", _nameOrIndex))
		}
		else {
			if (_strategyIndex = 1) {
				this.strategy := this.globalStrategy
			}
			else {
				_impl := Starbot.STRATEGIES[_strategyIndex - 1]
				if (!_impl)
					throw Exception("Strategy not registered.", _strategyName)
				_strategy := new _impl(_strategyName, this.console, this.globalStrategy.data)
				if (!IsObject(_strategy))
					throw Exception("Failed to instantiate strategy object.", _strategyName)
				this.strategy := _strategy
			}
			this.DisplayCommandPrompt()
		}
	}
	
	; called on exit
	StopGdiPlus() {
		if (this.gdipToken)
			Gdip_Shutdown(this.gdipToken)
	}
	
	; exception handler
	HandleError(e) {
		this.handler.done := true
		this.console.AppendException(e)
		if (!this.isInstantiated)
			Suspend, On	; restart required
		return true	; exit current thread
	}
	
	; [static] Registers a strategy in static memory (necessary hack for IoC)
	RegisterStrategy(_impl) {
		Starbot.STRATEGIES.Push(_impl)
	}
	
	; [static] sleep method which checks for interrupts
	Nap(_millis:=0) {
		if (Starbot.INPUT_BLOCKER.IsInterrupted())
			Exit
		Sleep, % _millis ? _millis : Starbot.PAUSE_MS
		if (Starbot.INPUT_BLOCKER.IsInterrupted())
			Exit
	}
	
	; never called; for GUI subroutine encapsulation only
	_guiSubroutines() {
		return
StarbotConsoleGuiSize:
	If (A_EventInfo != 1) {	; if not minimized
		Starbot.CONSOLE_INSTANCE.OnResize()
	}
Return
StarbotConsoleGuiClose:
	ExitApp
Return
	}
	
	class Point {
		__New(_x, _y) {
			this.x := _x
			this.y := _y
		}
		
		Up(_pixels) {
			return new Starbot.Point(this.x, this.y - _pixels)
		}
		
		Down(_pixels) {
			return new Starbot.Point(this.x, this.y + _pixels)
		}
		
		Left(_pixels) {
			return new Starbot.Point(this.x - _pixels, this.y)
		}
		
		Right(_pixels) {
			return new Starbot.Point(this.x + _pixels, this.y)
		}
		
		MouseTo(doSleep:=true) {
			MouseMove, % this.x, % this.y
			if (doSleep)
				Starbot.Nap()
			return this
		}
		
		LClick(doSleep:=true) {
			static count := 0
			;~ this.MouseTo(doSleep)
			Send, % "{Click, " this.x ", " this.y ", left}"
			if (doSleep)
				Starbot.Nap()
			return this
		}
		
		RClick(doSleep:=true) {
			;~ this.MouseTo(doSleep)
			Send, % "{Click, " this.x ", " this.y ", right}"
			if (doSleep)
				Starbot.Nap()
			return this
		}
		
		DragSelect(_radius:=20, _doSleep:=true) {
			_x1 := this.x - _radius
			_y1 := this.y - _radius
			_x2 := this.x + _radius
			_y2 := this.y + _radius
			MouseClickDrag, Left, %_x1%, %_y1%, %_x2%, %_y2%
			if _doSleep
				Starbot.Nap()
			return this
		}
		
		LineTo(_point) {
			return new Starbot.Line(this, _point)
		}
		
		MidwayTo(_point) {
			_x := (this.x + _point.x) / 2
			_y := (this.y + _point.y) / 2
			return new Starbot.Point(_x, _y)
		}
		
		ToString() {
			return Format("(x={:s}, y={:s})", this.x, this.y)
		}
		
		; sorting comparator
		class HorizontalCompare extends FunctionObject {
			Call(_p1, _p2) {
				return (_p1.x > _p2.x) ? 1 : (_p1.x < _p2.x) ? -1 : 0
			}
		}
		
		; sorting comparator
		class VerticalCompare extends FunctionObject {
			Call(_p1, _p2) {
				return (_p1.y > _p2.y) ? 1 : (_p1.y < _p2.y) ? -1 : 0
			}
		}
		
		; sorting comparator
		class HorizontalThenVerticalCompare extends FunctionObject {
			Call(_p1, _p2) {
				return (_p1.x > _p2.x) ? 1 : (_p1.x < _p2.x) ? -1 
						: (_p1.y > _p2.y) ? 1 : (_p1.y < _p2.y) ? -1 : 0
			}
		}
		
		; sorting comparator
		class VerticalThenHorizontalCompare extends FunctionObject {
			Call(_p1, _p2) {
				return (_p1.y > _p2.y) ? 1 : (_p1.y < _p2.y) ? -1 
						: (_p1.x > _p2.x) ? 1 : (_p1.x < _p2.x) ? -1 : 0
			}
		}
	}
	
	class Line {
		__New(_p1, _p2) {
			this.p1 := _p1
			this.p2 := _p2
		}
		
		MidPoint() {
			return this.p1.MidwayTo(this.p2)
		}
		
		IntersectionWith(_line) {
			; use determinants
			x1 := this.p1.x
			y1 := this.p1.y
			x2 := this.p2.x
			y2 := this.p2.y
			x3 := _line.p1.x
			y3 := _line.p1.y
			x4 := _line.p2.x
			y4 := _line.p2.y
			px := ((x1*y2 - y1*x2)*(x3 - x4) - (x1 - x2)*(x3*y4 - y3*x4))
					/ ((x1 - x2)*(y3 - y4) - (y1 - y2)*(x3 - x4))
			py := ((x1*y2 - y1*x2)*(y3 - y4) - (y1 - y2)*(x3*y4 - y3*x4))
					/ ((x1 - x2)*(y3 - y4) - (y1 - y2)*(x3 - x4))
			return new Starbot.Point(px, py)
		}
		
		ToString() {
			_p1 := this.p1.ToString()
			_p2 := this.p2.ToString()
			return Format("p1={:s}, p2={:s}", _p1, _p2)
		}
		
		Clone() {
			return new Starbot.Line(this.p1.Clone(), this.p2.Clone())
		}
	}

	class Coord {
		__New(_minimap, _battlefield) {
			this.minimap := _minimap
			this.battlefield := _battlefield
		}
		
		OnScreen() {
			this.minimap.LClick()
			return this
		}
		
		ToString() {
			_mm := this.minimap.ToString()
			_bf := StrJoin(", ", this.battlefield, Starbot.Point.ToString)
			return Format("minimap={:s}, battlefield=[{:s}]", _mm, _bf)
		}
		
		Clone() {
			_mmClone := this.minimap.Clone()
			_bfClone := []
			for _i, _pt in this.battlefield
				_bfClone.Push(_pt.Clone())
			return new Starbot.Coord(_mmClone, _bfClone)
		}
	}

	class Rect {
		__New(_topLeft, _bottomRight) {
			this.topLeft := _topLeft
			this.bottomRight := _bottomRight
		}
		
		; [static] get Rect containing the given points
		From(_points*) {
			static MAX_INTEGER := 0x7FFFFFFFFFFFFFFF
			static MIN_INTEGER := -0x8000000000000000
			_minX := MAX_INTEGER
			_minY := MAX_INTEGER
			_maxX := MIN_INTEGER
			_maxY := MIN_INTEGER
			for _i, _point in _points {
				_minX := Min(_minX, _point.x)
				_minY := Min(_minY, _point.y)
				_maxX := Max(_maxX, _point.x)
				_maxY := Max(_maxY, _point.y)
			}
			return new this(new Starbot.Point(_minX, _minY), new Starbot.Point(_maxX, _maxY))
		}
		
		DragSelect(_padding:=0, _doSleep:=true) {
			_x1 := this.topLeft.x - _padding
			_y1 := this.topLeft.y - _padding
			_x2 := this.bottomRight.x + _padding
			_y2 := this.bottomRight.y + _padding
			MouseClickDrag, Left, %_x1%, %_y1%, %_x2%, %_y2%
			if _doSleep
				Starbot.Nap()
		}
		
		GetWidth() {
			return this.bottomRight.x - this.topLeft.x
		}
		
		GetHeight() {
			return this.bottomRight.y - this.topLeft.y
		}
		
		Center() {
			return this.topLeft.MidwayTo(this.bottomRight)
		}
		
		Contains(_point) {
			return _point.x > this.topLeft.x
				&& _point.x < this.bottomRight.x
				&& _point.y > this.topLeft.y
				&& _point.y < this.bottomRight.y
		}
		
		SaveScreenshotTo(_filePath) {
			try {
				_pBitmap := this._getScreenshot()
				_errcode := Gdip_SaveBitmapToFile(_pBitmap, _filePath)
				if (_errCode < 0)
					throw Exception("Failed to save screenshot to disk.", _filePath, _errCode)
			}
			finally {
				Gdip_DisposeImage(_pBitmap)
			}
		}
		
		GetScreenshotAsDataUrl() {
			try {
				_pBitmap := this._getScreenshot()
				return Gdip_GenerateDataUrlFromBitmap(_pBitmap, "PNG")
			}
			finally {
				Gdip_DisposeImage(_pBitmap)
			}
		}
		
		_getScreenshot() {
			; caller is responsible for disposing of image
			WinGet, hwnd, ID, A
			_w := this.bottomRight.x - this.topLeft.x
			_h := this.bottomRight.y - this.topLeft.y
			pBitmap := Gdip_BitmapFromWindowArea(hwnd, this.topLeft.x, this.topLeft.y, _w, _h)
			if (pBitmap = -1)
				throw Exception("Failed to take screenshot.", this.ToString())
			return pBitmap
		}
		
		ToString() {
			_tl := this.topLeft.ToString()
			_br := this.bottomRight.ToString()
			return Format("topLeft={:s}, bottomRight={:s}", _tl, _br)
		}
		
		Clone() {
			return new Starbot.Rect(this.topLeft.Clone(), this.bottomRight.Clone())
		}
	}
	
	class ImageQuery {
		__New(_path, _dims, _searchContext) {
			this.path := _path
			this.dims := _dims
			this.searchContext := _searchContext
		}
		
		Clone() {
			return new Starbot.ImageQuery(this.path, this.dims.Clone(), this.searchContext.Clone())
		}
	}
	
	; strategy data model
	class Json {
		points := {}
		coords := {}
		rects := {}
		imageQueries := {}
		
		; non-overwriting deep merge from parent into this
		ExtendFrom(_parent) {
			_obj := new Starbot.Json()
			for _key, _point in _parent.points
				if (!this.points.HasKey(_key))
					this.points[_key] := _point.Clone()
			for _key, _coord in _parent.coords
				if (!this.coords.HasKey(_key))
					this.coords[_key] := _coord.Clone()
			for _key, _rects in _parent.rects
				if (!this.rects.HasKey(_key))
					this.rects[_key] := _rects.Clone()
			for _key, _imageQuery in _parent.imageQueries
				if (!this.imageQueries.HasKey(_key))
					this.imageQueries[_key] := _imageQuery.Clone()
		}
		
		; Deserialization behavior for JSON.Load()
		class Reviver extends FunctionObject {
			Call(obj, key, val) {
				if (val.HasKey("x") && val.HasKey("y")) {
					return new Starbot.Point(val.x, val.y)
				}
				else if (val.HasKey("minimap") && val.HasKey("battlefield")) {
					return new Starbot.Coord(val.minimap, val.battlefield)
				}
				else if (val.HasKey("topLeft") && val.HasKey("bottomRight")) {
					return new Starbot.Rect(val.topLeft, val.bottomRight)
				}
				else if (val.HasKey("path") && val.HasKey("dims") && val.HasKey("searchContext")) {
					return new Starbot.ImageQuery(val.path, val.dims, val.searchContext)
				}
				else if (val.HasKey("points") && val.HasKey("coords") && val.HasKey("rects") && val.HasKey("imageQueries")) {
					_data := new Starbot.Json()
					_data.points := val.points
					_data.coords := val.coords
					_data.rects := val.rects
					_data.imageQueries := val.imageQueries
					return _data
				}
				else {
					return val
				}
			}
		}
		
		; [static] Parse a .json file
		Read(_file) {
			_json := ""
			if (FileExist(_file)) {
				FileRead, _json, %_file%
				if (ErrorLevel) {
					throw Exception("Unable to open file.", _file)
				}
			}
			if (!_json) {
				_obj := new Starbot.Json()
			}
			else {
				_obj := JSON.Load(_json, new Starbot.Json.Reviver())
				if (_obj.__Class != "Starbot.Json") {
					throw Exception("Failed to parse file: " . _file)
				}
			}
			return _obj
		}
		
		; [static] stringify and write to disk
		Write(_obj, _file) {
			_json := JSON.Dump(_obj, , Starbot.JSON_INDENT)
			_fw := FileOpen(_file, "w")
			if (!_fw) {
				throw Exception("Unable to write file.", _file, A_LastError)
			}
			_fw.Write(_json)
			_fw.Close()
		}
	}
	
	;--------------------------------------------------------
	; [abstract] Handler
	;   Base class for hotkey-managed tasks.
	;--------------------------------------------------------
	class Handler {
		__New(_console) {
			this.console := _console
			this.done := false
		}
		
		; true when task is complete
		IsDone() {
			Critical
			return this.done
		}
		
		; the startup method
		Handle_Trigger() {
			throw Exception(Starbot.ERROR_ABSTRACT_METHOD, A_ThisFunc)
		}
		
		Handle_Backtick() {
			; no-op
		}
		
		Handle_CtrlBacktick() {
			; no-op
		}
		
		Handle_CtrlZ() {
			; no-op
		}
		
		Handle_LClick() {
			; no-op
		}
		
		Handle_RClick() {
			; no-op
		}
	}
	
	;--------------------------------------------------------
	; [abstract] AbstractCollector
	;	Left-click to capture, backtick to process captured points, 
	;	ctrl-Z to undo, ctrl-backtick to cancel.
	;--------------------------------------------------------
	class AbstractCollector extends Starbot.Handler {
		__New(_console) {
			base.__New(_console)
			this.points := []
		}
		
		Handle_Trigger() {
			Critical
			this._startup()
		}
		
		Handle_LClick() {
			Critical
			this._capturePoint()
		}
		
		Handle_Backtick() {
			Critical
			this._processPoints()
		}
		
		Handle_CtrlBacktick() {
			Critical
			this._cancel()
		}
		
		Handle_CtrlZ() {
			Critical
			this._undo()
		}
		
		_startup() {
			throw Exception(Starbot.ERROR_ABSTRACT_METHOD, A_ThisFunc)
		}
		
		_cancel() {
			this.done := true
			this.console.AppendWithColor("red", "Cancelled.")
		}
		
		_capturePoint() {
			if (!this.IsDone()) {
				MouseGetPos, _x, _y
				this.points.Push(new Starbot.Point(_x, _y))
			}
		}
		
		_processPoints() {
			if (!this.IsDone()) {
				this._pointsCollected()
				this.points := []
			}
		}
		
		_pointsCollected() {
			throw Exception(Starbot.ERROR_ABSTRACT_METHOD, A_ThisFunc)
		}
		
		_undo() {
			throw Exception(Starbot.ERROR_ABSTRACT_METHOD, A_ThisFunc)
		}
	}
	
	;--------------------------------------------------------
	; PointCollector
	;   Captures Points.
	;--------------------------------------------------------
	class PointCollector extends Starbot.AbstractCollector {
		__New(_console, _strategy) {
			base.__New(_console)
			this.strategy := _strategy
			this.pointCount := 0
			this.labels := []
			this.curLabelIndex := 0
			this.curPoint := "" ; null
			this.confirmed := false
		}
		
		Handle_LClick() {
			; no-op
		}
		
		Handle_Backtick() {
			Critical
			if (!this.curPoint) {
				this._capturePoint()
			}
			this._processPoints()
		}
		
		_startup() {
			this.strategy.ReloadData()
			this.console.Append(HtmlUtils.SpanWithColor("Point Collector", "yellow"))
			for i, _pointLabel in this.strategy.GetPointLabels() {
				if (!this.strategy.data.points.HasKey(_pointLabel)) {
					this.labels.Push(_pointLabel)
				}
			}
			if (this.labels.Length() = 0) {
				this.console.Append("Already done.  Delete points from the .json file to recapture them.")
				this.console.Append(Format("No changes made to {:s}"
						, HtmlUtils.SpanWithColor(this._getRelativeFilePath(), "peru")))
				this.done := true
			}
			else {
				this.console.Append("Press backtick to set points, Ctrl-z to undo, and Ctrl-backtick to cancel.")
				; kick-start the capture process
				this._promptNextPoint()
			}
		}
		
		_pointsCollected() {
			if (this.points.Length() > 0) {
				if (!this.curTopLeft) {
					; `point` chosen
					this.curTopLeft := this.points.Pop()
					this._logPoint(this.curPoint)
					this._promptConfirm()
				}
			}
			if (this.curPoint) {
				if (!this.confirmed) {
					this.confirmed := true
				}
				else {
					_curLabel := this.labels[this.curLabelIndex]
					this.strategy.data.points[_curLabel] := this.curPoint
					this.pointCount++
					this.curPoint := "" ; null
					; go to next label
					if (this.curLabelIndex < this.labels.Length()) {
						this._promptNextPoint()
					}
					else if (this.pointCount > 0) {
						; merge new points with existing ones
						Starbot.Json.Write(this.strategy.data, this.strategy.dataFile)
						this.console.Append(Format("Added {:s} point{:s} to {:s}"
								, HtmlUtils.SpanWithColor(this.pointCount, "peru")
								, (this.pointCount = 1 ? "" : "s")
								, HtmlUtils.SpanWithColor(this._getRelativeFilePath(), "peru")))
						this.done := true
					}
					else {
						this.console.Append(Format("No changes made to {:s}", HtmlUtils.SpanWithColor(this._getRelativeFilePath(), "peru")))
						this.done := true
					}
				}
			}
		}
		
		_undo() {
			this.points := []
			if (!this.curPoint) {
				; "undo" invoked @ `point` prompt
				if (this.curLabelIndex > 1) {
					; go back to previous point
					this.console.GetDocument().parentWindow
							.jQuery("span.pointcollector_point:last, span.pointcollector_pointname:last").closest("p").remove()
					this.curPoint := ""
					this.pointCount--
					this.curLabelIndex--
					this._promptClick("point")
				}
				else {
					; can't undo; at beginning.  Maybe play the windows `ding!`?
				}
			}
			else {
				; "undo" invoked @ confirmation prompt
				; go back to `point` prompt
				this.console.GetDocument().parentWindow
						.jQuery("span.pointcollector_confirm:last, span.pointcollector_point:last").closest("p").remove()
				this.curPoint := ""
				this._promptClick("point")
			}
		}
		
		_getRelativeFilePath() {
			return "." . SubStr(this.strategy.dataFile, StrLen(A_WorkingDir)+1)
		}
		
		_promptNextPoint() {
			this.confirmed := false
			this.console.Append(Format("<span class=""pointcollector_pointname"">Next: {:s}</span>"
					, HtmlUtils.SpanWithColor(this.labels[++this.curLabelIndex], "peru")))
			this._promptClick("point")
			WinActivate, % Starbot.STARCRAFT2_WIN_TITLE
		}
		
		_promptClick(_pointName) {
			this.console.Append(Format("<span class=""pointcollector_point"">&nbsp;&nbsp;&nbsp;&nbsp;{:s}: </span>"
			, HtmlUtils.SpanWithColor(_pointName, "yellow")))
		}
		
		_promptConfirm() {
			this.console.Append("<span class=""pointcollector_confirm"">&nbsp;&nbsp;&nbsp;&nbsp;Press `` to confirm...</span>")
		}
		
		_logPoint(_point) {
			this.console.GetDocument().parentWindow
					.jQuery("span.pointcollector_point:last").append(HtmlUtils.SpanWithColor(_point.ToString(), "lime"))
		}
	}
	
	;--------------------------------------------------------
	; RectCollector
	;   Captures Rects.
	;--------------------------------------------------------
	class RectCollector extends Starbot.AbstractCollector {
		__New(_console, _strategy) {
			base.__New(_console)
			this.strategy := _strategy
			this.rectCount := 0
			this.labels := []
			this.curLabelIndex := 0
			this.curTopLeft := "" ; null
			this.curBottomRight := "" ; null
			this.confirmed := false
		}
		
		Handle_LClick() {
			; no-op
		}
		
		Handle_Backtick() {
			Critical
			if (!(this.curTopLeft && this.curBottomRight)) {
				this._capturePoint()
			}
			this._processPoints()
		}
		
		_startup() {
			this.strategy.ReloadData()
			this.console.Append(HtmlUtils.SpanWithColor("Rect Collector", "yellow"))
			for i, _rectLabel in this.strategy.GetRectLabels() {
				if (!this.strategy.data.rects.HasKey(_rectLabel)) {
					this.labels.Push(_rectLabel)
				}
			}
			if (this.labels.Length() = 0) {
				this.console.Append("Already done.  Delete rects from the .json file to recapture them.")
				this.console.Append(Format("No changes made to {:s}"
						, HtmlUtils.SpanWithColor(this._getRelativeFilePath(), "peru")))
				this.done := true
			}
			else {
				this.console.Append("Press backtick to set points, Ctrl-z to undo, and Ctrl-backtick to cancel.")
				; kick-start the capture process
				this._promptNextRect()
			}
		}
		
		_pointsCollected() {
			if (this.points.Length() > 0) {
				if (!this.curTopLeft) {
					; `top-left` chosen
					this.curTopLeft := this.points.Pop()
					this._logPoint(this.curTopLeft)
					this._promptClick("bottom-right")
				}
				else if (!this.curBottomRight) {
					; `bottom-right` chosen
					this.curBottomRight := this.points.Pop()
					this._logPoint(this.curBottomRight)
					this._promptConfirm()
				}
			}
			if (this.curTopLeft && this.curBottomRight) {
				if (!this.confirmed) {
					this.confirmed := true
				}
				else {
					_curLabel := this.labels[this.curLabelIndex]
					_rect := new Starbot.Rect(this.curTopLeft, this.curBottomRight)
					this.strategy.data.rects[_curLabel] := _rect
					this.rectCount++
					this.curTopLeft := "" ; null
					this.curBottomRight := "" ; null
					; go to next label
					if (this.curLabelIndex < this.labels.Length()) {
						this._promptNextRect()
					}
					else if (this.rectCount > 0) {
						; merge new rects with existing ones
						Starbot.Json.Write(this.strategy.data, this.strategy.dataFile)
						this.console.Append(Format("Added {:s} rect{:s} to {:s}"
								, HtmlUtils.SpanWithColor(this.rectCount, "peru")
								, (this.rectCount = 1 ? "" : "s")
								, HtmlUtils.SpanWithColor(this._getRelativeFilePath(), "peru")))
						this.done := true
					}
					else {
						this.console.Append(Format("No changes made to {:s}", HtmlUtils.SpanWithColor(this._getRelativeFilePath(), "peru")))
						this.done := true
					}
				}
			}
		}
		
		_undo() {
			this.points := []
			if (!this.curTopLeft) {
				; "undo" invoked @ `top-left` prompt
				if (this.curLabelIndex > 1) {
					; go back to previous rect
					this.console.GetDocument().parentWindow
							.jQuery("span.rectcollector_point:last, span.rectcollector_rect:last").closest("p").remove()
					_curRect := this.strategy.data.rects[this.labels[this.curLabelIndex]]
					this.curTopLeft := _curRect.topLeft
					this.curBottomRight := ""
					this.rectCount--
					this.curLabelIndex--
					this._promptClick("bottom-right")
				}
				else {
					; can't undo; at beginning.  Maybe play the windows `ding!`?
				}
			}
			else if (!this.curBottomRight) {
				; "undo" invoked @ `bottom-right` prompt
				; go back to `top-left` prompt
				this.console.GetDocument().parentWindow
						.jQuery("span.rectcollector_point").slice(-2).closest("p").remove()
				this.curTopLeft := ""
				this._promptClick("top-left")
			}
			else {
				; "undo" invoked @ confirmation prompt
				; go back to `bottom-right` prompt
				this.console.GetDocument().parentWindow
						.jQuery("span.rectcollector_confirm:last, span.rectcollector_point:last").closest("p").remove()
				this.curBottomRight := ""
				this._promptClick("bottom-right")
			}
		}
		
		_getRelativeFilePath() {
			return "." . SubStr(this.strategy.dataFile, StrLen(A_WorkingDir)+1)
		}
		
		_promptNextRect() {
			this.confirmed := false
			this.console.Append(Format("<span class=""rectcollector_rect"">Next: {:s}</span>"
					, HtmlUtils.SpanWithColor(this.labels[++this.curLabelIndex], "peru")))
			this._promptClick("top-left")
			WinActivate, % Starbot.STARCRAFT2_WIN_TITLE
		}
		
		_promptClick(_pointName) {
			this.console.Append(Format("<span class=""rectcollector_point"">&nbsp;&nbsp;&nbsp;&nbsp;{:s}: </span>"
			, HtmlUtils.SpanWithColor(_pointName, "yellow")))
		}
		
		_promptConfirm() {
			this.console.Append("<span class=""rectcollector_confirm"">&nbsp;&nbsp;&nbsp;&nbsp;Press `` to confirm...</span>")
		}
		
		_logPoint(_point) {
			this.console.GetDocument().parentWindow
					.jQuery("span.rectcollector_point:last").append(HtmlUtils.SpanWithColor(_point.ToString(), "lime"))
		}
	}
	
	;--------------------------------------------------------
	; CoordCollector
	;   Records coordinates and writes them to a .json file
	;--------------------------------------------------------
	class CoordCollector extends Starbot.AbstractCollector {
		__New(_console, _strategy) {
			base.__New(_console)
			this.strategy := _strategy
			this.coordCount := 0
			this.labels := []
			this.skippedLabels := {}
			this.curLabelIndex := 0
			this.curCoords := []
			this.curLabel := "" ; null
			this.curMinimap := "" ; null
			this.curBattlefield := []
		}
		
		_startup() {
			this.strategy.ReloadData()
			this.console.Append(HtmlUtils.SpanWithColor("Coordinates Collector", "yellow"))
			for i, _coordLabel in this.strategy.GetCoordLabels() {
				if (!this.strategy.data.coords.HasKey(_coordLabel)) {
					this.labels.Push(_coordLabel)
				}
			}
			if (this.labels.Length() = 0) {
				this.console.Append("Already done.  Delete coords from the .json file to recapture them.")
				this.console.Append(Format("No changes made to {:s}"
						, HtmlUtils.SpanWithColor(this._getRelativeFilePath(), "peru")))
				this.done := true
			}
			else {
				this.console.Append("Left-click and press backtick to record a point, backtick alone to skip, Ctrl-z to undo, and Ctrl-backtick to cancel.")
				; kick-start the missing coord capture process
				this._promptCoordGroup(this.labels[++this.curLabelIndex])
			}
		}
		
		_pointsCollected() {
			if (this.points.Length() > 0 && !this.curMinimap) {
				; `minimap` chosen
				this.curMinimap := this.points.Pop()
				this._appendToConsole(this.curMinimap)
				this._promptClick("battlefield[" this.curBattlefield.Length()+1 "]")
			}
			else if (this.points.Length() > 0) {
				; `battlefield` point added
				_point := this.points.Pop()
				this.curBattlefield.Push(_point)
				this._appendToConsole(_point)
				this._promptClick("battlefield[" this.curBattlefield.Length()+1 "]")
			}
			else if (this.curMinimap) {
				; end of current coordinate
				if (this.curBattlefield.Length() > 0) {
					this.console.GetDocument().parentWindow
							.jQuery("span.coordcollector_point:last").closest("p").remove()
					_coord := new Starbot.Coord(this.curMinimap, this.curBattlefield)
					this.curCoords.Push(_coord)
					this.coordCount++
					this.curMinimap := "" ; null
					this.curBattlefield := []
					this._promptNextCoord()
					this._promptClick("minimap")
				}
				else {
					; cannot skip when being prompted for `battlefield`
				}
			}
			else {
				; end of current group; go to next label
				this.console.GetDocument().parentWindow
						.jQuery("span.coordcollector_coord:last, span.coordcollector_point:last").closest("p").remove()
				if (this.curCoords.Length() > 0) {
					this.skippedLabels[this.curLabel] := false
					this.strategy.data.coords[this.curLabel] := this.curCoords
					this.curCoords := []
				}
				else {
					this.skippedLabels[this.curLabel] := true
				}
				if (this.curLabelIndex < this.labels.Length()) {
					this._promptCoordGroup(this.labels[++this.curLabelIndex])
				}
				else {
					if (this.coordCount > 0) {
						; merge new coords with existing ones
						Starbot.Json.Write(this.strategy.data, this.strategy.dataFile)
						this.console.Append(Format("Merged {:s} coord{:s} to {:s}"
								, HtmlUtils.SpanWithColor(this.coordCount, "peru")
								, (this.coordCount = 1 ? "" : "s")
								, HtmlUtils.SpanWithColor(this._getRelativeFilePath(), "peru")))
					}
					else {
						this.console.Append(Format("No changes made to {:s}", HtmlUtils.SpanWithColor(this._getRelativeFilePath(), "peru")))
					}
					if (this.skippedLabels.Count() > 0) {
						_arrSkipped := []
						for _label, _isSkipped in this.skippedLabels
							if (_isSkipped)
								_arrSkipped.push(HtmlUtils.SpanWithColor(_label, "peru"))
						this.console.Append(Format("Skipped: {:s}", StrJoin(", ", _arrSkipped)))
					}
					this.done := true
				}
			}
		}
		
		_undo() {
			this.points := []
			if (!this.curMinimap) {
				; "undo" invoked @ `minimap` prompt
				if (this.curCoords.Length() > 0) {
					; go back to previous coord in group
					this.console.GetDocument().parentWindow
							.jQuery("span.coordcollector_point:last, span.coordcollector_coord:last").closest("p").remove()
					this.coordCount--
					_curCoord := this.curCoords.Pop()
					this.curMinimap := _curCoord.minimap
					this.curBattlefield := _curCoord.battlefield
					this._promptClick("battlefield[" this.curBattlefield.Length()+1 "]")
				}
				else if (this.curLabelIndex > 1) {
					; go back to previous group
					this.console.GetDocument().parentWindow
							.jQuery("span.coordcollector_point:last, span.coordcollector_coord:last").closest("p").remove()
					this.curLabel := this.labels[--this.curLabelIndex]
					_curCoords := this.strategy.data.coords[this.curLabel]
					this.curCoords := (_curCoords ? _curCoords : [])
					if (this.curCoords.Length() > 0) {
						this.coordCount--
						_curCoord := this.curCoords.Pop()
						this.curMinimap := _curCoord.minimap
						this.curBattlefield := _curCoord.battlefield
						this._promptClick("battlefield[" this.curBattlefield.Length()+1 "]")
					}
					else {
						; previous group has no coords; start at beginning
						this.curMinimap := ""
						this.curBattlefield := []
						this._promptNextCoord()	; necessary because label was skipped in console
						this._promptClick("minimap")
					}
				}
				else {
					; can't undo; at beginning.  Maybe play the windows `ding!`?
				}
			}
			else {
				; "undo" invoked @ `battlefield` prompt
				if (this.curBattlefield.Length() > 0) {
					; go back to previous battlefield prompt
					this.console.GetDocument().parentWindow
							.jQuery("span.coordcollector_point").slice(-2).closest("p").remove()
					this.curBattlefield.Pop()
					this._promptClick("battlefield[" this.curBattlefield.Length()+1 "]")
				}
				else {
					; go back to previous `minimap` prompt
					this.console.GetDocument().parentWindow
							.jQuery("span.coordcollector_point").slice(-2).closest("p").remove()
					this.curMinimap := ""
					this._promptClick("minimap")
				}
			}
		}
		
		_getRelativeFilePath() {
			return "." . SubStr(this.strategy.dataFile, StrLen(A_WorkingDir)+1)
		}
		
		_promptCoordGroup(_label) {
			this.curLabel := _label
			this._promptNextCoord()
			this._promptClick("minimap")
			WinActivate, % Starbot.STARCRAFT2_WIN_TITLE
		}
		
		_promptNextCoord() {
			this.console.Append(Format("<span class=""coordcollector_coord"">Next: {:s} ({:s})</span>"
			, HtmlUtils.SpanWithColor(this.curLabel, "peru"), this.curCoords.Length()+1))
		}
		
		_promptClick(_pointName) {
			this.console.Append(Format("<span class=""coordcollector_point"">&nbsp;&nbsp;&nbsp;&nbsp;{:s}: </span>"
			, HtmlUtils.SpanWithColor(_pointName, "yellow")))
		}
		
		_appendToConsole(_point) {
			this.console.GetDocument().parentWindow
					.jQuery("span.coordcollector_point:last").append(HtmlUtils.SpanWithColor(_point.ToString(), "lime"))
		}
	}
	
	;--------------------------------------------------------
	; ImageCollector
	;   Captures images and saves them to the `images` folder
	;--------------------------------------------------------
	class ImageCollector extends Starbot.AbstractCollector {
		__New(_console, _strategy) {
			base.__New(_console)
			this.strategy := _strategy
			this.imageCount := 0
			this.labels := []
			this.curLabelIndex := 0
			this.curTopLeft := "" ; null
			this.curBottomRight := "" ; null
			this.curSearchContextTopLeft := "" ; null
			this.curSearchContextBottomRight := "" ; null
			this.confirmed := false
		}
		
		Handle_LClick() {
			; no-op
		}
		
		Handle_Backtick() {
			Critical
			if (!(this.curTopLeft && this.curBottomRight && this.curSearchContextTopLeft && this.curSearchContextBottomRight)) {
				this._capturePoint()
			}
			this._processPoints()
		}
		
		_startup() {
			this.strategy.ReloadData()
			this.console.Append(HtmlUtils.SpanWithColor("Screenshot Capture", "yellow"))
			if (!InStr(FileExist(this._getImagesDir()), "D")) {
				FileCreateDir, % this._getImagesDir()
			}
			if (!InStr(FileExist(this._getImagesDir()), "D")) {
				throw Exception("Unable to create directory.", this._getImagesDir())
			}
			for i, _imageLabel in this.strategy.GetImageLabels() {
				if (this.strategy.data.imageQueries.HasKey(_imageLabel)) {
					; reference exists
					_screenshot := this.strategy.data.imageQueries[_imageLabel]
					if (!FileExist(_screenshot.path)) {
						; queue for capture
						this.labels.Push(_imageLabel)
					}
				}
				else {
					; queue for capture
					this.labels.Push(_imageLabel)
				}
			}
			if (this.labels.Length() = 0) {
				this.console.Append("Already done.  Delete images to recapture them.")
				this.console.Append(Format("No changes made to {:s}"
						, HtmlUtils.SpanWithColor(this._getRelativeFilePath(), "peru")))
				this.done := true
			}
			else {
				this.console.Append("Press backtick to set points, Ctrl-z to undo, and Ctrl-backtick to cancel.")
				; kick-start the image captures
				this._promptNextImage()
			}
		}
		
		_pointsCollected() {
			if (this.points.Length() > 0) {
				if (!this.curTopLeft) {
					; `top-left` chosen
					this.curTopLeft := this.points.Pop()
					this._logPoint(this.curTopLeft)
					this._promptClick("bottom-right")
				}
				else if (!this.curBottomRight) {
					; `bottom-right` chosen
					this.curBottomRight := this.points.Pop()
					this._logPoint(this.curBottomRight)
					this._promptClick("Search context, top-left")
				}
				else if (!this.curSearchContextTopLeft) {
					; `search context, top-left` chosen
					this.curSearchContextTopLeft := this.points.Pop()
					this._logPoint(this.curSearchContextTopLeft)
					this._promptClick("Search context, bottom-right")
				}
				else if (!this.curSearchContextBottomRight) {
					; `search context, bottom-right` chosen
					this.curSearchContextBottomRight := this.points.Pop()
					this._logPoint(this.curSearchContextBottomRight)
					this._promptConfirm()
				}
			}
			if (this.curTopLeft && this.curBottomRight && this.curSearchContextTopLeft && this.curSearchContextBottomRight) {
				if (!this.confirmed) {
					this.confirmed := true
				}
				else {
					; take screenshot
					_curLabel := this.labels[this.curLabelIndex]
					if (this.strategy.data.imageQueries.HasKey(_curLabel))
						_path := this.strategy.data.imageQueries[_curLabel].path
					else
						_path := this._getNewFilePath(this._getValidFilename(_curLabel))
					_dims := Starbot.Rect.From(this.curTopLeft, this.curBottomRight)
					_sc := Starbot.Rect.From(this.curSearchContextTopLeft, this.curSearchContextBottomRight)
					_imageQuery := new Starbot.ImageQuery(_path, _dims, _sc)
					this.strategy.data.imageQueries[_curLabel] := _imageQuery
					_dims.SaveScreenshotTo(_path)
					_scDataUrl := _sc.GetScreenshotAsDataUrl()
					this._logImageQuery(_imageQuery, _scDataUrl)
					this.imageCount++
					this.curTopLeft := "" ; null
					this.curBottomRight := "" ; null
					this.curSearchContextTopLeft := "" ; null
					this.curSearchContextBottomRight := "" ; null
					; go to next label
					if (this.curLabelIndex < this.labels.Length()) {
						this._promptNextImage()
					}
					else if (this.imageCount > 0) {
						; merge new imageQueries with existing ones
						Starbot.Json.Write(this.strategy.data, this.strategy.dataFile)
						this.console.Append(Format("Added {:s} image quer{:s} to {:s}"
								, HtmlUtils.SpanWithColor(this.imageCount, "peru")
								, (this.imageCount = 1 ? "y" : "ies")
								, HtmlUtils.SpanWithColor(this._getRelativeFilePath(), "peru")))
						this.done := true
					}
					else {
						this.console.Append(Format("No changes made to {:s}", HtmlUtils.SpanWithColor(this._getRelativeFilePath(), "peru")))
						this.done := true
					}
				}
			}
		}
		
		_undo() {
			this.points := []
			if (!this.curTopLeft) {
				; "undo" invoked @ `top-left` prompt
				if (this.curLabelIndex > 1) {
					; go back to previous image
					; rects are not saved during image capture, so start over from `top-left`
					this.console.GetDocument().parentWindow
							.jQuery("span.imagecollector_point:gt(-6), span.imagecollector_img:last").closest("p")
							.add(".imagecollector_query:last").closest("p").remove()
					this.imageCount--
					this.curLabelIndex--
					this._promptClick("top-left")
				}
				else {
					; can't undo; at beginning.  Maybe play the windows `ding!`?
				}
			}
			else if (!this.curBottomRight) {
				; "undo" invoked @ `bottom-right` prompt
				; go back to `top-left` prompt
				this.console.GetDocument().parentWindow
						.jQuery("span.imagecollector_point").slice(-2).closest("p").remove()
				this.curTopLeft := ""
				this._promptClick("top-left")
			}
			else if (!this.curSearchContextTopLeft) {
				; "undo" invoked @ `search context, top-left` prompt
				; go back to `bottom-right` prompt
				this.console.GetDocument().parentWindow
						.jQuery("span.imagecollector_point").slice(-2).closest("p").remove()
				this.curBottomRight := ""
				this._promptClick("bottom-right")
			}
			else if (!this.curSearchContextBottomRight) {
				; "undo" invoked @ `search context, bottom-right` prompt
				; go back to `search context, top-left` prompt
				this.console.GetDocument().parentWindow
						.jQuery("span.imagecollector_point").slice(-2).closest("p").remove()
				this.curSearchContextTopLeft := ""
				this._promptClick("Search context, top-left")
			}
			else {
				; "undo" invoked @ confirmation prompt
				; go back to `search context, bottom-right` prompt
				this.console.GetDocument().parentWindow
						.jQuery("span.imagecollector_confirm:last, span.imagecollector_point:last").closest("p").remove()
				this.curSearchContextBottomRight := ""
				this._promptClick("Search context, bottom-right")
			}
		}
		
		_getValidFilename(_fileName) {
			static FORBIDDEN_CHARS := "<,>,|,"",\,/,:,*,?"
			static REPLACEMENT := "_"
			Loop, Parse, FORBIDDEN_CHARS, `,
				StringReplace, _fileName, _fileName, %A_LoopField%, %REPLACEMENT%, All
			return _fileName
		}
		
		_getImagesDir() {
			return Format("{:s}\images", this.strategy.dir)
		}
		
		_getNewFilePath(_fileName) {
			_basePath := Format("{:s}\{:s}", this._getImagesDir(), _fileName)
			Loop
				_path := _basePath "_" A_Index ".png"
			Until !FileExist(_path)
			return _path
		}
		
		_getRelativeFilePath() {
			return "." . SubStr(this.strategy.dataFile, StrLen(A_WorkingDir)+1)
		}
		
		_promptNextImage() {
			this.confirmed := false
			this.console.Append(Format("<span class=""imagecollector_img"">Next: {:s}</span>"
					, HtmlUtils.SpanWithColor(this.labels[++this.curLabelIndex], "peru")))
			this._promptClick("top-left")
			WinActivate, % Starbot.STARCRAFT2_WIN_TITLE
		}
		
		_promptClick(_pointName) {
			this.console.Append(Format("<span class=""imagecollector_point"">&nbsp;&nbsp;&nbsp;&nbsp;{:s}: </span>"
			, HtmlUtils.SpanWithColor(_pointName, "yellow")))
		}
		
		_promptConfirm() {
			this.console.Append("<span class=""imagecollector_confirm"">&nbsp;&nbsp;&nbsp;&nbsp;Press `` to confirm...</span>")
		}
		
		_logPoint(_point) {
			this.console.GetDocument().parentWindow
					.jQuery("span.imagecollector_point:last").append(HtmlUtils.SpanWithColor(_point.ToString(), "lime"))
		}
		
		_logImageQuery(_imageQuery, _scDataUrl) {
			Transform, _src, HTML, % _imageQuery.path
			Transform, _scToString, HTML, % _imageQuery.searchContext.ToString()
			_html := Format("
			(LTrim
			<p class=""imagecollector_query"">
				<span style=""display:inline-block; white-space:nowrap; margin-bottom:7px;"">
					<span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>
					<span style=""display:inline-block; white-space:normal;"">
						<span style=""display:inline-block; vertical-align: top; white-space:nowrap; margin-right:10px;"">Image:<br/>
							<img style=""border: 1px solid white; vertical-align: top; margin-top: 2px;"" src=""{1:s}?timestamp={2:s}"" alt=""{1:s}""></img>
						</span>
						<span style=""display:inline-block; vertical-align: top; white-space:nowrap;"">Search context:<br/>
							<img style=""border: 1px solid white; vertical-align: top; margin-top: 2px;"" src=""{3:s}?timestamp={2:s}"" alt=""{4:s}""></img>
						</span>
					</span>
				</span>
			</p>
			)"
			, _src, A_TickCount, _scDataUrl, _scToString)
			; replace the confirmation prompt
			this.console.GetDocument().parentWindow
					.jQuery("span.imagecollector_confirm:last").closest("p").remove()
			this.console.GetDocument().parentWindow
					.jQuery("body").append(_html)
		}
	}
	
	;--------------------------------------
	; [abstract] Strategy
	;	Base class for Strategies which contain Actions.
	;--------------------------------------
	class Strategy extends Starbot.Handler {
		__New(_name, _console, _parentData) {
			base.__New(_console)
			_fileName := _name . ".json"
			if (!isValidFileName(_fileName))
				throw Exception("Invalid filename.", _fileName)
			_dir := Format("{1:s}\Strategies\{2:s}", A_WorkingDir, _name)
			this.dataFile := Format("{:s}\{:s}", _dir, _fileName)
			this.name := _name
			this.parentData := _parentData
			this.currentAction := ""	; null
			this.actionObjects := "" 	; null
			this.data := ""				; null
			this.timers := {}			; persisted across Actions
			this.ReloadData()
			this.MergeParentData()
		}
		
		; an array of point labels
		GetPointLabels() {
			throw Exception(Starbot.ERROR_ABSTRACT_METHOD, A_ThisFunc)
		}
		
		; an array of rect labels
		GetRectLabels() {
			throw Exception(Starbot.ERROR_ABSTRACT_METHOD, A_ThisFunc)
		}
		
		; an array of coord labels
		GetCoordLabels() {
			throw Exception(Starbot.ERROR_ABSTRACT_METHOD, A_ThisFunc)
		}
		
		; an array of image labels
		GetImageLabels() {
			throw Exception(Starbot.ERROR_ABSTRACT_METHOD, A_ThisFunc)
		}
		
		ReloadData() {
			this.data := Starbot.Json.Read(this.dataFile)
		}
		
		MergeParentData() {
			this.data.ExtendFrom(this.parentData)
		}
		
		Handle_Trigger() {
			this.done := false
			this._menuPrompt()
		}
		
		_menuPrompt() {
			static TAB := "&nbsp;&nbsp;&nbsp;&nbsp;"
			_impls := this._getActions()
			if (_impls.Count() = 0) {
				this.console.Append(Format("There are no actions to perform in {:s}", HtmlUtils.SpanWithColor(this.name, "yellow")))
				this.done := true
			}
			else {
				_actionMap := {}
				_text := ""
				for _i, _impl in _impls {
					_action := new _impl()
					_actionMap[_action.GetName()] := {action: _action, index: _i}
					_text .= TAB _i ") " HtmlUtils.SpanWithColor(_action.GetName(), "lime") ":  `t" _action.GetDescription() "`n"
				}
				_text := SubStr(_text, 1, -1)	; trim last newline
				this.console.Append("Choose an action:`n" . _text)
				this.console.Activate()
				this.console.FocusInput()
				this.console.GetInput(ObjBindMethod(this, "_actionMenuCallback", _actionMap))
			}
		}
		
		_getActions() {
			static ACTION_CLASS := "Starbot.Action"
			static DESC_METHOD := "GetDescription"
			_actions := []
			for _id, _member in ObjGetBase(this) {
				; concrete classes must have the description method
				if (IsObject(_member[DESC_METHOD]) && _member[DESC_METHOD].Name) {
					; verify inheritance from the Action base class
					while (IsObject(_member)) {
						if (_member.__Class = ACTION_CLASS) {
							_actions.push(this[_id])
							break
						}
						_member := ObjGetBase(_member)
					}
				}
			}
			return _actions
		}
		
		_actionMenuCallback(_actionMap, _actionName) {
			Critical
			try {
				for _key, _actionTuple in _actionMap {
					; match by name or index
					if ((_key = _actionName) || (_actionTuple.index = _actionName)) {
						this.currentAction := _actionTuple.action
					}
				}
				if (!this.currentAction) {
					this.console.AppendError(Format("Invalid action: ""{:s}""", _actionName))
				}
				else {
					this.console.Append(Format("Performing {:s}...", HtmlUtils.SpanWithColor(_actionName, "lime")))
					;~ WinActivate, % Starbot.STARCRAFT2_WIN_TITLE
					;~ WinWaitActive, % Starbot.STARCRAFT2_WIN_TITLE, , 2
					if (ErrorLevel = 1) {
						throw Exception(Format("The {:s} window is not open.", Starbot.STARCRAFT2_WIN_TITLE))
					}
					this.currentAction._initialize(this.data, this.console, this.parentData, this.timers)
					this.currentAction.Call(this)
					this.currentAction := ""	; null
					this.console.Append("Done.")
				}
			}
			finally {
				this.done := true
			}
		}
		
		GetNumberOfMissingPoints() {
			_count := 0
			for i, _label in this.GetPointLabels()
				if (!this.data.points.HasKey(_label))
					_count++
			return _count
		}
				
		GetNumberOfMissingRects() {
			_count := 0
			for i, _label in this.GetRectLabels()
				if (!this.data.rects.HasKey(_label))
					_count++
			return _count
		}
				
		GetNumberOfMissingCoords() {
			_count := 0
			for i, _label in this.GetCoordLabels()
				if (!this.data.coords.HasKey(_label))
					_count++
			return _count
		}
				
		GetNumberOfMissingImages() {
			_count := 0
			for i, _label in this.GetImageLabels()
				if (!this.data.imageQueries.HasKey(_label))
					_count++
			return _count
		}
	}
	
	;--------------------------------------
	; [abstract] Action
	;	Base class for Actions of a Strategy.
	;--------------------------------------
	class Action extends FunctionObject {
		_initialize(_data, _console, _parentData, _timers) {
			this.data := _data
			this.console := _console
			this.parentData := _parentData
			this.timers := _timers
		}
		
		Call() {
			throw Exception(Starbot.ERROR_ABSTRACT_METHOD, A_ThisFunc)
		}
		
		GetName() {
			return SubStr(this.__Class, 1 + InStr(this.__Class, ".", false, -1))
		}
		
		GetPoint(_key) {
			if (!this.data.points.HasKey(_key)) {
				throw Exception("Unknown point: " . _key)
			}
			return this.data.points[_key]
		}
		
		GetRect(_key) { ; lol
			if (!this.data.rects.HasKey(_key)) {
				throw Exception("Unknown rect: " . _key)
			}
			return this.data.rects[_key]
		}
		
		GetCoords(_key) {
			if (!this.data.coords.HasKey(_key)) {
				throw Exception("Unknown coord: " . _key)
			}
			return this.data.coords[_key]
		}
		
		FindImages(_key, _variation:=5) {
			_numFound := this._imageSearch(_key, _variation, _results)
			_retval := []
			if (_numFound = 0) {
				this.console.AppendWithColor("red", "Image not found: " _key, _imageQuery.path)
			}
			else {
				Loop, Parse, _results, `n
				{			
					_vals := StrSplit(A_LoopField, ",")
					_dims := this.data.imageQueries[_key].dims
					_topLeft := new Starbot.Point(_vals[1], _vals[2])
					_bottomRight := new Starbot.Point(_vals[1] + _dims.GetWidth(), _vals[2] + _dims.GetHeight())
					_retval.Push(new Starbot.Rect(_topLeft, _bottomRight))
				}
			}
			return _retval
		}
		
		WaitForImage(_key, _timeout:=5000, _interval:=10, _variation:=5) {
			_startTime := A_TickCount
			while (!this.IsVisible(_key, _variation)) {
				if ((A_TickCount - _startTime) >= _timeout) {
					throw Exception("Timed out waiting for image", _key, _timeout)
				}
				Starbot.Nap(_interval)
			}
		}
		
		IsVisible(_key, _variation:=5) {
			return (this._imageSearch(_key, _variation) > 0)
		}
		
		_imageSearch(_key, _variation:=5, ByRef _results="") {
			if (!this.data.imageQueries.HasKey(_key)) {
				throw Exception("Unknown image: " . _key)
			}
			_imageQuery := this.data.imageQueries[_key]
			if (!FileExist(_imageQuery.path)) {
				throw Exception("Image file not found.", _imageQuery.path, _key)
			}
			WinGet, _hwnd, ID, A
			try {
				_haystack := Gdip_BitmapFromScreen("hwnd:" _hwnd)
				_needle := Gdip_CreateBitmapFromFile(_imageQuery.path)
				if (_needle < 0)
					throw Exception("Unable to create bitmap from file: " _key, _imageQuery.path, _needle)
				_sc := _imageQuery.searchContext
				_numFound := Gdip_ImageSearch(_haystack, _needle, _results
						, _sc.topLeft.x, _sc.topLeft.y, _sc.bottomRight.x, _sc.bottomRight.y
						, _variation)
				if (_numFound < 0)
						throw Exception("Failed image search: " _key, _imageQuery.path, _numFound)
				return _numFound
			}
			finally {
				Gdip_DisposeImage(_haystack)
				Gdip_DisposeImage(_needle)
			}
		}
		
		AhkHotkey(_keyName, _label="", _options="") {
			; reference to if-expression string in Starbot_main.ahk
			Hotkey, If, % "hotkeysEnabled && WinActive(Starbot.STARCRAFT2_WIN_TITLE)"
			Hotkey, % _keyName, % _label, % _options " UseErrorLevel"
			if ErrorLevel in 5,6
				throw Exception("The hotkey does not exist or it has no variant for the current IfWin criteria.", _keyName)
		}
		
		StartTimer(_name, _funcObj, _period, _priority="") {
			this.timers[_name] := _funcObj
			SetTimer, % _funcObj, % _period, % _priority
		}
		
		StopTimer(_name) {
			_funcObj := this.timers[_name]
			SetTimer, % _funcObj, Off
			this.timers.Delete(_name)
		}
		
		StartBlockingInput() {
			Starbot.INPUT_BLOCKER.Start()
			OnExit(ObjBindMethod(Starbot.INPUT_BLOCKER, "Stop"))
		}
		
		StopBlockingInput() {
			Starbot.INPUT_BLOCKER.Stop()
		}
		
		Nap(_millis:=0) {
			Starbot.Nap(_millis)
		}
		
		WaitForGameToStart(_timeout:=120000, _interval:=100) {
			static UI := "__UI"
			this.WaitForImage(UI, _timeout, _interval)
		}
		
		FocusWindow() {
			WinActivate, % Starbot.STARCRAFT2_WIN_TITLE
		}
		
		IsWindowFocused() {
			return WinActive(Starbot.STARCRAFT2_WIN_TITLE)
		}

		Chat(_text) {
			Send, {Enter}
			SendRaw, %_text%
			Send, {Enter}
		}
		
		ChatAll(_text) {
			Send, +{Enter}
			SendRaw, %_text%
			Send, {Enter}
		}
		
		AssignCamera(_num) {
			this.AssignHotkey("{F" _num "}")
		}
		
		SelectCamera(_num) {
			this.SelectHotkey("{F" _num "}")
		}
		
		AssignHotkey(_hotkey) {
			Send, {CtrlDown}%_hotkey%{CtrlUp}
		}
		
		SelectHotkey(_hotkey) {
			Send, %_hotkey%
		}
		
		ZoomOut(_count, _sleep:=500) {
			Loop, %_count%
				Click, WheelDown
			Starbot.Nap(_sleep)
		}
		
		GetScreen() {
			WinGetPos, _x, _y, _w, _h, % Starbot.STARCRAFT2_WIN_TITLE
			_tl := new Starbot.Point(_x, _y)
			_br := new Starbot.Point(_x + _w, _y + _h)
			return new Starbot.Rect(_tl, _br)
		}
		
		FilterUnitSelection(_key) {
			_selection := this.FindImages(_key)
			_numFound := _selection.Count()
			if (_numFound > 0) {
				Send, {Ctrl Down}
				_selection[1].Center().LClick()
				Send, {Ctrl Up}
			}
			return _numFound
		}
		
		ForEachCoord(_coordName, _funcName, _params*) {
			_func := ObjBindMethod(this, _funcName)
			if (!IsObject(_func))
				throw Exception("Method not found: " _funcName)
			for _i, _coord in this.GetCoords(_coordName) {
				_coord.OnScreen()
				if (_params.Count() > 0)
					_func.Call(_coord, _params*)
				else
					_func.Call(_coord)
			}
		}
		
		ForEachPointInCoord(_coordName, _funcName, _params*) {
			_func := ObjBindMethod(this, _funcName)
			if (!IsObject(_func))
				throw Exception("Method not found: " _funcName)
			for _i, _coord in this.GetCoords(_coordName) {
				_coord.OnScreen()
				for _j, _point in _coord.battlefield {
					if (_params.Count() > 0)
						_func.Call(_point, _params*)
					else
						_func.Call(_point)
				}
			}
		}
		
		GetMinimapPosition() {
			static MINIMAP_RECT := "__minimap"
			static HBAR := Format("{:s}\{:s}", A_WorkingDir, Starbot.MINIMAP_HBAR)
			static VBAR := Format("{:s}\{:s}", A_WorkingDir, Starbot.MINIMAP_VBAR)
			static SEARCH_VARIATION := 1
			static SEARCH_DIRECTION_H := 1	; top->left->right->bottom
			static SEARCH_DIRECTION_V := 5	; left->top->bottom->right
			static SEARCH_INSTANCES := 0	; all
			static MIN_PIXEL_GAP := 3
			if (!FileExist(HBAR)) {
				throw Exception("Missing asset: " HBAR)
			}
			if (!FileExist(VBAR)) {
				throw Exception("Missing asset: " VBAR)
			}
			if (!this.data.rects.HasKey(MINIMAP_RECT)) {
				throw Exception("Missing coords: " MINIMAP_RECT)
			}
			_mmCoords := this.data.coords[MINIMAP_RECT][1]
			_mm := Starbot.Rect.From(_mmCoords.battlefield[1], _mmCoords.battlefield[2])
			WinGet, _hwnd, ID, A
			try {
				; find all possible minimap trapezoid pixels
				_haystack := Gdip_BitmapFromScreen("hwnd:" _hwnd)
				_needleH := Gdip_CreateBitmapFromFile(HBAR)
				_needleV := Gdip_CreateBitmapFromFile(VBAR)
				_numFound := Gdip_ImageSearch(_haystack, _needleH, _hResults
						, _mm.topLeft.x, _mm.topLeft.y, _mm.bottomRight.x, _mm.bottomRight.y
						, SEARCH_VARIATION, "", SEARCH_DIRECTION_H, SEARCH_INSTANCES)
				if (_numFound < 0)
					throw Exception("Failed image search: " HBAR)
				if (_numFound = 0)
					throw Exception("Minimap trapezoid horizontal-edges not found: " HBAR)
				_numFound := Gdip_ImageSearch(_haystack, _needleV, _vResults
						, _mm.topLeft.x, _mm.topLeft.y, _mm.bottomRight.x, _mm.bottomRight.y
						, SEARCH_VARIATION, "", SEARCH_DIRECTION_V, SEARCH_INSTANCES)
				if (_numFound < 0)
					throw Exception("Failed image search: " VBAR)
				if (_numFound = 0)
					throw Exception("Minimap trapezoid vertical-edges not found: " VBAR)
				
				; hash horizontal pixels by x-value
				_horizontalHash := {}
				Loop, Parse, _hResults, `n
				{
					_point := StrSplit(A_LoopField, ",")
					_point := new Starbot.Point(_point[1], _point[2])
					_curPoints := ""
					if (!_horizontalHash.HasKey(_point.x)) {
						_curPoints := []
						_horizontalHash[_point.x] := _curPoints
					}
					else
						_curPoints := _horizontalHash[_point.x]
					_curPoints.Push(_point)
				}
				; filter out columns not having exactly 2 widely-spaced pixels
				_topRow := []
				_bottomRow := []
				for _x, _points in _horizontalHash {
					if (_points.Count() = 2) {
						_p1 := _points[1]
						_p2 := _points[2]
						if (Abs(_p1.y - _p2.y) > MIN_PIXEL_GAP) {
							if (_p1.y < _p2.y) {
								_topRow.Push(_p1)
								_bottomRow.Push(_p2)
							}
							else {
								_topRow.Push(_p2)
								_bottomRow.Push(_p1)
							}
						}
					}
				}
				; sort rows horizontally and construct lines from endpoints
				_topRow := (new QuickSort()).Call(_topRow, new Starbot.Point.HorizontalCompare())
				_bottomRow := (new QuickSort()).Call(_bottomRow, new Starbot.Point.HorizontalCompare())
				_topLine := new Starbot.Line(_topRow[1], _topRow[_topRow.MaxIndex()])
				_bottomLine := new Starbot.Line(_bottomRow[1], _bottomRow[_bottomRow.MaxIndex()])
				
				; hash vertical pixels by y-value
				_verticalHash := {}
				Loop, Parse, _vResults, `n
				{
					_point := StrSplit(A_LoopField, ",")
					_point := new Starbot.Point(_point[1], _point[2])
					_curPoints := ""
					if (!_verticalHash.HasKey(_point.y)) {
						_curPoints := []
						_verticalHash[_point.y] := _curPoints
					}
					else
						_curPoints := _verticalHash[_point.y]
					_curPoints.Push(_point)
				}
				; filter out rows not having exactly 2 widely-spaced pixels
				_leftRow := []
				_rightRow := []
				for _x, _points in _verticalHash {
					if (_points.Count() = 2) {
						_p1 := _points[1]
						_p2 := _points[2]
						if (Abs(_p1.x - _p2.x) > MIN_PIXEL_GAP) {
							if (_p1.x < _p2.x) {
								_leftRow.Push(_p1)
								_rightRow.Push(_p2)
							}
							else {
								_leftRow.Push(_p2)
								_rightRow.Push(_p1)
							}
						}
					}
				}
				; sort columns vertically and construct lines from endpoints
				_leftRow := (new QuickSort()).Call(_leftRow, new Starbot.Point.VerticalCompare())
				_rightRow := (new QuickSort()).Call(_rightRow, new Starbot.Point.VerticalCompare())
				_leftLine := new Starbot.Line(_leftRow[1], _leftRow[_leftRow.MaxIndex()])
				_rightLine := new Starbot.Line(_rightRow[1], _rightRow[_rightRow.MaxIndex()])
				
				; calculate the corners of the trapezoid
				_topLeft := _topLine.IntersectionWith(_leftLine)
				_topRight := _topLine.IntersectionWith(_rightLine)
				_bottomLeft := _bottomLine.IntersectionWith(_leftLine)
				_bottomRight := _bottomLine.IntersectionWith(_rightLine)
				; approximate center of trapezoid using diagonal intersection
				_diag1 := _topLeft.LineTo(_bottomRight)
				_diag2 := _topRight.LineTo(_bottomLeft)
				return _diag1.IntersectionWith(_diag2)
			}
			finally {
				Gdip_DisposeImage(_haystack)
				Gdip_DisposeImage(_needleH)
				Gdip_DisposeImage(_needleV)
			}
		}
	}
	
	;--------------------------------------
	; GlobalStrategy
	;	For data not specific to any particular strategy.
	;--------------------------------------
	class GlobalStrategy extends Starbot.Strategy {
		static NAME := "(global)"
		
		__New(_console) {
			base.__New(Starbot.GlobalStrategy.NAME, _console, new Starbot.Json())
		}
		
		GetPointLabels() {
			return []
		}
		GetRectLabels() {
			return ["__minimap"]
		}
		GetCoordLabels() {
			return []
		}
		GetImageLabels() {
			return ["__UI"]
		}
	}
}
