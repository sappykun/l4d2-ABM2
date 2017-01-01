# ABM SourceMod Plugin

If you enjoy SourceMod and its community or if you rely on it - please don't just be a vampire's anal cavity and help them out. Help them meet their monthly goal [here](http://sourcemod.net/donate.php) and don't be too proud to throw them some pocket change if that's all you got.

Thanks :)

## License

ABM a SourceMod L4D2 Plugin
Copyright (C) 2016  Victor B. Gonzalez

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

## About

The ABM plugin helps add the 5th+ player to the cooperative experience in L4D2. It's been designed to "just work" with very little to no interaction on the admin's part short of dropping two files (**abm.smx** and **abm.text**) into their proper places. Once ABM is installed a 5+ player will spawn on their team equipped with a pump shotgun, baseball bat and an adrenaline shot (customizable). If any player in a 5+ campaign disconnects, their bot will disappear with them until the team size is at the minimum players required.

Players 1 through 8 should all be unique characters of the beloved series. If you start off with characters of the L4D1 series, new players will be of the L4D2 series and vice versa. Admins do have an interface in either the form of menus or chat commands. These "extras" were only implemented to help manually test some of the plugin's core functionality and are not the focal point of the plugin. Although the menus are helpful, the absolute core focus of the plugin is getting 5+ players to actually play together with as few bugs as is possible.

### Plugin Features

ABM tries to respect targeting permissions.

- Add X number of bots to survivor/infected teams.
- Remove X number of bots from survivor/infected teams.
- Switch any client between idle, spectator, survivor and infected.
- Switch to any available bot on survivor or infected.
- Respawn any client onto themselves or onto any other client.
- Teleport any client to any other client.
- Change any survivor's model to any other survivor model.
- Cycle through available bots on either team.
- Strip any survivor of one or all items in their inventory.

### Designed and Tested Against

- L4D2 (cooperative)
- A Linux dedicated server
- A clean SourceMod installation
- L4DToolZ

## Why?

The plugin at first may appear like a hodgepodge buffet of exquisite baloney but I assure you it's not. My approach to the plugin was pretty simple in that where I relied on a core feature I only added a way to test it. This route inevitably lead to the menus and chat commands and perhaps even the appearance that I may be trying to do more than I should.

If we removed the public interface...

We'll still need a way to **add** a bot or else player 5 will not have one to play as when they get in. When an extra player leaves, we **strip** and **remove** their bot to keep the bots from going sentient and to keep the server clean. Extra players spawn at the safe room so we **teleport** them and in a finale are required to **respawn** them.

A player **switching** to idle may lose their bot, idle more than one bot or lose their **model** in the process. **Cycling** is important for players that can join a team but don't already manage a bot on one. They'll **switch** to a free bot if one is available or one will be created for them.

At this point menus help troubleshoot if something is broke, or broke broke.

## How to install

### Prerequisites

You can skip the prerequisite here if you already have a way to unreserve your server or if you want all the other features that ABM provides (without the extra players).

- Install [L4DToolZ](https://forums.alliedmods.net/showthread.php?t=93600)
- Add the following (as an example) into your server.cfg
	- sv_maxplayers X  // replace X with players you want
	- sv_force_unreserved 1

### Installing and Configuring ABM

1. Drop abm.smx and abm.txt into their proper places
	- .../left4dead2/addons/sourcemod/plugins/abm.smx
	- .../left4dead2/addons/sourcemod/gamedata/abm.txt
2. Load up ABM (or restart the server)
	- sm_rcon sm plugins load abm
3. Customize ABM (Generated on first load)
	- .../left4dead2/cfg/sourcemod/abm.cfg

#### Fixing Some issues

If you have issues with a witch targeting the wrong player or a defib bringing back the wrong player, or if you're on Windows and Zoey is important to you, try these.

- [8+ Player](https://forums.alliedmods.net/showthread.php?t=121945)
- [Defibrillator](https://forums.alliedmods.net/showthread.php?t=118723)
- [FakeZoey](https://forums.alliedmods.net/showthread.php?t=258189)

You may not need these fixes at all if you keep your cooperative players less than or equal to 8 and everyone's model is unique.

## Usage

### Admin Menus
Most menus begin with a choose client option (admins see this screen).

```
abm             main menu
abm-menu        main menu
abm-join        (client > team)
abm-takeover    (client > bot)
abm-respawn     (client > client)
abm-model       (client > model)
abm-strip       (client > slot)
abm-teleport    (client > client)
abm-cycle       (client > team)
```

### Non Admin Menus

```
takeover  Choose from an available survivor bot
join      Choose a team (0 idler |1 spectator |2 survivor)
```

### Admin Chat Commands and Short Circuiting Menus

Most menus can be short circuited from ever showing e.g., **abm-join** for an admin brings up a **choose client > team** menu and for non-admins, just a team menu. To short circuit a menu, you'd say **abm-join 2** to join team survivors or **abm-join ID 2** to force a player with ID onto the survivors.

```
abm-mk <N> <TEAM>               add N bots (e.g., 4|-4) to TEAM (2|3)
abm-rm <N> <TEAM>               remove N bots (e.g., 4|-4) to TEAM (2|3)
abm-rm <TEAM>                   remove ALL bots on TEAM (2|3)
abm-join <TEAM>                 join team (creating a bot if necessary)
abm-join <HUMAN> <TEAM>         make player join team (creating a bot if necessary)
abm-takeover <BOT>              switch to BOT
abm-takeover <HUMAN> <BOT>      switch CLIENT to BOT
abm-respawn <HUMAN> [CLIENT]    respawn CLIENT on CLIENT (default is self e.g., defib)
abm-teleport <CLIENT> <CLIENT>  teleport CLIENT to CLIENT
abm-model <MODEL>               change model to MODEL (survivors only)
abm-model <MODEL> <CLIENT>      change model of client (survivors only)
abm-cycle <TEAM>                cycle through team (2|3)
abm-cycle <HUMAN> <TEAM>        cycle player through team (2|3)
abm-strip <CLIENT> [SLOT]       strip all items or specific slot (starts at 0)
abm-reset                       reset menus (in case of emergency)
abm-info                        how ABM is seeing the game
```

### Configuring ABM

```
abm_minplayers "4"                  minimum number of players at all times
abm_consumable "adrenaline"         5+ survivor consumable
abm_healitem ""                     5+ survivor healing item
abm_primaryweapon "shotgun_chrome"  5+ survivor primary weapon
abm_secondaryweapon "baseball_bat"  5+ survivor secondary weapon
abm_throwable ""                    5+ survivor throwable item
abm_loglevel "0"                    logging level of the plugin
abm_zoey "1"						this is auto-detected on Linux
```

### Checking the ABM version

```
- abm_version "..." Shows the version running on the server
```

## A Little Something Extra

Admins and players have manual access to **!join** and **!takeover** but note **!takeover** will also automatically show up on a players death. Admins may see an option to take over infected while non admins will not.

## Thanks

Yuge thanks to [MRxSNIPES2](http://steamcommunity.com/id/MRxSNIPES2/) for tirelessly being at the ready when I needed you. You certainly went out of your way to help and I salute you! A big thanks to [GamingBigFoot](http://steamcommunity.com/id/GamingBigfoot_Official/) for taking the testing of some issues to the next level. Making a plugin like this without those extra eyes is hard and I praise you guys for being so kind at helping me out :)

Thanks to **Kruffty** for trying out ABM on a Windows dedicated server and blowing shit up. You scare me but I still love you bro! Thanks to **Sheriff Huckleberry** for telling me you're too old for that Linux command line bullshit and that I should implement menus instead. Haha.

Major thanks to irc.[gamesurge.net](https://gamesurge.net/) for hosting the #sourcemod channel and in particular the following users **psychonic, asherkin, fakuivan, kbck** and **Peace-Maker** for putting up with me when I was too tired to Google another example and for forgiving what may have even been at the time "a stupid question". I thank you guys for being patient with me and helping me out :)

Thank you **cravenge** for plenty of insight, tips and criticisms on the [AlliedModders forums](https://forums.alliedmods.net). I've yet to get around to all of your suggestions but I'm working on them. Thank you for that unrecoverable time you spend in helping us all out :)

When I needed inspiration or insight on how to use any SourcePawn API feature my goto resources were in the following works.

- [MultiSlots](https://forums.alliedmods.net/showthread.php?t=132408)
- [Survivor bot take control](https://forums.alliedmods.net/showthread.php?p=1446781)
- [SM Respawn command](https://forums.alliedmods.net/showthread.php?p=862618)
- [Survivor Bot Select](https://forums.alliedmods.net/showthread.php?p=2426898)
- [Spectator Switch](https://forums.alliedmods.net/showthread.php?p=1983051)

Thank you **SwiftReal, MI 5, Pan XiaoHai, MasterMe, AtomicStryker, Ivailosp,
Merudo** and **HSFighter** for making L4D2 a fun game to play and SourceMod a great way to play it. Without your source code the ABM plugin would have been a whole lot harder to make and a lot longer to get out.

I can't thank each and every one of you enough!

## Reaching out to me

I love L4D2, developing, testing and running servers more than I like playing the game. Although I do enjoy the game and it is undoubtedly my favorite game, it is the community I think I love the most. It's always good to meet new people with the same interest :)

- [My Steam Profile](http://steamcommunity.com/id/buckwangs/)
- [My ABM GitLab Page](https://gitlab.com/vbgunz/ABM)
- [My SourceMod Thread](https://forums.alliedmods.net/showthread.php?t=291562)

## Notes and Stuff

Spectators and playing teams can't talk with one another by default. If you'd like to chat between spectator, survivor and infected you'll need to cast an all talk vote or run **sm_rcon sv_alltalk 1**. The following are some goodies that helped me out while developing this plugin, they can maybe help you out too if you don't know of them.

- sm_cvar display_game_events 1
- sm_cvar net_showevents 2
- find sm_dump
- objdump -d steamcmd/left4dead2/left4dead2/bin/server_srv.so > ~/server_srv.so.dump
- https://sm.alliedmods.net/new-api/
- https://forums.alliedmods.net/showthread.php?t=277703&

## Bugs

- Cycling through bots too fast can make them vaporize
- Defibs may do some strange things (see [this](https://forums.alliedmods.net/showthread.php?t=118723))
- Witchs may target the wrong player (see [this](https://forums.alliedmods.net/showthread.php?t=121945))
- abm_zoey 5 on Windows will most likely crash the server (also changing your model to Zoey on Windows may crash the server)

## What Next?

I'll try to fix whatever bugs come to my attention and I'll consider feature request but I think I'm done and I want to get started on another idea I think is unique. Hopefully it is and hopefully it's simpler.

Simpler, yeah right.
