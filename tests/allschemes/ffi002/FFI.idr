module FFI

import Data.Fin

data Secs = Zero | One | Two

%foreign "scheme,racket:blodwen-sleep"
         "C:idris2_sleep, libidris2_support, idris_support.h"
prim__sleep : Secs -> PrimIO ()

%foreign "scheme:(lambda (n x) (+ x 1))"
prim__plus : Fin n -> Nat

main : IO ()
main = do
  primIO $ prim__sleep One
  printLn (prim__plus {n = 10} 5)
