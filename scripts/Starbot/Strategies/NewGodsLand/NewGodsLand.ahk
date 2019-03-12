#Include <Starbot>

Starbot.RegisterStrategy(NewGodsLand)
class NewGodsLand extends Starbot.Strategy {

	;TODO move applicable labels from coord to point

	GetPointLabels() {
		return []
	}
	GetRectLabels() {
		return []
	}
	GetCoordLabels() {
		return ["god start", "starting barriers", "starting dl-rocks", "starting dr-rocks", "nat bunkers", "give units to", "statistics +/-", "give units to: slots"]
	}
	GetImageLabels() {
		return ["button: heal", "god title", "player select: neutral", "player select: hostile"]
	}
	
	;--------- ACTION CLASSES ---------
	
	class BlockRamps extends NewGodsLand.Action {
		GetDescription() {
			return "Setup the initial defenses around the map."
		}
		Call() {
			this.WaitForGameToStart()
			this.ZoomOut(2)
			
			; block the base ramps
			this.ForEachPointInCoord("starting dr-rocks", "SpawnSecondaryNeutralUnit", "drrocks")
			this.ForEachPointInCoord("starting dl-rocks", "SpawnSecondaryNeutralUnit", "dlrocks")
			
			; nerf the rocks
			this.ForEachPointInCoord("starting dr-rocks", "NerfStats", 2)
			this.ForEachPointInCoord("starting dl-rocks", "NerfStats", 2)
		}
	}
	
	class BunkersAndForceFields extends NewGodsLand.Action {
		GetDescription() {
			return "Put bunkers near the base nats, and block side entrances with forcefields."
		}
		Call() {
			; setup hostile outposts at each nat
			this.GiveUnitsToHostilePlayer()
			this.SelectGod()
			;~ this.ResearchAdvancedTerranUpgrades("hisec", "neosteel", "buildingarmor")
			this.ForEachCoord("nat bunkers", "SetupNatBunkers")
			
			; put forcefields at each starting base to block reapers
			this.ForEachPointInCoord("starting barriers", "SpawnNeutralUnit", "forcefield")
		}
		SetupNatBunkers(_coord) {
			_bunk1 := _coord.battlefield[1]
			_bunk2 := _coord.battlefield[2]
			this.SpawnTerranStructure(_bunk1, "bunker")
			this.SpawnTerranStructure(_bunk2, "bunker")
			_marines := _bunk1.MidwayTo(_bunk2)
			this.SelectGod()
			this.SpawnMeleeTerranUnit(_marines, "marine", 8)
			this.Nap()
			_marines.DragSelect(200)
			this.Nap()
			_bunk1.RClick()
			Send, {Shift down}
			_bunk2.RClick()
			Send, {Shift up}
			this.SelectGod()
		}
	}
	
	class RemoveStartingBarriers extends NewGodsLand.Action {
		GetDescription() {
			return "Remove the permanent forcefields that were placed near player bases."
		}
		Call() {
			this.ForEachCoord("starting barriers", "DestroyForceFields")
		}
	}
	
	class Tester extends NewGodsLand.Action {
		GetDescription() {
			return "Used to test little nidbits  :^)"
		}
		Call() {
			this.GetCoords("god start")[1].OnScreen()
					.battlefield[1].LClick()
			this.ResearchAdvancedTerranUpgrades("hisec", "neosteel", "buildingarmor")
		}
	}
	
	; [abstract] base class
	class Action extends Starbot.Action {
		mainMenu := "melee"	; "campaign" or "melee"
		
		ResearchAdvancedTerranUpgrades(_upgrades*) {
			static ADVANCED_TERRAN_UPGRADES := {hisec: "h", neosteel: "n", buildingarmor: "b"}	; incomplete
			this.OpenMeleeMenu()
			Send, u
			Send, x
			Send, x
			Loop, % _upgrades.Count()
				Send, % ADVANCED_TERRAN_UPGRADES[_upgrades[A_Index]]
			Send, {Esc}{Esc}
		}
		SpawnTerranStructure(_point, _structure) {
			static TERRAN_STRUCTURES := {commandcenter: "c", orbital: "b", planetary: "p", refinery: "r", supplydepot: "s", barracks: "a", factory: "f", starport: "e", bunker: "u", turret: "t", sensortower: "n", autoturret: "o", pdd: "d"}
			this.OpenMeleeMenu()
			Send, x
			Send, % TERRAN_STRUCTURES[_structure]
			_point.LClick()
			Send, {Esc}
		}
		SpawnMeleeTerranUnit(_point, _unit, _amount) {
			static MELEE_TERRAN_UNITS := {scv: "s", marine: "a", reaper: "r", marauder: "d", ghost: "g", hellion: "e", hellbat: "h", widowmine: "i", siegetank: "m", siegemode: "e", cyclone: "n", mule: "e", thor: "t"}
			Send, r
			_point.LClick()
			this.OpenMeleeMenu()
			Send, t
			Loop, %_amount%
				Send, % MELEE_TERRAN_UNITS[_unit]
			Send, {Esc}
		}
		SpawnMeleeTerranShip(_point, _ship, _amount) {
			static MELEE_TERRAN_SHIPS := {medivac: "d", viking: "v", assaultmode: "a", liberator: "n", defendermode: "f", raven: "r", banshee: "e", battlecruiser: "b"}
			Send, r
			_point.LClick()
			this.OpenMeleeMenu()
			Send, t
			Send, x
			Loop, %amount%
				Send, % MELEE_TERRAN_SHIPS[_ship]
			Send, {Esc}
		}
		SpawnNeutralUnit(_point, _unit) {
			static NEUTRAL_UNITS := {mineral: "m", vespene: "v", life: "h", energy: "e", forcefield: "f"}	; incomplete
			this.OpenMeleeMenu()
			Send, h
			Send, % NEUTRAL_UNITS[_unit]
			_point.LClick()
			Send, {Esc}
		}
		SpawnSecondaryNeutralUnit(_point, _unit) {
			static SECONDARY_NEUTRAL_UNITS := {rocks: "r", hrocks: "t", vrocks: "y", drrocks: "u", dlrocks: "i"}	; incomplete
			this.OpenMeleeMenu()
			Send, h
			Send, x
			Send, % SECONDARY_NEUTRAL_UNITS[_unit]
			_point.LClick()
			Send, {Esc}
		}
		OpenMeleeMenu() {
			this._openMainMenu("melee")
		}
		OpenCampaignMenu() {
			this._openMainMenu("campaign")
		}
		_openMainMenu(_menu) {
			Send, {Esc}{Esc}{Esc}
			if (this.mainMenu != _menu) {
				Send, n
				this.mainMenu := _menu
			}
		}
		CreateObjective(_text) {
			this.Chat("-q " . _text)
		}
		CreatePingHere() {
			this.Chat("-p")
		}
		DestroyForceFields(_coord) {
			_coord.OnScreen()
			this.Chat("-f")
		}
		GiveGodAllUpgrades() {
			; TODO
			throw Exception("NOT IMPLEMENTED YET")
		}
		SelectGod() {
			Send, {F3}
		}
		GiveUnitsToPlayer(_index) {
			this._openPlayerMenu()
			_slots := this.GetCoords("give units to: slots")[1].battlefield
			if (_index > _slots.Count()) {
				throw Exception("Index out of bounds: " _index, "Slots: " _slots.Count())
			}
			_slots[_index].Click()
		}
		GiveUnitsToHostilePlayer() {
			this._openPlayerMenu()
			this.FindImages("player select: hostile")[1]
					.Center().LClick()
		}
		BuffStats(_point:="", _count:=1) {
			if (_point) {
				_point.LClick()
			}
			_buff := this.GetCoords("statistics +/-")[1].battlefield[1]
			Loop, %_count%
				_buff.LClick()
		}
		NerfStats(_point:="", _count:=1) {
			if (_point) {
				_point.LClick()
			}
			_nerf := this.GetCoords("statistics +/-")[1].battlefield[2]
			Loop, %_count%
				_nerf.LClick()
		}
		_openPlayerMenu() {
			if (!this.IsVisible("player select: neutral")) {
				this.GetCoords("give units to")[1]
					.battlefield[1].LClick()
			}
		}
		_getNumPlayers() {
			this._openPlayerMenu()
			_neutral := this.FindImages("player select: neutral")[1].bottomRight
			_found := 0
			for _i, _slot in this.GetCoords("give units to: slots").battlefield {
				if (_slot.y > _neutral.y) {
					; we're at "Hostile"
					_found := _i - 2
				}
			}
			if (_found < 1)
				throw Exception("Failed to determine number of players.")
			return _found
		}
	}
}

