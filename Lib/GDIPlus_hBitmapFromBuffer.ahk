/*
 GDIPlus_hBitmapFromBuffer() returns the bitmap object
 
 TODO [JN] convert it to be compatible with 64-bit AHK (already done for the to-buffer function)
 
*/
GDIPlus_hBitmapFromBuffer( ByRef Buffer, nSize ) { ;  Last Modifed : 21-Jun-2011
; Adapted version by SKAN www.autohotkey.com/forum/viewtopic.php?p=383863#383863
; Original code   by Sean www.autohotkey.com/forum/viewtopic.php?p=147029#147029
 hData := DllCall("GlobalAlloc", UInt,2, UInt,nSize )
 pData := DllCall("GlobalLock",  UInt,hData )
 DllCall( "RtlMoveMemory", UInt,pData, UInt,&Buffer, UInt,nSize )
 DllCall( "GlobalUnlock" , UInt,hData )
 DllCall( "ole32\CreateStreamOnHGlobal", UInt,hData, Int,True, UIntP,pStream )
 DllCall( "gdiplus\GdipCreateBitmapFromStream",  UInt,pStream, UIntP,pBitmap )
 DllCall( "gdiplus\GdipCreateHBITMAPFromBitmap", UInt,pBitmap, UIntP,hBitmap, UInt
,DllCall( "ntdll\RtlUlongByteSwap",UInt
,DllCall( "GetSysColor", Int,15 ) <<8 ) | 0xFF000000 )
 DllCall( "gdiplus\GdipDisposeImage", UInt,pBitmap )
 DllCall( NumGet( NumGet(1*pStream)+8 ), UInt,pStream ) ; IStream::Release
Return hBitmap
}