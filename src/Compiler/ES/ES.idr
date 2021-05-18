module Compiler.ES.ES

import Compiler.Common
import Compiler.ES.Imperative
import Libraries.Utils.Hex
import Data.List1
import Data.Strings
import Libraries.Data.SortedMap
import Libraries.Data.String.Extra

import Core.Directory

%hide Data.Strings.lines
%hide Data.Strings.lines'
%hide Data.Strings.unlines
%hide Data.Strings.unlines'

data ESs : Type where

record ESSt where
  constructor MkESSt
  preamble : SortedMap String String
  ccTypes : List String

jsString : String -> String
jsString s = "'" ++ (concatMap okchar (unpack s)) ++ "'"
  where
    okchar : Char -> String
    okchar c = if (c >= ' ') && (c /= '\\')
                  && (c /= '"') && (c /= '\'') && (c <= '~')
                  then cast c
                  else case c of
                            '\0' => "\\0"
                            '\'' => "\\'"
                            '"' => "\\\""
                            '\r' => "\\r"
                            '\n' => "\\n"
                            other => "\\u{" ++ asHex (cast {to=Int} c) ++ "}"

esName : String -> String
esName x = "__esPrim_" ++ x


addToPreamble : {auto c : Ref ESs ESSt} ->
                String -> String -> String -> Core String
addToPreamble name newName def =
  do
    s <- get ESs
    case lookup name (preamble s) of
      Nothing =>
        do
          put ESs (record { preamble = insert name def (preamble s) } s)
          pure newName
      Just x =>
        if x /= def
         then throw $ InternalError $ "two incompatible definitions for "
                         ++ name ++ "<|" ++ x ++"|> <|"++ def ++ "|>"
         else pure newName

addSupportToPreamble : {auto c : Ref ESs ESSt} -> String -> String -> Core String
addSupportToPreamble name code =
  addToPreamble name name code

jsIdent : String -> String
jsIdent s = concatMap okchar (unpack s)
  where
    okchar : Char -> String
    okchar '_' = "_"
    okchar c = if isAlphaNum c
                  then cast c
                  else "$" ++ the (String) (asHex (cast {to=Int} c))

keywordSafe : String -> String
keywordSafe "var" = "var_"
keywordSafe s = s

jsName : Name -> String
jsName (NS ns n) = jsIdent (showNSWithSep "_" ns) ++ "_" ++ jsName n
jsName (UN n) = keywordSafe $ jsIdent n
jsName (MN n i) = jsIdent n ++ "_" ++ show i
jsName (PV n d) = "pat__" ++ jsName n
jsName (DN _ n) = jsName n
jsName (RF n) = "rf__" ++ jsIdent n
jsName (Nested (i, x) n) = "n__" ++ show i ++ "_" ++ show x ++ "_" ++ jsName n
jsName (CaseBlock x y) = "case__" ++ jsIdent x ++ "_" ++ show y
jsName (WithBlock x y) = "with__" ++ jsIdent x ++ "_" ++ show y
jsName (Resolved i) = "fn__" ++ show i

jsCrashExp : String -> String
jsCrashExp message  = esName "crashExp(" ++ message ++ ")"

toBigInt : String -> String
toBigInt e = "BigInt(" ++ e ++ ")"

fromBigInt : String -> String
fromBigInt e = "Number(" ++ e ++ ")"

useBigInt' : Int -> Bool
useBigInt' = (> 32)

useBigInt : IntKind -> Bool
useBigInt (Signed $ P x)     = useBigInt' x
useBigInt (Signed Unlimited) = True
useBigInt (Unsigned x)       = useBigInt' x

jsBigIntOfString : String -> String
jsBigIntOfString x = esName "bigIntOfString(" ++ x ++ ")"

jsNumberOfString : String -> String
jsNumberOfString x = "parseFloat(" ++ x ++ ")"

jsIntOfString : IntKind -> String -> String
jsIntOfString k = if useBigInt k then jsBigIntOfString else jsNumberOfString

nSpaces : Nat -> String
nSpaces n = pack $ List.replicate n ' '

binOp : String -> String -> String -> String
binOp o lhs rhs = "(" ++ lhs ++ " " ++ o ++ " " ++ rhs ++ ")"

adjInt : Int -> String -> String
adjInt bits = if useBigInt' bits then toBigInt else id

toInt : IntKind -> String -> String
toInt k = if useBigInt k then toBigInt else id

fromInt : IntKind -> String -> String
fromInt k = if useBigInt k then fromBigInt else id

jsIntOfChar : IntKind -> String -> String
jsIntOfChar k s = toInt k $ s ++ ".codePointAt(0)"

jsIntOfDouble : IntKind -> String -> String
jsIntOfDouble k s = toInt k $ "Math.trunc(" ++ s ++ ")"

jsAnyToString : String -> String
jsAnyToString s = "(''+" ++ s ++ ")"

-- Valid unicode code poing range is [0,1114111], therefore,
-- we calculate the remainder modulo 1114112 (= 17 * 2^16).
jsCharOfInt : IntKind -> String -> String
jsCharOfInt k e = esName "truncToChar(" ++ fromInt k e ++ ")"

op : (name : String) -> (args : List String) -> String
op n as = n ++ "(" ++ (fastConcat $ intersperse "," as) ++ ")"

-- We can't determine `isBigInt` from the given number of bits, since
-- when casting from BigInt to Number we need to truncate the BigInt
-- first, otherwise we might lose precision
truncateSigned : (isBigInt : Bool) -> Int -> String -> String
truncateSigned isBigInt bits e =
   let add = if isBigInt then "BigInt" else ""
    in op (esName "truncSigned" ++ add ++ show bits) [e]

truncateUnsigned : (isBigInt : Bool) -> Int -> String -> String
truncateUnsigned isBigInt bits e =
   let add = if isBigInt then "BigInt" else ""
    in op (esName "truncUnsigned" ++ add ++ show bits) [e]

boundedOp : (suffix : String) -> Int -> String -> String -> String -> String
boundedOp s bits o x y = op (fastConcat ["_", o, show bits, s]) [x,y]

boundedIntOp : Int -> String -> String -> String -> String
boundedIntOp = boundedOp "s"

boundedUIntOp : Int -> String -> String -> String -> String
boundedUIntOp = boundedOp "u"

boolOp : String -> String -> String -> String
boolOp o lhs rhs = "(" ++ binOp o lhs rhs ++ " ? BigInt(1) : BigInt(0))"

jsConstant : {auto c : Ref ESs ESSt} -> Constant -> Core String
jsConstant (I i) = pure $ show i ++ "n"
jsConstant (I8 i) = pure $ show i
jsConstant (I16 i) = pure $ show i
jsConstant (I32 i) = pure $ show i
jsConstant (I64 i) = pure $ show i ++ "n"
jsConstant (BI i) = pure $ show i ++ "n"
jsConstant (Str s) = pure $ jsString s
jsConstant (Ch c) = pure $ jsString $ Data.Strings.singleton c
jsConstant (Db f) = pure $ show f
jsConstant WorldVal = pure $ esName "idrisworld"
jsConstant (B8 i) = pure $ show i
jsConstant (B16 i) = pure $ show i
jsConstant (B32 i) = pure $ show i
jsConstant (B64 i) = pure $ show i ++ "n"
jsConstant ty = throw (InternalError $ "Unsuported constant " ++ show ty)

div : Maybe IntKind -> (x : String) -> (y : String) -> String
div (Just k) x y =
  if useBigInt k then binOp "/" x y
                 else jsIntOfDouble k (x ++ " / " ++ y)
div Nothing x y = binOp "/" x y

-- Creates the definition of a binary arithmetic operation.
-- Rounding / truncation behavior is determined from the
-- `IntKind`.
arithOp :  Maybe IntKind
        -> (sym : String)
        -> (op : String)
        -> (x : String)
        -> (y : String)
        -> String
arithOp (Just $ Signed $ P n) _   op = boundedIntOp n op
arithOp (Just $ Unsigned n)   _   op = boundedUIntOp n op
arithOp _                     sym _  = binOp sym

constPrimitives : {auto c : Ref ESs ESSt} -> ConstantPrimitives
constPrimitives = MkConstantPrimitives {
    charToInt    = \k => truncInt (useBigInt k) k . jsIntOfChar k
  , intToChar    = \k => pure . jsCharOfInt k
  , stringToInt  = \k,s => truncInt (useBigInt k) k (jsIntOfString k s)
  , intToString  = \_   => pure . jsAnyToString
  , doubleToInt  = \k => truncInt (useBigInt k) k . jsIntOfDouble k
  , intToDouble  = \k => pure . fromInt k
  , intToInt     = intImpl
  }
  where truncInt : (isBigInt : Bool) -> IntKind -> String -> Core String
        truncInt b (Signed Unlimited) = pure
        truncInt b (Signed $ P n)     = pure . truncateSigned b n
        truncInt b (Unsigned n)       = pure . truncateUnsigned b n

        shrink : IntKind -> IntKind -> String -> String
        shrink k1 k2 = case (useBigInt k1, useBigInt k2) of
                            (True, False) => fromBigInt
                            _             => id

        expand : IntKind -> IntKind -> String -> String
        expand k1 k2 = case (useBigInt k1, useBigInt k2) of
                            (False,True) => toBigInt
                            _            => id

        -- when going from BigInt to Number, we must make
        -- sure to first truncate the BigInt, otherwise we
        -- might get rounding issues
        intImpl : IntKind -> IntKind -> String -> Core String
        intImpl k1 k2 s =
          let expanded = expand k1 k2 s
              shrunk   = shrink k1 k2 <$> truncInt (useBigInt k1) k2 s
           in case (k1,k2) of
                (_, Signed Unlimited)    => pure $ expanded
                (Signed m, Signed n)     =>
                  if n >= m then pure expanded else shrunk

                (Signed _, Unsigned n)   =>
                  case (useBigInt k1, useBigInt k2) of
                       (False,True)  => truncInt True k2 (toBigInt s)
                       _             => shrunk

                (Unsigned m, Unsigned n) =>
                  if n >= m then pure expanded else shrunk

                -- Only if the precision of the target is greater
                -- than the one of the source, there is no need to cast.
                (Unsigned m, Signed n)   =>
                  if n > P m then pure expanded else shrunk

jsOp : {0 arity : Nat} -> {auto c : Ref ESs ESSt} ->
       PrimFn arity -> Vect arity String -> Core String
jsOp (Add ty) [x, y] = pure $ arithOp (intKind ty) "+" "add" x y
jsOp (Sub ty) [x, y] = pure $ arithOp (intKind ty) "-" "sub" x y
jsOp (Mul ty) [x, y] = pure $ arithOp (intKind ty) "*" "mul" x y
jsOp (Div ty) [x, y] = pure $ div (intKind ty) x y
jsOp (Mod ty) [x, y] = pure $ binOp "%" x y
jsOp (Neg ty) [x] = pure $ "(-(" ++ x ++ "))"
jsOp (ShiftL Int32Type) [x, y] = pure $ binOp "<<" x y
jsOp (ShiftL ty) [x, y] = pure $ arithOp (intKind ty) "<<" "shl" x y
jsOp (ShiftR Int32Type) [x, y] = pure $ binOp ">>" x y
jsOp (ShiftR ty) [x, y] = pure $ arithOp (intKind ty) ">>" "shr" x y
jsOp (BAnd Bits32Type) [x, y] = pure $ boundedUIntOp 32 "and" x y
jsOp (BOr Bits32Type) [x, y]  = pure $ boundedUIntOp 32 "or" x y
jsOp (BXOr Bits32Type) [x, y] = pure $ boundedUIntOp 32 "xor" x y
jsOp (BAnd ty) [x, y] = pure $ binOp "&" x y
jsOp (BOr ty) [x, y] = pure $ binOp "|" x y
jsOp (BXOr ty) [x, y] = pure $ binOp "^" x y
jsOp (LT ty) [x, y] = pure $ boolOp "<" x y
jsOp (LTE ty) [x, y] = pure $ boolOp "<=" x y
jsOp (EQ ty) [x, y] = pure $ boolOp "===" x y
jsOp (GTE ty) [x, y] = pure $ boolOp ">=" x y
jsOp (GT ty) [x, y] = pure $ boolOp ">" x y
jsOp StrLength [x] = pure $ toBigInt $ x ++ ".length"
jsOp StrHead [x] = pure $ "(" ++ x ++ ".charAt(0))"
jsOp StrTail [x] = pure $ "(" ++ x ++ ".slice(1))"
jsOp StrIndex [x, y] = pure $ "(" ++ x ++ ".charAt(" ++ fromBigInt y ++ "))"
jsOp StrCons [x, y] = pure $ binOp "+" x y
jsOp StrAppend [x, y] = pure $ binOp "+" x y
jsOp StrReverse [x] = pure $ op (esName "strReverse") [x]
jsOp StrSubstr [offset, length, str] =
  pure $ op (esName "substr") [offset,length,str]
jsOp DoubleExp [x] = pure $ op "Math.exp" [x]
jsOp DoubleLog [x] = pure $ op "Math.log" [x]
jsOp DoubleSin [x] = pure $ op "Math.sin" [x]
jsOp DoubleCos [x] = pure $ op "Math.cos" [x]
jsOp DoubleTan [x] = pure $ op "Math.tan" [x]
jsOp DoubleASin [x] = pure $ op "Math.asin" [x]
jsOp DoubleACos [x] = pure $ op "Math.acos" [x]
jsOp DoubleATan [x] = pure $ op "Math.atan" [x]
jsOp DoubleSqrt [x] = pure $ op "Math.sqrt" [x]
jsOp DoubleFloor [x] = pure $ op "Math.floor" [x]
jsOp DoubleCeiling [x] = pure $ op "Math.ceil" [x]

jsOp (Cast StringType DoubleType) [x] = pure $ jsNumberOfString x
jsOp (Cast ty StringType) [x] = pure $ jsAnyToString x
jsOp (Cast ty ty2) [x]        = castInt constPrimitives ty ty2 x
jsOp BelieveMe [_,_,x] = pure x
jsOp (Crash) [_, msg] = pure $ jsCrashExp msg


readCCPart : String -> (String, String)
readCCPart x =
  let (cc, def) = break (== ':') x
  in (cc, drop 1 def)


searchForeign : List String -> List String -> Maybe String
searchForeign prefixes [] = Nothing
searchForeign prefixes (x::xs) =
  let (cc, def) = readCCPart x
  in if cc `elem` prefixes then Just def
                           else searchForeign prefixes xs


makeForeign : {auto d : Ref Ctxt Defs} -> {auto c : Ref ESs ESSt} -> Name -> String -> Core String
makeForeign n x =
  do
    let (ty, def) = readCCPart x
    case ty of
      "lambda" => pure $ "const " ++ jsName n ++ " = (" ++ def ++ ")\n"
      "support" =>
        do
          let (name, lib_) = break (== ',') def
          let lib = drop 1 lib_
          lib_code <- readDataFile ("js/" ++ lib ++ ".js")
          ignore $ addSupportToPreamble lib lib_code
          pure $ "const " ++ jsName n ++ " = " ++ lib ++ "_" ++ name ++ "\n"
      "stringIterator" =>
          case def of
            "new" => pure $ "const " ++ jsName n ++ " = __prim_stringIteratorNew;\n"
            "next" => pure $ "const " ++ jsName n ++ " = __prim_stringIteratorNext;\n"
            "toString" => pure $ "const " ++ jsName n ++ " = __prim_stringIteratorToString;\n"
            _ => throw (InternalError $ "invalid string iterator function: " ++ def ++ ", supported functions are \"new\", \"next\", \"toString\"")


      _ => throw (InternalError $ "invalid foreign type : " ++ ty ++ ", supported types are \"lambda\", \"support\"")

foreignDecl :  {auto d : Ref Ctxt Defs}
            -> {auto c : Ref ESs ESSt}
            -> Name
            -> List String
            -> Core String
foreignDecl n ccs =
  do
    s <- get ESs
    case searchForeign (ccTypes s) ccs of
      Just x => makeForeign n x
      Nothing => throw (InternalError $ "No node or javascript definition found for " ++ show n ++ " in " ++ show ccs)

jsPrim : {auto c : Ref ESs ESSt} -> Name -> List String -> Core String
jsPrim (NS _ (UN "prim__newIORef")) [_,v,_] = pure $ "({value: "++ v ++"})"
jsPrim (NS _ (UN "prim__readIORef")) [_,r,_] = pure $ "(" ++ r ++ ".value)"
jsPrim (NS _ (UN "prim__writeIORef")) [_,r,v,_] = pure $ "(" ++ r ++ ".value=" ++ v ++ ")"
jsPrim (NS _ (UN "prim__newArray")) [_,s,v,_] = pure $ "(Array(Number(" ++ s ++ ")).fill(" ++ v ++ "))"
jsPrim (NS _ (UN "prim__arrayGet")) [_,x,p,_] = pure $ "(" ++ x ++ "[" ++ p ++ "])"
jsPrim (NS _ (UN "prim__arraySet")) [_,x,p,v,_] = pure $ "(" ++ x ++ "[" ++ p ++ "] = " ++ v ++ ")"
jsPrim (NS _ (UN "prim__os")) [] = pure $ esName "sysos"
jsPrim (NS _ (UN "void")) [_, _] = pure $ jsCrashExp $ jsString $ "Error: Executed 'void'"  -- DEPRECATED. TODO: remove when bootstrap has been updated
jsPrim (NS _ (UN "prim__void")) [_, _] = pure $ jsCrashExp $ jsString $ "Error: Executed 'void'"
jsPrim x args = throw $ InternalError $ "prim not implemented: " ++ (show x)

tag2es : Either Int String -> String
tag2es (Left x) = show x
tag2es (Right x) = jsString x

mutual
  impExp2es : {auto d : Ref Ctxt Defs} -> {auto c : Ref ESs ESSt} -> ImperativeExp -> Core String
  impExp2es (IEVar n) =
    pure $ jsName n
  impExp2es (IELambda args body) =
    pure $ "(" ++ showSep ", " (map jsName args) ++ ") => {" ++ !(imperative2es 0 body) ++ "}"
  impExp2es (IEApp f args) =
    pure $ !(impExp2es f) ++ "(" ++ showSep ", " !(traverse impExp2es args) ++ ")"
  impExp2es (IEConstant c) =
    jsConstant c
  impExp2es (IEPrimFn f args) =
    jsOp f !(traverseVect impExp2es args)
  impExp2es (IEPrimFnExt n args) =
    jsPrim n !(traverse impExp2es args)
  impExp2es (IEConstructorHead e) =
    pure $ !(impExp2es e) ++ ".h"
  impExp2es (IEConstructorTag x) =
    pure $ tag2es x
  impExp2es (IEConstructorArg i e) =
    pure $ !(impExp2es e) ++ ".a" ++ show i
  impExp2es (IEConstructor h args) =
    let argPairs = zipWith (\i,a => "a" ++ show i ++ ": " ++ a ) [1..length args] !(traverse impExp2es args)
    in pure $ "({" ++ showSep ", " (("h:" ++ tag2es h)::argPairs) ++ "})"
  impExp2es (IEDelay e) =
    pure $ "(()=>" ++ !(impExp2es e) ++ ")"
  impExp2es (IEForce e) =
    pure $ !(impExp2es e) ++ "()"
  impExp2es IENull =
    pure "undefined"

  imperative2es : {auto d : Ref Ctxt Defs} -> {auto c : Ref ESs ESSt} -> Nat -> ImperativeStatement -> Core String
  imperative2es indent DoNothing =
    pure ""
  imperative2es indent (SeqStatement x y) =
    pure $ !(imperative2es indent x) ++ "\n" ++ !(imperative2es indent y)
  imperative2es indent (FunDecl fc n args body) =
    pure $ nSpaces indent ++ "function " ++ jsName n ++ "(" ++ showSep ", " (map jsName args) ++ "){//"++ show fc ++"\n" ++
           !(imperative2es (indent+1) body) ++ "\n" ++ nSpaces indent ++ "}\n"
  imperative2es indent (ForeignDecl fc n path args ret) =
    pure $ !(foreignDecl n path) ++ "\n"
  imperative2es indent (ReturnStatement x) =
    pure $ nSpaces indent ++ "return " ++ !(impExp2es x) ++ ";"
  imperative2es indent (SwitchStatement e alts def) =
    do
      def <- case def of
                Nothing => pure ""
                Just x => pure $ nSpaces (indent+1) ++ "default:\n" ++ !(imperative2es (indent+2) x)
      let sw = nSpaces indent ++ "switch(" ++ !(impExp2es e) ++ "){\n"
      let alts = concat !(traverse (alt2es (indent+1)) alts)
      pure $ sw ++ alts ++ def ++ "\n" ++ nSpaces indent ++ "}"
  imperative2es indent (LetDecl x v) =
    case v of
      Nothing => pure $ nSpaces indent ++ "let " ++ jsName x ++ ";"
      Just v_ => pure $ nSpaces indent ++ "let " ++ jsName x ++ " = " ++ !(impExp2es v_) ++ ";"
  imperative2es indent (ConstDecl x v) =
    pure $ nSpaces indent ++ "const " ++ jsName x ++ " = " ++ !(impExp2es v) ++ ";"
  imperative2es indent (MutateStatement x v) =
    pure $ nSpaces indent ++ jsName x ++ " = " ++ !(impExp2es v) ++ ";"
  imperative2es indent (ErrorStatement msg) =
    pure $ nSpaces indent ++ "throw new Error("++ jsString msg ++");"
  imperative2es indent (EvalExpStatement e) =
    pure $ nSpaces indent ++ !(impExp2es e) ++ ";"
  imperative2es indent (CommentStatement x) =
    pure $ "\n/*" ++ x ++ "*/\n"
  imperative2es indent (ForEverLoop x) =
    pure $ nSpaces indent ++ "while(true){\n" ++ !(imperative2es (indent+1) x) ++ "\n" ++ nSpaces indent ++ "}"

  alt2es : {auto d : Ref Ctxt Defs} -> {auto c : Ref ESs ESSt} -> Nat -> (ImperativeExp, ImperativeStatement) -> Core String
  alt2es indent (e, b) = pure $ nSpaces indent ++ "case " ++ !(impExp2es e) ++ ": {\n" ++
                                !(imperative2es (indent+1) b) ++ "\n" ++ nSpaces (indent+1) ++ "break; }\n"

export
compileToES : Ref Ctxt Defs -> ClosedTerm -> List String -> Core String
compileToES c tm ccTypes =
  do
    (impDefs, impMain) <- compileToImperative c tm
    s <- newRef ESs (MkESSt empty ccTypes)
    defs <- imperative2es 0 impDefs
    main_ <- imperative2es 0 impMain
    let main = "try{" ++ main_ ++ "}catch(e){if(e instanceof IdrisError){console.log('ERROR: ' + e.message)}else{throw e} }"
    st <- get ESs
    static_preamble <- readDataFile ("js/support.js")
    let pre = showSep "\n" $ static_preamble :: (values $ preamble st)
    pure $ pre ++ "\n\n" ++ defs ++ main
