; Function object base class
; see:  https://autohotkey.com/docs/objects/Functor.htm#User-Defined-Examples
class FunctionObject {
    __Call(method, args*) {
        if (method = "")
            return this.Call(args*)
        if (IsObject(method))
            return this.Call(method, args*)
    }
}
