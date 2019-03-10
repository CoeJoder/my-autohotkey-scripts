;#####################################################################################

; Function			Gdip_BitmapFromWindowArea
; Description	Gets a gdi+ bitmap from an area of a window
;
; Hwnd				the target window
; x, y, w, h		the area to capture (relative to window)
; Raster			raster operation code
;
; return      		If the function succeeds, the return value is a pointer to a gdi+ bitmap
;						-1:	window does not exist
; notes				If no raster operation is specified, then SRCCOPY is used to the returned bitmap

Gdip_BitmapFromWindowArea(Hwnd, x, y, w, h, Raster="")
{
	if !WinExist("ahk_id " Hwnd)
		return -1
	hhdc := GetDCEx(Hwnd, 3)

	chdc := CreateCompatibleDC(), hbm := CreateDIBSection(w, h, chdc), obm := SelectObject(chdc, hbm), hhdc := hhdc ? hhdc : GetDC()
	BitBlt(chdc, 0, 0, w, h, hhdc, x, y, Raster)
	ReleaseDC(hhdc)
	
	pBitmap := Gdip_CreateBitmapFromHBITMAP(hbm)
	SelectObject(chdc, obm), DeleteObject(hbm), DeleteDC(hhdc), DeleteDC(chdc)
	
	return pBitmap
}
