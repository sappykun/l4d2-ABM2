# ABM SourceMod Plugin

If you enjoy SourceMod and its community or if you rely on it - please don't just be a vampire's anal cavity and help them out. Help them meet their monthly goal [here](http://sourcemod.net/donate.php) and don't be too proud to throw them some pocket change if that's all you got.

Thanks :)

## License
ABM a SourceMod L4D2 Plugin
Copyright (C) 2017  Victor "NgBUCKWANGS" Gonzalez

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

## About
ABM is an alternative to [MultiSlots](https://forums.alliedmods.net/showthread.php?p=1239544), [DDRKhat's SuperVersus](https://forums.alliedmods.net/showthread.php?p=830069) and [Merudo's SuperVersus](https://forums.alliedmods.net/showthread.php?p=2393931#post2393931). It's main purpose is to allow a greater number of players than is officially supported to play in any given game mode (e.g., campaign, survival, versus, etc). ABM works in the background but does expose what's under its hood in the form of menus and chat triggers. ABM is not pursuing a be-all-end-all plugin full of random goodies but is pretty focused on getting more players together, enjoying the game.

> ABM is stable for the most part but hasn't been thoroughly tested in competitive modes and may be a bit rough around the edges. If you're up to trying ABM in any mode and you're willing to provide some feedback on your experience, post it [here on AlliedModders](https://forums.alliedmods.net/showthread.php?t=291562) and [friend me on Steam](http://steamcommunity.com/id/buckwangs/).

### In a Nutshell
Out of the box ABM does very little augmentation to core mechanics when players are within the officially supported limits (4 for non-competitive, 8 for competitive). In non competitive modes and when limits are exceeded ABM will help spawn more SI but in competitive modes (and if L4Downtown2 is available), they'll only be unlocked. ABM has made this customizable and you can turn this off completely if required.

### Prerequisites
ABM was developed against the following

- [SourceMod 1.8](https://www.sourcemod.net/)

If you're trying to unlock slots (ABM only handles them after they're unlocked)

- [L4DToolZ](https://forums.alliedmods.net/showthread.php?t=93600)

If you're playing some custom campaigns that like to move dead bodies around (e.g., Tanks Playground), you'll need the following

- [L4D2 Bug Fixes](https://github.com/Accelerator74/l4d2_bugfixes)
- [L4D2 Defib Fix](https://github.com/Accelerator74/l4d2_defibfix)

The following is optional but if you plan on using ABM in competitive modes with greater than 8 players you'll want either of the following (non-slot) builds of Left 4 Downtown 2.

- [Left 4 Downtown 2](https://forums.alliedmods.net/showthread.php?t=134032) (official thread)
- [Spirit_12's Linux Build of Left 4 Downtown 2](https://forums.alliedmods.net/showpost.php?p=2286832&postcount=758) (this is the build I tested against)

### Installing ABM
1. Drop abm.smx and abm.txt into their proper places
	- .../left4dead2/addons/sourcemod/plugins/abm.smx
	- .../left4dead2/addons/sourcemod/gamedata/abm.txt
2. Load up ABM
  - ```sm_rcon sm plugins load abm```
  - OR restart the server
3. Customize ABM (Generated on first load)
	- .../left4dead2/cfg/sourcemod/abm.cfg

### Uninstalling ABM
1. Remove .../left4dead2/addons/sourcemod/plugins/abm.smx
2. Remove .../left4dead2/addons/sourcemod/gamedata/abm.txt
3. Remove .../left4dead2/cfg/sourcemod/abm.cfg
4. Remove .../left4dead2/left4dead2/addons/sourcemod/logs/abm.log

### Disabling ABM
1. Move abm.smx into plugins/disabled
2. ```sm_rcon sm plugins unload abm```

## ABM Menus/Commands
```
"abm-cycle"
 - Menu/Cmd: <TEAM> | <ID> <TEAM>
"abm-info"
 - Cmd: (Print some diagnostic information)
"abm-join"
 - Menu/Cmd: <TEAM> | <ID> <TEAM> | <ID> 3 <SI>
"abm-menu"
 - Menu: (Main ABM menu)
"abm-mk"
 - Cmd: <N|-N> <TEAM>
"abm-model"
 - Menu/Cmd: <MODEL> | <MODEL> <ID>
"abm-reset"
 - Cmd: (Use only in case of emergency)
"abm-respawn"
 - Menu/Cmd: <ID> [ID]
"abm-rm"
 - Cmd: <TEAM> | <N|-N> <TEAM>
"abm-strip"
 - Menu/Cmd: <ID> [SLOT]
"abm-takeover"
 - Menu/Cmd: <ID> | <ID1> <ID2>
"abm-teleport"
 - Menu/Cmd: <ID1> <ID2>>
```

Menus are available only in game and require zero arguments. If you're using commands anything in <> is required. Anything in [] is optional. Anything split with a | is an either or. Menus are great if you're in game and commands are the only option if you're managing a game from an SSH/terminal session. Some commands make handy binds e.g., ```bind n "abm-cycle 2"```.

### Legend
- **TEAM**: 0: idler, 1: spectator, 2: survivor, 3: infected
- **ID**: A client Id (you can see these with ```abm-info``` or ```status```)
- **MODEL**: A model name e.g., Nick
- **SLOT**: 0 (Primary weapon) of 4 (consumable) Inventory slots

### Legend Example
- **abm-cycle**  // Menu: Choose player menu > choose team menu
- **abm-cycle 2**  // Cmd: Will cycle the commander through team 2 (survivors)
- **abm-cycle 1 3**  // Cmd: Will cycle client with ID 1 through team 3 (infected)

Notice how in the second bullet item, TEAM is in argument position 1 and in the third bullet item, the client ID is in argument position 1 and TEAM in argument position 2. ```<TEAM> | <ID> <TEAM>.```

### Note on Menus/Commands
Menus that are shared between admins and non-admins e.g., ```!takeover``` differ slightly. Admins will get a choose player menu where as non-admins do not. Admins will have an option to takeover infected bots whereas non-admins (not on team 3) do not.  Administrators on death will have the ability to take over any available bot from any team whereas non-admins are only offered bots of their own team.

Administrators can put anyone onto any team and into any bot using either menus or commands. Be careful whom you give admin with ABM as ABM provides quite a bit of power. Admins can go onto the special infected team in any mode. An admin just having fun can ruin an otherwise great game for unsuspecting players. It should go without saying, respect your players.

## Configuration Variables (Cvars)
```
"abm_autohard" = "1"
 - 0: Off 1: Non-Vs > 4 2: Non-Vs >= 1
"abm_automodel" = "1"
 - 1: Full set of survivors 0: Map set of survivors
"abm_consumable" = "adrenaline"
 - 5+ survivor consumable item
"abm_extraplayers" = "0"
 - Extra survivors to start the round with
"abm_healitem" = ""
 - 5+ survivor healing item
"abm_identityfix" = "1"
 - 0: Do not assign identities 1: Assign identities
"abm_joinmenu" = "1"
 - 0: Off 1: Admins only 2: Everyone
"abm_keepdead" = "0"
 - 0: The dead return alive 1: the dead return dead
"abm_loglevel" = "0"
 - Development logging level 0: Off, 4: Max
"abm_minplayers" = "4"
 - Pruning extra survivors stops at this size
"abm_offertakeover" = "1"
 - 0: Off 1: Survivors 2: Infected 3: All
"abm_primaryweapon" = "shotgun_chrome"
 - 5+ survivor primary weapon
"abm_secondaryweapon" = "baseball_bat"
 - 5+ survivor secondary weapon
"abm_spawninterval" = "36"
 - SI full team spawn in (5 x N)
"abm_stripkick" = "0"
 - 0: Don't strip removed bots 1: Strip removed bots
"abm_tankchunkhp" = "2500"
 - Health chunk per survivor on 5+ missions
"abm_teamlimit" = "16"
 - Humans on team limit
"abm_throwable" = ""
 - 5+ survivor throwable item
"abm_unlocksi" = "0"
 - 0: Off 1: Use Left 4 Downtown 2 2: Use VScript Director Options Unlocker
"abm_version" = "0.1.73"
 - ABM plugin version
"abm_zoey" = "5"
 - 0:Nick 1:Rochelle 2:Coach 3:Ellis 4:Bill 5:Zoey 6:Francis 7:Louis
```

### Extending Configurations
ABM provides a way to override cvars based on the map name. Create the folder cfg/sourcemod/abm and create a file named MAPNAME.cfg. When loading a map with an extended configuration, cvars provided here will override any found in abm.cfg. Some maps may require this e.g., Tanks Playground, Tanks Challenge, Tanks Arena. Taking Tanks Challenge as an example, create the file cfg/sourcemod/abm/l4d2_tank_challenge.cfg and to prevent any spawning of SI and make all Tanks health a bit more reasonable, do this
```
abm_unlocksi 0
abm_spawninterval 0
abm_tankchunkhp 1000
```

Overridden cvars are reset back to normal when a map changes to one without an extended config.

### Locking and Unlocking Cvars
During a game, changing a plugin cvar that differs from the value in its cfg will normally get reset on map change. ABM provides a way to lock and unlock cvars that will last across map changes. When setting an ABM cvar, prefix it with -l (for lock) or -u (for unlock). __It is safe to separate the switch (-l or -u) with white space in a terminal but the universal approach is no white space between the switch and its value__.

- abm_minplayers 1  // revert to cfg value on next map
- abm_minplayers -l1  // lock this value until we unlock it
- abm_minplayers -u1  // unlock back to default behavior

### Cvars Explained
Some cvars are self explanatory and those that are not are addressed below.

#### abm_autohard (default 1)
If greater than or equal to 1, (abm_spawninterval x 5) will match a full wave of SI to the size of the surviving team. Half this value will match half the size of the surviving team. SI waves only spawn in non-competitive modes. See abm_unlocksi for spawning more SI in competitive modes.

#### abm_joinmenu (default 1)
When set to 0, players joining will automatically be put onto a team. When set to 1 only admins will join in as spectators and be offered an option to join idler, spectator, survivor or infected. When set to 2, non-admins will join in as spectators and be able to choose from idler, spectator or survivor.

#### abm_loglevel (default 0)
When set to 1 or greater (up to 4 for increased verbosity) will show you the calls ABM makes. This isn't useful for figuring out any random crashes but helps when developing a feature or for figuring out a reliable and repeatable problem.

#### abm_minplayers (default 4)
On the start of every round and during play, survivors are pruned to match this value (includes abm_extraplayers). If you set this to 2, every round will start off with only 2 survivors. When extra players join in and then leave, pruning of survivors will continue until this value (and abm_extraplayers) is matched.

#### abm_offertakeover (default 1)
When set to 0 this will be turned off. When set to 1 (for survivors) or 2 (for infected), players will be offered a takeover menu (only if a bot is available) upon their death. Setting this to 3, everyone will get a takeover menu on death. This can get noisy for people on SI and may even cause confusion or death.

#### abm_spawninterval (default 36)
The Assistant Director (ADTimer) is fired every 5 seconds. When abm_spawninterval is met a full wave (in non-competitive modes) spawns in. When half this value is met, half the SI will spawn in. See abm_autohard for more details.

#### abm_tankchunkhp (default 2500)
Tank's health multiplied per survivor. Setting this to 0 will turn this enhancement off. This cvar also depends on abm_autohard being greater than or equal to 1. If abm_autohard is set to 1, Tank's health is only modified when the surviving team size is greater than 4. If abm_autohard is set to 2, Tank's health will always be modified based on this value.

#### abm_teamlimit (default 16)
This sets a limit of humans allowed on any given playable team. Only new players joining the server will automatically get moved to spectator if the humans on team have already met this limit. If you're having a match that requires teams be of a certain size, setting this will move those extra players onto spectator.

#### abm_extraplayers (default 0)
This many extra survivors are added spawned in at the start of every round. If this is set to 4 and abm_minplayers is also set to 4, you'll get a total of 8 players at the start of the round.

#### abm_zoey (Linux default 5, Windows default 1)
Due to a bug on Windows, spawning in a Zoey can crash the server. This value is auto detected and set to 5 on Linux and 1 on Windows by default. You'll get the model Zoey in all cases but only on Windows will Zoey really be Rochelle or the model you decide on.

#### abm_unlocksi (default 0)
With this value at 0, ABM will not be able to unlock SI in some situations (e.g., Versus). Changing this to 1 will unlock SI with the use of Left 4 Downtown 2 and with a value of 2 will use VScript Director Options Unlocker. Any value greater than 0 here should have its respective plugin already on the server.

- [VScript Director Options Unlocker](https://forums.alliedmods.net/showthread.php?t=299532)
- [Left 4 Downtown 2](https://forums.alliedmods.net/showthread.php?t=134032)

#### abm_automodel (default 1)
Try to automatically model survivors to as unique a set as possible. This includes L4D1 characters on an L4D2 map and vice versa. Give this a value of 0 to turn it off.

#### abm_identityfix (default 1)
Try to remember and restore a survivor (real client, not bot) character. In some situations a survivor may change identity and ABM will try to fix that. If you're purposefully changing characters outside of ABM or wish to disable this, a value of 0 will turn this off.

#### abm_keepdead (default 0)
New survivor bots are created for new players and some people that may die may leave and rejoin to take advantage of it. Turning this to 1 will try to prevent that in making sure that players that leave and return, return dead.

#### abm_stripkick (default 0)
This will not strip leaving survivors of their inventory and all of their items will drop to the floor where they leave the game. Turning this to 1 will strip leaving survivors of all of their inventory and nothing will drop.


## How-to

### Get Client Ids
- Q. How do I get client Ids when working from a terminal?
	- A. ```abm-info``` OR ```status```

### Add Bots
- Q. I have 4 survivors. How do I add 4 more?
  - A. ```abm-mk 4 2```
- Q. I have an unknown number of survivors, how do I not exceed 16?
  - A. ```abm-mk -16 2```
- Q. Does adding bots have a menu?
  - A. No

### Remove Bots
- Q. I have 4 survivors. How do I remove only 1?
  - A. ```abm-rm 1 2```
- Q. I have an unknown number of survivors, how do I remove all but 4?
  - A. ```abm-rm -4 2```
- Q. How do I remove all survivors?
  - A. ```abm-rm 2```
- Q. Does removing bots have a menu>?
  - A. No

### Cycle through Bots
- Q. Can I cycle through the dead?
	- A. No
- Q. How do I cycle among survivors?
  - A. ```abm-cycle 2```
- Q. How do I cycle among Special Infected?
  - A. ```abm-cycle 3```
- Q. How do I cycle someone else through a team?
  - A. ```abm-cycle ID TEAM```
- Q. Cycling skips the dead so how do I get dead Zoey?
  - A. ```abm-takeover|takeover [ZOEYS-ID]```
- Q. How do I get to the menu?
  - A. ```abm-cycle```

### Gather Information
- Q. How can I get some insight into ABM?
  - A. ```abm-info```
- Q. Where are my logs?
	- A. ```.../left4dead2/addons/sourcemod/logs/```

### Join a Team
- Q. What are the teams?
	- 0 = Idlers
	- 1 = Spectators
	- 2 = Survivors
	- 3 = Infected
- Q. How do I join idlers?
  - A. ```abm-join|join 0```
- Q. I'm Special Infected but I can't idle?
  - A. Special Infected can't idle, they can only spectate
- Q. How do I spectate?
  - A. ```abm-join|join 1```
- Q. How do I join survivors?
  - A. ```abm-join|join 2```
- Q. How do I put someone else onto a team?
  - A. ```abm-join|join [ID TEAM]```
- Q. How do I join SI as a particular SI?
  - A. ```abm-join|join 3 NAME```
- Q. How do I make someone else a particular SI?
  - A. ```abm-join|join ID 3 NAME```
- Q. How do I see the Join menu?
  - A. ```abm-join|join```

### Change Models
- Q. Can I change my Special Infected model?
  - A. No
- Q. How do I change my survivor model?
  - A. ```abm-model [MODEL]```
- Q. How do I change another survivor model?
  - A. ```abm-model [MODEL ID]```
- Q. How do I get to the model menu?
	- A. ```abm-model```
- Q. I want more model options, how?
	- A. [L4D2 Model Changer](https://forums.alliedmods.net/showthread.php?t=286987) is compatible with ABM

### Respawn Clients
- Q. How do I respawn a player?
	- A. ```abm-respawn ID```
- Q. Player respawns dead OR how do I respawn a player onto a target?
	- A. Respawn on top of another player ```abm-respawn [ID TARGET-ID]```
- Q. How do I see the respawn menu?
	- A. ```abm-respawn```

### Fix Menus
- Q. How do I open up the main menu?
	- A. ```abm-menu```
- Q. I'm having an issue with the menus, nothing's working?
	- A. Check if ABM is loaded ```sm_rcon sm plugins list all```
- Q. ABM is loaded but menus aren't working?
	- A. Do you hear the menu? If so, restart the client.
- Q. I don't hear the menu, ABM is loaded, what can I do?
	- A. After exhausting all options try ```abm-reset``` and try again
- Q. After running abm-reset, I still don't have menus?
	- A. Try ```sm_rcon sm plugins reload abm```
- Q. I can't exit the menu
	- A. ```bind 0 slot10```
- Q. I'm out of options, how do I troubleshoot?
	- A. See ```.../left4dead2/addons/sourcemod/logs/```

### Strip Clients
- Q. Why is this useful?
	- A. Cleans up after pruned survivors
- Q. How do I strip a player of all of their inventory?
	- A. ```abm-strip [ID]```
- Q. How do I strip a particular inventory item?
	- A. Slots are from 0 to 4, ```abm-strip [ID SLOT]```
- Q. How do I get to the strip menu?
	- A. ```abm-strip```

### Takeover Bots
- Q. Can I takeover dead bots?
	- A. Dead survivor bots, yes. Infected, no.
- Q. How do I takeover a bot?
	- A. ```abm-takeover|takeover [TARGET-ID]```
- Q. How do I make someone else takeover a bot?
	- A. ```abm-takeover|takeover [ID TARGET-ID]```
- Q. How do I get to the Takeover menu?
	- A. ```abm-takeover|takeover```

### Teleport Clients
- Q. What are my teleporting options?
	- A. You can ONLY teleport any one player to another players position
- Q. How do I teleport players?
	- A. ```abm-teleport [ID TARGET-ID]```
- Q. How do I get to the Teleport menu?
	- A. ```abm-teleport```

### Configure ABM
- Q. How do I start every round with only 2 survivors?
	- ```abm_minplayers 2```
	- ```abm_extraplyers 0```
- Q. How do I start every round with 8 survivors?
	- ```abm_minplayers 4```
	- ```abm_extraplayers 4```
- Q. Using L4DToolZ, I want 12 players but only 8 playing at once?
	- ```sv_minplayers 12```
	- ```abm_teamlimit 8```
- Q. How do I turn off the auto-difficulty in ABM?
	- ```abm_autohard 0```
	- ```abm_tankchunkhp 0```
- Q. How can I immediately get put on a team when joining the server?
	- ```abm_joinmenu 0```
- Q. How do I get a list of inventory items for survivors?
	- A. ```sm_dump_classes sm_dump_classes.txt (search for - weapon_)```
- Q. How can I enforce a change to a cvar without editing the cfg?
	- A. Use the -l switch (l for lock) e.g., ```abm_minplayers -l2```
- Q. I locked a cvar, how do I unlock it?
	- A. Use the -u switch (u for unlock) e.g., ```abm_minplayers -u4```
- Q. Do I always have to lock/unlock cvars?
	- A. Lock cvars when you require persistence (until unlock/restart)
	- A. Unlock cvars (only if they're locked) and changes are temporary
- Q. How do I turn off takeover menus on a players death?
	- A. ```abm_offertakeover 0```
- Q. Can I change configuration based on the map we're playing?
    - A. See "Extending Configurations"

## Thanks
The most valuable assets of any good community are in the time of its people and knowledge summed. I've learned some valuable insights while writing ABM and it is what it is because of good people.

I will take your time and knowledge and pass it forward. I thank you all :)

### Contributers
**Lux, Spirit_12, cravenge and Timocop.** You fellas stepped up with code and support when I needed it the most (sometimes I didn't even ask).

### Testers
**MrSNIPES2, Sev, GamingBigFoot, bluejoy, Maii Maii, Nick9572, TheoldDinosaurT -ZK, MomigaJedi, BooBooKittyFuck, CollDragon and UnaBonger.** When servers crashed and burned you guys stood at the ready.

### Advisers
**Kruffty, Sheriff Huckleberry, MasterMind420, psychonic, asherkin, fakuivan, kbck, Peace-Maker and ProdigySim**. When I had a question you guys had an answer.

### Inspiration
When I didn't know how something worked or I needed examples in action, it was in the following works I'd go to for some enlightenment.

- [MultiSlots](https://forums.alliedmods.net/showthread.php?t=132408) (SwiftReal, MI 5, Pan XiaoHai, MasterMe)
- [Survivor bot take control](https://forums.alliedmods.net/showthread.php?p=1446781) (Pan Xiaohai)
- [SM Respawn command](https://forums.alliedmods.net/showthread.php?p=862618) (AtomicStryker, Ivailosp)
- [Survivor Bot Select](https://forums.alliedmods.net/showthread.php?p=2426898) (Merudo)
- [Spectator Switch](https://forums.alliedmods.net/showthread.php?p=1983051) (HSFighter)

## Reaching Me
I love L4D2, developing, testing and running servers more than I like playing the game. Although I do enjoy the game and it is undoubtedly my favorite game, it is the community I think I love the most. It's always good to meet new people with the same interest :)

- [My Steam Profile](http://steamcommunity.com/id/buckwangs/)
- [My ABM GitLab Page](https://gitlab.com/vbgunz/ABM)
- [My SourceMod Thread](https://forums.alliedmods.net/showthread.php?t=291562)
