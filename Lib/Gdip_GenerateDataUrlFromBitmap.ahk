#include <GdiPlus_SaveImageToBuffer>
#include <Base64>
/*
 * GenerateDataUrlFromBitmap
 * 	Desc: Generates a web-compatible data URI encoded in base 64 from a bitmap obj.  
 *  	  Requires Gdip.
 *  @bitmap  - a pointer to a bitmap/hbitmap
 *  @type    - BMP DIB RLE JPG JPEG JPE JFIF GIF TIF TIFF PNG.
 *  		   JPG is default
 *  @quality - For JPG, pass a value from 0 to 100. For TIF pass 6, only if you required uncompressed image.
 * 			   If a value is not passed, default compression will be applied
 *  Returns the base64-encoded string.
 * 	Author: CoeJoder
 */
Gdip_GenerateDataUrlFromBitmap(bitmap, type:="JPG", quality:="") {
	bufsize := GdiPlus_SaveImageToBuffer(bitmap, buf, type, quality)
    Base64_encode(encoded, buf, bufsize)
    RegRead, mimeType, HKCR, % ("." type), Content Type
    Return "data:" mimeType ";base64," encoded
}
