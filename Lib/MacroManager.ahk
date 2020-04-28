/*
 ``````````````````````````````````````````````````````````````````````````````
 ` MacroManager
 ` A text macro manager which assigns command keys to each (a-z).
 `
 ` Author: CoeJoder
 ``````````````````````````````````````````````````````````````````````````````
 */
class MacroManager {
	
	class Macro {
		static _INSTANCE_COUNT := 0
		static _MAX_INSTANCES := 26
		static _ASCII_ALPHABET_OFFSET := 96
		
		index := ""
		commandKey := ""
		title := ""
		subtitle := ""
		body := ""
		
		__New(title, subtitle, body) {
			if (MacroManager.Macro._INSTANCE_COUNT + 1 > MacroManager.Macro._MAX_INSTANCES) {
				throw Exception(Format("Max Macro count reached ({:}).", MacroManager.Macro._MAX_INSTANCES))
			}
			MacroManager.Macro._INSTANCE_COUNT++
			asciiCommandKey := MacroManager.Macro._ASCII_ALPHABET_OFFSET + MacroManager.Macro._INSTANCE_COUNT
			Transform, tempCommandKey, Chr, %asciiCommandKey%
			
			this.index := MacroManager.Macro._INSTANCE_COUNT
			this.commandKey := tempCommandKey
			this.title := title
			this.subtitle := subtitle
			this.body := body
		}
	}
	
	_macroList := []
	
	AddMacro(title, subtitle, body) {
		this._macroList.Push(new MacroManager.Macro(title, subtitle, body))
	}
	
	ClearMacros() {
		this._macroList := []
		MacroManager.Macro._INSTANCE_COUNT := 0
	}
	
	GetMacroByCommandKey(commandKey) {
		for index, macro in this.GetMacros() {
			if (macro.commandKey = commandKey) {
				return macro
			}
		}
		return ""
	}
	
	GetMacros() {
		return this._macroList
	}
	
	; [static] test driver
	_Main() {
		mm := new MacroManager()
		mm.AddMacro("Screen resolution .reg file", "notepad", Format("
			(LTrim
			REGEDIT4
			
			[HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Hardware Profiles\0001\System\CurrentControlSet\Services\vmx\svga\Device0]
			""DefaultSettings.XResolution""=dword:00000400
			""DefaultSettings.YResolution""=dword:00000300
			)"))
		mm.AddMacro("Java ""Hello, World"".", "notepad", Format("
			(LTrim
			public static void main(String[] args) {
				System.out.println(""Hello, Wrrrrld!"")
			}
			)"))
			
		println("Macros found:")
		for index, macro in mm.GetMacros() {
			println(Format(" index: {:}`n commandKey: {:}`n title: {:}`n subtitle: {:}`n body:`n{:}`n"
				, macro.index, macro.commandKey, macro.title, macro.subtitle, macro.body))
		}
	}
}

if (A_ScriptName="MacroManager.ahk") {
	MacroManager._Main()
}
