{- git-annex command
 -
 - Copyright 2011,2013 Joey Hess <id@joeyh.name>
 -
 - Licensed under the GNU GPL version 3 or higher.
 -}

module Command.InitRemote where

import qualified Data.Map as M

import Common.Annex
import Annex.SpecialRemote
import Command
import qualified Remote
import qualified Logs.Remote
import qualified Types.Remote as R
import Logs.UUID

cmd :: Command
cmd = command "initremote" SectionSetup
	"creates a special (non-git) remote"
	(paramPair paramName $ paramOptional $ paramRepeating paramKeyValue)
	(withParams seek)

seek :: CmdParams -> CommandSeek
seek = withWords start

start :: [String] -> CommandStart
start [] = error "Specify a name for the remote."
start (name:ws) = ifM (isJust <$> findExisting name)
	( error $ "There is already a special remote named \"" ++ name ++
		"\". (Use enableremote to enable an existing special remote.)"
	, do
		ifM (isJust <$> Remote.byNameOnly name)
			( error $ "There is already a remote named \"" ++ name ++ "\""
			, do
				let c = newConfig name
				t <- either error return (findType config)

				showStart "initremote" name
				next $ perform t name $ M.union config c
			)
	)
  where
	config = Logs.Remote.keyValToConfig ws

perform :: RemoteType -> String -> R.RemoteConfig -> CommandPerform
perform t name c = do
	(c', u) <- R.setup t Nothing Nothing c
	next $ cleanup u name c'

cleanup :: UUID -> String -> R.RemoteConfig -> CommandCleanup
cleanup u name c = do
	describeUUID u name
	Logs.Remote.configSet u c
	return True
