#Include <Starbot>

Starbot.RegisterStrategy(ZagaraCoop)
class ZagaraCoop extends Starbot.Strategy {
	
	GetPointLabels() {
		return []
	}
	GetRectLabels() {
		return ["hatchery queens"]
	}
	GetCoordLabels() {
		return []
	}
	GetImageLabels() {
		return ["selection: queen"]
	}
	
	;--------- ACTION CLASSES ---------
	
	class SetupHotkeys extends ZagaraCoop.Action {
		GetDescription() {
			return "Sets hotkeys ""1"" and ""2"" for blitzkreig style."
		}
		Call() {
			this.AhkHotkey("1", ObjBindMethod(this, "_hotkey1"), "On")
			this.AhkHotkey("2", ObjBindMethod(this, "_hotkey2"), "On")
		}
		_hotkey1() {
			Send, 9{F2}{Shift Down}9{Shift Up}9
		}
		_hotkey2() {
			Send, 9{F2}{Shift Down}9{Shift Up}9a
		}
	}
	
	class ToggleAutoInject extends ZagaraCoop.Action {
		GetDescription() {
			return "Toggles the auto-inject thread."
		}
		Call() {
			;~ static WAIT_25_ENERGY := 32000
			static WAIT_25_ENERGY := 5000
			if (!this.timers.HasKey(A_ThisFunc))
				this.StartTimer(A_ThisFunc, ObjBindMethod(this, "_injectLarvae"), WAIT_25_ENERGY)
			else
				this.StopTimer(A_ThisFunc)
		}
	}
	
	class InjectLarvae extends ZagaraCoop.Action {
		GetDescription() {
			return "Inject larvae one time."
		}
		Call() {
			this.FocusWindow()
			this.Nap()
			this._injectLarvae()
		}
	}
	
	; [abstract] base class
	class Action extends Starbot.Action {
		_injectLarvae() {
			static CAMERA := 7
			static INJECTS_PER_CYCLE := 2
			static NUM_HATCHERIES := 2 ; TODO dynamically count hatcheries by position
			if (!this.IsWindowFocused()) {
				this.console.AppendWithColor("red", "Skipping inject because alt-tabbed!")
			}
			else {
				this.console.Append("Injecting larvae...")
				;~ this.StartBlockingInput()
				;~ this.console.Append("[DEBUG] INPUT IS BLOCKED....")
				this.AssignCamera(CAMERA)
				this.console.Append("[DEBUG] CAMERA IS ASSIGNED....")
				_hatchery := this.GetScreen().Center().Up(150)
				_hatchery.MouseTo(false)
				Loop, %NUM_HATCHERIES% {
					Send, {Esc}{Backspace}
					this.console.Append("[DEBUG] BACKSPACE WAS PRESSED....")
					this.Nap()
					this.GetRect("hatchery queens").DragSelect()
					this.Nap()
					if (this.FilterUnitSelection("selection: queen") > 0) {
						Send, v{Shift Down}
						Loop, %INJECTS_PER_CYCLE% {
							_hatchery.LClick(false)
						}
						Send, {Shift Up}{Esc}
					}
				}
				this.SelectCamera(CAMERA)
				;~ this.StopBlockingInput()
			}
		}
	}
}