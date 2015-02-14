module Util where

import GHC
import Outputable
import GhcMonad
import Data.IORef
import System.IO
import Control.Monad.IO.Class (MonadIO)
import Types
import Control.Monad
-- PARSE IMPORTS
import Parser
import Lexer
import StringBuffer (stringToStringBuffer)
import FastString (fsLit)
import SrcLoc
import GhcMonad

runParserM parser str = do
  fs <- getSessionDynFlags
  let buf = stringToStringBuffer str
      loc = mkRealSrcLoc (fsLit "<slick>") 1 1
  return $ case unP parser (mkPState fs buf loc) of
    PFailed span err -> Left (showSDoc fs err)
    POk _pst x       -> Right x


(>>|) :: Functor f => f a -> (a -> b) -> f b
(>>|) x f = fmap f x

showPprM :: (Outputable a, GhcMonad m) => a -> m String
showPprM = showSDocM . ppr

output :: (Outputable a, GhcMonad m) => a -> m ()
output = liftIO . putStrLn <=< showSDocM . ppr

showSDocM x = getSessionDynFlags >>| \fs -> showSDoc fs x

gReadIORef :: MonadIO m => IORef a -> m a
gReadIORef = liftIO . readIORef

gModifyIORef :: MonadIO m => IORef a -> (a -> a) -> m ()
gModifyIORef x = liftIO . modifyIORef x

logS stRef s = liftIO $ flip hPutStrLn s . logFile =<< readIORef stRef

nextSubexpr  hole       = foldr (\(L l x) r -> if hole `isSubspanOf` l then x else r) (error "nextSubexpr failure")
nextLocatedSubexpr hole = foldr (\(L l x) r -> if hole `isSubspanOf` l then x else r) (error "nextLocatedSubexpr failure")
nextSubexpr' hole       = foldr (\(L l x) r -> if hole `isSubspanOf` l then Just x else r) Nothing

-- foldExprs :: ([s] -> s) -> (LHsExpr id -> s -> Maybe s) -> HsModule id -> 