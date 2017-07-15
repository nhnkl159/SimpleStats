#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "nhnkl159"
#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <sdktools>
#include <colors>
#include <simplestats>

#define PREFIX "\x05[SimpleStats]\x01"

// === MySQL === //
Database gB_DBSQL = null;

// === Player Stats === //
int gB_PKills[MAXPLAYERS + 1] = 0;
int gB_PDeaths[MAXPLAYERS + 1] = 0;
int gB_PShots[MAXPLAYERS + 1] = 0;
int gB_PHits[MAXPLAYERS + 1] = 0;
int gB_PHS[MAXPLAYERS + 1] = 0;
int gB_PAssists[MAXPLAYERS + 1] = 0;
int gB_PlayTime[MAXPLAYERS + 1] = 0;

int gB_RemoveClient[MAXPLAYERS + 1];

// === ConVars === //
ConVar gB_PluginEnabled;
ConVar gB_MinimumPlayers;
ConVar gB_WarmUP;
ConVar gB_CountKnife;

public Plugin myinfo = 
{
	name = "[CS:GO / ?] Simple Stats", 
	author = PLUGIN_AUTHOR, 
	description = "Realy simple stats plugin.", 
	version = PLUGIN_VERSION, 
	url = "keepomod.com"
};

public void OnPluginStart()
{
	// === Admin Commands === //
	RegAdminCmd("sm_ssreset", Cmd_ResetPlayer, ADMFLAG_ROOT, "Command for flag z to reset player stats");
	
	// === Player Commands === //
	RegConsoleCmd("sm_stats", Cmd_Stats, "Command for client to open menu with his stats.");
	
	// === Events === //
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("player_hurt", Event_PlayerHurt);
	
	// === ConVars && More === //
	gB_PluginEnabled = CreateConVar("sm_ss_enabled", "1", "Sets whether or not to record stats");
	gB_MinimumPlayers = CreateConVar("sm_ss_minplayers", "4", "Minimum players to start record stats");
	gB_WarmUP = CreateConVar("sm_ss_warmup", "1", "Record stats while we are in warmup ?");
	gB_CountKnife = CreateConVar("sm_ss_countknife", "1", "Record knife as shot when client slash ?");
	
	
	SQL_StartConnection();
	
	AutoExecConfig(true, "sm_simplestats");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("SS_GetKillsAmount", Native_GetKillsAmount);
	CreateNative("SS_GetDeathsAmount", Native_GetDeathsAmount);
	CreateNative("SS_GetShotsAmount", Native_GetShotsAmount);
	CreateNative("SS_GetHitsAmount", Native_GetHitsAmount);
	CreateNative("SS_GetHeadshotsAmount", Native_GetHSAmount);
	CreateNative("SS_GetAssistsAmount", Native_GetAssistsAmount);
	CreateNative("SS_GetPlayTimeAmount", Native_GetPlayTimeAmount);
	
	RegPluginLibrary("simplestats");
	
	if (late)
	{
		for (int i = 0; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				OnClientPutInServer(i);
			}
		}
	}
	
	return APLRes_Success;
}

public void OnClientPutInServer(int client)
{
	if (!IsValidClient(client))
	{
		return;
	}
	
	if (!gB_PluginEnabled.BoolValue)
	{
		return;
	}
	
	if (gB_DBSQL == null)
	{
		return;
	}
	
	// Player Stuff
	gB_PKills[client] = 0;
	gB_PDeaths[client] = 0;
	gB_PShots[client] = 0;
	gB_PHits[client] = 0;
	gB_PHS[client] = 0;
	gB_PAssists[client] = 0;
	gB_PlayTime[client] = 0;
	
	char gB_PlayerName[MAX_NAME_LENGTH];
	GetClientName(client, gB_PlayerName, MAX_NAME_LENGTH);
	
	char gB_SteamID64[17];
	if (!GetClientAuthId(client, AuthId_SteamID64, gB_SteamID64, 17))
	{
		KickClient(client, "Verification problem , please reconnect.");
		return;
	}
	
	//escaping name , dynamic array;
	int iLength = ((strlen(gB_PlayerName) * 2) + 1);
	char[] gB_EscapedName = new char[iLength];
	gB_DBSQL.Escape(gB_PlayerName, gB_EscapedName, iLength);
	
	char gB_ClientIP[64];
	GetClientIP(client, gB_ClientIP, 64);
	
	char gB_Query[512];
	FormatEx(gB_Query, 512, "INSERT INTO `players` (`steamid`, `name`, `ip`, `lastconn`) VALUES ('%s', '%s', '%s', CURRENT_TIMESTAMP()) ON DUPLICATE KEY UPDATE `name` = '%s', `ip` = '%s', `lastconn` = CURRENT_TIMESTAMP();", gB_SteamID64, gB_EscapedName, gB_ClientIP, gB_EscapedName, gB_ClientIP);
	gB_DBSQL.Query(SQL_InsertPlayer_Callback, gB_Query, GetClientSerial(client), DBPrio_Normal);
}

public void OnClientDisconnect(int client)
{
	if (!IsValidClient(client))
	{
		return;
	}
	
	if (!gB_PluginEnabled.BoolValue)
	{
		return;
	}
	
	if (gB_DBSQL == null)
	{
		return;
	}
	
	FuckingUpdateThatSHITHeadPlayer(client, GetClientTime(client));
}

public Action Cmd_Stats(int client, int args)
{
	if (!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	if (!gB_PluginEnabled.BoolValue)
	{
		return Plugin_Handled;
	}
	
	char gB_SteamID64[17];
	GetClientAuthId(client, AuthId_SteamID64, gB_SteamID64, 17);
	
	OpenStatsMenu(client, client);
	
	return Plugin_Handled;
}

void OpenStatsMenu(int client, int displayto)
{
	Menu menu = new Menu(Stats_MenuHandler);
	
	char gB_PlayerName[MAX_NAME_LENGTH];
	GetClientName(client, gB_PlayerName, MAX_NAME_LENGTH);
	char gB_Title[32];
	FormatEx(gB_Title, 32, "%s's stats :", gB_PlayerName);
	menu.SetTitle(gB_Title);
	
	char gH_Kills[128], gH_Deaths[128], gH_Shots[128], gH_Hits[128], gH_HS[128], gH_Assists[128], gH_PlayTime[258], gH_PlayTime2[128];
	int gB_Seconds = RoundToZero(GetClientTime(client));
	int CurrentTime = gB_Seconds + gB_PlayTime[client];
	SecondsToTime(CurrentTime, gH_PlayTime2);
	
	int gB_Accuracy = 0;
	if (gB_PHits[client] != 0 && gB_PShots[client] != 0)
	{
		gB_Accuracy = (100 * gB_PHits[client] + gB_PShots[client] / 2) / gB_PShots[client];
	}
	
	int gB_HSP = 0;
	if (gB_PHits[client] != 0 && gB_PHS[client] != 0)
	{
		gB_HSP = (100 * gB_PHits[client] + gB_PHS[client] / 2) / gB_PHS[client];
	}
	
	FormatEx(gH_Kills, 128, "Your total kills : %d", gB_PKills[client]);
	FormatEx(gH_Deaths, 128, "Your total deaths : %d", gB_PDeaths[client]);
	FormatEx(gH_Shots, 128, "Your total shots : %d", gB_PShots[client]);
	FormatEx(gH_Hits, 128, "Your total hits : %d (Accuracy : %d%%%)", gB_PHits[client], gB_Accuracy);
	FormatEx(gH_HS, 128, "Your total headshots : %d (HS Percent : %d%%%)", gB_PHS[client], gB_HSP);
	FormatEx(gH_Assists, 128, "Your total assists : %d", gB_PAssists[client]);
	FormatEx(gH_PlayTime, 128, "Play time : %s", gH_PlayTime2);
	
	menu.AddItem("", gH_Kills, ITEMDRAW_DISABLED);
	menu.AddItem("", gH_Deaths, ITEMDRAW_DISABLED);
	menu.AddItem("", gH_Shots, ITEMDRAW_DISABLED);
	menu.AddItem("", gH_Hits, ITEMDRAW_DISABLED);
	menu.AddItem("", gH_HS, ITEMDRAW_DISABLED);
	menu.AddItem("", gH_Assists, ITEMDRAW_DISABLED);
	menu.AddItem("", gH_PlayTime, ITEMDRAW_DISABLED);
	
	menu.ExitButton = true;
	menu.Display(displayto, 30);
}

public int Stats_MenuHandler(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	return 0;
}

public Action Cmd_ResetPlayer(int client, int args)
{
	if (!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	if (!gB_PluginEnabled.BoolValue)
	{
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		CPrintToChat(client, "%s Usage : sm_ssreset <target>", PREFIX);
		return Plugin_Handled;
	}
	
	char arg1[MAX_TARGET_LENGTH];
	GetCmdArg(1, arg1, MAX_TARGET_LENGTH);
	
	int target = FindTarget(client, arg1, false, false);
	
	if (target == -1)
	{
		CPrintToChat(client, "%s Cant find target with this specific name , try to add more letters.", PREFIX);
		return Plugin_Handled;
	}
	
	gB_RemoveClient[client] = GetClientSerial(target);
	
	Menu menu = new Menu(AreYouSureHandler);
	char gB_PlayerName[MAX_NAME_LENGTH];
	GetClientName(target, gB_PlayerName, MAX_NAME_LENGTH);
	char gB_Title[32];
	FormatEx(gB_Title, 32, "Reset %s's stats ?", gB_PlayerName);
	menu.SetTitle(gB_Title);
	menu.AddItem("yes", "Yes");
	menu.AddItem("no", "No");
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int AreYouSureHandler(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(item, info, 32);
		
		if (StrEqual(info, "yes"))
		{
			int target = GetClientFromSerial(gB_RemoveClient[client]);
			
			char gB_SteamID64[17];
			GetClientAuthId(target, AuthId_SteamID64, gB_SteamID64, 17);
			char gB_Query[512];
			FormatEx(gB_Query, 512, "DELETE FROM `players` WHERE `steamid` = '%s'", gB_SteamID64);
			gB_DBSQL.Query(SQL_RemovePlayer_Callback, gB_Query, GetClientSerial(client), DBPrio_Normal);
		}
	}
	if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public void SQL_RemovePlayer_Callback(Database db, DBResultSet results, const char[] error, any data)
{
	int client = GetClientFromSerial(data);
	if (results == null)
	{
		if (client == 0)
		{
			LogError("[SS] Client is not valid. Reason: %s", error);
		}
		else
		{
			LogError("[SS] Cant use client data. Reason: %s", GetClientFromSerial(gB_RemoveClient[client]), error);
		}
		return;
	}
	
	CPrintToChat(client, "%s You have been restarted \x07%N's\x01 stats.", PREFIX, GetClientFromSerial(gB_RemoveClient[client]));
	OnClientPutInServer(GetClientFromSerial(gB_RemoveClient[client]));
	gB_RemoveClient[client] = 0;
}

public void SQL_InsertPlayer_Callback(Database db, DBResultSet results, const char[] error, any data)
{
	int client = GetClientFromSerial(data);
	if (results == null)
	{
		if (client == 0)
		{
			LogError("[SS] Client is not valid. Reason: %s", error);
		}
		else
		{
			LogError("[SS] Cant use client data. Reason: %s", client, error);
		}
		return;
	}
	
	char gB_SteamID64[17];
	GetClientAuthId(client, AuthId_SteamID64, gB_SteamID64, 17);
	
	char gB_Query[512];
	FormatEx(gB_Query, 512, "SELECT kills, deaths, shots, hits, headshots, assists, secsonserver FROM `players` WHERE `steamid` = '%s'", gB_SteamID64);
	gB_DBSQL.Query(SQL_SelectPlayer_Callback, gB_Query, GetClientSerial(client), DBPrio_Normal);
}

public void SQL_SelectPlayer_Callback(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		LogError("[SS] Selecting player error. Reason: %s", error);
		return;
	}
	
	int client = GetClientFromSerial(data);
	if (client == 0)
	{
		LogError("[SS] Client is not valid. Reason: %s", error);
		return;
	}
	
	while (results.FetchRow())
	{
		gB_PKills[client] = results.FetchInt(0);
		gB_PDeaths[client] = results.FetchInt(1);
		gB_PShots[client] = results.FetchInt(2);
		gB_PHits[client] = results.FetchInt(3);
		gB_PHS[client] = results.FetchInt(4);
		gB_PAssists[client] = results.FetchInt(5);
		gB_PlayTime[client] = results.FetchInt(6);
	}
}

public void Event_RoundEnd(Event e, const char[] name, bool dontBroadcast)
{
	if (!gB_PluginEnabled.BoolValue)
	{
		return;
	}
	
	if (gB_DBSQL == null)
	{
		return;
	}
	
	for (int i = 0; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			FuckingUpdateThatSHITHeadPlayer(i, GetClientTime(i));
		}
	}
}

public void Event_PlayerDeath(Event e, const char[] name, bool dontBroadcast)
{
	if (!gB_PluginEnabled.BoolValue)
	{
		return;
	}
	
	if (gB_DBSQL == null)
	{
		return;
	}
	
	if(GetPlayersCount() < gB_MinimumPlayers.IntValue)
	{
		return;
	}
	
	if(InWarmUP() && !gB_WarmUP.BoolValue)
	{
		return;
	}
	
	//Check shit
	int client = GetClientOfUserId(GetEventInt(e, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(e, "attacker"));
	bool headshot = GetEventBool(e, "headshot");
	int assister = GetClientOfUserId(GetEventInt(e, "assister"));
	
	if (!IsValidClient(client) || !IsValidClient(attacker))
	{
		return;
	}
	
	if (attacker == client)
	{
		return;
	}
	
	//Player Stats//
	gB_PKills[attacker]++;
	gB_PDeaths[client]++;
	if (headshot)
		gB_PHS[attacker]++;
	
	if (assister)
		gB_PAssists[assister]++;
}

public void Event_WeaponFire(Event e, const char[] name, bool dontBroadcast)
{
	if (!gB_PluginEnabled.BoolValue)
	{
		return;
	}
	if (gB_DBSQL == null)
	{
		return;
	}
	
	if(GetPlayersCount() < gB_MinimumPlayers.IntValue)
	{
		return;
	}
	
	if(InWarmUP() && !gB_WarmUP.BoolValue)
	{
		return;
	}
	
	char FiredWeapon[32];
	GetEventString(e, "weapon", FiredWeapon, sizeof(FiredWeapon));
	
	if (StrEqual(FiredWeapon, "hegrenade") || StrEqual(FiredWeapon, "flashbang") || StrEqual(FiredWeapon, "smokegrenade") || StrEqual(FiredWeapon, "molotov") || StrEqual(FiredWeapon, "incgrenade") || StrEqual(FiredWeapon, "decoy"))
	{
		return;
	}
	
	if(!gB_CountKnife.BoolValue && StrEqual(FiredWeapon, "weapon_knife"))
	{
		return;
	}
	
	//Check shit
	int client = GetClientOfUserId(GetEventInt(e, "userid"));
	if (!IsValidClient(client))
	{
		return;
	}
	
	//Player Stats//
	gB_PShots[client]++;
}

public void Event_PlayerHurt(Event e, const char[] name, bool dontBroadcast)
{
	if (!gB_PluginEnabled.BoolValue)
	{
		return;
	}
	
	if (gB_DBSQL == null)
	{
		return;
	}
	
	if(GetPlayersCount() < gB_MinimumPlayers.IntValue)
	{
		return;
	}
	
	if(InWarmUP() && !gB_WarmUP.BoolValue)
	{
		return;
	}
	
	//Check shit
	int client = GetClientOfUserId(GetEventInt(e, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(e, "attacker"));
	
	if (!IsValidClient(client) || !IsValidClient(attacker))
	{
		return;
	}
	
	int gB_ClientTeam = GetClientTeam(client);
	int gB_AttackerTeam = GetClientTeam(attacker);
	
	if (gB_ClientTeam != gB_AttackerTeam)
	{
		//Player Stats//
		gB_PHits[attacker]++;
	}
}

void FuckingUpdateThatSHITHeadPlayer(int client, float timeonserver)
{
	if (!gB_PluginEnabled.BoolValue)
	{
		return;
	}
	if (gB_DBSQL == null)
	{
		return;
	}
	
	char gB_SteamID64[17];
	GetClientAuthId(client, AuthId_SteamID64, gB_SteamID64, 17);
	
	
	int gB_Seconds = RoundToZero(timeonserver);
	
	char gB_Query[512];
	FormatEx(gB_Query, 512, "UPDATE `players` SET `kills`= %d,`deaths`= %d,`shots`= %d,`hits`= %d,`headshots`= %d,`assists`= %d, `secsonserver` = secsonserver + %d WHERE `steamid` = '%s';", gB_PKills[client], gB_PDeaths[client], gB_PShots[client], gB_PHits[client], gB_PHS[client], gB_PAssists[client], gB_Seconds, gB_SteamID64);
	gB_DBSQL.Query(SQL_UpdatePlayer_Callback, gB_Query, GetClientSerial(client), DBPrio_Normal);
}

public void SQL_UpdatePlayer_Callback(Database db, DBResultSet results, const char[] error, any data)
{
	int client = GetClientFromSerial(data);
	if (results == null)
	{
		if (client == 0)
		{
			LogError("[SS] Client is not valid. Reason: %s", error);
		}
		else
		{
			LogError("[SS] Cant use client data. Reason: %s", client, error);
		}
		return;
	}
}

void SQL_StartConnection()
{
	if (!gB_PluginEnabled.BoolValue)
	{
		return;
	}
	if (gB_DBSQL != null)
	{
		delete gB_DBSQL;
	}
	
	char gB_Error[255];
	if (SQL_CheckConfig("simplestats"))
	{
		gB_DBSQL = SQL_Connect("simplestats", true, gB_Error, 255);
		
		if (gB_DBSQL == null)
		{
			SetFailState("[SS] Error on start. Reason: %s", gB_Error);
		}
	}
	else
	{
		SetFailState("[SS] Cant find `simplestats` on database.cfg");
	}
	
	gB_DBSQL.SetCharset("utf8");
	
	char gB_Query[512];
	FormatEx(gB_Query, 512, "CREATE TABLE IF NOT EXISTS `players` (`steamid` VARCHAR(17) NOT NULL, `name` VARCHAR(32), `ip` VARCHAR(64), `kills` INT(11) NOT NULL, `deaths` INT(11) NOT NULL, `shots` INT(11) NOT NULL, `hits` INT(11) NOT NULL, `headshots` INT(11) NOT NULL, `assists` INT(11) NOT NULL, `secsonserver` INT(20) NOT NULL, `lastconn` INT(32) NOT NULL, PRIMARY KEY (`steamid`))");
	if (!SQL_FastQuery(gB_DBSQL, gB_Query))
	{
		SQL_GetError(gB_DBSQL, gB_Error, 255);
		LogError("[SS] Cant create table. Error : %s", gB_Error);
	}
}

stock int SecondsToTime(int seconds, char[] buffer)
{
	int mins, secs;
	if (seconds >= 60)
	{
		mins = RoundToFloor(float(seconds / 60));
		seconds = seconds % 60;
	}
	secs = RoundToFloor(float(seconds));
	
	if (mins)
		Format(buffer, 70, "%s%d mins, ", buffer, mins);
	
	Format(buffer, 70, "%s%d secs", buffer, secs);
}

stock int GetPlayersCount()
{
	int count = 0;
	for (int i = 0; i < MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			count++;
		}
	}
	return count;
}


stock bool IsValidClient(int client, bool alive = false, bool bots = false)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && (alive == false || IsPlayerAlive(client)) && (bots == false && !IsFakeClient(client)))
	{
		return true;
	}
	return false;
}

public int Native_GetKillsAmount(Handle handler, int numParams)
{
	return gB_PKills[GetNativeCell(1)];
}

public int Native_GetDeathsAmount(Handle handler, int numParams)
{
	return gB_PDeaths[GetNativeCell(1)];
}

public int Native_GetShotsAmount(Handle handler, int numParams)
{
	return gB_PShots[GetNativeCell(1)];
}
public int Native_GetHitsAmount(Handle handler, int numParams)
{
	return gB_PHits[GetNativeCell(1)];
}

public int Native_GetHSAmount(Handle handler, int numParams)
{
	return gB_PHS[GetNativeCell(1)];
}

public int Native_GetAssistsAmount(Handle handler, int numParams)
{
	return gB_PAssists[GetNativeCell(1)];
}

public int Native_GetPlayTimeAmount(Handle handler, int numParams)
{
	return gB_PlayTime[GetNativeCell(1)];
}

stock bool InWarmUP() 
{
	return GameRules_GetProp("m_bWarmupPeriod") != 0;
}