module Core.Options.Log

import public Data.List
import Data.List1
import public Data.Maybe
import Libraries.Data.StringMap
import Libraries.Data.StringTrie
import Data.Strings
import Data.These
import Libraries.Text.PrettyPrint.Prettyprinter

%default total

||| Log levels are characterised by two things:
||| * a dot-separated path of ever finer topics of interest e.g. scope.let
||| * a natural number corresponding to the verbosity level e.g. 5
|||
||| If the user asks for some logs by writing
|||
|||     %log scope 5
|||
||| they will get all of the logs whose path starts with `scope` and whose
||| verbosity level is less or equal to `5`. By combining different logging
||| directives, users can request information about everything (with a low
||| level of details) and at the same time focus on a particular subsystem
||| they want to get a lot of information about. For instance:
|||
|||     %log 1
|||     %log scope.let 10
|||
||| will deliver basic information about the various phases the compiler goes
||| through and deliver a lot of information about scope-checking let binders.
public export
data LogTopic =
      Auto
    | BuiltinNatural
    | BuiltinNaturalAddTransform
    | BuiltinNaturalToInteger
    | BuiltinNaturalToIntegerAddTransforms
    | CompileCasetree
    | CompilerInlineEval
    | CompilerRefc
    | CompilerRefcCc
    | CompilerSchemeChez
    | Coverage
    | CoverageEmpty
    | CoverageMissing
    | CoverageRecover
    | DeclareData
    | DeclareDataConstructor
    | DeclareDataParameters
    | DeclareDef
    | DeclareDefClause
    | DeclareDefClauseImpossible
    | DeclareDefClauseWith
    | DeclareDefImpossible
    | DeclareDefLhs
    | DeclareDefLhsImplicits
    | DeclareParam
    | DeclareRecord
    | DeclareRecordField
    | DeclareRecordProjection
    | DeclareRecordProjectionPrefix
    | DeclareType
    | DesugarIdiom
    | DocRecord
    | Elab
    | ElabAmbiguous
    | ElabAppLhs
    | ElabAs
    | ElabBindnames
    | ElabBinder
    | ElabCase
    | ElabDefLocal
    | ElabDelay
    | ElabHole
    | ElabImplicits
    | ElabImplementation
    | ElabInterface
    | ElabInterfaceDefault
    | ElabLocal
    | ElabPrun
    | ElabPrune
    | ElabRecord
    | ElabRetry
    | ElabRewrite
    | ElabUnify
    | ElabUpdate
    | ElabWith
    | EvalCasetree
    | EvalCasetreeStuck
    | EvalEta
    | EvalStuck
    | IdemodeHole
    | IdemodeHighlight
    | IdemodeHighlightAlias
    | IdemodeSend
    | Import
    | ImportFile
    | InteractionCasesplit
    | InteractionGenerate
    | InteractionSearch
    | MetadataNames
    | Quantity
    | QuantityHole
    | QuantityHoleUpdate
    | ReplEval
    | Specialise
    | Totality
    | TotalityPositivity
    | TotalityTermination
    | TotalityTerminationCalc
    | TotalityTerminationGuarded
    | TotalityTerminationSizechange
    | TotalityTerminationSizechangeCheckCall
    | TotalityTerminationSizechangeCheckCallInPath
    | TotalityTerminationSizechangeCheckCallInPathNotRestart
    | TotalityTerminationSizechangeCheckCallInPathNotReturn
    | TotalityTerminationSizechangeInPath
    | TotalityTerminationSizechangeIsTerminating
    | TotalityTerminationSizechangeNeedsChecking
    | TtcRead
    | TtcWrite
    | TypesearchEquiv
    | UnelabCase
    | Unify
    | UnifyApplication
    | UnifyBinder
    | UnifyConstant
    | UnifyConstraint
    | UnifyDelay
    | UnifyEqual
    | UnifyHead
    | UnifyHole
    | UnifyInstantiate
    | UnifyInvertible
    | UnifyMeta
    | UnifyNoeta
    | UnifyPostpone
    | UnifyRetry
    | UnifySearch
    | UnifyUnsolved
---------------------------------------------------------------------

logTopics : LogTopic -> List String
logTopics Auto = [ "auto" ]
logTopics BuiltinNatural = [ "builtin", "Natural" ]
logTopics BuiltinNaturalAddTransform = [ "builtin", "Natural", "addTransform" ]
logTopics BuiltinNaturalToInteger = [ "builtin", "NaturalToInteger" ]
logTopics BuiltinNaturalToIntegerAddTransforms = [ "builtin", "NaturalToInteger", "addTransforms" ]
logTopics CompileCasetree = [ "compile", "casetree" ]
logTopics CompilerInlineEval = [ "compiler", "inline", "eval" ]
logTopics CompilerRefc = [ "compiler", "refc" ]
logTopics CompilerRefcCc = [ "compiler", "refc", "cc" ]
logTopics CompilerSchemeChez = [ "compiler", "scheme", "chez" ]
logTopics Coverage = [ "coverage" ]
logTopics CoverageEmpty = [ "coverage", "empty" ]
logTopics CoverageMissing = [ "coverage", "missing" ]
logTopics CoverageRecover = [ "coverage", "recover" ]
logTopics DeclareData = [ "declare", "data" ]
logTopics DeclareDataConstructor = [ "declare", "data", "constructor" ]
logTopics DeclareDataParameters = [ "declare", "data", "parameters" ]
logTopics DeclareDef = [ "declare", "def" ]
logTopics DeclareDefClause = [ "declare", "def", "clause" ]
logTopics DeclareDefClauseImpossible = [ "declare", "def", "clause", "impossible" ]
logTopics DeclareDefClauseWith = [ "declare", "def", "clause", "with" ]
logTopics DeclareDefImpossible = [ "declare", "def", "impossible" ]
logTopics DeclareDefLhs = [ "declare", "def", "lhs" ]
logTopics DeclareDefLhsImplicits = [ "declare", "def", "lhs", "implicits" ]
logTopics DeclareParam = [ "declare", "param" ]
logTopics DeclareRecord = [ "declare", "record" ]
logTopics DeclareRecordField = [ "declare", "record", "field" ]
logTopics DeclareRecordProjection = [ "declare", "record", "projection" ]
logTopics DeclareRecordProjectionPrefix = [ "declare", "record", "projection", "prefix" ]
logTopics DeclareType = [ "declare", "type" ]
logTopics DesugarIdiom = [ "desugar", "idiom" ]
logTopics DocRecord = [ "doc", "record" ]
logTopics Elab = [ "elab" ]
logTopics ElabAmbiguous = [ "elab", "ambiguous" ]
logTopics ElabAppLhs = [ "elab", "app", "lhs" ]
logTopics ElabAs = [ "elab", "as" ]
logTopics ElabBindnames = [ "elab", "bindnames" ]
logTopics ElabBinder = [ "elab", "binder" ]
logTopics ElabCase = [ "elab", "case" ]
logTopics ElabDefLocal = [ "elab", "def", "local" ]
logTopics ElabDelay = [ "elab", "delay" ]
logTopics ElabHole = [ "elab", "hole" ]
logTopics ElabImplicits = [ "elab", "implicits" ]
logTopics ElabImplementation = [ "elab", "implementation" ]
logTopics ElabInterface = [ "elab", "interface" ]
logTopics ElabInterfaceDefault = [ "elab", "interface", "default" ]
logTopics ElabLocal = [ "elab", "local" ]
logTopics ElabPrun = [ "elab", "prun" ]
logTopics ElabPrune = [ "elab", "prune" ]
logTopics ElabRecord = [ "elab", "record" ]
logTopics ElabRetry = [ "elab", "retry" ]
logTopics ElabRewrite = [ "elab", "rewrite" ]
logTopics ElabUnify = [ "elab", "unify" ]
logTopics ElabUpdate = [ "elab", "update" ]
logTopics ElabWith = [ "elab", "with" ]
logTopics EvalCasetree = [ "eval", "casetree" ]
logTopics EvalCasetreeStuck = [ "eval", "casetree", "stuck" ]
logTopics EvalEta = [ "eval", "eta" ]
logTopics EvalStuck = [ "eval", "stuck" ]
logTopics IdemodeHole = [ "idemode", "hole" ]
logTopics IdemodeHighlight = [ "ide-mode", "highlight" ]
logTopics IdemodeHighlightAlias = [ "ide-mode", "highlight", "alias" ]
logTopics IdemodeSend = [ "ide-mode", "send" ]
logTopics Import = [ "import" ]
logTopics ImportFile = [ "import", "file" ]
logTopics InteractionCasesplit = [ "interaction", "casesplit" ]
logTopics InteractionGenerate = [ "interaction", "generate" ]
logTopics InteractionSearch = [ "interaction", "search" ]
logTopics MetadataNames = [ "metadata", "names" ]
logTopics Quantity = [ "quantity" ]
logTopics QuantityHole = [ "quantity", "hole" ]
logTopics QuantityHoleUpdate = [ "quantity", "hole", "update" ]
logTopics ReplEval = [ "repl", "eval" ]
logTopics Specialise = [ "specialise" ]
logTopics Totality = [ "totality" ]
logTopics TotalityPositivity = [ "totality", "positivity" ]
logTopics TotalityTermination = [ "totality", "termination" ]
logTopics TotalityTerminationCalc = [ "totality", "termination", "calc" ]
logTopics TotalityTerminationGuarded = [ "totality", "termination", "guarded" ]
logTopics TotalityTerminationSizechange = [ "totality", "termination", "sizechange" ]
logTopics TotalityTerminationSizechangeCheckCall = [ "totality", "termination", "sizechange", "checkCall" ]
logTopics TotalityTerminationSizechangeCheckCallInPath = [ "totality", "termination", "sizechange", "checkCall", "inPath" ]
logTopics TotalityTerminationSizechangeCheckCallInPathNotRestart = [ "totality", "termination", "sizechange", "checkCall", "inPathNot", "restart" ]
logTopics TotalityTerminationSizechangeCheckCallInPathNotReturn = [ "totality", "termination", "sizechange", "checkCall", "inPathNot", "return" ]
logTopics TotalityTerminationSizechangeInPath = [ "totality", "termination", "sizechange", "inPath" ]
logTopics TotalityTerminationSizechangeIsTerminating = [ "totality", "termination", "sizechange", "isTerminating" ]
logTopics TotalityTerminationSizechangeNeedsChecking = [ "totality", "termination", "sizechange", "needsChecking" ]
logTopics TtcRead = [ "ttc", "read" ]
logTopics TtcWrite = [ "ttc", "write" ]
logTopics TypesearchEquiv = [ "typesearch", "equiv" ]
logTopics UnelabCase = [ "unelab", "case" ]
logTopics Unify = [ "unify" ]
logTopics UnifyApplication = [ "unify", "application" ]
logTopics UnifyBinder = [ "unify", "binder" ]
logTopics UnifyConstant = [ "unify", "constant" ]
logTopics UnifyConstraint = [ "unify", "constraint" ]
logTopics UnifyDelay = [ "unify", "delay" ]
logTopics UnifyEqual = [ "unify", "equal" ]
logTopics UnifyHead = [ "unify", "head" ]
logTopics UnifyHole = [ "unify", "hole" ]
logTopics UnifyInstantiate = [ "unify", "instantiate" ]
logTopics UnifyInvertible = [ "unify", "invertible" ]
logTopics UnifyMeta = [ "unify", "meta" ]
logTopics UnifyNoeta = [ "unify", "noeta" ]
logTopics UnifyPostpone = [ "unify", "postpone" ]
logTopics UnifyRetry = [ "unify", "retry" ]
logTopics UnifySearch = [ "unify", "search" ]
logTopics UnifyUnsolved = [ "unify", "unsolved" ]

----------------------------------------------------------------------------------
-- INDIVIDUAL LOG LEVEL

||| An individual log level is a pair of a list of non-empty strings and a number.
||| We keep the representation opaque to force users to call the smart constructor
export
data LogLevel : Type where
  MkLogLevel : List String -> Nat -> LogLevel

||| If we have already processed the input string into (maybe) a non-empty list of
||| non-empty topics we can safely make a `LogLevel`.
export
mkLogLevel' : Maybe (List1 String) -> Nat -> LogLevel
mkLogLevel' ps n = MkLogLevel (maybe [] forget ps) n

||| The smart constructor makes sure that the empty string is mapped to the empty
||| list. This bypasses the fact that the function `split` returns a non-empty
||| list no matter what.
|||
||| However, invoking this function comes without guarantees that
||| the passed string corresponds to a known topic. For this,
||| use `mkLogLevel`.
|||
||| Use this function to create user defined loglevels, for instance, during
||| elaborator reflection.
export
mkUnverifiedLogLevel : Bool -> (s : String) -> Nat -> LogLevel
mkUnverifiedLogLevel False _ = mkLogLevel' Nothing
mkUnverifiedLogLevel _ "" = mkLogLevel' Nothing
mkUnverifiedLogLevel _ ps = mkLogLevel' (Just (split (== '.') ps))

||| Like `mkUnverifiedLogLevel` but with a compile time check that
||| the passed string is a known topic.
export
mkLogLevel : Bool -> LogTopic -> Nat -> LogLevel
mkLogLevel False _ = mkLogLevel' Nothing
mkLogLevel True  t = MkLogLevel (logTopics t)

||| The unsafe constructor should only be used in places where the topic has already
||| been appropriately processed.
export
unsafeMkLogLevel : List String -> Nat -> LogLevel
unsafeMkLogLevel = MkLogLevel

||| The topics attached to a `LogLevel` can be reconstructed from the list of strings.
export
topics : LogLevel -> List String
topics (MkLogLevel ps _) = ps

||| The verbosity is provided by the natural number
export
verbosity : LogLevel -> Nat
verbosity (MkLogLevel _ n) = n

||| When writing generic functions we sometimes want to keep the same topic but
||| change the verbosity.
export
withVerbosity : Nat -> LogLevel -> LogLevel
withVerbosity n (MkLogLevel ps _) = MkLogLevel ps n

||| A log level is show as `P.Q.R:N` where `P`, `Q` and `R` are topics and `N` is
||| a verbosity level. If there are no topics then we simply print `N`.
export
Show LogLevel where

  show (MkLogLevel ps n) = case ps of
    [] => show n
    _  => fastAppend (intersperse "." ps) ++ ":" ++ show n

export
Pretty LogLevel where

  pretty = pretty . show

export
parseLogLevel : String -> Maybe LogLevel
parseLogLevel str = do
  (c, n) <- let nns = split (== ':') str
                n = head nns
                ns = tail nns in
                case ns of
                     [] => pure (MkLogLevel [], n)
                     [ns] => pure (mkUnverifiedLogLevel True n, ns)
                     _ => Nothing
  lvl <- parsePositive n
  pure $ c (fromInteger lvl)

----------------------------------------------------------------------------------
-- COLLECTION OF LOG LEVELS

||| We store the requested log levels in a Trie which makes it easy to check
||| whether a given log level is captured by the user's request for information.
export
LogLevels : Type
LogLevels = StringTrie Nat

||| By default we log everything but with very few details (i.e. next to nothing)
export
defaultLogLevel : LogLevels
defaultLogLevel = singleton [] 0

export
insertLogLevel : LogLevel -> LogLevels -> LogLevels
insertLogLevel (MkLogLevel ps n) = insert ps n

----------------------------------------------------------------------------------
-- CHECKING WHETHER TO LOG

||| We keep a log if there is a prefix of its path associated to a larger number
||| in the LogLevels.
export
keepLog : LogLevel -> Bool -> LogLevels -> Bool
keepLog (MkLogLevel _ Z) _ _ = True
keepLog (MkLogLevel path n) enabled levels = enabled && go path levels where

  go : List String -> StringTrie Nat -> Bool
  go path (MkStringTrie current) = here || there where

    here : Bool
    here = case fromThis current of
      Nothing => False
      Just m  => n <= m

    there : Bool
    there = case path of
      [] => False
      (p :: rest) => fromMaybe False $ do
        assoc <- fromThat current
        next  <- lookup p assoc
        pure $ go rest next
