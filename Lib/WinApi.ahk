class WinApi {
	static Msg := {WM_NCHITTEST : 0x84
		, WM_MOUSEMOVE : 0x200
		, WM_SETCURSOR : 0x20
		, WM_MOUSEACTIVATE : 0x21
		, WM_LBUTTONDOWN : 0x201
		, WM_LBUTTONUP : 0x202
		, WM_RBUTTONDOWN : 0x204
		, WM_RBUTTONUP  : 0x205
		, WM_MBUTTONDOWN : 0x207
		, WM_MBUTTONUP : 0x208
		, WM_CAPTURECHANGED : 0x215	
		, WM_ACTIVATEAPP : 0x1C
		, WM_NCACTIVATE : 0x86
		, WM_ACTIVATE : 0x06
		, WM_IME_SETCONTEXT : 0x281
		, WM_IME_NOTIFY : 0x282
		, WM_SETFOCUS : 0x07
		, WM_WINDOWPOSCHANGING : 0x46
		, ImmersiveFocusNotification : 0xC0C9}
	static MK_LBUTTON := 0x0001
	static MK_RBUTTON := 0x0002
	static MK_MBUTTON := 0x0010
	static HTCLIENT := 1
	static ISC_SHOWUIALL := 0xC000000F
	static IMN_OPENSTATUSWINDOW := 0x2
	static ZERO := 0x0
	static ONE := 0x1
	
	__New(_debug) {
		this.debug := _debug	; if true, print message data to console
	}
	
	leftClick(title, x, y) {
		;~ WinGet, sc2Hwnd, ID, %title%
		;~ sendMsg(Msg.WM_NCHITTEST, ZERO, getLParam(x, y), title)
		;~ sendMsg(Msg.WM_NCHITTEST, ZERO, getLParam(x, y), title)
		
		;~ WinActivate, %title%
		;~ sendMsg(Msg.WM_ACTIVATEAPP, ONE, ONE, title)
		;~ sendMsg(Msg.WM_NCACTIVATE, ONE, ZERO, title)
		;~ sendMsg(Msg.WM_ACTIVATE, ONE, ZERO, title)
		;~ sendMsg(Msg.WM_IME_SETCONTEXT, ONE, ISC_SHOWUIALL, title)
		;~ sendMsg(Msg.WM_IME_NOTIFY, IMN_OPENSTATUSWINDOW, ZERO, title)
		;~ sendMsg(Msg.WM_SETFOCUS, ZERO, ZERO, title)
		
		;~ postMsg(Msg.ImmersiveFocusNotification, 0xFFFFFFFFFFFFFFFC, ZERO, title)
		;~ postMsg(Msg.ImmersiveFocusNotification, ZERO, ZERO, title)
		; TODO WM_WINDOWPOSCHANGING
		
		
		;~ sendMsg(Msg.WM_SETCURSOR, sc2Hwnd, getLParam(HTCLIENT, Msg.WM_LBUTTONDOWN), title)
		this.postMsg(this.Msg.WM_LBUTTONDOWN, this.MK_LBUTTON, this.getLParam(x, y), title)
		this.postMsg(this.Msg.WM_LBUTTONUP, this.ZERO, this.getLParam(x, y), title)
		
		;~ sendMsg(Msg.WM_CAPTURECHANGED, ZERO, ZERO, title)
		;~ sendMsg(Msg.WM_NCHITTEST, ZERO, getLParam(x, y), title)
		;~ sendMsg(Msg.WM_NCHITTEST, ZERO, getLParam(x, y), title)
		
		;~ sendMsg(Msg.WM_SETCURSOR, sc2Hwnd, getLParam(HTCLIENT, Msg.WM_MOUSEMOVE), title)
		;~ postMsg(Msg.WM_MOUSEMOVE, ZERO, getLParam(x, y), title)
	}
	
	;UNTESTED
	rightClick(title, x, y) {
		this.postMsg(this.Msg.WM_RBUTTONDOWN, this.MK_RBUTTON, this.getLParam(x, y), title)
		this.postMsg(this.Msg.WM_RBUTTONUP, this.ZERO, this.getLParam(x, y), title)
	}
	
	;UNTESTED
	middleClickDrag(title, x1, y1, x2, y2) {
		WinGet, sc2Hwnd, ID, %title%
		this.sendMsg(this.Msg.WM_SETCURSOR, sc2Hwnd, this.getLParam(this.HTCLIENT, this.Msg.WM_MBUTTONDOWN), title)
		this.postMsg(this.Msg.WM_MBUTTONDOWN, this.MK_MBUTTON, this.getLParam(x1, y1), title)
		;~ this.postMsg(this.Msg.WM_MOUSEMOVE, this.MK_MBUTTON, this.getLParam(x2, y2), title)
		Loop, 10
			this.postMsg(this.Msg.WM_MOUSEMOVE, this.MK_MBUTTON, this.getLParam(x1+A_Index, y1+A_Index), title)
		;~ this.postMsg(this.Msg.WM_MBUTTONUP, this.ZERO, this.getLParam(x2, y2), title)
		this.postMsg(this.Msg.WM_MBUTTONUP, this.ZERO, this.getLParam(x1+10, y1+10), title)
	}
	
	postMsg(msg, wParam, lParam, title) {
		PostMessage, %msg%, %wParam%, %lParam%, , %title%
		if (this.debug)
			println(Format("P {:s} [wParam:{:x} lParam:{:x}]", this.getMessageKey(msg), wParam, lParam))
	}

	sendMsg(msg, wParam, lParam, title) {
		SendMessage, %msg%, %wParam%, %lParam%, , %title%
		msgReply := ErrorLevel << 32 >> 32
		msgKey := this.getMessageKey(msg)
		if (this.debug) {
			println(Format("S {:s} [wParam:00000000{:x} lParam:00000000{:x}]", msgKey, wParam, lParam))
			println(Format("R {:s} [lResult:00000000{:x}]", msgKey, msgReply))
		}
	}
	
	getMessageKey(val) {
		for k, v in this.Msg {
			if (v = val) {
				return k
			}
		}
	}

	getLParam(loWord, hiWord) {
		return loWord | (hiWord << 16)
	}
}