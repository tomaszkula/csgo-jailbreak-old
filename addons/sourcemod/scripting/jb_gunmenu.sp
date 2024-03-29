#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Gun Menu"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

#define GUN_1 "weapon_ak47"
#define GUN_2 "weapon_m4a1_silencer"
#define GUN_3 "weapon_m4a1"
#define GUN_4 "weapon_awp"
#define GUN_5 "weapon_galilar"
#define GUN_6 "weapon_famas"

bool g_bIsBlocked = true, g_bGun[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("bronie", GunsMenuCmd);
	RegConsoleCmd("guns", GunsMenuCmd);
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
		g_bGun[i] = false;
}

public void OnDayMode(int iOldDayMode, int iNewDayMode)
{
	if(iOldDayMode == WARM_UP || iOldDayMode == NORMAL)
	{
		g_bIsBlocked = true;
		for (int i = 1; i <= MaxClients; i++)
			g_bGun[i] = false;
		
		UnhookEvent("round_prestart", RoundPrestartEvent);
		UnhookEvent("player_team", PlayerTeamEvent);
		UnhookEvent("player_spawn", PlayerSpawnEvent);
		UnhookEvent("player_death", PlayerDeathEvent);
	}
	
	if(iNewDayMode == WARM_UP || iNewDayMode == NORMAL)
	{
		g_bIsBlocked = false;
		
		HookEvent("round_prestart", RoundPrestartEvent);
		HookEvent("player_team", PlayerTeamEvent);
		HookEvent("player_spawn", PlayerSpawnEvent);
		HookEvent("player_death", PlayerDeathEvent);
	}
}

public Action RoundPrestartEvent(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
		g_bGun[i] = false;
	
	return Plugin_Continue;
}

public Action PlayerTeamEvent(Event event, const char[] name, bool dontBroadcast)
{
	bool disconnected = event.GetBool("disconnect");
	if(disconnected)
	{
		int iClient = GetClientOfUserId(event.GetInt("userid"));
		g_bGun[iClient] = false;
	}
	
	return Plugin_Continue;
}

public Action PlayerSpawnEvent(Event event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	if(GetClientTeam(iClient) == CS_TEAM_CT)
	{
		g_bGun[iClient] = true;
		DisplayGunsMenu(iClient);
	}
	
	return Plugin_Continue;
}

public Action PlayerDeathEvent(Event event, const char[] name, bool dontBroadcast)
{
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	g_bGun[iVictim] = false;
		
	return Plugin_Continue;
}

public Action GunsMenuCmd(int iClient, int args)
{
	if(g_bIsBlocked || !IsUserValid(iClient) || !IsPlayerAlive(iClient) || GetClientTeam(iClient) != CS_TEAM_CT || !g_bGun[iClient])
		return Plugin_Continue;
	
	DisplayGunsMenu(iClient);
	return Plugin_Handled;
}


public void DisplayGunsMenu(int iClient)
{
	if(g_bIsBlocked || !IsUserValid(iClient) || !IsPlayerAlive(iClient) || GetClientTeam(iClient) != CS_TEAM_CT || !g_bGun[iClient])
		return;
	
	Menu menu = CreateMenu(GunsMenuHandler);
	menu.AddItem(GUN_1, "AK-47");
	menu.AddItem(GUN_2, "M4A1-S");
	menu.AddItem(GUN_3, "M4A4");
	menu.AddItem(GUN_4, "AWP");
	menu.AddItem(GUN_5, "Galil AR");
	menu.AddItem(GUN_6, "Famas");
	menu.SetTitle("[Menu] Wybierz broń");
	menu.Display(iClient, MENU_TIME_FOREVER);
}

public int GunsMenuHandler(Menu menu, MenuAction action, int iClient, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(g_bIsBlocked || !IsUserValid(iClient) || !IsPlayerAlive(iClient) || GetClientTeam(iClient) != CS_TEAM_CT || !g_bGun[iClient])
				return -1;
				
			g_bGun[iClient] = false;
			
			char szInfo[MAX_TEXT_LENGTH];
			menu.GetItem(param2, szInfo, sizeof(szInfo));
			
			int iWeapon;
			if ((iWeapon = GetPlayerWeaponSlot(iClient, 0)) != -1)
				RemovePlayerItem(iClient, iWeapon);
			if ((iWeapon = GetPlayerWeaponSlot(iClient, 1)) != -1)
				RemovePlayerItem(iClient, iWeapon);
			
			GivePlayerItem(iClient, szInfo);
			GivePlayerItem(iClient, "weapon_deagle");
		}
		
		case MenuAction_End:
			delete menu;
	}
	
	return 0;
}