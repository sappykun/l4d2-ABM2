# ABM Change Log

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
