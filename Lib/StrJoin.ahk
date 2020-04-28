/*
 ``````````````````````````````````````````````````````````````````````````````
 ` StrJoin()
 ` Join a collection of objects into a single string
 `
 ` @sep      - term separator
 ` @param    - array or objects of terms
 ` @toString - [optional] function to convert terms into strings
 ` return    - the joined string
 ``````````````````````````````````````````````````````````````````````````````
 */
StrJoin(sep, params, toString="") {
	str := ""
    for i, param in params {
		if (toString) {
			param := toString.Call(param)
		}
        str .= param . sep
	}
    return (sep != "") ? SubStr(str, 1, -StrLen(sep)) : SubStr(str, 1)
}
