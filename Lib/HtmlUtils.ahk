#Include <FunctionObject>

;-------------------------------------------------------------
; HtmlUtils
;    Static methods for generating HTML snippets.
;-------------------------------------------------------------
class HtmlUtils {
	Kbd(text) {
		return Format("<kbd>{1:s}</kbd>", text)
	}

	Span(text, fontWeight := "normal") {
		return Format("<span style=""font-weight: {2:s};"">{1:s}</span>", text, fontWeight)
	}

	SpanWithColor(text, color, fontWeight := "normal", fontFamily := "Consolas; sans-serif") {
		return Format("<span style=""color: {2:s}; font-weight: {3:s}; font-family: {4:s};"">{1:s}</span>", text, color, fontWeight, fontFamily)
	}
	
	CenteredHeader(text, fontFamily := "Consolas; sans-serif", emSize := 2) {
		return Format("<center><h1 style=""font-family: {3:s}; font-size: {2:i}em; color: yellow;"">{1:s}</h1></center>", text, emSize, fontFamily)
	}
}
