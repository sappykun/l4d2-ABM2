# ABM Change Log
## [0.1.29] - 2017-28-01
### Fixed
- TakeOverZombieBotSig and Spirit_12 came in with the win, thank you :D
- SI in campaign wouldn't respawn if a round was reset (.e.g, survivors died)
- Setting abm_tankchunkhp to 0 would give you a zero health Tank
- SI assisted spawning shouldn't clobber survivors while they're getting ready

### Changed
- The ADTimer interval is reset until survivors are at least greater than zero
- Human SI spawn intervals went from Ludicrous Speed to Ridiculous Speed
- Spawning more than 1 survivor spawns them in 0.2 (from 0.1)

### Added
- A print to chat when a signature is broken reasoning why ABM is unloaded

## [0.1.28] - 2017-26-01
### Fixed
- Switch client team menu

### Added
- You can choose your own SI when joining team 3, (e.g., "join 3 tank")
- Dying while SI in a non-competitive mode gives you a new ghost immediately

## [0.1.27] - 2017-26-01
### Added
- The ability to spawn specific SI is in place (but not fully implemented)
- CleanSIName function will sanitize or remove invalid SI names

### Changed
- g_SpecialNames to g_InfectedNames for clarity
- Switching to spectator should snap you onto your survivor or another survivor
- Switching to SI should always give you a ghost (even if a script restricts it)

## [0.1.26] - 2017-24-01
### Fixed
- Regression: SI in campaign unqueued after next map start
- Regression: Losing survivor model in some situations

## [0.1.25] - 2017-23-01
### Added
- g_sQueue and g_iQueue for survivor/infected queuing assignments
- Admins now get a preview of the choose which to team to join on connection

### Fixed
- Entity errors on m_iObserverMode should be solved
- Spectating self on !join 1 or spectating others on join now solved

### Changed
- Client assignments in OnSpawnHook now respect player queues
- GetSafeClient changed to GetSafeSurvivor to better detail its purpose

## [0.1.24] - 2017-23-01
### Added
- g_RemovedPlayers bool must be fired before g_AddedPlayers is checked
- After all players are loaded, g_MinPlayers is applied
- After g_MinPlayers is applied, g_ExtraPlayers is applied

### Changed
- Tank health is now adjusted regardless of the size of survivors
- UpdateConVarsHook greatly simplified
- No more aggressive checks in GoIdle (stack trace still happens, not sure why)

## [0.1.23] - 2017-22-01
### Added
- The ability to start out with extra survivors
- An auto difficulty for campaign when teams are larger than size 4
- You can now lock cvars over the console with an -l option
- You can now unlock cvars previously locked with a -u option

### Changed
- Special infected now spawn 0.4 seconds apart from one another
- Tried simplifying the spectating bug glitch fix
- GoIdle now takes an argument (0 for idle, 1 for spectator)
- Extra players are now included in the count before removing "extra" bots
- Clients are checked to be on team 2 before stripping
- Joining idle or spectator should now lock onto your survivor correctly
- Big changes to UpdateConVarsHook, SwitchTeam, MkBots, MkBotsTimer and TakeOverZombieBotSig

### Fixed
- Joining teams is a lot smoother from either the menu or chat commands
- Aggressive validation is now done before putting someone into an SI character

## [0.1.19] - 2017-14-01
### Removed
- Witches no longer spawn with abm-mk (they don't stop spawning though)

### Added
- An assistant director added to help with spawning SI in certain situations
- g_ADFreeze bool insures all players are loaded before the AD truly kicks in
- g_ADInterval int is a counter for how many times we've been through the AD
- Several hooks will stop the AD automatically e.g., round_end, mission_lost
- RoundStartHook atm calls StartAD
- StopAD stops the AD timer
- StartAD starts the AD timer (was StartTracking)

### Changed
- Humans on SI in campaign mode should now ghost immediately on round start
- Some spectator code has been commented out in ADTimer (will probably be removed)
- When SI die, they no longer get an automatic takeover menu (it's still there)
- Cleaned up a bit (replaced INVALID_HANDLE/CloseHandle /w null and delete)
- g_hTrackingTimer is now g_AD (AD stands for Assistant Director)
- DebugToFile is now Echo

## [0.1.18] - 2017-11-01
### Added
- g_GameData is now the global LoadGameConfigFile handle

### Fixed
- Memory leak caused by ABM menus

## [0.1.17] - 2017-10-01
### Added
- g_AssistedSpawning flips to true when a human goes SI in cooperative
- g_hTrackingTimer assists with checking for unwanted spectators and SI assist
- SwitchToSpec function added to assist with purposely going spectator
- A person going to SI in any non-competitive mode spawns correctly

### Changed
- Tanks removed from spawning with abm-mk N 3 (replaced with Witches)
- Logic (never tested) for team assignment moved to TakeOverTimer

### Fixed
- Massive performance boost regarding SI spawning

## [0.1.15] - 2017-08-01
### Added
- g_inspec key helps to check if someone is explicitly in spectator mode
- PlayerActivate parted from PlayerActivateHook (any new spectating bug fixes will probably start here)
- InSpec and LastId added to abm-info

### Fixed
- duplicate characters should safely be able to idle without going into spectate
- OnClientPostAdminCheck should now give all players a bot to play with on join

### Changed
- RemoveQDBKey required a char, it now requires an actual int client
- g_previd is now g_lastid
- On a players death, GenericMenuCleaner is now called before a takeover menu is shown
- QTeamHook tries to fix a spectating bug on any player that didn't use !join 1 to join spectators
- NewBotTakeOverTimer is now TakeOver (new was misleading as players wouldn't always get a new bot)
- A check to see if a client isn't already on a team >= 2 added to TakeOverTimer
- Switching to specator using !join 1 will set g_inspec to true
- abm-reset now resets every clients menu (use with caution in case of emergency)
- GenericMenuCleaner no longer checks if g_callBacks is empty
- An extra check if g_callBacks == INVALID_HANDLE in GenericMenuHandler


## [0.1.14] - 2017-05-01
### Added
- StringMap g_ghost key added (on activation, this model is used)
- g_cisi (client id to steam id) array added (g_cisi[client] = STEAMID)
- RoundFreezeEndHook helps to store user's models in memory for the next map
- PlayerActivateHook helps to restore a user's model from the last map
- OnPluginStart will now try to add client id's to g_cisi
- RemoveQDBKey helps to remove a STEAMID from g_QDB (parted from CleanQDBHook)
- NewBotTakeOverTimer is a recursive attempt at assigning a bot to a new player
- New (maybe better) signatures added to abm.txt for Windows servers (thanks cravenge)

### Changed
- GoIdle adds a check to make sure the person idling is a survivor
- OnSpawnHook is greatly simplified and models survivors at the most now

### Removed
- g_WasPlayers is gone (a whole new approach to abm_minplayers implemented)
- g_automd has been replaced with g_ghost (see PlayerActivateHook)

### Fixed
- An idle regression where idlers fought to idle
- Models are now better remembered across maps (not campaigns)

## [0.1.12] - 2017-01-01
### Fixed
- Last of the regressions due to Zoey should be fixed in this release (please God)
- Least amount of duplicates across Windows and Linux (e.g, abm-mk -32 2)
- Players should never idle more than 1 bot
- Player models should be remembered better
- Players 5 through 8 should be unique again

### Added
- QDB entries have a new key "g_automd" to flag if a client has been auto modeled

### Changed
- GetClientManager has been rewritten to hopefully squash an idling bug

## [0.1.11] - 2017-01-01
### Fixed
- Don't try applying models to an invalid client
- Don't assume a client selected from a menu is actually valid

## [0.1.10] - 2016-12-26
### Fixed
- Several regressions due to the rewrites for Zoey's workaround should be fixed in this release

### Removed
- g_ExtPlayers purpose replaced with g_WasPlayers which only changes upon updating abm_minplayers

## [0.1.9] - 2016-12-26
### Added
- ABM should now detect the OS on a new installation to avoid a crash on Windows
- MkBotsTimer (spawning survivors too fast screwed up the counting of team mates)
- Better Zoey support (if one spawns naturally, we won't try to change its netprop)
- You can change your model to Zoey on Windows but it's just a model (no voice, icon, etc)
- An UpdateMinPlayersHook watches for changes to abm_minplayers and updates extra players

### Changed
- Spawning survivors now works using a timer (they spawn in at 0.1 each)
- abm_minplayers should be better at staying on top of the minimum player base

### Removed
- AddToQDBHook (moved the RmBotsTimer to CleanQDBHook)

## [0.1.8] - 2016-12-23
### Added
- A GetOS function added to workaround the Zoey bug (Valve please fix?)
- abm_zoey cvar introduced to workaround crashes on Windows
- abm_zoey cvar is autodetected on Linux and new installations
- Added OS to gamedata.txt

### Changed
- Changed player_spawn back to player_first_spawn (it was getting kind of crazy)
- AutoModelAssigner changed to AutoModelTimer (and is a timer now)
- The algorithm for assigning models is greatly improved

### Removed
- OnSpawnHookTimer is gone (was a middle man timer to the now AutoModelTimer)
- Premature fix at spawning bots in version 0.1.7 is gone (Zoey was the problem)

## [0.1.7] - 2016-12-22
### Fixed
- Windows servers should now be able to spawn up to 32 survivors

## [0.1.6] - 2016-12-19
### Added
- Made a g_IsVs cvar to determine if game is a competitive pvp
- Try to distribute humans evenly across teams if mode is competitive
- New ClientHomeTeam function to determine a humans home team
- Non-admins on SI will see SI with !takeover
- Non-admins on SI will see a takeover menu on death
- Enabling logging will also send messages to the server terminal

### Changed
- Changed the algorithm for kicking extra players
- Reduced the amount of calls to some timers (e.g., OnSpawnHook, OnClientPostAdminCheck)
- Refactored TeamMatesMenu with more descriptive variable names
- Turned off the kicking of any bots if game is competitive
- Respawning should now respawn SI too
- Spawning of SI now use z\_spawn\_old ... auto
- abm-info shows MinPlayers/ExtPlayers now
- CountTeamMates uses GetTeamClientCount when we want all members

## [0.1.5] - 2016-12-15
### Changed
- Fixed some typos
- Removed #define DEBUG
- Lowered the size of g_menuItems
- Changed FirstSpawnHook to OnSpawnHook
- Human SI in a non-Vs are queued up again on death
- Reduced the usage of StringMap R again
- Changed the tracking of g_onteam to always point to the home team
- Added more checks to AddSurvivor
- Fixed a small bug in RmBots where passing in -0 can remove a bot
- Switching to an already living SI takes them over immediately

## [0.1.5] - 2016-12-15
### Changed
- Reduced the usage of StringMap R where possible
- Reduced the calls to FirstSpawnHookTimer from FirstSpawnHook
- Simplified FirstSpawnHookTimers algorithm

## [0.1.4] - 2016-12-15
### Changed
- Removed some code that didn't really do anything
- Fixed some typos

## [0.1.4] - 2016-12-14
### Added
- First Release

## This CHANGELOG follows http://keepachangelog.com/en/0.3.0/
### CHANGELOG legend

- Added: for new features.
- Changed: for changes in existing functionality.
- Deprecated: for once-stable features removed in upcoming releases.
- Removed: for deprecated features removed in this release.
- Fixed: for any bug fixes.
- Security: to invite users to upgrade in case of vulnerabilities.
- [YANKED]: a tag too signify a release to be avoided.
