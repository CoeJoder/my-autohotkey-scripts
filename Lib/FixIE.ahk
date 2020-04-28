/*
 ``````````````````````````````````````````````````````````````````````````````
 ` FixIE()
 ` Changes the rendering mode of the ActiveX browser control by editing the registry.
 ` Modified from:  https://autohotkey.com/board/topic/93660-embedded-ie-shellexplorer-render-issues-fix-force-it-to-use-a-newer-render-engine/
 `
 ` @Version - The IE version to use (default uses system's installed browser, incl. Edge).
 `            Empty string will delete the registry value.
 ` @ExeName - The name of the process affected (default uses the currently running process).
 ` return   - A map of the previous registry key values.
 ``````````````````````````````````````````````````````````````````````````````
 */
FixIE(Version=0, ExeName="")
{ 
	; [JN] added 32-bit key as well
	static HKCU_Key32 := "HKEY_CURRENT_USER\Software\Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_BROWSER_EMULATION"
	static HKCU_Key64 := "HKEY_CURRENT_USER\Software\WOW6432Node\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION"
	
	static AllKeys := [HKCU_Key32, HKCU_Key64]
	static Versions := {7:7000, 8:8888, 9:9999, 10:10001, 11:11001}
	
	if Versions.HasKey(Version)
		Version := Versions[Version]
	
	if !ExeName
	{
		if A_IsCompiled
			ExeName := A_ScriptName
		else
			SplitPath, A_AhkPath, ExeName
	}
	
	PreviousValues := {}
	for Index, RegKey in AllKeys
	{
		RegRead, PreviousValue, %RegKey%, %ExeName%
		PreviousValues[RegKey] := PreviousValue
		if (Version = "")
			RegDelete, %RegKey%, %ExeName%
		else
			RegWrite, REG_DWORD, %RegKey%, %ExeName%, %Version%
	}
	
	return PreviousValues
}
