; Base64 encoding & decoding
; https://autohotkey.com/board/topic/85709-base64enc-base64dec-base64-encoder-decoder/
; by SKAN
Base64_encode(ByRef OutData, ByRef InData, InDataLen) {
 DllCall( "Crypt32.dll\CryptBinaryToString" ( A_IsUnicode ? "W" : "A" )
        , UInt,&InData, UInt,InDataLen, UInt,1, UInt,0, UIntP,TChars, "CDECL Int" )
 VarSetCapacity( OutData, Req := TChars * ( A_IsUnicode ? 2 : 1 ) )
 DllCall( "Crypt32.dll\CryptBinaryToString" ( A_IsUnicode ? "W" : "A" )
        , UInt,&InData, UInt,InDataLen, UInt,1, Str,OutData, UIntP,Req, "CDECL Int" )
Return TChars
}

Base64_decode(ByRef OutData, ByRef InData) {
 DllCall( "Crypt32.dll\CryptStringToBinary" ( A_IsUnicode ? "W" : "A" ), UInt,&InData
        , UInt,StrLen(InData), UInt,1, UInt,0, UIntP,Bytes, Int,0, Int,0, "CDECL Int" )
 VarSetCapacity( OutData, Req := Bytes * ( A_IsUnicode ? 2 : 1 ) )
 DllCall( "Crypt32.dll\CryptStringToBinary" ( A_IsUnicode ? "W" : "A" ), UInt,&InData
        , UInt,StrLen(InData), UInt,1, Str,OutData, UIntP,Req, Int,0, Int,0, "CDECL Int" )
Return Bytes
}

; just used in the main method/test driver
VarZ_Save( ByRef Data, DataSize, TrgFile ) { ; By SKAN
 ; http://www.autohotkey.com/community/viewtopic.php?t=45559
 hFile :=  DllCall( "_lcreat", ( A_IsUnicode ? "AStr" : "Str" ),TrgFile, UInt,0 )
 IfLess, hFile, 1, Return "", ErrorLevel := 1
 nBytes := DllCall( "_lwrite", UInt,hFile, UInt,&Data, UInt,DataSize, UInt )
 DllCall( "_lclose", UInt,hFile )
Return nBytes
}

;~ ; Encoding / Decoding test
;~ If (A_ScriptName="Base64.ahk") {
	;~ SetWorkingDir, %A_ScriptDir%
	;~ GoSub, LoadPNGDATA
	;~ Bytes := Base64_decode( BIN, PNGDATA )
	;~ VarZ_Save( BIN, Bytes, "ahk.png" )
	;~ VarSetcapacity( PNGDATA, 0 )

	;~ Gui, Margin, 20, 20
	;~ Gui, Add, Picture,, ahk.png
	;~ Gui, Show
	;~ Return

	;~ GuiClose:
	 ;~ ExitApp

	;~ LoadPNGDATA:
	;~ PNGData=
	;~ (
	;~ iVBORw0KGgoAAAANSUhEUgAAAPAAAABOCAYAAAAelZuXAAAMvElEQVR42uydUW8U
	;~ 1xmG9yJyHCuBNKItILBQFVUVErkIVxG+yHXpbS9K/0DoDyDkB6T8AJL2HgtxgRCh
	;~ LkKkQsRyXAKinV27jrGQ2a4Xs+suZrMYh7q5mO6z8ddwfHb3eM5skWfOZ+nFO3hm
	;~ PPP4POd8c2bWLmzjY6id4W1n39GRnRyOMUkcbJSf8tt5/Ka++tvB6b9+9V6tvjKz
	;~ vLwcVyqVThYflHvm/v37WU7Xc6pWq3G9Xp/58tad96bulA4qP+W34/kV/zF/9FGt
	;~ FlUfLtdXnzRj0mq14tbTtf9lbS3r4Tx6h3OWVKsP48XFB/VHtXo0f+/eu8pP+e1Y
	;~ fp9//pfRperD4vKjWtx4vNpJs9k04g+SbV5WvI7DOtdGo9FJrVaL5+bm4qWlpeiL
	;~ 6TsHB8Av8xztvDR+OWWYnl/hTxMTYw/K5frKykpMVldXjdATPn/+3My/NyQsW1n/
	;~ tkvWe2ft2XqS2Pv4NlE4pxdjnK9woIwrl8txsVisf/bZlWOe/IRhLjk2v2mRl8Ev
	;~ rwwNeVf+1SDIS7bB79D7wwsLCyWGbNkI+yX0EBv/+c6KDzTybN0IAJKG7cx4QHu6
	;~ tk6kZDHOWThwLbK4uBhHURTP31soMrGSkB/hB5Nnjgj8/+aXf4bNlsibiB8fu6Ji
	;~ SSYMDIitpwYwo+F/01qT8AO0ghRbQmnUKxx40nTbT7fvax0b4CUcf6/GR5hooIy5
	;~ e/du3GY14uDn6ARzy5FlznuQ/EJk6MOvsOf27dud2a/KUpWyh3TKlo2NDQnfAKEl
	;~ WYZGrMmDbo0PJu3RIZ6dnY1v3rwZF9489Gab1yvb4CdlZEgc2U7OX4RMy4/wvUNi
	;~ mLT9FfZOfTmN6dTbsjGQBBhlATvPAzQ5ZisiL42IAI/Mff11XCqV4hs3bsSFXQfe
	;~ EoAOfrK/4DhSCpMB8AuVYaL2x8LeyclJAHYiPef68w0JZUoOoRnnQ5lmySvlCyXe
	;~ 9evX48Ib+/YUDv96aBv8ZCQJjSMj5qD4Bc0QFm5+ABzZs5/heX5+XjZiB8YFdgjQ
	;~ WI8RQCIsKF+YRLh27VpMuQdABz9phHQKwXF8vNqEQVp+Eo4lNIZs6+BnA8R06m3C
	;~ AVkza3mH9qTZYsaPCAcpX4gB0MFPRiAEDpHjoPghcIgMWc/FzwRIfY3p9IKEETjA
	;~ hie9HgwkwGMG0ADo4Cf7CbEjZL1B8aMSCpUh8hLh5xSYFekFCRMHQTc8GEiiog3Q
	;~ wU9GEjrCEDkOgp8ydPCzALIivSDWLz+qBd/wJFEUWQBd/AiNr1ZTjin4KUMHPxNg
	;~ FAGQMPMXfMMjpZmZDhfuU1oAe/OjAWpHmI5f2AxXm8LCwc8ECHCiAv/QAOn9rB7Q
	;~ wS/4xpeSnwr8g8D9+QnA9j0mFdhfYPipwP4Cw08FVoFVYBU4XIFZSQX2F5h1VGCz
	;~ 8ZEk/FTgzTxWgVVgFVgFVoG/F5hZQBXYX2D4qcD+AsNPBVaBVWAVWAVWgVXgHSsw
	;~ T8MQFXiLwLdu3TIAOvjJ9nBUgf35ERXY4OcSOIp0BPYXWPhJVOB2UvDTETihwJtv
	;~ XdIR2FNg4SfbawndTnJ+OgKrwCqwCqwCq8AqsAqcCYHbX1SB+wg8PT1tArT5qcDd
	;~ Bd4uPxW4t8DwcwrMVDUzgPp2wqQC2/zkt0uowO2k4EdU4EQCR5EK7C8w/FRgf4Hh
	;~ pwJ7CkydrbeRfAS2+WkJ7RDYwU9L6KQCX716VQX2Fxh+KrC/wPBTgQcgMCvrJFYX
	;~ gfnLATASgA5+RB+l3IwnP32U0sVPALazf+LPV7GclfVRyoQC2/x0FtoQOBk/fZTS
	;~ S+CJiXhqakoF9hNY+KnAfgILPxV4IAJHkQrsLzD8VGB/geGnAqvAKrAKHJDAV65c
	;~ ASD34lTgHgJznWYBtPmpwJbAifipwCKwxU8FTi/w6z/9iQrsLzD8VGBvgW1+LKjA
	;~ /gLzWgX2F5jXKrAKrAKrwCEL/NqBy5cvD0zgD09/FI+NjcUff3wmXwJPTHANIgAt
	;~ fr4CS06e/B3cnI3v2LGx+IMPTmZIYH9+boZufpJPPvm0w+43J04gSBYEdvMTgGlH
	;~ YMk/K1W+SSe7d+8ORWD4pRaYxgc3h8CsQ0PMlcD+I7Cbn8jL144cOcIfDs+bwIWB
	;~ Cfz7M2c6oATm+Pj5vAm8t0sJqAI7BPbhl15gW94H5QpyZFhg+NkCpy6hJaOjo52R
	;~ t1ia7UD75fHjuRO4naEu/FRgh8Ae/NIJbMub6Wtgm58AHP7RKD0gK7Gyp8Bynyo+
	;~ ceK38ZNmC2gs82ic9HqZFhhGFkCbnwpsCezDL73An/7hj5a8GRPYzU8AYrcARDgf
	;~ gREXYJNT0wjMJBbLfM63wDY/FdghsJOfv8CWvGWRN48Cby4AMNW7kZi8onSmhEZe
	;~ wn6AyP/lQWDKvA7AQ+8PO/ilEvj06Y+MnPrwtJGMCezHz19gkZcwM01bzKrAbn4C
	;~ ELvTCCzQBJiEhsb/fzE5lQuBee8qAB380gjMZyMwfCFZFtjNL73AmyPvOwwovOY6
	;~ OC8C2/xYkB6QN1R7CgwwYDERYQgskwjce8u6wJcuXeJc9rcz3IOfltC2wB78vAUW
	;~ eakIaYtyO5MBJIsCu/kBkH/pAZMKLGHngOoyenANIhC5/5ZXgeGnAvsLDL9BCYy8
	;~ cowyDyMTWTkUmIVXd/8shcAyecVnrtmsSNl39uzZHAj82gGYbeWnAjsE9uA3qPvA
	;~ x4//SqrAzAsMv0ELzOhKLHASyhdpdFkW+OLFi5yHCuwnsPB72QIzC81EqlwPZ+hB
	;~ Dje/VzYXfAVm8kpG374NTwD+PSplWmBueRT2HR3Zwk8FdgjswS+9wPYgQnidXYGF
	;~ nwDcXHibGS4PgYEmk1d9G55ci5w6dSorAiOvIfCFCxc4h9F2Rhz8ZB9wVIH9+aUX
	;~ 2H4qi8GE+ZidLrCz/cljbF0BVqsP47Vn6y/GAjYzOydAXG/hYuSVdXcwtG0JfKjw
	;~ 48Ov0/hID37SeBHY4ph3gR9bAnvzk18razH0EJhwHZyFyzm2dbc/BN5c+LkBMIri
	;~ crkcP11bN5L392CyP1NeE+D58+djrtfavDoASS9+0gArlUp4HFcaA+OHwJWlaoAM
	;~ V1z8Cv0EBlxo0Kg6AGZFfjM+ALleg5mrAcq2CwsLYXIslSS+/EJmSKdFJUK68xOB
	;~ N23+BVPU8iQMAXyj0cgvNDt0WgCz8mIPSLlnjCB9+EkajdWQOFLBDIKfMuzPr/Nh
	;~ CMxKvJ1LekH+Mlwg0Bg1OOeugQmTdOPj41YD7MNPwggSLsf0/BiFg2To5icCDw0d
	;~ BiArSRkjYbYu59DYD6DknK0IwHPnzn0P8K23d1G9EAc/9kt4CihMjun5Bc+wKz8R
	;~ mAUAco9JAG6BSO/Hc815hMZkHefYL/DoCpA4+BkNMEiO6fn9t72zaXEaCANwEQRd
	;~ MYh4Ucoe9uxBEFZbxJO17LIrXoRFals8eFAR/0YPJfYHlPbUQy8u1UsppfRP7KoL
	;~ e+3Fj5+wzgN5YeLsJi42bRrfwANtSSaZp5PJzJvM5L93iI+oE5gvIhCkGeNAx5oD
	;~ WHVpMJvNiHKS179iOp06VxAeQoj150JkOmsek/CnDiP8cQI7QSxWIpAAUYkhkH4J
	;~ wYV46IgvmsjjoUaLw8nzZDKxgwge7mL8xSHBmqx5TN5f9h3G+5MTWG6kI5CVpBYk
	;~ kYTgD5oXpLcIKFzyLOo6hQ536k/9LcuffQJf4sd+v3+IQCAamFSGgfTjSY9AChRv
	;~ R/+4v3/AgGoKHQJB/am/pfmTW0nM9l6pvKjy9jMECmyYANQmUcj+HSLWT/K4pfny
	;~ vVar7+Wu3rxBoUOgIP4Gg8EP9af+kvBH/7darVn+wtN6eltb2wUj+XA0Gp0IZ2Vk
	;~ PB4vAvb1r8wlTZp3vV7vYGd3954EYAT1p/6W4o/FHhFCLWiGBD7rdrtHDO3ikh0H
	;~ V+zz8ulzJGfuS/5UWwbfbYbDoQPbnhN7e2q+n+12+0u9Xn/Kqx2ZQQJnNra/Tqfz
	;~ 1fRVfqk/9TcnfyfG3zfXX3gJooGX84VC4XG5XH7v+x+OGX4FzWbTodFoJM2p+/V9
	;~ 34bf5k6r1ZLPx6VS6V2xWHwUTOe5FrhSf+ovPf6s2tAz3KJhbXho4KyvGF4aXgW8
	;~ zuUuvDmd3Ns0wzFGQf6CvD43PDE84CED5NF0kb6b+lN/qfInfWGaMqxIRxmRwT2n
	;~ 24Y7hrsBmxb3V5zNEOTv4hXyirQNIn6BizVAHqg/9Zc6fyLRGmLoAX0TaoA/yAPT
	;~ e2QFCowF0q6BNFss1J/6S6c/FjuwAPRNQpCol7+eWbgCgOQ/LE/9qb80+3NrQ9rd
	;~ QGJWopnCzluEOPWn/lbHn9SGDkjNIm5eZVF/6i+V/n4D8vgs7OivT6kAAAAASUVO
	;~ RK5CYII=
	;~ )
	;~ Return
;~ }