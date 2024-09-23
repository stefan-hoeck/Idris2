module FFI

data Secs = Zero | One | Two

%foreign "scheme,racket:blodwen-sleep"
         "C:idris2_sleep, libidris2_support, idris_support.h"
prim__sleep : Secs -> PrimIO ()

main : IO ()
main = primIO $ prim__sleep One
