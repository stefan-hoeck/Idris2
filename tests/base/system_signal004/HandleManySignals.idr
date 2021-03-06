import System.Signal
import System
import Data.List
import Data.Fuel

main : IO ()
main = do
  Right () <- collectSignal SigABRT
    | Left (Error code) => putStrLn $ "error " ++ (show code)
  putStrLn "before"
  [Right (), Right (), Right ()] <- sequence $ replicate 3 (raiseSignal SigABRT)
    | _ => putStrLn $ "got non-zero exit from a system call"
  sleep 1
  [SigABRT, SigABRT, SigABRT] <- handleManyCollectedSignals (limit 4)
    | (_ :: _ :: _ :: [])  => putStrLn "received the wrong signals."
    | _ => putStrLn "did not receive expected number of signals."
  putStrLn "after"
  Right () <- defaultSignal SigABRT
    | Left (Error code) => putStrLn $ "error " ++ (show code)
  putStrLn "done."
