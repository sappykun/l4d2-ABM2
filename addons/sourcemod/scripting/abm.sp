//# vim: set filetype=cpp :

/*
ABM a SourceMod L4D2 Plugin
Copyright (C) 2016-2017  Victor "NgBUCKWANGS" Gonzalez

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the

Free Software Foundation, Inc.
51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

// TODO:
//SetEntProp(client, Prop_Send,"m_bHasNightVision", 1);
//SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#undef REQUIRE_EXTENSIONS
#include <left4downtown>

#define PLUGIN_VERSION "0.1.50"
#define LOGFILE "addons/sourcemod/logs/abm.log"  // TODO change this to DATE/SERVER FORMAT?

Handle g_GameData = null;
ArrayList g_sQueue;
ArrayList g_iQueue;

int g_OS;  // no one wants to do OS specific stuff but a bug on Windows crashes the server

// menu parameters
#define menuArgs g_menuItems[client]     // Global argument tracking for the menu system
#define menuArg0 g_menuItems[client][0]  // GetItem(1...)
#define menuArg1 g_menuItems[client][1]  // GetItem(2...)
g_menuItems[MAXPLAYERS + 1][2];

// menu tracking
#define g_callBacks g_menuStack[client]
ArrayStack g_menuStack[MAXPLAYERS + 1];
new Function:callBack;

char g_QKey[64];      // holds players by STEAM_ID
StringMap g_QDB;      // holds player records linked by STEAM_ID
StringMap g_QRecord;  // changes to an individual STEAM_ID mapping
StringMap g_Cvars;

char g_InfectedNames[6][] = {"Boomer", "Smoker", "Hunter", "Spitter", "Jockey", "Charger"};
char g_SurvivorNames[8][] = {"Nick", "Rochelle", "Coach", "Ellis", "Bill", "Zoey", "Francis", "Louis"};
char g_SurvivorPaths[8][] = {
    "models/survivors/survivor_gambler.mdl",
    "models/survivors/survivor_producer.mdl",
    "models/survivors/survivor_coach.mdl",
    "models/survivors/survivor_mechanic.mdl",
    "models/survivors/survivor_namvet.mdl",
    "models/survivors/survivor_teenangst.mdl",
    "models/survivors/survivor_biker.mdl",
    "models/survivors/survivor_manager.mdl",
};

char g_dB[512];                     // generic debug string buffer
char g_sB[512];                     // generic catch all string buffer
char g_pN[128];                     // a dedicated buffer to storing a players name
int g_client;                       // g_QDB client id
int g_target;                       // g_QDB player (human or bot) id
int g_lastid;                       // g_QDB client's last known bot id
int g_onteam = 1;                   // g_QDB client's team
char g_model[64];                   // g_QDB client's model
char g_ghost[64];                   // g_QDB client model backup (for activation)
bool g_queued = false;              // g_QDB client's takeover state
float g_origin[3];                  // g_QDB client's origin vector
bool g_inspec = false;              // g_QDB check client's specator mode
char g_cisi[MAXPLAYERS + 1][64];    // g_QDB client Id to steam Id array
Handle g_AD;                        // Assistant Director Timer

bool g_IsVs = false;
bool g_IsCoop = true;
bool g_AssistedSpawning = false;
bool g_RemovedPlayers = false;
bool g_AddedPlayers = false;
bool g_ADFreeze = true;
int g_ADInterval;

ConVar g_cvLogLevel;
ConVar g_cvMinPlayers;
ConVar g_cvPrimaryWeapon;
ConVar g_cvSecondaryWeapon;
ConVar g_cvThrowable;
ConVar g_cvHealItem;
ConVar g_cvConsumable;
ConVar g_cvZoey;
ConVar g_cvExtraPlayers;
ConVar g_cvGameMode;
ConVar g_cvTankHealth;
ConVar g_cvDvarsHandle;
ConVar g_cvTankChunkHp;
ConVar g_cvSpawnInterval;
ConVar g_cvMaxSI;
ConVar g_cvAutoHard;
ConVar g_cvUnlockSI;
ConVar g_cvJoinMenu;
ConVar g_cvTeamLimit;
ConVar g_cvOfferTakeover;
ConVar g_cvStripKick;
ConVar g_cvAutoModel;

int g_LogLevel;
int g_MinPlayers;
char g_PrimaryWeapon[64];
char g_SecondaryWeapon[64];
char g_Throwable[64];
char g_HealItem[64];
char g_Consumable[64];
int g_Zoey;
int g_ExtraPlayers;
int g_TankChunkHp;
int g_SpawnInterval;
int g_MaxSI;
int g_AutoHard;
int g_UnlockSI;
int g_JoinMenu;
int g_TeamLimit;
int g_OfferTakeover;
int g_StripKick;
int g_AutoModel;

static char g_DvarsOriginStr[2048];  // will get lost to an sm plugins reload abm
static bool g_DvarsCheck;

public Plugin myinfo= {
    name = "ABM",
    author = "Victor \"NgBUCKWANGS\" Gonzalez",
    description = "A 5+ Player Enhancement Plugin for L4D2",
    version = PLUGIN_VERSION,
    url = "https://gitlab.com/vbgunz/ABM"
}

public OnPluginStart() {
    Echo(1, "OnPluginStart");

    g_GameData = LoadGameConfigFile("abm");
    if (g_GameData == null) {
        SetFailState("[ABM] Game data missing!");
    }

    HookEvent("player_first_spawn", OnSpawnHook);
    HookEvent("player_death", OnDeathHook, EventHookMode_Pre);
    HookEvent("player_disconnect", CleanQDBHook);
    HookEvent("player_afk", GoIdleHook);
    HookEvent("player_team", QTeamHook);
    HookEvent("player_bot_replace", QAfkHook);
    HookEvent("bot_player_replace", QBakHook);
    HookEvent("player_activate", PlayerActivateHook, EventHookMode_Pre);
    HookEvent("player_connect", PlayerActivateHook, EventHookMode_Pre);
    HookEvent("round_end", RoundFreezeEndHook, EventHookMode_Pre);
    HookEvent("mission_lost", RoundFreezeEndHook, EventHookMode_Pre);
    HookEvent("round_freeze_end", RoundFreezeEndHook, EventHookMode_Pre);
    HookEvent("map_transition", RoundFreezeEndHook, EventHookMode_Pre);
    HookEvent("round_start", RoundStartHook, EventHookMode_Pre);

    RegAdminCmd("abm", MainMenuCmd, ADMFLAG_GENERIC);
    RegAdminCmd("abm-menu", MainMenuCmd, ADMFLAG_GENERIC, "Menu: (Main ABM menu)");
    RegAdminCmd("abm-join", SwitchTeamCmd, ADMFLAG_GENERIC, "Menu/Cmd: <TEAM> | <ID> <TEAM>");
    RegAdminCmd("abm-takeover", SwitchToBotCmd, ADMFLAG_GENERIC, "Menu/Cmd: <ID> | <ID1> <ID2>");
    RegAdminCmd("abm-respawn", RespawnClientCmd, ADMFLAG_GENERIC, "Menu/Cmd: <ID> [ID]");
    RegAdminCmd("abm-model", AssignModelCmd, ADMFLAG_GENERIC, "Menu/Cmd: <MODEL> | <MODEL> <ID>");
    RegAdminCmd("abm-strip", StripClientCmd, ADMFLAG_GENERIC, "Menu/Cmd: <ID> [SLOT]");
    RegAdminCmd("abm-teleport", TeleportClientCmd, ADMFLAG_GENERIC, "Menu/Cmd: <ID1> <ID2>");
    RegAdminCmd("abm-cycle", CycleBotsCmd, ADMFLAG_GENERIC, "Menu/Cmd: <TEAM> | <ID> <TEAM>");
    RegAdminCmd("abm-reset", ResetCmd, ADMFLAG_GENERIC, "Cmd: (Use only in case of emergency)");
    RegAdminCmd("abm-info", QuickClientPrintCmd, ADMFLAG_GENERIC, "Cmd: (Print some diagnostic information)");
    RegAdminCmd("abm-mk", MkBotsCmd, ADMFLAG_GENERIC, "Cmd: <N|-N> <TEAM>");
    RegAdminCmd("abm-rm", RmBotsCmd, ADMFLAG_GENERIC, "Cmd: <TEAM> | <N|-N> <TEAM>");
    RegConsoleCmd("takeover", SwitchToBotCmd, "Menu/Cmd: <ID> | <ID1> <ID2>");
    RegConsoleCmd("join", SwitchTeamCmd, "Menu/Cmd: <TEAM> | <ID> <TEAM>");

    g_OS = GetOS();  // 0: Linux 1: Windows
    g_QDB = new StringMap();
    g_QRecord = new StringMap();
    g_Cvars = new StringMap();
    g_sQueue = new ArrayList(2);
    g_iQueue = new ArrayList(2);

    for (int i = 1; i <= MaxClients; i++) {
        g_menuStack[i] = new ArrayStack(128);
    }

    // Register everyone that we can find
    for (int i = 1; i <= MaxClients; i++) {
        if (!GetQRecord(i)) {
            if (SetQRecord(i) != -1) {
                g_cisi[i] = g_QKey;
            }
        }
    }

    g_cvGameMode = FindConVar("mp_gamemode");
    g_cvTankHealth = FindConVar("z_tank_health");
    g_cvDvarsHandle = FindConVar("l4d2_directoroptions_overwrite");

    CreateConVar("abm_version", PLUGIN_VERSION, "ABM plugin version", FCVAR_DONTRECORD);
    g_cvLogLevel = CreateConVar("abm_loglevel", "0", "Development logging level 0: Off, 4: Max");
    g_cvMinPlayers = CreateConVar("abm_minplayers", "4", "Pruning extra survivors stops at this size");
    g_cvPrimaryWeapon = CreateConVar("abm_primaryweapon", "shotgun_chrome", "5+ survivor primary weapon");
    g_cvSecondaryWeapon = CreateConVar("abm_secondaryweapon", "baseball_bat", "5+ survivor secondary weapon");
    g_cvThrowable = CreateConVar("abm_throwable", "", "5+ survivor throwable item");
    g_cvHealItem = CreateConVar("abm_healitem", "", "5+ survivor healing item");
    g_cvConsumable = CreateConVar("abm_consumable", "adrenaline", "5+ survivor consumable item");
    g_cvExtraPlayers = CreateConVar("abm_extraplayers", "0", "Extra survivors to start the round with");
    g_cvTankChunkHp = CreateConVar("abm_tankchunkhp", "2500", "Health chunk per survivor on 5+ missions");
    g_cvSpawnInterval = CreateConVar("abm_spawninterval", "36", "SI full team spawn in (5 x N)");
    g_cvAutoHard = CreateConVar("abm_autohard", "1", "0: Off 1: Non-Vs > 4 2: Non-Vs >= 1");
    g_cvUnlockSI = CreateConVar("abm_unlocksi", "0", "0: Off 1: Use Left 4 Downtown 2 2: Use VScript Director Options Unlocker");
    g_cvJoinMenu = CreateConVar("abm_joinmenu", "1", "0: Off 1: Admins only 2: Everyone");
    g_cvTeamLimit = CreateConVar("abm_teamlimit", "16", "Humans on team limit");
    g_cvOfferTakeover = CreateConVar("abm_offertakeover", "1", "0: Off 1: Survivors 2: Infected 3: All");
    g_cvStripKick = CreateConVar("abm_stripkick", "0", "0: Don't strip removed bots 1: Strip removed bots");
    g_cvAutoModel = CreateConVar("abm_automodel", "1", "1: Full set of survivors 0: Map set of survivors");

    g_cvMaxSI = FindConVar("z_max_player_zombies");
    SetConVarBounds(g_cvMaxSI, ConVarBound_Lower, true, 1.0);
    SetConVarBounds(g_cvMaxSI, ConVarBound_Upper, true, 24.0);

    char zoeyId[2];
    switch(g_OS) {
        case 0: Format(zoeyId, sizeof(zoeyId), "5");
        case 1: Format(zoeyId, sizeof(zoeyId), "1");
        default: PrintToChatAll("Zoey has gone Sarah Palin");
    }

    g_cvZoey = CreateConVar("abm_zoey", zoeyId, "0:Nick 1:Rochelle 2:Coach 3:Ellis 4:Bill 5:Zoey 6:Francis 7:Louis");

    HookConVarChange(g_cvLogLevel, UpdateConVarsHook);
    HookConVarChange(g_cvMinPlayers, UpdateConVarsHook);
    HookConVarChange(g_cvPrimaryWeapon, UpdateConVarsHook);
    HookConVarChange(g_cvSecondaryWeapon, UpdateConVarsHook);
    HookConVarChange(g_cvThrowable, UpdateConVarsHook);
    HookConVarChange(g_cvHealItem, UpdateConVarsHook);
    HookConVarChange(g_cvConsumable, UpdateConVarsHook);
    HookConVarChange(g_cvExtraPlayers, UpdateConVarsHook);
    HookConVarChange(g_cvTankChunkHp, UpdateConVarsHook);
    HookConVarChange(g_cvSpawnInterval, UpdateConVarsHook);
    HookConVarChange(g_cvZoey, UpdateConVarsHook);
    HookConVarChange(g_cvAutoHard, UpdateConVarsHook);
    HookConVarChange(g_cvUnlockSI, UpdateConVarsHook);
    HookConVarChange(g_cvJoinMenu, UpdateConVarsHook);
    HookConVarChange(g_cvTeamLimit, UpdateConVarsHook);
    HookConVarChange(g_cvOfferTakeover, UpdateConVarsHook);
    HookConVarChange(g_cvGameMode, UpdateConVarsHook);
    HookConVarChange(g_cvStripKick, UpdateConVarsHook);
    HookConVarChange(g_cvAutoModel, UpdateConVarsHook);

    UpdateConVarsHook(g_cvLogLevel, "0", "0");
    UpdateConVarsHook(g_cvMinPlayers, "4", "4");
    UpdateConVarsHook(g_cvPrimaryWeapon, "shotgun_chrome", "shotgun_chrome");
    UpdateConVarsHook(g_cvSecondaryWeapon, "baseball_bat", "baseball_bat");
    UpdateConVarsHook(g_cvThrowable, "", "");
    UpdateConVarsHook(g_cvHealItem, "", "");
    UpdateConVarsHook(g_cvConsumable, "adrenaline", "adrenaline");
    UpdateConVarsHook(g_cvExtraPlayers, "0", "0");
    UpdateConVarsHook(g_cvTankChunkHp, "2500", "2500");
    UpdateConVarsHook(g_cvSpawnInterval, "18", "18");
    UpdateConVarsHook(g_cvZoey, zoeyId, zoeyId);
    UpdateConVarsHook(g_cvAutoHard, "1", "1");
    UpdateConVarsHook(g_cvUnlockSI, "0", "0");
    UpdateConVarsHook(g_cvJoinMenu, "1", "1");
    UpdateConVarsHook(g_cvTeamLimit, "16", "16");
    UpdateConVarsHook(g_cvOfferTakeover, "1", "1");
    UpdateConVarsHook(g_cvStripKick, "0", "0");
    UpdateConVarsHook(g_cvAutoModel, "1", "1");

    AutoExecConfig(true, "abm");
    StartAD();
}

public OnEntityCreated(int ent, const char[] classname) {
    Echo(1, "OnEntityCreated: %d %s", ent, classname);

    if(classname[0] == 'f') {
        bool gClip = !StrEqual(classname, "func_playerghostinfected_clip", false);
        bool iClip = !StrEqual(classname, "func_playerinfected_clip", false);

        if (!(gClip && iClip)) {
            CreateTimer(1.0, KillEntTimer, EntIndexToEntRef(ent));
        }
    }
}

public Action KillEntTimer(Handle timer, any ref) {
    Echo(1, "KillEntTimer: %d", ref);

    int ent = EntRefToEntIndex(ref);
    if (ent != INVALID_ENT_REFERENCE || IsValidEntity(ent)) {
        AcceptEntityInput(ent, "kill");
    }

    return Plugin_Stop;
}

public Action L4D_OnGetScriptValueInt(const String:key[], &retVal) {
    Echo(4, "L4D_OnGetScriptValueInt: %s, %d", key, retVal);

    // see UpdateConVarsHook "g_UnlockSI" for VScript Director Options Unlocker

    if (g_UnlockSI == 1) {
        int val = retVal;

        if (StrEqual(key, "MaxSpecials")) val = g_MaxSI;
        else if (StrEqual(key, "BoomerLimit")) val = 4;
        else if (StrEqual(key, "SmokerLimit")) val = 4;
        else if (StrEqual(key, "HunterLimit")) val = 4;
        else if (StrEqual(key, "ChargerLimit")) val = 4;
        else if (StrEqual(key, "SpitterLimit")) val = 4;
        else if (StrEqual(key, "JockeyLimit")) val = 4;

        if (val != retVal) {
            retVal = val;
            return Plugin_Handled;
        }
    }

    return Plugin_Continue;
}

public RoundFreezeEndHook(Handle event, const char[] name, bool dontBroadcast) {
    Echo(1, "RoundFreezeEndHook: %s", name);

    if (g_ADFreeze) {
        return;
    }

    StopAD();
    StringMapSnapshot keys = g_QDB.Snapshot();
    g_iQueue.Clear();

    if (!g_IsVs) {
        for (int i; i < keys.Length; i++) {
            keys.GetKey(i, g_sB, sizeof(g_sB));
            g_QDB.GetValue(g_sB, g_QRecord);
            g_QRecord.GetValue("onteam", g_onteam);
            g_QRecord.GetValue("client", g_client);
            g_QRecord.GetString("model", g_model, sizeof(g_model));
            g_QRecord.SetString("ghost", g_model, true);

            if (g_onteam == 3) {
                SwitchToSpec(g_client);
                g_QRecord.SetValue("queued", true, true);
                g_QRecord.SetValue("inspec", false, true);
            }
        }
    }

    delete keys;
}

public PlayerActivateHook(Handle event, const char[] name, bool dontBroadcast) {
    Echo(1, "PlayerActivateHook: %s", name);

    int userid = GetEventInt(event, "userid");
    int client = GetClientOfUserId(userid);
    PlayerActivate(client);
}

PlayerActivate(int client) {
    Echo(1, "PlayerActivate: %d", client);

    if (GetQRecord(client)) {
        StartAD();
        AssignModel(client, g_ghost);

        if (!g_IsVs) {
            if (g_onteam == 3) {
                SwitchTeam(client, 3);
            }
        }
    }
}

public RoundStartHook(Handle event, const char[] name, bool dontBroadcast) {
    Echo(1, "RoundStartHook: %s", name);
    StartAD();

    for (int i = 1; i <= MaxClients; i++) {
        if (GetQRecord(i)) {
            if (!g_IsVs && g_onteam == 3) {
                SwitchTeam(i, 3);
            }
        }
    }
}

bool StopAD() {
    Echo(1, "StopAD");

    if (g_AD != null) {
        g_ADFreeze = true;
        g_AssistedSpawning = false;
        g_RemovedPlayers = false;
        g_AddedPlayers = false;
        g_ADInterval = 0;

        delete g_AD;
        g_AD = null;
    }

    return g_AD == null;
}

bool StartAD() {
    Echo(1, "StartAD");

    if (g_AD == null) {
        g_ADFreeze = true;
        g_AssistedSpawning = false;
        g_RemovedPlayers = false;
        g_AddedPlayers = false;
        g_ADInterval = 0;

        g_AD = CreateTimer(
            5.0, ADTimer, _, TIMER_REPEAT
        );
    }

    return g_AD != null;
}

public Action ADTimer(Handle timer) {
    Echo(3, "ADTimer");

    if (g_ADFreeze) {
        for (int i = 1; i <= MaxClients; i++) {
            if (IsClientConnected(i)) {
                if (!IsClientInGame(i)) {
                    Echo(1, " -- ADTimer: Client %d isn't loaded in yet.", i);
                    return Plugin_Continue;
                }

                else {
                    if (!g_IsVs) {
                        if (GetQRecord(i)) {
                            if (g_onteam == 3 && g_queued) {
                                SwitchTeam(i, 3);
                            }
                        }
                    }
                }
            }
        }

        Echo(1, " -- ADTimer: All clients are loaded in. Assisting.");
        g_ADFreeze = false;
    }

    if (!g_RemovedPlayers && CountTeamMates(2) >= 1) {
        RmBots((g_MinPlayers + g_ExtraPlayers) * -1, 2);
        g_RemovedPlayers = true;
    }

    if (g_RemovedPlayers) {
        if (!g_AddedPlayers && CountTeamMates(2) >= 1) {
            MkBots((g_MinPlayers + g_ExtraPlayers) * -1, 2);
            g_AddedPlayers = true;
        }
    }

    g_ADInterval++;
    int teamSize = CountTeamMates(2);

    if (teamSize == 0) {
        g_ADInterval = 0;
        return Plugin_Continue;
    }

    static lastSize;
    bool autoWave;

    if (g_IsCoop) {
        if (lastSize != teamSize) {
            lastSize = teamSize;
            AutoSetTankHp();
            RegulateSI();
        }
    }

    // Auto difficulty here will not spawn SI in competitive modes.
    // SI are unlocked (without spawn) see L4D_OnGetScriptValueInt.

    switch (g_IsVs) {
        case 1: autoWave = false;
        case 0: autoWave = g_AutoHard == 2 || teamSize > 4 && g_AutoHard == 1;
    }

    if (autoWave || g_AssistedSpawning) {
        if (g_SpawnInterval > 0) {
            if (g_ADInterval >= g_SpawnInterval) {
                if (g_ADInterval % g_SpawnInterval == 0) {
                    Echo(1, " -- Assisting SI %d: Matching Full Team", g_ADInterval);
                    MkBots(teamSize * -1, 3);
                }

                else if (g_ADInterval % (g_SpawnInterval / 2) == 0) {
                    Echo(1, " -- Assisting SI %d: Matching Half Team", g_ADInterval);
                    MkBots((teamSize / 2) * -1, 3);
                }
            }
        }
    }

    int onteam;
    float nTakeover = 0.1;
    g_AssistedSpawning = false;

    for (int i = 1; i <= MaxClients; i++) {
        if (GetQRecord(i)) {
            if (g_onteam == 3) {
                if (!g_IsVs) {
                    g_AssistedSpawning = true;

                    if (!IsPlayerAlive(i) && !g_queued && !g_inspec) {
                        g_QRecord.SetValue("queued", true, true);
                        QueueUp(i, 3);
                    }
                }

                continue;
            }

            onteam = GetClientTeam(i);
            if (onteam == 3) {
                continue;
            }

            if (!g_inspec && onteam <= 1) {
                CreateTimer(nTakeover, TakeoverTimer, i);
                nTakeover += 0.1;
            }
        }
    }

    return Plugin_Continue;
}

public UpdateConVarsHook(Handle convar, const char[] oldCv, const char[] newCv) {
    GetConVarName(convar, g_sB, sizeof(g_sB));
    Echo(1, "UpdateConVarsHook: %s %s %s", g_sB, oldCv, newCv);

    char name[32];
    char value[32];

    Format(name, sizeof(name), g_sB);
    Format(value, sizeof(value), "%s", newCv);
    TrimString(value);

    if (StrContains(newCv, "-l") == 0) {
        strcopy(value, sizeof(value), value[2]);
        TrimString(value);
        g_Cvars.SetString(name, value, true);
    }

    else if (StrContains(newCv, "-u") == 0) {
        strcopy(value, sizeof(value), value[2]);
        TrimString(value);
        g_Cvars.Remove(name);
    }

    g_Cvars.GetString(name, value, sizeof(value));
    if (!StrEqual(newCv, value)) {
        SetConVarString(convar, value);
        return;
    }

    else if (StrEqual(name, "abm_loglevel")) {
        g_LogLevel = GetConVarInt(g_cvLogLevel);
    }

    else if (StrEqual(name, "abm_extraplayers")) {
        g_ExtraPlayers = GetConVarInt(g_cvExtraPlayers);
    }

    else if (StrEqual(name, "abm_tankchunkhp")) {
        g_TankChunkHp = GetConVarInt(g_cvTankChunkHp);
        AutoSetTankHp();
    }

    else if (StrEqual(name, "abm_spawninterval")) {
        g_SpawnInterval = GetConVarInt(g_cvSpawnInterval);
    }

    else if (StrEqual(name, "abm_primaryweapon")) {
        GetConVarString(g_cvPrimaryWeapon, g_PrimaryWeapon, sizeof(g_PrimaryWeapon));
    }

    else if (StrEqual(name, "abm_secondaryweapon")) {
        GetConVarString(g_cvSecondaryWeapon, g_SecondaryWeapon, sizeof(g_SecondaryWeapon));
    }

    else if (StrEqual(name, "abm_throwable")) {
        GetConVarString(g_cvThrowable, g_Throwable, sizeof(g_Throwable));
    }

    else if (StrEqual(name, "abm_healitem")) {
        GetConVarString(g_cvHealItem, g_HealItem, sizeof(g_HealItem));
    }

    else if (StrEqual(name, "abm_consumable")) {
        GetConVarString(g_cvConsumable, g_Consumable, sizeof(g_Consumable));
    }

    else if (StrEqual(name, "abm_minplayers")) {
        g_MinPlayers = GetConVarInt(g_cvMinPlayers);
    }

    else if (StrEqual(name, "abm_autohard")) {
        g_AutoHard = GetConVarInt(g_cvAutoHard);
        AutoSetTankHp();
    }

    else if (StrEqual(name, "abm_unlocksi")) {
        g_UnlockSI = GetConVarInt(g_cvUnlockSI);
        RegulateSI();
    }

    else if (StrEqual(name, "abm_joinmenu")) {
        g_JoinMenu = GetConVarInt(g_cvJoinMenu);
    }

    else if (StrEqual(name, "abm_teamlimit")) {
        g_TeamLimit = GetConVarInt(g_cvTeamLimit);
    }

    else if (StrEqual(name, "abm_offertakeover")) {
        g_OfferTakeover = GetConVarInt(g_cvOfferTakeover);
    }

    else if (StrEqual(name, "mp_gamemode")) {
        g_IsVs = (StrEqual(newCv, "versus") || StrEqual(newCv, "scavenge"));
        g_IsCoop = StrEqual(newCv, "coop");  // forgot about survival, etc
    }

    else if (StrEqual(name, "abm_zoey")) {
        g_Zoey = GetConVarInt(g_cvZoey);
    }

    else if (StrEqual(name, "abm_stripkick")) {
        g_StripKick = GetConVarInt(g_cvStripKick);
    }

    else if (StrEqual(name, "abm_automodel")) {
        g_AutoModel = GetConVarInt(g_cvAutoModel);
    }
}

void RegulateSI() {
    Echo(1, "RegulateSI");

    static lastSISize;

    if (g_DvarsCheck && g_cvDvarsHandle != null) {
        if (g_UnlockSI == 2 && g_MaxSI > 4) {
            Format(g_sB, sizeof(g_sB), "MaxSpecials=%d;DominatorLimit=%d", g_MaxSI, g_MaxSI);
            SetConVarString(g_cvDvarsHandle, g_sB);

            if (lastSISize != g_MaxSI) {
                lastSISize = g_MaxSI;
            }
        }

        else {
            RestoreDvars();
            lastSISize = 0;
        }
    }
}

void RestoreDvars() {
    Echo(1, "RestoreDvars");

    if (g_DvarsCheck && g_cvDvarsHandle != null) {
        SetConVarString(g_cvDvarsHandle, g_DvarsOriginStr);
    }
}

AutoSetTankHp() {
    Echo(1, "AutoSetTankHp");

    int tankHp;
    int teamSize = CountTeamMates(2);

    if (teamSize > 4 || g_AutoHard == 2) {
        tankHp = teamSize * g_TankChunkHp;
    }

    if (g_AutoHard == 0 || tankHp == 0) {
        GetConVarDefault(g_cvTankHealth, g_sB, sizeof(g_sB));
        tankHp = StringToInt(g_sB);
    }

    SetConVarInt(g_cvTankHealth, tankHp);
}

public OnConfigsExecuted() {
    Echo(1, "OnConfigsExecuted");

    PrecacheModels();

    if (!g_DvarsCheck) {
        g_DvarsCheck = true;

        if (g_cvDvarsHandle != null) {
            GetConVarString(g_cvDvarsHandle, g_DvarsOriginStr, sizeof(g_DvarsOriginStr));
            RegulateSI();
        }
    }
}

public OnClientPostAdminCheck(int client) {
    Echo(1, "OnClientPostAdminCheck: %d", client);

    if (!GetQRecord(client)) {
        if (SetQRecord(client) >= 0) {
            g_cisi[client] = g_QKey;
            Echo(0, "AUTH ID: %s, ADDED TO QDB.", g_QKey);

            if (g_JoinMenu == 2 || g_JoinMenu == 1 && IsAdmin(client)) {
                GoIdle(client, 1);
                menuArg0 = client;
                SwitchTeamHandler(client, 1);
            }

            else if (CountTeamMates(2) >= 1) {
                CreateTimer(0.1, TakeoverTimer, client);
            }
        }
    }
}

public GoIdleHook(Handle event, const char[] name, bool dontBroadcast) {
    Echo(1, "GoIdleHook: %s", name);
    int player = GetEventInt(event, "player");
    int client = GetClientOfUserId(player);

    if (GetQRecord(client)) {
        switch (g_onteam) {
            case 2: GoIdle(client);
            case 3: SwitchTeam(client, 3);
        }
    }
}

GoIdle(int client, onteam=0) {
    Echo(1, "GoIdle: %d %d", client, onteam);

    if (GetQRecord(client)) {

        int spec_target;

        if (g_onteam == 2) {
            SwitchToSpec(client);
            SetHumanSpecSig(g_target, client);

            if (onteam == 1) {
                SwitchToSpec(client);
                Unqueue(client);
            }

            AssignModel(g_target, g_model);
        }

        else {
            SwitchToSpec(client);
        }

        switch (IsClientValid(g_target) && IsFakeClient(g_target)) {
            case 1: spec_target = g_target;
            case 0: spec_target = GetSafeSurvivor(client);
        }

        if (IsClientValid(spec_target)) {
            SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", spec_target);
            SetEntProp(client, Prop_Send, "m_iObserverMode", 5);
        }
    }
}

public CleanQDBHook(Handle event, const char[] name, bool dontBroadcast) {
    Echo(1, "CleanQDBHook: %s", name);

    int userid = GetEventInt(event, "userid");
    int client = GetClientOfUserId(userid);
    RemoveQDBKey(client);
}

RemoveQDBKey(int client) {
    Echo(1, "RemoveQDBKey: %d", client);

    // during map change, GetQRecord is not reliable :'(
    Format(g_sB, sizeof(g_sB), "%s", g_cisi[client]);

    if (g_QDB.Remove(g_sB)) {
        g_cisi[client] = "";
        Echo(0, "AUTH ID: %s, REMOVED FROM QDB.", g_sB);

        int survivors = CountTeamMates(2);
        if (survivors > (g_MinPlayers + g_ExtraPlayers)) {
            CreateTimer(1.0, RmBotsTimer, 1);
        }
    }
}

public Action RmBotsTimer(Handle timer, any asmany) {
    Echo(3, "RmBotsTimer: %d", asmany);

    if (!g_IsVs) {
        RmBots(asmany, 2);
    }
}

bool IsAdmin(int client) {
    Echo(1, "IsAdmin: %d", client);
    return CheckCommandAccess(
        client, "generic_admin", ADMFLAG_GENERIC, false
    );
}

bool IsClientValid(int client) {
    Echo(3, "IsClientValid: %d", client);

    if (client >= 1 && client <= MaxClients) {
        if (IsClientConnected(client)) {
            if (IsClientInGame(client)) {
                return true;
            }
        }
    }

    return false;
}

bool CanClientTarget(int client, int target) {
    Echo(1, "CanClientTarget: %d %d", client, target);

    if (client == target) {
        return true;
    }

    else if (!IsClientValid(client) || !IsClientValid(target)) {
        return false;
    }

    else if (IsFakeClient(target)) {
        int manager = GetClientManager(target);

        if (manager != -1) {
            if (manager == 0) {
                return true;
            }

            else {
                return CanClientTarget(client, manager);
            }
        }
    }

    return CanUserTarget(client, target);
}

int GetPlayClient(int client) {
    Echo(2, "GetPlayClient: %d", client);

    if (GetQRecord(client)) {
        return g_target;
    }

    else if (IsClientValid(client)) {
        return client;
    }

    return -1;
}

int ClientHomeTeam(int client) {
    Echo(1, "ClientHomeTeam: %d", client);

    if (GetQRecord(client)) {
        return g_onteam;
    }

    else if (IsClientValid(client)) {
        return GetClientTeam(client);
    }

    return -1;
}

// ================================================================== //
// g_QDB MANAGEMENT
// ================================================================== //

bool SetQKey(int client) {
    Echo(2, "SetQKey: %d", client);

    if (IsClientValid(client) && !IsFakeClient(client)) {
        if (GetClientAuthId(client, AuthId_Steam2, g_QKey, sizeof(g_QKey), true)) {
            return true;
        }
    }

    return false;
}

bool GetQRecord(int client) {
    Echo(2, "GetQRecord: %d", client);

    if (SetQKey(client)) {
        if (g_QDB.GetValue(g_QKey, g_QRecord)) {

            if (IsClientValid(client) && IsPlayerAlive(client)) {
                GetClientAbsOrigin(client, g_origin);
                g_QRecord.SetArray("origin", g_origin, sizeof(g_origin), true);
            }

            g_QRecord.GetValue("client", g_client);
            g_QRecord.GetValue("target", g_target);
            g_QRecord.GetValue("lastid", g_lastid);
            g_QRecord.GetValue("onteam", g_onteam);
            g_QRecord.GetValue("queued", g_queued);
            g_QRecord.GetValue("inspec", g_inspec);

            if (GetClientTeam(client) == 2) {
                int i = GetClientModelIndex(client);
                if (i >= 0) {
                    Format(g_model, sizeof(g_model), "%s", g_SurvivorNames[i]);
                    g_QRecord.SetString("model", g_model, true);
                }
            }

            g_QRecord.GetString("model", g_model, sizeof(g_model));
            g_QRecord.GetString("ghost", g_ghost, sizeof(g_ghost));
            return true;
        }
    }

    return false;
}

bool NewQRecord(int client) {
    Echo(2, "NewQRecord: %d", client);

    g_QRecord = new StringMap();

    GetClientAbsOrigin(client, g_origin);
    g_QRecord.SetArray("origin", g_origin, sizeof(g_origin), true);
    g_QRecord.SetValue("client", client, true);
    g_QRecord.SetValue("target", client, true);
    g_QRecord.SetValue("lastid", client, true);
    g_QRecord.SetValue("onteam", GetClientTeam(client), true);
    g_QRecord.SetValue("queued", false, true);
    g_QRecord.SetValue("inspec", false, true);
    g_QRecord.SetString("model", "", true);
    g_QRecord.SetString("ghost", "", true);
    return true;
}

int SetQRecord(int client) {
    Echo(2, "SetQRecord: %d", client);

    int result = -1;

    if (SetQKey(client)) {
        if (g_QDB.GetValue(g_QKey, g_QRecord)) {
            result = 0;
        }

        else if (NewQRecord(client)) {
            g_QDB.SetValue(g_QKey, g_QRecord, true);
            result = 1;
        }

        GetQRecord(client);
    }

    return result;
}

QueueUp(int client, int onteam) {
    Echo(1, "QueueUp: %d %d", client, onteam);

    if (onteam >= 2 && GetQRecord(client)) {
        Unqueue(client);

        switch (onteam) {
            case 2: g_sQueue.Push(client);
            case 3: g_iQueue.Push(client);
        }

        g_QRecord.SetValue("queued", true, true);
    }
}

Unqueue(int client) {
    Echo(1, "Unqueue: %d", client);

    if (GetQRecord(client)) {
        g_QRecord.SetValue("queued", false, true);

        int iLength = g_iQueue.Length;
        int sLength = g_sQueue.Length;

        if (iLength > 0) {
            for (int i = iLength - 1; i > -1; i--) {
                if (g_iQueue.Get(i) == client) {
                    g_iQueue.Erase(i);
                }
            }
        }

        if (sLength > 0) {
            for (int i = sLength - 1; i > -1; i--) {
                if (g_sQueue.Get(i) == client) {
                    g_sQueue.Erase(i);
                }
            }
        }
    }
}

public OnSpawnHook(Handle event, const char[] name, bool dontBroadcast) {
    Echo(1, "OnSpawnHook: %s", name);

    int userid = GetEventInt(event, "userid");
    int target = GetClientOfUserId(userid);
    GetClientName(target, g_pN, sizeof(g_pN));

    int flag1 = StrContains(g_pN, "SPECIAL");
    int flag2 = StrContains(g_pN, "SURVIVOR");
    if (flag1 >= 0 || flag2 >= 0) {
        return;
    }

    int client;
    int onteam = GetClientTeam(target);

    if (onteam == 3) {

        // set glows for troubleshooting SI
        //int iGlowColour = 4278124800;
        //SetEntProp(target, Prop_Send, "m_iGlowType", 3);
        //SetEntProp(target, Prop_Send, "m_glowColorOverride", iGlowColour);

        if (!g_IsVs) {
            if (g_AssistedSpawning) {
                int zClass = GetEntProp(target, Prop_Send, "m_zombieClass");
                if (zClass == 8) {

                    int j = 1;
                    static i = 1;

                    for (; i <= MaxClients + 1; i++) {
                        if (j++ == MaxClients + 1) {  // join 3 Tank requires +1
                            return;
                        }

                        if (i > MaxClients) {
                            i = 1;
                        }

                        if (GetQRecord(i) && g_onteam == 3 && !g_inspec) {
                            if (GetEntProp(i, Prop_Send, "m_zombieClass") != 8) {
                                client = i;
                                i++;
                                break;
                            }
                        }
                    }

                    switch (IsClientValid(client)) {
                        case 1: SwitchToBot(client, target);
                        case 0: CreateTimer(1.0, TankAssistTimer, target, TIMER_REPEAT);
                    }
                }
            }

            if (g_iQueue.Length > 0) {
                SwitchToBot(g_iQueue.Get(0), target);
                return;
            }
        }
    }

    if (onteam == 2) {
        if (g_AutoModel == 1) {
            CreateTimer(0.2, AutoModelTimer, target);
        }

        CreateTimer(0.4, OnSpawnHookTimer, target);
    }
}

public Action TankAssistTimer(Handle timer, any client) {
    Echo(3, "TankAssistTimer: %d", client);

    /*
    * Human players on the infected team in modes that do not officially
    * support them, can get Tanks stuck in "stasis" until they die. This
    * function works around the issue by watching Tanks for movement. If
    * a Tank does not move in 11 seconds, it is replaced with another.
    */

    float origin[3];
    static const float nullOrigin[3];
    static times[MAXPLAYERS + 1] = {11, ...};
    static float origins[MAXPLAYERS + 1][3];
    static i;

    if (IsClientValid(client)) {
        i = times[client]--;

        if (i == 11) {
            GetClientAbsOrigin(client, origins[client]);
            return Plugin_Continue;
        }

        else if (i >= 0) {
            GetClientAbsOrigin(client, origin);

            if (origin[0] == origins[client][0]) {
                if (i == 0) {
                    TeleportEntity(client, nullOrigin, NULL_VECTOR, NULL_VECTOR);
                    ForcePlayerSuicide(client);
                    AddInfected("tank");
                }

                return Plugin_Continue;
            }
        }
    }

    i = times[client] = 11;
    return Plugin_Stop;
}

public Action ForceSpawnTimer(Handle timer, any client) {
    Echo(3, "ForceSpawnTimer: %d", client);

    static times[MAXPLAYERS + 1] = {20, ...};
    static i;

    if (IsClientValid(client)) {
        i = times[client]--;

        if (GetEntProp(client, Prop_Send, "m_zombieClass") != 8) {
            return Plugin_Stop;
        }

        if (GetEntProp(client, Prop_Send, "m_isGhost") == 1) {
            if (i >= 1) {
                PrintHintText(client, "FORCING SPAWN IN: %d", i);
                return Plugin_Continue;
            }

            if (GetEntProp(client, Prop_Send, "m_ghostSpawnState") <= 2) {
                SetEntProp(client, Prop_Send, "m_isGhost", 0);
            }

            return Plugin_Continue;
        }

        if (GetClientTeam(client) == 3) {
            PrintHintText(client, "KILL ALL HUMANS");
        }
    }

    i = times[client] = 20;
    return Plugin_Stop;
}
public Action OnSpawnHookTimer(Handle timer, any target) {
    Echo(1, "OnSpawnHookTimer: %d", target);

    if (g_sQueue.Length > 0) {
        SwitchToBot(g_sQueue.Get(0), target);
        return;
    }
}

public OnDeathHook(Handle event, const char[] name, bool dontBroadcast) {
    Echo(3, "OnDeathHook: %s", name);

    int userid = GetEventInt(event, "userid");
    int client = GetClientOfUserId(userid);

    if (GetQRecord(client)) {
        GetClientAbsOrigin(client, g_origin);
        g_QRecord.SetValue("target", client, true);
        g_QRecord.SetArray("origin", g_origin, sizeof(g_origin), true);
        bool offerTakeover;

        switch (g_onteam) {
            case 3: {
                if (!g_IsVs) {
                    switch (g_OfferTakeover) {
                        case 2, 3: {
                            QueueUp(client, 3);
                            GoIdle(client, 1);
                            offerTakeover = true;
                        }

                        default: SwitchTeam(client, 3);
                    }
                }
            }

            case 2: {
                switch (g_OfferTakeover) {
                    case 1, 3: offerTakeover = true;
                }
            }
        }

        if (offerTakeover) {
            GenericMenuCleaner(client);
            menuArg0 = client;
            SwitchToBotHandler(client, 1);
        }
    }
}

public QTeamHook(Handle event, const char[] name, bool dontBroadcast) {
    Echo(1, "QTeamHook: %s", name);

    int userid = GetEventInt(event, "userid");
    int client = GetClientOfUserId(userid);
    int onteam = GetEventInt(event, "team");

    if (GetQRecord(client)) {
        if (onteam >= 2) {
            g_QRecord.SetValue("inspec", false, true);
            g_QRecord.SetValue("target", client, true);
            g_QRecord.SetValue("onteam", onteam, true);
            g_QRecord.SetValue("queued", false, true);

            if (onteam == 3) {
                g_QRecord.SetString("model", "", true);
                return;
            }
        }

        if (onteam <= 1) { // cycling requires 0.2 or higher?
            CreateTimer(0.2, QTeamHookTimer, client);
        }
    }
}

public Action QTeamHookTimer(Handle timer, any client) {
    Echo(1, "QTeamHookTimer: %d", client);

    if (GetQRecord(client) && !g_inspec) {
        if (g_onteam == 2) {
            if (IsClientValid(g_target) && g_target != client) {
                SetHumanSpecSig(g_target, client);
            }
        }
    }
}

public QAfkHook(Handle event, const char[] name, bool dontBroadcast) {
    Echo(1, "QAfkHook: %s", name);

    int client = GetClientOfUserId(GetEventInt(event, "player"));
    int target = GetClientOfUserId(GetEventInt(event, "bot"));
    int clientTeam = GetClientTeam(client);
    int targetTeam = GetClientTeam(target);

    if (GetQRecord(client)) {
        int onteam = GetClientTeam(client);

        if (onteam == 2) {
            g_QRecord.SetValue("target", target, true);
            AssignModel(target, g_model);
        }
    }

    if (targetTeam == 2 && IsClientValid(client)) {
        if (IsClientInKickQueue(client)) {
            if (client && target && clientTeam == targetTeam) {
                int safeClient = GetSafeSurvivor(target);
                RespawnClient(target, safeClient);
            }
        }
    }
}

public QBakHook(Handle event, const char[] name, bool dontBroadcast) {
    Echo(1, "QBakHook: %s", name);

    int client = GetClientOfUserId(GetEventInt(event, "player"));
    int target = GetClientOfUserId(GetEventInt(event, "bot"));

    if (GetQRecord(client)) {
        if (g_target != target) {
            g_QRecord.SetValue("lastid", target);
            g_QRecord.SetValue("target", client);

            GetClientName(target, g_pN, sizeof(g_pN));
            int i = GetModelIndexByName(g_pN);

            if (i != -1) {
                Format(g_model, sizeof(g_model), "%s", g_SurvivorNames[i]);
                g_QRecord.SetString("model", g_model, true);
            }
        }

        if (GetClientTeam(client) == 2) {
            AssignModel(client, g_model);
        }
    }
}

// ================================================================== //
// UNORGANIZED AS OF YET
// ================================================================== //

StripClient(int client) {
    Echo(1, "StripClient: %d", client);

    if (IsClientValid(client)) {
        if (GetClientTeam(client) == 2) {
            for (int i = 4; i >= 0; i--) {
                StripClientSlot(client, i);
            }
        }
    }
}

StripClientSlot(int client, int slot) {
    Echo(1, "StripClientSlot: %d %d", client, slot);

    client = GetPlayClient(client);

    if (IsClientValid(client)) {
        if (GetClientTeam(client) == 2) {
            int ent = GetPlayerWeaponSlot(client, slot);
            if (IsValidEntity(ent)) {
                RemovePlayerItem(client, ent);
                RemoveEdict(ent);
            }
        }
    }
}

RespawnClient(int client, int target=0) {
    Echo(1, "RespawnClient: %d %d", client, target);

    if (!IsClientValid(client)) {
        return;
    }

    else if (GetQRecord(client)) {
        if (g_onteam == 3) {
            Takeover(client, 3);
            return;
        }
    }

    float origin[3];
    client = GetPlayClient(client);
    target = GetPlayClient(target);

    if (!IsClientValid(target)) {
        target = client;
    }

    RoundRespawnSig(client);
    GetClientAbsOrigin(target, origin);
    QuickCheat(client, "give", g_PrimaryWeapon);
    QuickCheat(client, "give", g_SecondaryWeapon);
    QuickCheat(client, "give", g_Throwable);
    QuickCheat(client, "give", g_HealItem);
    QuickCheat(client, "give", g_Consumable);
    TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
}

TeleportClient(int client, int target) {
    Echo(1, "TeleportClient: %d %d", client, target);

    float origin[3];
    client = GetPlayClient(client);
    target = GetPlayClient(target);

    if (IsClientValid(client) && IsClientValid(target)) {
        GetClientAbsOrigin(target, origin);
        TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
    }
}

int GetSafeSurvivor(int client) {
    Echo(1, "GetSafeSurvivor: %d", client);

    int last_survivor;

    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientValid(i) && i != client) {
            if (IsPlayerAlive(i) && GetClientTeam(i) == 2) {
                last_survivor = i;

                if (GetEntProp(i, Prop_Send, "m_isHangingFromLedge") == 0) {
                    return i;
                }
            }
        }
    }

    return last_survivor;
}

bool AddSurvivor() {
    Echo(1, "AddSurvivor");

    bool result = false;
    int survivor = CreateFakeClient("SURVIVOR");

    if (IsClientValid(survivor)) {
        if (DispatchKeyValue(survivor, "classname", "SurvivorBot")) {
            ChangeClientTeam(survivor, 2);

            if (DispatchSpawn(survivor)) {
                KickClient(survivor);
                result = true;
            }
        }
    }

    return result;
}

GhostsModeProtector(int state) {
    Echo(1, "GhostsModeProtector: %d", state);
    // CAREFUL: 0 starts this function and you must close it with 1 or
    // risk breaking things. Close this with 1 immediately when done.

    // e.g.,
    // GhostsModeProtector(0);
    // z_spawn_old tank auto;
    // GhostsModeProtector(1);

    if (CountTeamMates(3, 1) == 0) {
        return;
    }

    static ghosts[MAXPLAYERS + 1];

    switch (state) {
        case 0: {
            for (int i = 1; i <= MaxClients; i++) {
                if (GetQRecord(i) && g_onteam == 3) {
                    if (GetEntProp(i, Prop_Send, "m_isGhost") == 1) {
                        SetEntProp(i, Prop_Send, "m_isGhost", 0);
                        ghosts[i] = 1;
                    }
                }
            }
        }

        case 1: {
            for (int i = 1; i <= MaxClients; i++) {
                if (ghosts[i] == 1) {
                    SetEntProp(i, Prop_Send, "m_isGhost", 1);
                    ghosts[i] = 0;
                }
            }
        }
    }
}

void CleanSIName(char model[32]) {
    Echo(1, "CleanSIName: %s", model);

    int i;
    static char tmpModel[32];

    if (model[0] != EOS) {
        for (i = 0; i < sizeof(g_InfectedNames); i++) {
            tmpModel = g_InfectedNames[i];
            if (StrContains(tmpModel, model, false) == 0) {
                model = tmpModel;
                return;
            }
        }

        if (StrContains("Tank", model, false) == 0) {
            model = "Tank";
            return;
        }
    }

    i = GetRandomInt(0, sizeof(g_InfectedNames) - 1);
    model = g_InfectedNames[i];
}

bool AddInfected(char model[32]="") {
    Echo(1, "AddInfected: %d", model);

    bool result;
    CleanSIName(model);

    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientValid(i)) {
            GhostsModeProtector(0);
            Format(g_sB, sizeof(g_sB), "%s auto area", model);
            QuickCheat(i, "z_spawn_old", g_sB);
            GhostsModeProtector(1);
            result = true;
            break;
        }
    }

    return result;
}

SwitchToSpec(int client, int onteam=1) {
    Echo(1, "SwitchToSpectator: %d %d", client, onteam);

    if (GetQRecord(client)) {
        g_QRecord.SetValue("inspec", true, true);
        ChangeClientTeam(client, onteam);

        if (client != g_target) {
            SetEntProp(g_target, Prop_Send, "m_humanSpectatorUserID", 0);
        }
    }
}

QuickCheat(int client, char [] cmd, char [] arg) {
    Echo(1, "QuickCheat: %d %s %s", client, cmd, arg);

    int flags = GetCommandFlags(cmd);
    SetCommandFlags(cmd, flags & ~FCVAR_CHEAT);
    FakeClientCommand(client, "%s %s", cmd, arg);
    SetCommandFlags(cmd, flags);
}

SwitchToBot(int client, int bot, bool si_ghost=true) {
    Echo(1, "SwitchToBot: %d %d %d", client, bot, si_ghost);

    if (client != bot && IsClientValid(bot)) {
        switch (GetClientTeam(bot)) {
            case 2: TakeoverBotSig(client, bot);
            case 3: TakeoverZombieBotSig(client, bot, si_ghost);
        }
    }
}

Takeover(int client, int onteam) {
    Echo(1, "Takeover: %d %d", client, onteam);

    if (GetQRecord(client)) {
        if (IsClientValid(g_target) && IsFakeClient(g_target)) {
            if (client != g_target && GetClientTeam(g_target) == onteam) {
                SwitchToBot(client, g_target);
                return;
            }
        }

        g_QRecord.SetValue("target", client, true);
        g_QRecord.SetValue("inspec", false, true);
        g_QRecord.SetValue("onteam", onteam, true);
        g_QRecord.SetValue("queued", true, true);

        int nextBot;
        nextBot = GetNextBot(onteam);

        if (nextBot >= 1) {
            SwitchToBot(client, nextBot);
            return;
        }

        switch (onteam) {
            case 2: {
                QueueUp(client, 2);
                AddSurvivor();
            }

            case 3: {
                QueueUp(client, 3);
                AddInfected();
            }
        }
    }
}

public Action TakeoverTimer(Handle timer, any client) {
    Echo(3, "TakeoverTimer: %d", client);

    if (CountTeamMates(2) <= 0) {
        return Plugin_Handled;
    }

    static team2;
    static team3;
    static teamX;

    if (GetQRecord(client)) {
        if (GetClientTeam(client) >= 2) {
            return Plugin_Handled;
        }

        teamX = 2;
        if (g_onteam == 3) {
            teamX = 3;
        }

        if (g_IsVs && g_onteam <= 1) {
            team2 = CountTeamMates(2, 1);
            team3 = CountTeamMates(3, 1);

            if (team3 < team2) {
                teamX = 3;
            }
        }

        if (CountTeamMates(teamX, 1) < g_TeamLimit) {
            Takeover(client, teamX);
        }
    }

    return Plugin_Handled;
}


int CountTeamMates(int onteam, int mtype=2) {
    Echo(1, "CountTeamMates: %d %d", onteam, mtype);

    // mtype 0: counts only bots
    // mtype 1: counts only humans
    // mtype 2: counts all players on team

    if (g_ADFreeze) {
        return 0;
    }

    int result;

    if (mtype == 2) {
        static lastSize;
        result = GetTeamClientCount(onteam);

        if (result > 0 && onteam == 2) {
            g_MaxSI = result;

            if (g_MaxSI != lastSize) {
                SetConVarFloat(g_cvMaxSI, float(result));
                lastSize = g_MaxSI;
            }
        }

        return result;
    }

    int j;
    int humans;
    int bots;

    for (int i = 1; i <= MaxClients; i++) {
        j = GetClientManager(i);

        if (j >= 0 && GetClientTeam(i) == onteam) {
            switch (j) {
                case 0: bots++;
                default: humans++;
            }
        }
    }

    switch (mtype) {
        case 0: result = bots;
        case 1: result = humans;
    }

    return result;
}

int GetClientManager(int target) {
    Echo(3, "GetClientManager: %d", target);

    int result;
    int userid;
    int client;

    if (GetQRecord(target)) {
        return target;
    }

    else if (IsClientValid(target)) {
        for (int i = 1; i <= MaxClients; i++) {
            if (IsClientValid(i) && IsFakeClient(i) && GetClientTeam(i) == 2) {

                // let's really put a stop to the "idling 2 bots at once" problem
                userid = GetEntData(i, FindSendPropInfo("SurvivorBot", "m_humanSpectatorUserID"));
                client = GetClientOfUserId(userid);

                if (GetQRecord(client) && i != g_target) {
                    if (HasEntProp(i, Prop_Send, "m_humanSpectatorUserID")) {
                        SetEntProp(i, Prop_Send, "m_humanSpectatorUserID", 0);
                    }
                }
            }
        }

        for (int i = 1; i <= MaxClients; i++) {
            if (GetQRecord(i)) {
                if (IsClientValid(g_target) && g_target == target) {
                    result = i;
                    break;
                }
            }
        }
    }

    else {
        result = -1;  // this target is NOT valid
    }

    return result;  // target IS valid and NOT managed
}

int GetNextBot(int onteam, int skipIndex=0, alive=false) {
    Echo(1, "GetNextBot: %d %d", onteam, skipIndex);

    int bot;

    for (int i = 1; i <= MaxClients; i++) {
        if (GetClientManager(i) == 0) {
            if (GetClientTeam(i) == onteam) {
                if (bot == 0) {
                    if (!alive || alive && IsPlayerAlive(i)) {
                        bot = i;
                    }
                }

                if (i > skipIndex) {
                    if (!alive || alive && IsPlayerAlive(i)) {
                        bot = i;
                        break;
                    }
                }
            }
        }
    }

    return bot;
}

CycleBots(int client, int onteam) {
    Echo(1, "CycleBots: %d %d", client, onteam);

    if (onteam <= 1) {
        return;
    }

    if (GetQRecord(client)) {
        int bot = GetNextBot(onteam, g_lastid, true);
        if (GetClientManager(bot) == 0) {
            SwitchToBot(client, bot, false);
        }
    }
}

SwitchTeam(int client, int onteam, char model[32]="") {
    Echo(1, "SwitchTeam: %d %d", client, onteam);

    if (GetQRecord(client)) {
        if (GetClientTeam(client) >= 2) {
            if (onteam == 2 && onteam == g_onteam) {
                return;  // keep survivors from rejoining survivors
            }
        }
        switch (onteam) {
            case 0: GoIdle(client, 0);
            case 1: GoIdle(client, 1);
            //case 4: ChangeClientTeam(client, 4);
            default: {
                if (onteam <= 3 && onteam >= 2) {
                    if (g_onteam != onteam) {
                        GoIdle(client, 1);
                    }

                    g_QRecord.SetValue("queued", true, true);
                    g_QRecord.SetValue("onteam", onteam, true);

                    if (onteam == 3) {

                        if (g_IsVs) {
                            ChangeClientTeam(client, 3);
                            return;
                        }

                        switch (g_model[0] == EOS && model[0] != EOS) {
                            case 1: CleanSIName(model);
                            case 0: {
                                Format(model, sizeof(model), "%s", g_model);
                                CleanSIName(model);
                            }
                        }

                        g_QRecord.SetString("model", model, true);
                        QueueUp(client, 3);
                        AddInfected(model);
                        return;
                    }

                    Takeover(client, onteam);
                }
            }
        }
    }
}

public Action MkBotsCmd(int client, args) {
    Echo(1, "MkBotsCmd: %d", client);

    switch(args) {
        case 2: {
            GetCmdArg(1, g_sB, sizeof(g_sB));
            int asmany = StringToInt(g_sB);
            GetCmdArg(2, g_sB, sizeof(g_sB));
            int onteam = StringToInt(g_sB);

            if (onteam >= 2 || onteam <= 3) {
                MkBots(asmany, onteam);
            }
        }
    }
}

MkBots(int asmany, int onteam) {
    Echo(1, "MkBots: %d %d", asmany, onteam);

    if (asmany < 0) {
        asmany = asmany * -1 - CountTeamMates(onteam);
    }

    float rate;
    DataPack pack = new DataPack();

    switch (onteam) {
        case 2: rate = 0.2;
        case 3: rate = 0.4;
    }

    CreateDataTimer(rate, MkBotsTimer, pack, TIMER_REPEAT);
    pack.WriteCell(asmany);
    pack.WriteCell(onteam);
}

public Action MkBotsTimer(Handle timer, Handle pack) {
    Echo(1, "MkBotsTimer");

    static i;

    ResetPack(pack);
    int asmany = ReadPackCell(pack);
    int onteam = ReadPackCell(pack);

    if (i++ < asmany) {
        switch (onteam) {
            case 2: AddSurvivor();
            case 3: AddInfected();
        }

        return Plugin_Continue;
    }

    i = 0;
    return Plugin_Stop;
}

public Action RmBotsCmd(int client, args) {
    Echo(1, "RmBotsCmd: %d", client);

    int asmany;
    int onteam;

    switch(args) {
        case 1: {
            GetCmdArg(1, g_sB, sizeof(g_sB));
            onteam = StringToInt(g_sB);
            asmany = MaxClients;
        }

        case 2: {
            GetCmdArg(1, g_sB, sizeof(g_sB));
            asmany = StringToInt(g_sB);
            GetCmdArg(2, g_sB, sizeof(g_sB));
            onteam = StringToInt(g_sB);
        }
    }

    if (onteam >= 2 || onteam <= 3) {
        RmBots(asmany, onteam);
    }
}

RmBots(int asmany, int onteam) {
    Echo(1, "RmBots: %d %d", asmany, onteam);

    int j;

    if (onteam == 0) {
        onteam = asmany;
        asmany = MaxClients;
    }

    else if (asmany == -0) {
        return;
    }

    else if (asmany < 0) {
        asmany += CountTeamMates(onteam);
        if (asmany <= 0) {
            return;
        }
    }

    for (int i = MaxClients; i >= 1; i--) {
        if (GetClientManager(i) == 0 && GetClientTeam(i) == onteam) {

            j++;
            if (g_StripKick == 1) {
                StripClient(i);
            }

            KickClient(i);

            if (j >= asmany) {
                break;
            }
        }
    }
}

// ================================================================== //
// MODEL FEATURES
// ================================================================== //

public Action AutoModelTimer(Handle timer, any client) {
    Echo(1, "AutoModelTimer: %d", client);

    if (!IsClientValid(client)) {
        return Plugin_Handled;
    }

    int target = GetClientManager(client);
    if (GetQRecord(target) && g_model[0] != EOS) {
        return Plugin_Handled;
    }

    int smq[8];  // survivor model queue
    int model;
    int count;

    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientValid(i) && GetClientTeam(i) == 2) {
            model = GetClientModelIndex(i);

            if (model != -1) {
                smq[model]++;
            }
        }
    }

    model = GetClientModelIndex(client);
    if (model == -1) model = 0;
    count = smq[model];

    if (count <= 1 || count <= CountTeamMates(2) / 8) {
        return Plugin_Handled;
    }

    for (int i = 1; i <= (MaxClients / 8) + 1; i++) {
        for (model = 0; model < 8; model++) {
            if (smq[model] < i) {
                i = MaxClients;
                break;
            }
        }
    }

    AssignModel(client, g_SurvivorNames[model]);
    return Plugin_Handled;
}

PrecacheModels() {
    Echo(1, "PrecacheModels");

    for (int i = 0; i < sizeof(g_SurvivorPaths); i++) {
        Format(g_sB, sizeof(g_sB), "%s", g_SurvivorPaths[i]);
        if (!IsModelPrecached(g_sB)) {
            int retcode = PrecacheModel(g_sB);
            Echo(1, " - Precaching Survivor %s, retcode: %d", g_sB, retcode);
        }
    }
}

AssignModel(int client, char [] model) {
    Echo(1, "AssignModel: %d %s", client, model);

    if (GetClientTeam(client) != 2 || IsClientsModel(client, model)) {
        return;
    }

    if (IsClientValid(client)) {
        int i = GetModelIndexByName(model);

        if (i >= 0 && i < sizeof(g_SurvivorPaths)) {

            switch(i == 5) {
                case 1: SetEntProp(client, Prop_Send, "m_survivorCharacter", g_Zoey);
                case 0: SetEntProp(client, Prop_Send, "m_survivorCharacter", i);
            }

            SetEntityModel(client, g_SurvivorPaths[i]);
            Format(g_pN, sizeof(g_pN), "%s", g_SurvivorNames[i]);

            if (IsFakeClient(client)) {
                SetClientInfo(client, "name", g_pN);
                int boss = GetClientManager(client);

                if (boss > 0) {
                    client = boss;
                }
            }

            if (GetQRecord(client)) {
                g_QRecord.SetString("model", g_pN);
            }
        }
    }
}

int GetClientModelIndex(int client) {
    Echo(2, "GetClientModelIndex: %d", client);

    if (!IsClientValid(client)) {
        return -2;
    }

    char modelName[64];

    GetEntPropString(client, Prop_Data, "m_ModelName", modelName, sizeof(modelName));
    for (int i = 0; i < sizeof(g_SurvivorPaths); i++) {
        if (StrEqual(modelName, g_SurvivorPaths[i], false)) {
            return i;
        }
    }

    return -1;
}

int GetModelIndexByName(char [] name, int onteam=2) {
    Echo(1, "GetModelIndexByName: %s %d", name, onteam);

    if (onteam == 2) {
        for (int i; i < sizeof(g_SurvivorNames); i++) {
            if (StrContains(name, g_SurvivorNames[i], false) != -1) {
                return i;
            }
        }
    }

    else if (onteam == 3) {
        for (int i; i < sizeof(g_InfectedNames); i++) {
            if (StrContains(g_InfectedNames[i], name, false) != -1) {
                return i;
            }
        }
    }

    return -1;
}

bool IsClientsModel(int client, char [] name) {
    Echo(1, "IsClientsModel: %d %s", client, name);

    int modelIndex = GetClientModelIndex(client);
    Format(g_sB, sizeof(g_sB), "%s", g_SurvivorNames[modelIndex]);
    return StrEqual(name, g_sB);
}

// ================================================================== //
// BLACK MAGIC SIGNATURES. SOME SPOOKY SHIT.
// ================================================================== //

int GetOS() {
    Echo(1, "GetOS");
    return GameConfGetOffset(g_GameData, "OS");
}

void RoundRespawnSig(int client) {
    Echo(1, "RoundRespawnSig: %d", client);

    static Handle hRoundRespawn;
    if (hRoundRespawn == null) {
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(g_GameData, SDKConf_Signature, "RoundRespawn");
        hRoundRespawn = EndPrepSDKCall();
    }

    if (hRoundRespawn != null) {
        SDKCall(hRoundRespawn, client);
    }

    else {
        PrintToChat(client, "[ABM] RoundRespawnSig Signature broken.");
        SetFailState("[ABM] RoundRespawnSig Signature broken.");
    }
}

void SetHumanSpecSig(int bot, int client) {
    Echo(1, "SetHumanSpecSig: %d %d", bot, client);

    static Handle hSpec;
    if (hSpec == null) {
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(g_GameData, SDKConf_Signature, "SetHumanSpec");
        PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
        hSpec = EndPrepSDKCall();
    }

    if(hSpec != null) {
        SDKCall(hSpec, bot, client);
    }

    else {
        PrintToChat(client, "[ABM] SetHumanSpecSig Signature broken.");
        SetFailState("[ABM] SetHumanSpecSig Signature broken.");
    }
}

void State_TransitionSig(int client, int mode) {
    Echo(1, "State_TransitionSig: %d %d", client, mode);

    static Handle hSpec;
    if (hSpec == null) {
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(g_GameData, SDKConf_Signature, "State_Transition");
        PrepSDKCall_AddParameter(SDKType_PlainOldData , SDKPass_Plain);
        hSpec = EndPrepSDKCall();
    }

    if(hSpec != null) {
        SDKCall(hSpec, client, mode);  // mode 8, press 8 to get closer
    }

    else {
        PrintToChat(client, "[ABM] State_TransitionSig Signature broken.");
        SetFailState("[ABM] State_TransitionSig Signature broken.");
    }
}

bool TakeoverBotSig(int client, int bot) {
    Echo(1, "TakeoverBotSig: %d %d", client, bot);

    if (!GetQRecord(client)) {
        return false;
    }

    static Handle hSwitch;
    if (hSwitch == null) {
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(g_GameData, SDKConf_Signature, "TakeOverBot");
        PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
        hSwitch = EndPrepSDKCall();
    }

    if (hSwitch != null) {
        if (IsClientInKickQueue(bot)) {
            KickClient(bot);
        }

        else if (IsClientValid(bot) && IsFakeClient(bot)) {
            if (GetClientTeam(bot) == 2) {
                SwitchToSpec(client);
                SetHumanSpecSig(bot, client);
                SDKCall(hSwitch, client, true);

                Unqueue(client);
                return true;
            }
        }
    }

    else {
        PrintToChat(client, "[ABM] TakeoverBotSig Signature broken.");
        SetFailState("[ABM] TakeoverBotSig Signature broken.");
    }

    g_QRecord.SetValue("lastid", bot, true);
    if (GetClientTeam(client) == 1) {
        g_QRecord.SetValue("queued", true, true);
        QueueUp(client, 2);
    }

    return false;
}

bool TakeoverZombieBotSig(int client, int bot, bool si_ghost) {
    Echo(1, "TakeoverZombieBotSig: %d %d", client, bot);

    if (!GetQRecord(client)) {
        return false;
    }

    static Handle hSwitch;
    if (hSwitch == null) {
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(g_GameData, SDKConf_Signature, "TakeOverZombieBot");
        PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
        hSwitch = EndPrepSDKCall();
    }

    if (hSwitch != null) {
        if (IsClientInKickQueue(bot)) {
            KickClient(bot);
        }

        else if (IsClientValid(bot) && IsFakeClient(bot) && IsPlayerAlive(bot)) {
            if (GetClientTeam(bot) == 3) {
                SwitchToSpec(client);
                SDKCall(hSwitch, client, bot);

                if (si_ghost) {
                    State_TransitionSig(client, 8);
                    if (GetEntProp(client, Prop_Send, "m_zombieClass") == 8) {
                        CreateTimer(1.0, ForceSpawnTimer, client, TIMER_REPEAT);
                    }
                }

                Unqueue(client);
                g_AssistedSpawning = true;
                return true;
            }
        }
    }

    else {
        PrintToChat(client, "[ABM] TakeoverZombieBotSig Signature broken.");
        SetFailState("[ABM] TakeoverZombieBotSig Signature broken.");
    }

    g_QRecord.SetValue("lastid", bot, true);
    if (GetClientTeam(client) == 1) {
        g_QRecord.SetValue("queued", true, true);
        QueueUp(client, 3);
    }

    return false;
}

// ================================================================== //
// PUBLIC INTERFACE AND MENU HANDLERS
// ================================================================== //

public Action TeleportClientCmd(int client, args) {
    Echo(1, "TeleportClientCmd: %d", client);

    int level;

    switch(args) {
        case 1: {
            GetCmdArg(1, g_sB, sizeof(g_sB));
            menuArg1 = StringToInt(g_sB);
        }

        case 2: {
            GetCmdArg(1, g_sB, sizeof(g_sB));
            menuArg0 = StringToInt(g_sB);
            GetCmdArg(2, g_sB, sizeof(g_sB));
            menuArg1 = StringToInt(g_sB);
        }
    }

    if (args) {
        level = 2;
    }

    TeleportClientHandler(client, level);
    return Plugin_Handled;
}

public TeleportClientHandler(int client, int level) {
    Echo(1, "TeleportClientHandler: %d %d", client, level);

    if (!RegMenuHandler(client, "TeleportClientHandler", level, 0)) {
        return;
    }

    switch(level) {
        case 0: TeamMatesMenu(client, "Teleport Client", 2, 1);
        case 1: {
            GetClientName(menuArg0, g_sB, sizeof(g_sB));
            Format(g_sB, sizeof(g_sB), "%s: Teleporting", g_sB);
            TeamMatesMenu(client, g_sB, 2, 1);
        }

        case 2: {
            if (CanClientTarget(client, menuArg0)) {
                if (GetClientTeam(menuArg0) <= 1) {
                    menuArg0 = GetPlayClient(menuArg0);
                }

                TeleportClient(menuArg0, menuArg1);
            }

            GenericMenuCleaner(client);
        }
    }
}

public Action SwitchTeamCmd(int client, args) {
    Echo(1, "SwitchTeamCmd: %d", client);

    int level;

    char model[32];
    GetCmdArg(args, model, sizeof(model));
    int result = StringToInt(model);
    CleanSIName(model);

    if (args == 1 || args == 2 && result == 0) {
        menuArg0 = client;
        GetCmdArg(1, g_sB, sizeof(g_sB));
        menuArg1 = StringToInt(g_sB);
    }

    else if (args >= 2) {
        GetCmdArg(1, g_sB, sizeof(g_sB));
        menuArg0 = StringToInt(g_sB);
        GetCmdArg(2, g_sB, sizeof(g_sB));
        menuArg1 = StringToInt(g_sB);
    }

    if (args) {
        level = 2;
    }

    else if (!IsAdmin(client)) {
        menuArg0 = client;
        level = 1;
    }

    if (menuArg1 == 3 && GetQRecord(menuArg0)) {
        g_QRecord.SetString("model", model);
    }

    SwitchTeamHandler(client, level);
    return Plugin_Handled;
}

public SwitchTeamHandler(int client, int level) {
    Echo(1, "SwitchTeamHandler: %d %d", client, level);

    if (!RegMenuHandler(client, "SwitchTeamHandler", level, 0)) {
        return;
    }

    switch(level) {
        case 0: TeamMatesMenu(client, "Switch Client's Team", 1);
        case 1: {
            GetClientName(menuArg0, g_sB, sizeof(g_sB));
            Format(g_sB, sizeof(g_sB), "%s: Switching", g_sB);
            TeamsMenu(client, g_sB);
        }

        case 2: {
            if (CanClientTarget(client, menuArg0)) {
                if (!IsAdmin(client) && menuArg1 == 3) {
                    GenericMenuCleaner(client);
                    return;
                }

                SwitchTeam(menuArg0, menuArg1);
            }

            GenericMenuCleaner(client);
        }
    }
}

public Action AssignModelCmd(int client, args) {
    Echo(1, "AssignModelCmd: %d", client);

    int level;

    switch(args) {
        case 1: {
            menuArg0 = client;
            GetCmdArg(1, g_sB, sizeof(g_sB));
            menuArg1 = GetModelIndexByName(g_sB);
        }

        case 2: {
            GetCmdArg(1, g_sB, sizeof(g_sB));
            menuArg1 = GetModelIndexByName(g_sB);
            GetCmdArg(2, g_sB, sizeof(g_sB));
            menuArg0 = StringToInt(g_sB);
        }
    }

    if (args) {
        level = 2;
    }

    AssignModelHandler(client, level);
    return Plugin_Handled;
}

public AssignModelHandler(int client, int level) {
    Echo(1, "AssignModelHandler: %d %d", client, level);

    if (!RegMenuHandler(client, "AssignModelHandler", level, 0)) {
        return;
    }

    switch(level) {
        case 0: TeamMatesMenu(client, "Change Client's Model", 2, 0, false);
        case 1: {
            GetClientName(menuArg0, g_sB, sizeof(g_sB));
            Format(g_sB, sizeof(g_sB), "%s: Modeling", g_sB);
            ModelsMenu(client, g_sB);
        }

        case 2: {
            if (CanClientTarget(client, menuArg0)) {
                if (GetClientTeam(menuArg0) <= 1) {
                    menuArg0 = GetPlayClient(menuArg0);
                }

                AssignModel(menuArg0, g_SurvivorNames[menuArg1]);
            }

            GenericMenuCleaner(client);
        }
    }
}

public Action SwitchToBotCmd(int client, args) {
    Echo(1, "SwitchToBotCmd: %d", client);

    int level;

    switch(args) {
        case 1: {
            menuArg0 = client;
            GetCmdArg(1, g_sB, sizeof(g_sB));
            menuArg1 = StringToInt(g_sB);
        }

        case 2: {
            GetCmdArg(1, g_sB, sizeof(g_sB));
            menuArg0 = StringToInt(g_sB);
            GetCmdArg(2, g_sB, sizeof(g_sB));
            menuArg1 = StringToInt(g_sB);
        }
    }

    if (args) {
        level = 2;
    }

    else if (!IsAdmin(client)) {
        menuArg0 = client;
        level = 1;
    }

    SwitchToBotHandler(client, level);
    return Plugin_Handled;
}

public SwitchToBotHandler(int client, int level) {
    Echo(1, "SwitchToBotHandler: %d %d", client, level);

    int homeTeam = ClientHomeTeam(client);
    if (!RegMenuHandler(client, "SwitchToBotHandler", level, 0)) {
        return;
    }

    switch(level) {
        case 0: TeamMatesMenu(client, "Takeover Bot", 1);
        case 1: {
            GetClientName(menuArg0, g_sB, sizeof(g_sB));
            Format(g_sB, sizeof(g_sB), "%s: Takeover", g_sB);
            TeamMatesMenu(client, g_sB, 0, 0, true, false, homeTeam);
        }

        case 2: {
            if (CanClientTarget(client, menuArg0)) {
                if (IsClientValid(menuArg1)) {
                    if (homeTeam != 3 && GetClientTeam(menuArg1) == 3) {
                        if (!IsAdmin(client)) {
                            GenericMenuCleaner(client);
                            return;
                        }
                    }

                    if (GetClientManager(menuArg1) == 0) {
                        SwitchToBot(menuArg0, menuArg1, false);
                    }
                }
            }

            GenericMenuCleaner(client);
        }
    }
}

public Action RespawnClientCmd(int client, args) {
    Echo(1, "RespawnClientCmd: %d", client);

    int level;

    switch(args) {
        case 1: {
            GetCmdArg(1, g_sB, sizeof(g_sB));
            menuArg0 = StringToInt(g_sB);
            menuArg1 = menuArg0;
        }

        case 2: {
            GetCmdArg(1, g_sB, sizeof(g_sB));
            menuArg0 = StringToInt(g_sB);
            GetCmdArg(2, g_sB, sizeof(g_sB));
            menuArg1 = StringToInt(g_sB);
        }
    }

    if (args) {
        level = 2;
    }

    RespawnClientHandler(client, level);
    return Plugin_Handled;
}

public RespawnClientHandler(int client, int level) {
    Echo(1, "RespawnClientHandler: %d %d", client, level);

    if (!RegMenuHandler(client, "RespawnClientHandler", level, 0)) {
        return;
    }

    switch(level) {
        case 0: TeamMatesMenu(client, "Respawn Client");
        case 1: {
            GetClientName(menuArg0, g_sB, sizeof(g_sB));
            Format(g_sB, sizeof(g_sB), "%s: Respawning", g_sB);
            TeamMatesMenu(client, g_sB);
        }

        case 2: {
            if (CanClientTarget(client, menuArg0)) {
                if (GetClientTeam(menuArg0) <= 1) {
                    menuArg0 = GetPlayClient(menuArg0);
                }

                RespawnClient(menuArg0, menuArg1);
            }

            GenericMenuCleaner(client);
        }
    }
}

public Action CycleBotsCmd(int client, args) {
    Echo(1, "CycleBotsCmd: %d", client);

    int level;

    switch(args) {
        case 1: {
            menuArg0 = client;
            GetCmdArg(1, g_sB, sizeof(g_sB));
            menuArg1 = StringToInt(g_sB);
        }

        case 2: {
            GetCmdArg(1, g_sB, sizeof(g_sB));
            menuArg0 = StringToInt(g_sB);
            GetCmdArg(2, g_sB, sizeof(g_sB));
            menuArg1 = StringToInt(g_sB);
        }
    }

    if (args) {
        if (menuArg1 > 3 || menuArg1 < 2) {
            return Plugin_Handled;
        }

        level = 2;
    }

    CycleBotsHandler(client, level);
    return Plugin_Handled;
}

public CycleBotsHandler(int client, int level) {
    Echo(1, "CycleBotsHandler: %d %d", client, level);

    if (!RegMenuHandler(client, "CycleBotsHandler", level, 0)) {
        return;
    }

    switch(level) {
        case 0: TeamMatesMenu(client, "Cycle Client", 1);
        case 1: {
            GetClientName(menuArg0, g_sB, sizeof(g_sB));
            Format(g_sB, sizeof(g_sB), "%s: Cycling", g_sB);
            TeamsMenu(client, g_sB, false);
        }

        case 2: {
            if (CanClientTarget(client, menuArg0)) {
                if (!IsAdmin(client) && menuArg1 == 3) {
                    GenericMenuCleaner(client);
                    return;
                }

                CycleBots(menuArg0, menuArg1);
                menuArg1 = 0;
            }

            CycleBotsHandler(client, 1);
        }
    }
}

public Action StripClientCmd(int client, args) {
    Echo(1, "StripClientCmd: %d", client);

    int target;
    int level;

    switch(args) {
        case 1: {
            GetCmdArg(1, g_sB, sizeof(g_sB));
            target = StringToInt(g_sB);
            target = GetPlayClient(target);

            if (CanClientTarget(client, target)) {
                StripClient(target);
            }

            return Plugin_Handled;
        }

        case 2: {
            GetCmdArg(1, g_sB, sizeof(g_sB));
            menuArg0 = StringToInt(g_sB);
            GetCmdArg(2, g_sB, sizeof(g_sB));
            menuArg1 = StringToInt(g_sB);
        }
    }

    if (args) {
        level = 2;
    }

    StripClientHandler(client, level);
    return Plugin_Handled;
}

public StripClientHandler(int client, int level) {
    Echo(1, "StripClientHandler: %d %d", client, level);

    if (!RegMenuHandler(client, "StripClientHandler", level, 0)) {
        return;
    }

    switch(level) {
        case 0: TeamMatesMenu(client, "Strip Client", 2, 1);
        case 1: {
            GetClientName(menuArg0, g_sB, sizeof(g_sB));
            Format(g_sB, sizeof(g_sB), "%s: Stripping", g_sB);
            InvSlotsMenu(client, menuArg0, g_sB);
        }

        case 2: {
            if (CanClientTarget(client, menuArg0)) {
                if (GetClientTeam(menuArg0) <= 1) {
                    menuArg0 = GetPlayClient(menuArg0);
                }

                StripClientSlot(menuArg0, menuArg1);
                menuArg1 = 0;
                StripClientHandler(client, 1);
            }
        }
    }
}

public Action ResetCmd(int client, args) {
    Echo(1, "ResetCmd: %d", client);

    for (int i = 1; i <= MaxClients; i++) {
        GenericMenuCleaner(i);
        if (GetQRecord(i)) {
            CancelClientMenu(i, true, null);
        }
    }
}

bool RegMenuHandler(int client, char [] handler, int level, int clearance=0) {
    Echo(1, "RegMenuHandler: %d %s %d %d", client, handler, level, clearance);

    g_callBacks.PushString(handler);
    if (!IsAdmin(client) && level <= clearance) {
        GenericMenuCleaner(client);
        return false;
    }

    return true;
}

public Action MainMenuCmd(int client, args) {
    Echo(1, "MainMenuCmd: %d", client);

    GenericMenuCleaner(client);
    MainMenuHandler(client, 0);
    return Plugin_Handled;
}

public MainMenuHandler(int client, int level) {
    Echo(1, "MainMenuHandler: %d %d", client, level);

    if (!RegMenuHandler(client, "MainMenuHandler", level, 0)) {
        return;
    }

    int cmd = menuArg0;
    menuArg0 = 0;

    char title[32];
    Format(title, sizeof(title), "ABM Menu %s", PLUGIN_VERSION);

    switch(level) {
        case 0: MainMenu(client, title);
        case 1: {
            switch(cmd) {
                case 0: TeleportClientCmd(client, 0);
                case 1: SwitchTeamCmd(client, 0);
                case 2: AssignModelCmd(client, 0);
                case 3: SwitchToBotCmd(client, 0);
                case 4: RespawnClientCmd(client, 0);
                case 5: CycleBotsCmd(client, 0);
                case 6: StripClientCmd(client, 0);
            }
        }
    }
}

// ================================================================== //
// MENUS BACKBONE
// ================================================================== //

GenericMenuCleaner(int client, bool clearStack=true) {
    Echo(1, "GenericMenuCleaner: %d %d", client, clearStack);

    for (int i = 0; i < sizeof(g_menuItems[]); i++) {
        g_menuItems[client][i] = 0;
    }

    if (clearStack == true) {
        if (g_callBacks != null) {
            delete g_callBacks;
        }

        g_callBacks = new ArrayStack(128);
    }
}

public GenericMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
    Echo(1, "GenericMenuHandler: %d %d", param1, param2);

    int client = param1;
    int i;  // -1;
    char sB[128];

    if (IsClientValid(param1)) {
        for (i = 0; i < sizeof(g_menuItems[]); i++) {
            if (menuArgs[i] == 0) {
                break;
            }
        }
    }

    switch(action) {
        case MenuAction_Select: {
            menu.GetItem(param2, g_sB, sizeof(g_sB));
            menuArgs[i] = StringToInt(g_sB);
            i = i + 1;
        }

        case MenuAction_Cancel: {
            if (param2 == MenuCancel_ExitBack) {
                if (i > 0) {
                    i = i - 1;
                    menuArgs[i] = 0;
                }

                else if (i == 0) {

                    if (g_callBacks.Empty) {
                        GenericMenuCleaner(param1);
                        return;
                    }

                    g_callBacks.PopString(g_sB, sizeof(g_sB));
                    GenericMenuCleaner(param1, false);

                    while (!g_callBacks.Empty) {
                        g_callBacks.PopString(sB, sizeof(sB));

                        if (!StrEqual(g_sB, sB)) {
                            g_callBacks.PushString(sB);
                            break;
                        }
                    }

                    if (g_callBacks.Empty) {
                        GenericMenuCleaner(param1);
                        return;
                    }
                }
            }

            else {
                return;
            }
        }

        case MenuAction_End: {
            delete menu;
            return;
        }
    }

    if (g_callBacks == null || g_callBacks.Empty) {
        GenericMenuCleaner(param1);
        return;
    }

    g_callBacks.PopString(g_sB, sizeof(g_sB));
    callBack = GetFunctionByName(null, g_sB);

    Call_StartFunction(null, callBack);
    Call_PushCell(param1);
    Call_PushCell(i);
    Call_Finish();
}

// ================================================================== //
// MENUS
// ================================================================== //

MainMenu(int client, char [] title) {
    Echo(1, "MainMenu: %d %s", client, title);

    Menu menu = new Menu(GenericMenuHandler);
    menu.SetTitle(title);
    menu.AddItem("0", "Teleport Client");  // "Telespiznat");    // teleport
    menu.AddItem("1", "Switch Client Team");  //"Swintootle");    // switch team
    menu.AddItem("2", "Change Client Model");  //"Changdangle");    // makeover
    menu.AddItem("3", "Switch Client Bot");  //"Inbosnachup");    // takeover
    menu.AddItem("4", "Respawn Client");  //"Respiggle");        // respawn
    menu.AddItem("5", "Cycle Client");  //"Cycolicoo");        // cycle
    menu.AddItem("6", "Strip Client");  //"Upsticky");        // strip
    menu.ExitBackButton = true;
    menu.ExitButton = true;
    menu.Display(client, 120);
}

InvSlotsMenu(int client, int target, char [] title) {
    Echo(1, "InvSlotsMenu: %d %d %s", client, target, title);

    int ent;
    char weapon[64];
    Menu menu = new Menu(GenericMenuHandler);
    menu.SetTitle(title);

    for (int i; i < 5; i++) {
        IntToString(i, g_sB, sizeof(g_sB));
        ent = GetPlayerWeaponSlot(target, i);

        if (IsValidEntity(ent)) {
            GetEntityClassname(ent, weapon, sizeof(weapon));
            menu.AddItem(g_sB, weapon);
        }
    }

    menu.ExitBackButton = true;
    menu.ExitButton = true;
    menu.Display(client, 120);
}

ModelsMenu(int client, char [] title) {
    Echo(1, "ModelsMenu: %d %s", client, title);

    Menu menu = new Menu(GenericMenuHandler);
    menu.SetTitle(title);

    for (int i; i < sizeof(g_SurvivorNames); i++) {
        IntToString(i, g_sB, sizeof(g_sB));
        menu.AddItem(g_sB, g_SurvivorNames[i]);
    }

    menu.ExitBackButton = true;
    menu.ExitButton = true;
    menu.Display(client, 120);
}

TeamsMenu(int client, char [] title, bool all=true) {
    Echo(1, "TeamsMenu: %d %s %d", client, title, all);

    Menu menu = new Menu(GenericMenuHandler);
    menu.SetTitle(title);

    if (all) {
        menu.AddItem("0", "Idler");
        menu.AddItem("1", "Spectator");
    }

    menu.AddItem("2", "Survivor");
    if (IsAdmin(client)) {
        menu.AddItem("3", "Infected");
    }

    menu.ExitBackButton = true;
    menu.ExitButton = true;
    menu.Display(client, 120);
}

TeamMatesMenu(int client, char [] title, int mtype=2, int target=0, bool incDead=true,
            bool repeat=false, int homeTeam=0) {
    Echo(1, "TeamMatesMenu: %d %s %d %d %d %d %d", client, title, mtype, target, incDead, repeat, homeTeam);

    Menu menu = new Menu(GenericMenuHandler);
    menu.SetTitle(title);
    int isAdmin = IsAdmin(client);
    char health[32];
    bool mflag = false;
    int isAlive;
    int playClient;
    int bossClient;
    int targetClient;
    int manager;

    for (int i = 1; i <= MaxClients; i++) {
        bossClient = i;
        playClient = i;

        if (GetQRecord(i)) {

            if (mtype == 0) {
                continue;
            }

            if (mtype == 1 || mtype == 2) {
                mflag = true;
            }

            if (IsClientValid(g_target) && g_target != i) {
                isAlive = IsPlayerAlive(g_target);
                playClient = g_target;
            }

            else {
                isAlive = IsPlayerAlive(i);
            }
        }

        else if (IsClientValid(i)) {
            isAlive = IsPlayerAlive(i);

            if (mtype == 0 || mtype == 2) {
                mflag = true;
            }

            manager = GetClientManager(i);

            if (manager != 0) {
                if (target == 0 || !repeat) {
                    mflag = false;
                    continue;
                }

                bossClient = manager;
            }
        }

        else {
            continue;
        }

        // at this point the client is valid.
        // bossClient is the human (if there is one)
        // playClient is the bot (or human if not idle)

        if (!isAlive && !incDead) {
            continue;
        }

        if (GetClientTeam(playClient) != homeTeam && !isAdmin) {
            continue;
        }

        switch(target) {
            case 0: targetClient = bossClient;
            case 1: targetClient = playClient;
        }

        if (mflag) {
            mflag = false;

            Format(health, sizeof(health), "%d", GetClientHealth(playClient));
            if (!IsPlayerAlive(playClient)) {
                Format(health, sizeof(health), "DEAD");
            }

            else if (GetEntProp(playClient, Prop_Send, "m_isIncapacitated")) {
                Format(health, sizeof(health), "DOWN");
            }

            GetClientName(bossClient, g_pN, sizeof(g_pN));
            Format(g_pN, sizeof(g_pN), "%s  (%s)", g_pN, health);
            IntToString(targetClient, g_sB, sizeof(g_sB));

            switch(bossClient == client && menu.ItemCount > 0) {
                case 0: menu.AddItem(g_sB, g_pN);
                case 1: menu.InsertItem(0, g_sB, g_pN);
            }
        }
    }

    menu.ExitBackButton = true;
    menu.ExitButton = true;
    menu.Display(client, 120);
}

// ================================================================== //
// MISC STUFF USEFUL FOR TROUBLESHOOTING
// ================================================================== //

Echo(int level, char [] format, any ...) {
    if (g_LogLevel >= level) {
        VFormat(g_dB, sizeof(g_dB), format, 3);
        LogToFile(LOGFILE, g_dB);
        PrintToServer("%s", g_dB);
    }
}

QDBCheckCmd(client) {
    Echo(1, "QDBCheckCmd");

    PrintToConsole(client, "-- STAT: QDB Size is %d", g_QDB.Size);
    PrintToConsole(client, "-- MinPlayers is %d", g_MinPlayers);

    for (int i = 1; i <= MaxClients; i++) {
        if (GetQRecord(i)) {
            PrintToConsole(client, "\n -");
            GetClientName(i, g_pN, sizeof(g_pN));

            float x = g_origin[0];
            float y = g_origin[1];
            float z = g_origin[2];

            PrintToConsole(client, " - Name: %s", g_pN);
            PrintToConsole(client, " - Origin: {%d.0, %d.0, %d.0}", x, y, z);
            PrintToConsole(client, " - Status: %d", IsPlayerAlive(i));
            PrintToConsole(client, " - Client: %d", g_client);
            PrintToConsole(client, " - Target: %d", g_target);
            PrintToConsole(client, " - LastId: %d", g_lastid);
            PrintToConsole(client, " - OnTeam: %d", g_onteam);
            PrintToConsole(client, " - Queued: %d", g_queued);
            PrintToConsole(client, " - InSpec: %d", g_inspec);

            if (GetClientTeam(i) == 2) {
                int j = GetClientModelIndex(i);
                if (j != -1) {
                    PrintToConsole(client, " - Initialized Model: %s", g_SurvivorNames[j]);
                }
            }

            PrintToConsole(client, " - Model: %s", g_model);
            PrintToConsole(client, " -\n");
        }
    }
}

public Action QuickClientPrintCmd(int client, args) {
    Echo(1, "QuickClientPrintCmd: %d", client);

    int onteam;
    int state;
    int manager;

    PrintToConsole(client, "\nTeam\tState\tId\tManager\tName");

    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientValid(i)) {
            manager = i;
            GetClientName(i, g_pN, sizeof(g_pN));
            onteam = GetClientTeam(i);
            state = IsPlayerAlive(i);


            if (IsFakeClient(i)) {
                manager = GetClientManager(i);
            }

            PrintToConsole(client,
                "%d, \t%d, \t%d, \t%d, \t%s", onteam, state, i, manager, g_pN
            );
        }
    }

    QDBCheckCmd(client);
}
