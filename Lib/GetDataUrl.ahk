GenerateDataUrl(fileFullPath) {
    Static encoding := "base64"
 
    SplitPath, fileFullPath,,, ext
    mimeType := GetMimeType("." ext)
 
    FileGetSize, fileSize, %fileFullPath%
    FileRead, fileContent, *c %fileFullPath%
    encodedFileContent := Base64Encode(fileContent, fileSize)
 
    Return "data:" mimeType ";" encoding "," encodedFileContent
}
 
GetMimeType(ext) {
    RegRead, mimeType, HKCR, %ext%, Content Type
    Return mimeType
}
 
Base64Encode(ByRef InData, InDataLen) { ; by SKAN
    DllCall( "Crypt32.dll\CryptBinaryToString" ( A_IsUnicode ? "W" : "A" ), UInt,&InData, UInt,InDataLen, UInt,1, UInt,0, UIntP,TChars, "CDECL Int" )
    VarSetCapacity( OutData, Req := TChars * ( A_IsUnicode ? 2 : 1 ) )
    DllCall( "Crypt32.dll\CryptBinaryToString" ( A_IsUnicode ? "W" : "A" ) , UInt,&InData, UInt,InDataLen, UInt,1, Str,OutData, UIntP,Req, "CDECL Int" )
    Return OutData
}
