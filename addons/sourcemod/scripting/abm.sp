//# vim: set filetype=cpp :

/*
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
along with this program; if not, write to the

Free Software Foundation, Inc.
51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "0.1.14"
#define LOGFILE "addons/sourcemod/logs/abm.log"  // TODO change this to DATE/SERVER FORMAT?

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

char g_SpecialNames[7][] = {"Tank", "Boomer", "Smoker", "Hunter", "Spitter", "Jockey", "Charger"};
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
char g_cisi[MAXPLAYERS + 1][64];    // g_QDB client Id to steam Id array

ConVar g_cvLogLevel;
ConVar g_cvMinPlayers;
ConVar g_cvPrimaryWeapon;
ConVar g_cvSecondaryWeapon;
ConVar g_cvThrowable;
ConVar g_cvHealItem;
ConVar g_cvConsumable;
ConVar g_cvZoey;

bool g_IsVs = false;
char g_GameMode[16];
int g_LogLevel;
int g_MinPlayers;
char g_PrimaryWeapon[64];
char g_SecondaryWeapon[64];
char g_Throwable[64];
char g_HealItem[64];
char g_Consumable[64];
int g_Zoey;

public Plugin myinfo= {
	name = "ABM",
	author = "Victor B. Gonzalez",
	description = "A 5+ Player Enhancement Plugin for L4D2",
	version = PLUGIN_VERSION,
	url = "https://gitlab.com/vbgunz/ABM"
}

public OnPluginStart() {
	DebugToFile(1, "OnPluginStart");

	HookEvent("player_first_spawn", OnSpawnHook);
	HookEvent("player_death", OnDeathHook);
	HookEvent("player_disconnect", CleanQDBHook);
	HookEvent("player_afk", GoIdleHook);
	HookEvent("player_team", QTeamHook);
	HookEvent("player_bot_replace", QAfkHook);
	HookEvent("bot_player_replace", QBakHook);

	HookEvent("round_freeze_end", RoundFreezeEndHook);
	HookEvent("player_activate", PlayerActivateHook);

	RegAdminCmd("abm", MainMenuCmd, ADMFLAG_GENERIC);
	RegAdminCmd("abm-menu", MainMenuCmd, ADMFLAG_GENERIC);
	RegAdminCmd("abm-join", SwitchTeamCmd, ADMFLAG_GENERIC);
	RegAdminCmd("abm-takeover", SwitchToBotCmd, ADMFLAG_GENERIC);
	RegAdminCmd("abm-respawn", RespawnClientCmd, ADMFLAG_GENERIC);
	RegAdminCmd("abm-model", AssignModelCmd, ADMFLAG_GENERIC);
	RegAdminCmd("abm-strip", StripClientCmd, ADMFLAG_GENERIC);
	RegAdminCmd("abm-teleport", TeleportClientCmd, ADMFLAG_GENERIC);
	RegAdminCmd("abm-cycle", CycleBotsCmd, ADMFLAG_GENERIC);
	RegAdminCmd("abm-reset", ResetCmd, ADMFLAG_GENERIC);
	RegAdminCmd("abm-info", QuickClientPrintCmd, ADMFLAG_GENERIC);
	RegAdminCmd("abm-mk", MkBotsCmd, ADMFLAG_GENERIC);
	RegAdminCmd("abm-rm", RmBotsCmd, ADMFLAG_GENERIC);
	RegConsoleCmd("takeover", SwitchToBotCmd);
	RegConsoleCmd("join", SwitchTeamCmd);

	g_OS = GetOS();  // 0: Linux 1: Windows
	g_QDB = new StringMap();
	g_QRecord = new StringMap();

	for (int i = 1 ; i <= MaxClients ; i++) {
		g_menuStack[i] = new ArrayStack(128);
	}

	// Register everyone that we can find
	for (int i = 1 ; i <= MaxClients ; i++) {
		if (!GetQRecord(i)) {
			if (SetQRecord(i) != -1) {
				g_cisi[i] = g_QKey;
			}
		}
	}

	FindConVar("mp_gamemode").GetString(g_GameMode, sizeof(g_GameMode));
	g_IsVs = (StrEqual(g_GameMode, "versus") || StrEqual(g_GameMode, "scavenge"));

	CreateConVar("abm_version", PLUGIN_VERSION, "ABM plugin version", FCVAR_DONTRECORD);
	g_cvMinPlayers = CreateConVar("abm_minplayers", "4", "Pruning extra survivors stops at this size");
	g_cvPrimaryWeapon = CreateConVar("abm_primaryweapon", "shotgun_chrome", "5+ survivor primary weapon");
	g_cvSecondaryWeapon = CreateConVar("abm_secondaryweapon", "baseball_bat", "5+ survivor secondary weapon");
	g_cvThrowable = CreateConVar("abm_throwable", "", "5+ survivor throwable item");
	g_cvHealItem = CreateConVar("abm_healitem", "", "5+ survivor healing item");
	g_cvConsumable = CreateConVar("abm_consumable", "adrenaline", "5+ survivor consumable item");
	g_cvLogLevel = CreateConVar("abm_loglevel", "0", "Level of debugging");

	switch(g_OS) {
		case 0: Format(g_sB, sizeof(g_sB), "5");
		case 1: Format(g_sB, sizeof(g_sB), "1");
		default: PrintToChatAll("Zoey has gone Sarah Palin");
	}

	g_cvZoey = CreateConVar("abm_zoey", g_sB, "0:Nick 1:Rochelle 2:Coach 3:Ellis 4:Bill 5:Zoey 6:Francis 7:Louis");

	HookConVarChange(g_cvLogLevel, UpdateConVarsHook);
	HookConVarChange(g_cvMinPlayers, UpdateMinPlayersHook);
	HookConVarChange(g_cvPrimaryWeapon, UpdateConVarsHook);
	HookConVarChange(g_cvSecondaryWeapon, UpdateConVarsHook);
	HookConVarChange(g_cvThrowable, UpdateConVarsHook);
	HookConVarChange(g_cvHealItem, UpdateConVarsHook);
	HookConVarChange(g_cvConsumable, UpdateConVarsHook);
	HookConVarChange(g_cvZoey, UpdateConVarsHook);
	UpdateConVarsHook(g_cvLogLevel, "0", "0");
	UpdateMinPlayersHook(g_cvMinPlayers, "4", "4");
	UpdateConVarsHook(g_cvZoey, g_sB, g_sB);
	AutoExecConfig(true, "abm");
}

public RoundFreezeEndHook(Handle event, const char[] name, bool dontBroadcast) {
	DebugToFile(1, "RoundFreezeEndHook: %s", name);

	StringMapSnapshot keys = g_QDB.Snapshot();

	for (int i ; i < keys.Length ; i++) {
		keys.GetKey(i, g_sB, sizeof(g_sB));
		g_QDB.GetValue(g_sB, g_QRecord);
		g_QRecord.GetString("model", g_sB, sizeof(g_sB));
		g_QRecord.SetString("ghost", g_sB, true);
	}

	CloseHandle(keys);
}

public PlayerActivateHook(Handle event, const char[] name, bool dontBroadcast) {
	DebugToFile(1, "PlayerActivateHook: %s", name);

	int userid = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userid);

	if (GetQRecord(client)) {
		AssignModel(client, g_ghost);
	}
}

public UpdateMinPlayersHook(Handle convar, const char[] oldCv, const char[] newCv) {
	DebugToFile(1, "UpdateMinPlayersHook: %s %s", oldCv, newCv);

	g_MinPlayers = GetConVarInt(g_cvMinPlayers);
	CreateTimer(0.1, RmBotsTimer, g_MinPlayers * -1);
}

public UpdateConVarsHook(Handle convar, const char[] oldCv, const char[] newCv) {
	DebugToFile(1, "UpdateConVarsHook: %s %s", oldCv, newCv);

	g_LogLevel = GetConVarInt(g_cvLogLevel);
	GetConVarString(g_cvPrimaryWeapon, g_PrimaryWeapon, sizeof(g_PrimaryWeapon));
	GetConVarString(g_cvSecondaryWeapon, g_SecondaryWeapon, sizeof(g_SecondaryWeapon));
	GetConVarString(g_cvThrowable, g_Throwable, sizeof(g_Throwable));
	GetConVarString(g_cvHealItem, g_HealItem, sizeof(g_HealItem));
	GetConVarString(g_cvConsumable, g_Consumable, sizeof(g_Consumable));

	switch(g_OS) {  // Zoey hates Windows :'(
		case 0: g_Zoey = 5;
		default: g_Zoey = GetConVarInt(g_cvZoey);
	}
}

public OnConfigsExecuted() {
	DebugToFile(1, "OnConfigsExecuted");
	PrecacheModels();
}

public OnClientPostAdminCheck(int client) {
	DebugToFile(1, "OnClientPostAdminCheck: %d", client);

	if (!GetQRecord(client)) {
		if (SetQRecord(client) >= 0) {
			g_cisi[client] = g_QKey;
			PrintToServer("AUTH ID: %s, ADDED TO QDB.", g_QKey);

			int onteam = 2;
			if (g_IsVs && CountTeamMates(3) < CountTeamMates(2)) {
				onteam = 3;
			}

			if (!g_IsVs && CountTeamMates(onteam) >= 1) {
				NewBotTakeOver(client, onteam);
			}
		}
	}
}

public GoIdleHook(Handle event, const char[] name, bool dontBroadcast) {
	DebugToFile(1, "GoIdleHook: %s", name);
	int player = GetEventInt(event, "player");
	int client = GetClientOfUserId(player);
	GoIdle(client);
}

GoIdle(int client) {
	DebugToFile(1, "GoIdle: %d", client);

	if (GetQRecord(client)) {
		if (GetClientTeam(client) == 2) {
			ChangeClientTeam(client, 1);
			SetHumanSpecSig(g_target, client);
			AssignModel(g_target, g_model);
		}
	}
}

public CleanQDBHook(Handle event, const char[] name, bool dontBroadcast) {
	DebugToFile(1, "CleanQDBHook: %s", name);

	int userid = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userid);

	// during map change, GetQRecord doesn't work :'(
	Format(g_sB, sizeof(g_sB), "%s", g_cisi[client]);

	if (g_sB[0] != EOS) {
		g_cisi[client] = "";

		if (g_QDB.GetValue(g_sB, g_QRecord)) {
			RemoveQDBKey(g_sB);
		}
	}
}

RemoveQDBKey(char[] key) {
	DebugToFile(1, "RemoveQDBKey: %s", key);

	bool rmbot = g_QDB.Size > g_MinPlayers;
	int asmany = CountTeamMates(2) - 1 * -1;

	if (g_QDB.Remove(key)) {
		PrintToServer("AUTH ID: %s, REMOVED FROM QDB.", key);

		if (rmbot) {
			CreateTimer(1.0, RmBotsTimer, asmany);
		}
	}
}

public Action RmBotsTimer(Handle timer, any asmany) {
	DebugToFile(3, "RmBotsTimer");

	if (!g_IsVs) {
		RmBots(asmany, 2);
	}
}

bool IsAdmin(int client) {
	DebugToFile(1, "IsAdmin: %d", client);
	return CheckCommandAccess(
		client, "generic_admin", ADMFLAG_GENERIC, false
	);
}

bool IsClientValid(int client) {
	DebugToFile(3, "IsClientValid: %d", client);

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
	DebugToFile(1, "CanClientTarget: %d %d", client, target);

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
	DebugToFile(2, "GetPlayClient: %d", client);

	if (GetQRecord(client)) {
		return g_target;
	}

	else if (IsClientValid(client)) {
		return client;
	}

	return -1;
}

int ClientHomeTeam(int client) {
	DebugToFile(1, "ClientHomeTeam: %d", client);

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
	DebugToFile(2, "SetQKey: %d", client);

	if (IsClientValid(client) && !IsFakeClient(client)) {
		if (GetClientAuthId(client, AuthId_Steam2, g_QKey, sizeof(g_QKey), true)) {
			return true;
		}
	}

	return false;
}

bool GetQRecord(int client) {
	DebugToFile(2, "GetQRecord: %d", client);

	if (SetQKey(client)) {
		if (g_QDB.GetValue(g_QKey, g_QRecord)) {
			if (IsPlayerAlive(client)) {
				GetClientAbsOrigin(client, g_origin);
				g_QRecord.SetArray("origin", g_origin, sizeof(g_origin), true);
			}

			g_QRecord.GetValue("client", g_client);
			g_QRecord.GetValue("target", g_target);
			g_QRecord.GetValue("previd", g_lastid);
			g_QRecord.GetValue("onteam", g_onteam);
			g_QRecord.GetValue("queued", g_queued);

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
	DebugToFile(2, "NewQRecord: %d", client);

	g_QRecord = new StringMap();

	GetClientAbsOrigin(client, g_origin);
	g_QRecord.SetArray("origin", g_origin, sizeof(g_origin), true);
	g_QRecord.SetValue("client", client, true);
	g_QRecord.SetValue("target", client, true);
	g_QRecord.SetValue("previd", client, true);
	g_QRecord.SetValue("onteam", GetClientTeam(client), true);
	g_QRecord.SetValue("queued", false, true);
	g_QRecord.SetString("model", "", true);
	g_QRecord.SetString("ghost", "", true);
	return true;
}

int SetQRecord(int client) {
	DebugToFile(2, "SetQRecord: %d", client);

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

public OnSpawnHook(Handle event, const char[] name, bool dontBroadcast) {
	DebugToFile(1, "OnSpawnHook: %s", name);

	int userid = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userid);
	GetClientName(client, g_pN, sizeof(g_pN));

	int flag1 = StrContains(g_pN, "SPECIAL");
	int flag2 = StrContains(g_pN, "SURVIVOR");
	if (flag1 >= 0 || flag2 >= 0) {
		return;
	}

	if (GetClientTeam(client) == 2) {
		CreateTimer(0.1, AutoModelTimer, client);
	}
}

public OnDeathHook(Handle event, const char[] name, bool dontBroadcast) {
	DebugToFile(3, "OnDeathHook: %s", name);

	int userid = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userid);
	int playClient = GetPlayClient(client);

	if (GetQRecord(playClient)) {
		float origin[3];
		GetClientAbsOrigin(client, origin);
		g_QRecord.SetArray("origin", origin, sizeof(origin), true);

		if (g_onteam == 3) {
			g_QRecord.SetValue("target", g_client, true);
			g_QRecord.SetValue("queued", true, true);
		}

		menuArg0 = playClient;
		SwitchToBotHandler(playClient, 1);
	}
}

public QTeamHook(Handle event, const char[] name, bool dontBroadcast) {
	DebugToFile(1, "QTeamHook: %s", name);

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int onteam = GetEventInt(event, "team");

	if (GetQRecord(client)) {
		if (onteam >= 2) {
			g_QRecord.SetValue("target", client, true);
			g_QRecord.SetValue("onteam", onteam, true);

			if (onteam == 3) {
				g_QRecord.SetString("model", "", true);
			}
		}
	}
}

public QAfkHook(Handle event, const char[] name, bool dontBroadcast) {
	DebugToFile(1, "QAfkHook: %s", name);

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

	if (IsClientValid(client)) {
		if (IsClientInKickQueue(client)) {
			if (client && target && clientTeam == targetTeam) {
				int safeClient = GetSafeClient(target);
				RespawnClient(target, safeClient);
			}
		}
	}
}

public QBakHook(Handle event, const char[] name, bool dontBroadcast) {
	DebugToFile(1, "QBakHook: %s", name);

	int client = GetClientOfUserId(GetEventInt(event, "player"));
	int target = GetClientOfUserId(GetEventInt(event, "bot"));

	if (GetQRecord(client)) {
		if (g_target != target) {
			g_QRecord.SetValue("previd", target);
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
	DebugToFile(1, "StripClient: %d", client);

	for (int i = 0 ; i < 5 ; i++) {
		StripClientSlot(client, i);
	}
}

StripClientSlot(int client, int slot) {
	DebugToFile(1, "StripClientSlot: %d %d", client, slot);

	client = GetPlayClient(client);

	if (IsClientValid(client)) {
		int ent = GetPlayerWeaponSlot(client, slot);
		if (IsValidEntity(ent)) {
			RemovePlayerItem(client, ent);
			RemoveEdict(ent);
		}
	}
}

RespawnClient(int client, int target=0) {
	DebugToFile(1, "RespawnClient: %d %d", client, target);

	if (!IsClientValid(client)) {
		return;
	}

	else if (GetQRecord(client)) {
		if (g_onteam == 3) {
			NewBotTakeOver(client, 3);
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
	DebugToFile(1, "TeleportClient: %d %d", client, target);

	float origin[3];
	client = GetPlayClient(client);
	target = GetPlayClient(target);

	if (IsClientValid(client) && IsClientValid(target)) {
		GetClientAbsOrigin(target, origin);
		TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
	}
}

int GetSafeClient(int client) {
	DebugToFile(1, "GetSafeClient: %d", client);

	client = GetPlayClient(client);
	int onteam = GetClientTeam(client);

	for (int i = 1 ; i <= MaxClients ; i++) {
		if (IsClientValid(i) && i != client) {
			if (IsPlayerAlive(i) && GetClientTeam(i) == onteam) {
				if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge") == 0) {
					return i;
				}
			}
		}
	}

	return -1;
}

bool AddSurvivor() {
	DebugToFile(1, "AddSurvivor");

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

bool AddInfected() {
	DebugToFile(1, "AddInfected");

	bool result = false;
	int index;
	char si[32];

	index = GetRandomInt(0, sizeof(g_SpecialNames) - 1);
	si = g_SpecialNames[index];

	int special = CreateFakeClient("SPECIAL");
	if (IsClientValid(special)) {
		ChangeClientTeam(special, 3);
		Format(g_sB, sizeof(g_sB), "%s auto", si);
		QuickCheat(special, "z_spawn_old", g_sB);
		KickClient(special);
		result = true;
	}

	return result;
}

QuickCheat(int client, char [] cmd, char [] arg) {
	DebugToFile(1, "QuickCheat: %d %s %s", client, cmd, arg);

	int flags = GetCommandFlags(cmd);
	SetCommandFlags(cmd, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", cmd, arg);
	SetCommandFlags(cmd, flags);
}

SwitchToBot(int client, int bot, bool si_ghost=true) {
	DebugToFile(1, "SwitchToBot: %d %d %d", client, bot, si_ghost);

	if (client != bot && IsClientValid(bot)) {
		int onteam = GetClientTeam(bot);

		if (GetQRecord(client)) {
			ChangeClientTeam(client, 1);
			SwitchToBotMiddleManWTF(client, bot, onteam, si_ghost);
		}
	}
}

SwitchToBotMiddleManWTF(int client, int bot, int onteam, bool si_ghost=true) {
	DebugToFile(1, "SwitchToBotMiddleManWTF: %d %d %d %d", client, bot, onteam, si_ghost);

	DataPack pack;
	CreateDataTimer(0.1, SwitchToBotTimer, pack);
	pack.WriteCell(client);
	pack.WriteCell(bot);
	pack.WriteCell(onteam);
	pack.WriteCell(si_ghost);
}

public Action SwitchToBotTimer(Handle timer, Handle pack) {
	DebugToFile(1, "SwitchToBotTimer");

	int client;
	int bot;
	int onteam;
	bool si_ghost;

	ResetPack(pack);
	client = ReadPackCell(pack);
	bot = ReadPackCell(pack);
	onteam = ReadPackCell(pack);
	si_ghost = ReadPackCell(pack);

	if (IsClientValid(bot)) {
		switch (onteam) {
			case 2: {
				SetHumanSpecSig(bot, client);
				TakeOverBotSig(client);
			}

			case 3: {
				TakeOverZombieBotSig(client, bot);
				if (si_ghost) {
					State_TransitionSig(client, 8);
				}
			}
		}
	}

	return Plugin_Stop;
}

NewBotTakeOver(int client, int onteam) {
	DebugToFile(1, "NewBotTakeOver: %d %d", client, onteam);

	if (GetQRecord(client)) {
		StringMap R = g_QRecord;
		ChangeClientTeam(client, 1);

		if (IsClientValid(g_target)) {
			if (client != g_target && GetClientTeam(g_target) == onteam) {
				SwitchToBot(client, g_target);
				return;
			}
		}

		int nextBot;
		nextBot = GetNextBot(onteam);

		if (nextBot >= 1) {
			SwitchToBot(client, nextBot);
			return;
		}

		R.SetValue("onteam", onteam, true);
		R.SetValue("queued", true, true);

		switch (onteam) {
			case 2: AddSurvivor();
			case 3: {
				AddInfected();
				State_TransitionSig(client, 8);
			}
		}

		CreateTimer(1.0, NewBotTakeOverTimer, client);
	}
}

public Action NewBotTakeOverTimer(Handle timer, any client) {
	DebugToFile(1, "NewBotTakeOverTimer: %d", client);

	if (GetQRecord(client)) {
		NewBotTakeOver(client, g_onteam);
	}
}


int CountTeamMates(int onteam, int mtype=2) {
	DebugToFile(1, "CountTeamMates: %d %d", onteam, mtype);

	// mtype 0: counts only bots
	// mtype 1: counts only humans
	// mtype 2: counts all players on team

	if (mtype == 2) {
		return GetTeamClientCount(onteam);
	}

	int j;
	int result;
	int humans;
	int bots;

	for (int i = 1 ; i <= MaxClients ; i++) {
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
	DebugToFile(3, "GetClientManager: %d", target);

	int result;
	int userid;
	int client;

	if (GetQRecord(target)) {
		return target;
	}

	else if (IsClientValid(target)) {
		for (int i = 1 ; i <= MaxClients ; i++) {
			if (IsClientValid(i) && IsFakeClient(i) && GetClientTeam(i) == 2) {

				// let's really put a stop to the "idling 2 bots at once" problem
				userid = GetEntData(i, FindSendPropInfo("SurvivorBot", "m_humanSpectatorUserID"));
				client = GetClientOfUserId(userid);

				if (GetQRecord(client) && i != g_target) {
					SetEntProp(i, Prop_Send, "m_humanSpectatorUserID", 0);
				}
			}
		}

		for (int i = 1 ; i <= MaxClients ; i++) {
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

int GetNextBot(int onteam, int skipIndex=1) {
	DebugToFile(1, "GetNextBot: %d %d", onteam, skipIndex);

	int bot;

	for (int i = 1 ; i <= MaxClients ; i++) {
		if (GetClientManager(i) == 0) {
			if (GetClientTeam(i) == onteam) {
				if (bot == 0) {
					bot = i;
				}

				if (i > skipIndex) {
					bot = i;
					break;
				}
			}
		}
	}

	return bot;
}

CycleBots(int client, int onteam) {
	DebugToFile(1, "CycleBots: %d %d", client, onteam);

	if (onteam <= 1) {
		return;
	}

	if (GetQRecord(client)) {
		int bot = GetNextBot(onteam, g_lastid);
		if (GetClientManager(bot) == 0) {
			SwitchToBot(client, bot, false);
		}
	}
}

SwitchTeam(int client, int onteam) {
	DebugToFile(1, "SwitchTeam: %d %d", client, onteam);

	if (GetQRecord(client)) {
		if (GetClientManager(g_target) == client) {
			if (GetClientTeam(g_target) == onteam) {
				SwitchToBot(client, g_target);
				return;
			}
		}
	}

	switch (onteam) {
		case 0: GoIdle(client);
		case 1: ChangeClientTeam(client, 0);
		default: {
			int bot = GetNextBot(onteam);

			if (!IsClientValid(bot)) {
				NewBotTakeOver(client, onteam);
				return;
			}

			SwitchToBot(client, bot);
		}
	}
}

public Action MkBotsCmd(int client, args) {
	DebugToFile(1, "MkBotsCmd: %d", client);

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
	DebugToFile(1, "MkBots: %d %d", asmany, onteam);

	if (asmany < 0) {
		asmany = asmany * -1 - CountTeamMates(onteam);
	}

	for (int i = 1 ; i <= asmany ; i++) {
		switch (onteam) {
			case 2: {
				CreateTimer(0.1, MkBotsTimer, asmany, TIMER_REPEAT);
				return;
			}

			case 3: AddInfected();
		}
	}
}

public Action MkBotsTimer(Handle timer, any asmany) {
	DebugToFile(1, "MkBotsTimer: %d", asmany);
	static i;

	if (i++ < asmany) {
		AddSurvivor();
		return Plugin_Continue;
	}

	i = 0;
	return Plugin_Stop;
}

public Action RmBotsCmd(int client, args) {
	DebugToFile(1, "RmBotsCmd: %d", client);

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
	DebugToFile(1, "RmBots: %d %d", asmany, onteam);

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

	for (int i = MaxClients ; i >= 1 ; i--) {
		if (GetClientManager(i) == 0 && GetClientTeam(i) == onteam) {

			j++;
			StripClient(i);
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
	DebugToFile(1, "AutoModelTimer: %d", client);

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

	for (int i = 1 ; i <= MaxClients ; i++) {
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

	for (int i = 1 ; i <= (MaxClients / 8) + 1 ; i++) {
		for (model = 0 ; model < 8 ; model++) {
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
	DebugToFile(1, "PrecacheModels");

	for (int i = 0 ; i < sizeof(g_SurvivorPaths) ; i++) {
		Format(g_sB, sizeof(g_sB), "%s", g_SurvivorPaths[i]);
		if (!IsModelPrecached(g_sB)) {
			int retcode = PrecacheModel(g_sB);
			PrintToServer(" - Precaching %s, retcode: %d", g_sB, retcode);
		}
	}
}

AssignModel(int client, char [] model) {
	DebugToFile(1, "AssignModel: %d %s", client, model);

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

			if (GetQRecord(client)) {
				StringMap R = g_QRecord;
				R.SetString("model", g_pN);
			}

			else {
				SetClientInfo(client, "name", g_pN);
			}
		}
	}
}

int GetClientModelIndex(int client) {
	DebugToFile(2, "GetClientModelIndex: %d", client);

	if (!IsClientValid(client)) {
		return -2;
	}

	char modelName[64];

	GetEntPropString(client, Prop_Data, "m_ModelName", modelName, sizeof(modelName));
	for (int i = 0 ; i < sizeof(g_SurvivorPaths) ; i++) {
		if (StrEqual(modelName, g_SurvivorPaths[i], false)) {
			return i;
		}
	}

	return -1;
}

int GetModelIndexByName(char [] name) {
	DebugToFile(1, "GetModelIndexByName: %s", name);

	for (int i = 0 ; i < sizeof(g_SurvivorNames) ; i ++) {
		if (StrContains(name, g_SurvivorNames[i], false) != -1) {
			return i;
		}
	}

	return -1;
}

bool IsClientsModel(int client, char [] name) {
	DebugToFile(1, "IsClientsModel: %d %s", client, name);

	int modelIndex = GetClientModelIndex(client);
	Format(g_sB, sizeof(g_sB), "%s", g_SurvivorNames[modelIndex]);
	return StrEqual(name, g_sB);
}

// ================================================================== //
// BLACK MAGIC SIGNATURES. SOME SPOOKY SHIT.
// ================================================================== //

int GetOS() {
	DebugToFile(1, "GetOS");

	Handle hGameConf = LoadGameConfigFile("abm");
	int result = GameConfGetOffset(hGameConf, "OS");
	CloseHandle(hGameConf);
	return result;  // 0: Linux 1: Windows
}

void RoundRespawnSig(int client) {
	DebugToFile(1, "RoundRespawnSig: %d", client);

	static Handle hRoundRespawn = INVALID_HANDLE;
	if (hRoundRespawn == INVALID_HANDLE) {
		Handle hGameConf = LoadGameConfigFile("abm");
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RoundRespawn");
		hRoundRespawn = EndPrepSDKCall();
		CloseHandle(hGameConf);
	}

	if (hRoundRespawn != INVALID_HANDLE) {
		SDKCall(hRoundRespawn, client);
	}

	else {
		PrintToChatAll("[ABM] RoundRespawnSig Signature broken.");
		DebugToFile(0, "[ABM] RoundRespawnSig Signature broken.");
	}
}

void SetHumanSpecSig(int bot, int client) {
	DebugToFile(1, "SetHumanSpecSig: %d %d", bot, client);

	static Handle hSpec = INVALID_HANDLE;
	if (hSpec == INVALID_HANDLE) {
		Handle hGameConf = LoadGameConfigFile("abm");
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "SetHumanSpec");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		hSpec = EndPrepSDKCall();
		CloseHandle(hGameConf);
	}

	if(hSpec != INVALID_HANDLE) {
		SDKCall(hSpec, bot, client);
	}

	else {
		PrintToChatAll("[ABM] SetHumanSpecSig Signature broken.");
		DebugToFile(0, "[ABM] SetHumanSpecSig Signature broken.");
	}
}

void State_TransitionSig(int client, int mode) {
	DebugToFile(1, "State_TransitionSig: %d %d", client, mode);

	static Handle hSpec = INVALID_HANDLE;
	if (hSpec == INVALID_HANDLE) {
		Handle hGameConf = LoadGameConfigFile("abm");
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "State_Transition");
		PrepSDKCall_AddParameter(SDKType_PlainOldData , SDKPass_Plain);
		hSpec = EndPrepSDKCall();
		CloseHandle(hGameConf);
	}

	if(hSpec != INVALID_HANDLE) {
		// mode 8 while infected causes the press e to move closer to take over;
		SDKCall(hSpec, client, mode);
	}

	else {
		PrintToChatAll("[ABM] State_TransitionSig Signature broken.");
		DebugToFile(0, "[ABM] State_TransitionSig Signature broken.");
	}
}

void TakeOverBotSig(int client) {
	DebugToFile(1, "TakeOverBotSig: %d", client);

	static Handle hSwitch = INVALID_HANDLE;
	if (hSwitch == INVALID_HANDLE) {
		Handle hGameConf = LoadGameConfigFile("abm");
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "TakeOverBot");
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		hSwitch = EndPrepSDKCall();
		CloseHandle(hGameConf);
	}

	if (hSwitch != INVALID_HANDLE) {
		SDKCall(hSwitch, client, true);
	}

	else {
		PrintToChatAll("[ABM] TakeOverBotSig Signature broken.");
		DebugToFile(0, "[ABM] TakeOverBotSig Signature broken.");

	}

}

void TakeOverZombieBotSig(int client, int bot) {
	DebugToFile(1, "TakeOverZombieBotSig: %d %d", client, bot);

	static Handle hSwitch = INVALID_HANDLE;
	if (hSwitch == INVALID_HANDLE) {
		Handle hGameConf = LoadGameConfigFile("abm");
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "TakeOverZombieBot");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		hSwitch = EndPrepSDKCall();
		CloseHandle(hGameConf);
	}

	if (hSwitch != INVALID_HANDLE) {
		SDKCall(hSwitch, client, bot);
	}

	else {
		PrintToChatAll("[ABM] TakeOverZombieBotSig Signature broken.");
		DebugToFile(0, "[ABM] TakeOverZombieBotSig Signature broken.");
	}
}

// ================================================================== //
// PUBLIC INTERFACE AND MENU HANDLERS
// ================================================================== //

public Action TeleportClientCmd(int client, args) {
	DebugToFile(1, "TeleportClientCmd: %d", client);

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
	DebugToFile(1, "TeleportClientHandler: %d %d", client, level);

	Menu menu = new Menu(GenericMenuHandler);
	if (!RegMenuHandler(client, "TeleportClientHandler", level, 0)) {
		return;
	}

	switch(level) {
		case 0: TeamMatesMenu(client, menu, "Teleport Client", 2, 1);
		case 1: {
			GetClientName(menuArg0, g_sB, sizeof(g_sB));
			Format(g_sB, sizeof(g_sB), "%s: Teleporting", g_sB);
			TeamMatesMenu(client, menu, g_sB, 2, 1);
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
	DebugToFile(1, "SwitchTeamCmd: %d", client);

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

	SwitchTeamHandler(client, level);
	return Plugin_Handled;
}

public SwitchTeamHandler(int client, int level) {
	DebugToFile(1, "SwitchTeamHandler: %d %d", client, level);

	Menu menu = new Menu(GenericMenuHandler);
	if (!RegMenuHandler(client, "SwitchTeamHandler", level, 0)) {
		return;
	}

	switch(level) {
		case 0: TeamMatesMenu(client, menu, "Switch Client's Team", 1);
		case 1: {
			GetClientName(menuArg0, g_sB, sizeof(g_sB));
			Format(g_sB, sizeof(g_sB), "%s: Switching", g_sB);
			TeamsMenu(client, menu, g_sB);
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
	DebugToFile(1, "AssignModelCmd: %d", client);

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
	DebugToFile(1, "AssignModelHandler: %d %d", client, level);

	Menu menu = new Menu(GenericMenuHandler);
	if (!RegMenuHandler(client, "AssignModelHandler", level, 0)) {
		return;
	}

	switch(level) {
		case 0: TeamMatesMenu(client, menu, "Change Client's Model", 2, 0, false);
		case 1: {
			GetClientName(menuArg0, g_sB, sizeof(g_sB));
			Format(g_sB, sizeof(g_sB), "%s: Modeling", g_sB);
			ModelsMenu(client, menu, g_sB);
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
	DebugToFile(1, "SwitchToBotCmd: %d", client);

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
	DebugToFile(1, "SwitchToBotHandler: %d %d", client, level);

	int homeTeam = ClientHomeTeam(client);
	Menu menu = new Menu(GenericMenuHandler);
	if (!RegMenuHandler(client, "SwitchToBotHandler", level, 0)) {
		return;
	}

	switch(level) {
		case 0: TeamMatesMenu(client, menu, "Takeover Bot", 1);
		case 1: {
			GetClientName(menuArg0, g_sB, sizeof(g_sB));
			Format(g_sB, sizeof(g_sB), "%s: Takeover", g_sB);
			TeamMatesMenu(client, menu, g_sB, 0, 0, true, false, homeTeam);
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
	DebugToFile(1, "RespawnClientCmd: %d", client);

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
	DebugToFile(1, "RespawnClientHandler: %d %d", client, level);

	Menu menu = new Menu(GenericMenuHandler);
	if (!RegMenuHandler(client, "RespawnClientHandler", level, 0)) {
		return;
	}

	switch(level) {
		case 0: TeamMatesMenu(client, menu, "Respawn Client");
		case 1: {
			GetClientName(menuArg0, g_sB, sizeof(g_sB));
			Format(g_sB, sizeof(g_sB), "%s: Respawning", g_sB);
			TeamMatesMenu(client, menu, g_sB);
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
	DebugToFile(1, "CycleBotsCmd: %d", client);

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
	DebugToFile(1, "CycleBotsHandler: %d %d", client, level);

	Menu menu = new Menu(GenericMenuHandler);
	if (!RegMenuHandler(client, "CycleBotsHandler", level, 0)) {
		return;
	}

	switch(level) {
		case 0: TeamMatesMenu(client, menu, "Cycle Client", 1);
		case 1: {
			GetClientName(menuArg0, g_sB, sizeof(g_sB));
			Format(g_sB, sizeof(g_sB), "%s: Cycling", g_sB);
			TeamsMenu(client, menu, g_sB, false);
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
	DebugToFile(1, "StripClientCmd: %d", client);

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
	DebugToFile(1, "StripClientHandler: %d %d", client, level);

	Menu menu = new Menu(GenericMenuHandler);
	if (!RegMenuHandler(client, "StripClientHandler", level, 0)) {
		return;
	}

	switch(level) {
		case 0: TeamMatesMenu(client, menu, "Strip Client", 2, 1);
		case 1: {
			GetClientName(menuArg0, g_sB, sizeof(g_sB));
			Format(g_sB, sizeof(g_sB), "%s: Stripping", g_sB);
			InvSlotsMenu(client, menuArg0, menu, g_sB);
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
	DebugToFile(1, "ResetCmd: %d", client);
	GenericMenuCleaner(client);
}

bool RegMenuHandler(int client, char [] handler, int level, int clearance=0) {
	DebugToFile(1, "RegMenuHandler: %d %s %d %d", client, handler, level, clearance);

	g_callBacks.PushString(handler);
	if (!IsAdmin(client) && level <= clearance) {
		GenericMenuCleaner(client);
		return false;
	}

	return true;
}

public Action MainMenuCmd(int client, args) {
	DebugToFile(1, "MainMenuCmd: %d", client);

	GenericMenuCleaner(client);
	MainMenuHandler(client, 0);
	return Plugin_Handled;
}

public MainMenuHandler(int client, int level) {
	DebugToFile(1, "MainMenuHandler: %d %d", client, level);

	Menu menu = new Menu(GenericMenuHandler);
	if (!RegMenuHandler(client, "MainMenuHandler", level, 0)) {
		return;
	}

	int cmd = menuArg0;
	menuArg0 = 0;

	char title[32];
	Format(title, sizeof(title), "ABM Menu %s", PLUGIN_VERSION);

	switch(level) {
		case 0: MainMenu(client, menu, title);
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
	DebugToFile(1, "GenericMenuCleaner: %d %d", client, clearStack);

	for (int i = 0 ; i < sizeof(g_menuItems[]) ; i++) {
		g_menuItems[client][i] = 0;
	}

	if (clearStack == true && !g_callBacks.Empty) {
		CloseHandle(g_callBacks);
		g_callBacks = new ArrayStack(128);
	}
}

public GenericMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
	DebugToFile(1, "GenericMenuHandler: %d %d", param1, param2);

	int client = param1;
	int i = -1;
	char sB[128];

	if (IsClientValid(param1)) {
		for (i = 0 ; i < sizeof(g_menuItems[]) ; i++) {
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

	if (g_callBacks.Empty) {
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

MainMenu(int client, Menu menu,  char [] title) {
	DebugToFile(1, "MainMenu: %d %s", client, title);

	menu.SetTitle(title);
	menu.AddItem("0", "Teleport Client");  // "Telespiznat");	// teleport
	menu.AddItem("1", "Switch Client Team");  //"Swintootle");	// switch team
	menu.AddItem("2", "Change Client Model");  //"Changdangle");	// makeover
	menu.AddItem("3", "Switch Client Bot");  //"Inbosnachup");	// takeover
	menu.AddItem("4", "Respawn Client");  //"Respiggle");		// respawn
	menu.AddItem("5", "Cycle Client");  //"Cycolicoo");		// cycle
	menu.AddItem("6", "Strip Client");  //"Upsticky");		// strip
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, 120);
}

InvSlotsMenu(int client, int target, Menu menu,  char [] title) {
	DebugToFile(1, "InvSlotsMenu: %d %d %s", client, target, title);

	int ent;
	char weapon[64];
	menu.SetTitle(title);

	for (new i = 0 ; i < 5 ; i++) {
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

ModelsMenu(int client, Menu menu,  char [] title) {
	DebugToFile(1, "ModelsMenu: %d %s", client, title);

	menu.SetTitle(title);

	for (new i = 0 ; i < sizeof(g_SurvivorNames) ; i++) {
		IntToString(i, g_sB, sizeof(g_sB));
		menu.AddItem(g_sB, g_SurvivorNames[i]);
	}

	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, 120);
}

TeamsMenu(int client, Menu menu,  char [] title, bool all=true) {
	DebugToFile(1, "TeamsMenu: %d %s", client, title);

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

TeamMatesMenu(int client, Menu menu,  char [] title, int mtype=2, int target=0, bool incDead=true,
			  bool repeat=false, int homeTeam=0) {
	DebugToFile(1, "TeamMatesMenu: %d %s %d %d %d %d", client, title, mtype, target, incDead, repeat);

	menu.SetTitle(title);
	int isAdmin = IsAdmin(client);
	char health[32];
	bool mflag = false;
	int isAlive;
	int playClient;
	int bossClient;
	int targetClient;
	int manager;

	for (int i = 1 ; i <= MaxClients ; i++) {
		bossClient = i;
		playClient = i;

		if (GetQRecord(i)) {

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

DebugToFile(int level, char [] format, any ...) {
	if (g_LogLevel >= level) {
		VFormat(g_dB, sizeof(g_dB), format, 3);
		LogToFile(LOGFILE, g_dB);
		PrintToServer("%s", g_dB);
	}
}

QDBCheckCmd(client) {
	DebugToFile(1, "QDBCheckCmd");

	PrintToConsole(client, "-- STAT: QDB Size is %d", g_QDB.Size);
	PrintToConsole(client, "-- MinPlayers is %d", g_MinPlayers);

	for (int i = 1 ; i <= MaxClients ; i++) {
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
			PrintToConsole(client, " - PrevId: %d", g_lastid);
			PrintToConsole(client, " - OnTeam: %d", g_onteam);
			PrintToConsole(client, " - Queued: %d", g_queued);

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
	DebugToFile(1, "QuickClientPrintCmd: %d", client);

	int onteam;
	int state;
	int manager;

	PrintToConsole(client, "\nTeam\tState\tId\tManager\tName");

	for (int i = 1 ; i <= MaxClients ; i++) {
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
