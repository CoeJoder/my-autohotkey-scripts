/*
GdiPlus_SaveImageToBuffer() returns the size of created data buffer.

Tested in Windows 10 Pro 64-bit with AHK 1.1 U64/U32/A32
Parameters:

Image : A handle to either GDI or GDIPlus Bitmap.
ICON is not supported owing to complex code required for Alpha transparency.

Buffer : Variable to hold raw image data.

Type : BMP DIB RLE JPG JPEG JPE JFIF GIF TIF TIFF PNG.
JPG is default

Quality : For JPG, pass a value from 0 to 100. For TIF pass 6, only if you required uncompressed image.
If a value is not passed, default compression will be applied

Note: GDI+ needs to be initialized before calling this function. I presume you already have gdip.ahk in UserLib
*/
GdiPlus_SaveImageToBuffer( Image, ByRef Buffer, Type="JPG", nQuality="") {
	/*
	Modified by CoeJoder for 64-bit compatibility - 02-Aug-2018
	
	Code adapted by SKAN for Wicked, Created / Last Modified:  09-Oct-2012
                http://www.autohotkey.com/community/viewtopic.php?&t=93472


	Credit Sean: Screen Capture with Transparent Windows and Mouse Cursor
                http://www.autohotkey.com/community/viewtopic.php?t=18146
                http://www.autohotkey.com/community/viewtopic.php?p=408135#p408135


                How to convert Image data (JPEG/PNG/GIF) to hBITMAP ?
                http://www.autohotkey.com/community/viewtopic.php?p=147029#p147029
	*/
	static PTR := A_PtrSize ? "Ptr" : "UInt"
	static PTR_SIZE := (A_PtrSize ? A_PtrSize : 4)
	static _CLSID := 16
	static _GUID := 16
	static _DWORD := 4
	static _ULONG := 4
	static ENCODER_EXT_OFFSET := _CLSID + _GUID + (3 * PTR_SIZE) 			; (A_PtrSize = 8 ? 56 : 44)
	static ENCODER_SIZE := _CLSID + _GUID + (7 * PTR_SIZE) + (_DWORD * 4) 	; (A_PtrSize = 8 ? 104 : 76)
	static ENC_PARAM_NUMVALS_OFFSET := _GUID + PTR_SIZE 					; (A_PtrSize = 8 ? 24 : 20)
	static ENC_PARAM_TYPE_OFFSET := _GUID + PTR_SIZE + _ULONG				; (A_PtrSize = 8 ? 28 : 24)
	static ENC_PARAM_SIZE := _GUID + (2 * _ULONG) + PTR_SIZE 				; (A_PtrSize = 8 ? 32 : 28)
	static ENC_PARAM_VALUE_OFFSET := (3 * _ULONG) + PTR_SIZE				; (A_PtrSize = 8 ? 20 : 16)
	
	; Test for GDI / GDIPlus bitmap
	If DllCall("GetObjectType", PTR,Image) = 7
		DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", PTR,Image, UInt,0, UIntP,pBM)
	Else If DllCall("gdiplus\GdipGetImageType", PTR,Image, UIntP,ErrorLevel) = 0
		pBM := Image
	Else Return 0

	; Determine Encoder CLSID
	DllCall("gdiplus\GdipGetImageEncodersSize", UIntP,nCount, UIntP,nSize)
	VarSetCapacity(ci, nSize)
	DllCall("gdiplus\GdipGetImageEncoders", UInt,nCount, UInt,nSize, UInt,&ci)

	Loop %nCount% {
		If ((pStr := NumGet(ci, Ix := ENCODER_SIZE * (A_Index-1) + ENCODER_EXT_OFFSET)) && A_IsUnicode) {
			Extns := DllCall("MulDiv", PTR,pStr, Int,1, Int,1, Str)
		}
		Else {
			VarSetCapacity(Extns, nSize := DllCall("lstrlenW", PTR,pStr) + 1, 0)
			DllCall("WideCharToMultiByte", UInt,0, UInt,0, PTR,pStr, Int,-1, Str,Extns, Int,nSize, Int,0, Int,0)
		}
		If ((Found := InStr(Extns, "*." Type)) && (pEnc := &ci + Ix - ENCODER_EXT_OFFSET))
			Break
	} IfLess, Found, 1, Return 0

	; Determine Encoder Parameters in case of JPG/TIF
	pEncP := 0
	If (InStr(".JPG.JPEG.JPE.JFIF", "." . Type) && nQuality <> "") {
		nQuality := (nQuality < 0 || nQuality > 100) ? 75 : nQuality
		DllCall("gdiplus\GdipGetEncoderParameterListSize", PTR,pBM, PTR,pEnc, UIntP,nSz)
		VarSetCapacity(pi,nSz,0)
		DllCall("gdiplus\GdipGetEncoderParameterList", PTR,pBM, PTR,pEnc, UInt,nSz, PTR,&pi)
		Loop % NumGet(pi, "UInt") {
			If (NumGet(pi, ENC_PARAM_SIZE * (A_Index-1) + ENC_PARAM_NUMVALS_OFFSET, "UInt") = 1 && NumGet(pi, ENC_PARAM_SIZE * (A_Index-1) + ENC_PARAM_TYPE_OFFSET, "UInt") = 6) {
				pEncP := &pi + ENC_PARAM_SIZE * (A_Index-1)
				NumPut(nQuality, NumGet(NumPut(4, NumPut(1, pEncP + 0, "UInt") + ENC_PARAM_NUMVALS_OFFSET, "UInt"), "UInt"), "UInt")
				Break
			}
		}
	}
	Else If (InStr(".TIF.TIFF", "." . Type) && nQuality <> "") {
		nQuality := (nQuality < 2 || nQuality > 6) ? 6 : nQuality
		DllCall("gdiplus\GdipGetEncoderParameterListSize", PTR,pBM, PTR,pEnc, UIntP,nSz)
		VarSetCapacity(pi, nSz, 0)
		DllCall("gdiplus\GdipGetEncoderParameterList", PTR,pBM, PTR,pEnc, Int,nSz, PTR,&pi)
		Loop % NumGet(pi, "UInt") {
			If (NumGet(pi, ENC_PARAM_SIZE * (A_Index-1) + ENC_PARAM_NUMVALS_OFFSET, "UInt") = 5 && NumGet(NumGet(pi, ENC_PARAM_SIZE * (A_Index-1) + (ENC_PARAM_SIZE), PTR), "UInt") = 2) {
				pEncP := &pi + ENC_PARAM_SIZE*(A_Index-1)
				NumPut(nQuality, NumGet(NumPut(1, NumPut(1, pEncP + 0, "UInt") + ENC_PARAM_VALUE_OFFSET, "UInt") + _ULONG, PTR), "UInt")
				Break
			}
		}
	}
	
	; Save Image to Stream and copy it to Buffer
	DllCall("ole32\CreateStreamOnHGlobal", PTR,0, Int,1, UIntP,pStream)
	DllCall("gdiplus\GdipSaveImageToStream", PTR,pBM, PTR,pStream, PTR,pEnc, PTR,pEncP)
	DllCall("gdiplus\GdipDisposeImage", PTR,pBM)
	DllCall("ole32\GetHGlobalFromStream", PTR,pStream, UIntP,hData)
	pData := DllCall("GlobalLock", PTR,hData)
	nSize := DllCall("GlobalSize", PTR,pData)
	VarSetCapacity(Buffer, nSize, 0)
	DllCall("RtlMoveMemory", PTR,&Buffer, PTR,pData, UInt,nSize)
	DllCall("GlobalUnlock", PTR,hData)
	DllCall(NumGet(NumGet(1 * pStream, PTR) + 8, PTR), PTR,pStream)
	DllCall("GlobalFree", PTR,hData)
	return nSize
}
