class RandomTimer {
	__New(boundFunc, interval, plusMin, plusMax) {
		this.boundFunc := boundFunc
		this.interval := interval
		this.plusMin := plusMin
		this.plusMax := plusMax
		this.timer := ObjBindMethod(this, "_runner")	; first-order method
		this.stopped := true
	}
	Start() {
		this.stopped := false
		this._setTimer()
	}
	Stop() {
		this.stopped := true
		_timer := this.timer
		SetTimer, % _timer, Off
	}
	_setTimer() {
			_period := -1 * this.interval		; negative means 1 iteration only
			_timer := this.timer
			SetTimer, % _timer, % _period
	}
	_runner() {
		if (!this.stopped) {
			Random, _napTime, % this.plusMin, % this.plusMax
			Sleep, %_napTime%
			this.boundFunc.Call()
			this._setTimer()
		}
	}
}