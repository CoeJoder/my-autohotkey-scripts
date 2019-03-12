#Include <Starbot>

Starbot.RegisterStrategy(<NAME_OF_STRATEGY>)
class <NAME_OF_STRATEGY> extends Starbot.Strategy {

	GetPointLabels() {
		return []
	}
	GetRectLabels() {
		return []
	}
	GetCoordLabels() {
		return []
	}
	GetImageLabels() {
		return []
	}
	
	;--------- ACTION CLASSES ---------
	
	; [abstract] base class
	class Action extends Starbot.Action {
	}
	
	class <NAME_OF_ACTION> extends <NAME_OF_STRATEGY>.Action {
		GetDescription() {
			return ""
		}
		Call() {
			this.WaitForGameToStart()
			;TODO
		}
	}
}