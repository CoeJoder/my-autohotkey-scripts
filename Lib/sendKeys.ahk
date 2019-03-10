sendKeys(title, keys, x, y) {
	println("sendKeys: " . keys)
	;~ if (WinActive(title)) {
		;~ SetControlDelay	, -1
		;~ ControlClick, X%x% Y%y%, %title%,,,, NA
	;~ }
	ControlSend, , %keys%, %title%
}
