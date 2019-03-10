class DoUntil {
	__New(boundFunc, timeout, interval) {
		this.boundFunc := boundFunc
		this.timeout := timeout
		this.interval := interval * -1	; negative: 1 iteration per call
		this.timer := ObjBindMethod(this, "_runner")
	}
	Run() {
		this.done := false
		this.startTime := A_TickCount
		this._runner()
	}
	Cancel() {
		this.done := true
		_timer := this.timer
		SetTimer, % _timer, Off
	}
	_runner() {
		_timedOut := (A_TickCount - this.startTime) >= this.timeout
		if (!this.done && !_timedOut && !this.boundFunc.Call()) {
			_timer := this.timer
			SetTimer, % _timer, % this.interval
		}
		else
			this.done := true
	}
}