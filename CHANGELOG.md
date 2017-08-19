# ABM Change Log

## [0.1.83] - 2017-19-08
### Fixed
- Regression in performance due to not unhooking in AutoModel

## [0.1.82] - 2017-18-08
### Fixed
- Players on changelevel and sm_map possibly ending up botless

### Added
- OnMapEnd is the new RoundFreezeEndHook (should fix changelevel and sm_map)

## [0.1.81] - 2017-18-08
### Changed
- Optimized UpdateConVarsHook lookups

### Fixed
- OnPluginStart cvar definition order

## [0.1.80] - 2017-18-08
### Added
- SetupCvar function to help simplify in setting up new cvars

### Changed
- Huge refactoring effort in organizing and creating cvars from the source

### Fixed
- Pushing a human into any bot (SI included) when not explicitly spectating

## [0.1.79] - 2017-16-08
### Added
- CmdIntercept function to watch for use of z_spawn commands

### Fixed
- Tank spawn timer not getting reset in some situations
- Using z_spawn should no longer knock out ABMs SI in non-competitive modes

## [0.1.78] - 2017-16-08
### Added
- IsEntityValid function

### Changed
- IsValidEntity calls to use IsEntityValid
- Tweaked up just a bit

## [0.1.77] - 2017-16-08
### Fixed
- Slight optimization to OnEntityCreated (if else if)
- SI to spectator model is now correctly blanked out
- Cleaned up a bit

## [0.1.76] - 2017-15-08
### Fixed
- Executing abm.cfg on some Linux servers that seem to ignore it

## [0.1.75] - 2017-15-08
### Added
- Extended configuration support e.g., cfg/sourcemod/abm/tankyard.cfg

## [0.1.74] - 2017-14-08
### Fixed
- Quicker model detection
- QRtmp now mirrors QRecord perfectly

## [0.1.73] - 2017-14-08
### Changed
- OnEntityCreated will now automatically model a survivor on next frame
- AutoModelTimer is no longer a timer and is now called \_AutoModel

### Fixed
- AssignModel again checks if client passed in is valid

## [0.1.72] - 2017-13-08
### Changed
- Checking for and forcing players onto a team after a changelevel

### Fixed
- Respawning real survivors onto themselves

## [0.1.71] - 2017-13-08
### Added
- abm_identityfix cvar 1 tries to correct player identities, 0 is off

## [0.1.70] - 2017-13-08
### Added
- GetAllSurvivorModels function split from AutoModelTimer
- AutoModel is now a proxy function to AutoModelTimer
- g_models is an array that inventories all survivor models

### Fixed
- Skipping Nick when checking for models to auto assign

## [0.1.69] - 2017-12-08
### Added
- OnMapStart added and here models are now precached

### Changed
- Slowed down KillEntTimer from 1.0 to 2.0
- Tweaked AutoModelTimer
- PrecacheModels doesn't check if a model is precached, we just precache it

## [0.1.68] - 2017-11-08
### Changed
- Replaced several GetQRecord calls with GetQRtmp

### Added
- GetQRtmp now sets all expected keys prefixed with g_tmp e.g., g_tmpOnteam

### Fixed
- Regression with ABMClients not getting properly kicked

## [0.1.67] - 2017-11-08
### Changed
- Echo level 1 is now meant for active development

## [0.1.66] - 2017-11-08
### Added
- Checks to both adding survivors and infected to prevent some warnings

## [0.1.65] - 2017-11-08
### Fixed
- Changing sides on Versus should no longer be limited by vs_max_team_switches

## [0.1.64] - 2017-11-08
### Added
- QRtmp identical to QRecord meant for use where records may change rapidly
- GetQRtmp function acts similiar to GetQRecord

## [0.1.63] - 2017-11-08
### Changed
- Refactored TakeoverBotSig and TakeoverZombieBotSig functions

## [0.1.62] - 2017-11-08
### Added
- GetBotCharacter function to grab a players/bot correct model
- Try to apply a players model ASAP in QTeamHook
- Figuring out a players model ASAP in GetQRecord

### Fixed
- Properly detect and assign requested SI to humans in non-competitive modes

### Changed
- Refactored AutoModelTimer and now detect proper survivor set for map

### Removed
- QRecord key "ghost" removed. Will try to rely only on the "model" key

## [0.1.61] - 2017-11-08
### Changed
- IsClientValid now has optional arguments of team/any and human/bot/all

### Added
- Try to Automodel bots *after* humans are all loaded

## [0.1.60] - 2017-24-07
### Changed
- Tweaked LifeCheckTimer
- Tweaked OnAllSpawnHook
- Small tweaks all around and most functions are now tagged

## [0.1.59] - 2017-23-07
### Changed
- ADTimer reorganized

## [0.1.58] - 2017-23-07
### Fixed
- Spectator -> idle -> specate bug (spectated bots had wrong name)

## [0.1.57] - 2017-23-07
### Changed
- Refactored CountTeamMates function
- Refactored GetClientManager function

## [0.1.56] - 2017-21-07
### Added
- Finalized abm_keepdead support
- OnAllSpawnHook function -> LifeCheckTimer
- GetRealClient function to track an idler/spectators bot
- LifeCheckTimer function to track a players bot life/death state
- New QRecord key "update", when true will reset a players QRecord

### Changed
- OnClientPostAdminCheck rewritten to support abm_keepdead
- RemoveQDBKey no longers removes QRecords, makes "update" true
- Experimental changes to AddSurvivor function (trying to simplify it)

### Fixed
- Jockey parent bug (thanks to Lux for the fix)

## [0.1.55] - 2017-21-07
### Changed
- Added optional update argument to SetQRecord prototype

## [0.1.54] - 2017-21-07
### Added
- Preliminary abm_keepdead cvar (1 keeps raging survivors dead, 0 doesn't)
- UpdateGameMode function to better detect gamemodes (competitive Vs non)

### Fixed
- mp_gamemode detection regression

## [0.1.53] - 2017-20-07
### Changed
- Cleaned and tweaked SI spawning in non-competitive modes

## [0.1.52] - 2017-20-07
### Fixed
- SI regression (creation and takeover)

## [0.1.51] - 2017-19-07
### Added
- Fifth+ survivor should now auto-idle on join
- AutoIdleTimer function helps with survivors auto-idling

## [0.1.50] - 2017-19-07
### Fixed
- Corrected UpdateConVarsHook abm_zoey value to its correct value

## [0.1.49] - 2017-19-07
### Added
- RegulateSI function to help configure VScript Director Options Unlocker
- RestoreDvars function for restoring default VScript Director Options Unlocker value

## [0.1.48] - 2017-18-07
### Added
- abm_stripkick cvar option, 1 strips survivors, 0 drops their items
- abm_automodel cvar option, 1 will automodel, 0 will use default behavior

## [0.1.47] - 2017-18-07
### Added
- abm_unlocksi when set to 2 will configure and use VScript Director Options Unlocker

## [0.1.46] - 2017-18-07
### Changed
- Cleaned up AddInfected function, trying to reduce CreateFakeClient
- Cleaned up L4D_OnGetScriptValueInt (match VScript Director Options Unlocker)
- Cleaned up UpdateConVarsHook
- abm_unlocksi now defaults to 0 

## [0.1.45] - 2017-13-07
### Fixed
- Tank health calculation

## [0.1.44] - 2017-12-07
### Changed
- Cleaned up whitespace all around

### Fixed
- Humans controlling SI in non-competitive modes spawn fast again

## [0.1.42] - 2017-12-07
### Added
- abm_unlocksi for use with Left4Downtown2 in competitive modes
- Tanks in non-competitive modes are now forced to spawn

### Changed
- Rewrote CleanSIName function and made it simpler
- Cleaned g_InfectedNames array
- Increased abm_spawninterval default from 18 to 36 (feels about right)

### Fixed
- Hang from switching SI from a controlled Tank
- Rejoining survivors and sometimes creating a new bot
- Premature ending of competitive rounds

## [0.1.37] - 2017-09-03
### Added
- abm_spawninterval 0 will turn off SI waves

### Changed
- Human activation of stasis Tanks in non-competitive mode
- README description of locking/unlocking cvars and white space

## [0.1.36] - 2017-21-02
### Added
- abm_autohard cvar 0: Off 1 (default): Non-Vs > 4 2: Non-Vs >= 1"
- abm_joinmenu cvar 0: Off 1: (default) Admins only 2: Everyone
- abm_teamlimit cvar (default is 16), humans on team before going spectator
- abm_offertakeover cvar 0: Off 1 (default): Survivors 2: Infected 3: All
- OnEntityCreated/KillEntTimer (contributed by Ludastar) removes SI barriers
- Command arguments defined

### Changed
- L4D_OnGetScriptValueInt kicks in *if* abm_autohard >= 1
- Rebalanced SI waves (90 seconds full wave, 45 seconds half wave)
- Human on SI in non-Vs modes no longer speeds up any SI waves
- abm_tankchunkhp and abm_autohard may manage Tank health interactively
- CountTeamMates will return 0 until the round is unfrozen
- Refactored TakeOver to Takeover (where possible)

## [0.1.35] - 2017-13-02
### Fixed
- Mobs of SI far greater than the size of the surviving team
- SI spectators forced to be a Tank (even if explicitly spectating)
- Extra Tanks in ghost mode dying when a human is on SI in non-Vs
- Model assignment slowed from 0.1 to 0.2 (fixes Fall in Death model 5+)

## [0.1.34] - 2017-09-02
### Added
- Preliminary Vs support
- Optional dependency on Left 4 Downtown 2 (5+ auto difficulty on campaigns)

## [0.1.33] - 2017-03-02
### Fixed
- When someone joins a new bot is created over stuffing them into a dead body

## [0.1.32] - 2017-02-02
### Changed
- Slight optimizations all across the board
- g_AssistedSpawning now toggles its state based on humans on SI
- Cycling through bots on a team should only cycle through the living

### Fixed
- Joining survivors as a dead teammate could lock you into that dead body
- Cycling through bots fast enough can cause you to lose a bot to the ether
- More aggressive checking may have solved some crashes related to ABM

## [0.1.31] - 2017-01-02
### Added
- QueueUp adds players to team queues (automatically unqueues them elsewhere)
- Unqueue will remove any one player from all possible queues
- Everyone playing SI in non-Vs mode should automatically get the Tank next

### Fixed
- Losing your SI to spectator in certain situations puts you in a new body

### Changed
- Cleaned up some Echo calls
- TakeOverBotSig cleaned with aggressive checking and now takes a bot argument
- Takeovers with TakeOverBotSig and TakeOverZombieBotSig unqueues automatically
- TakeOverZombieBotSig now takes a si_ghost argument

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
