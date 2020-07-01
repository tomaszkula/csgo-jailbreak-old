#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Warm Up"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

#define GODMODE_TIME 60

int g_iGodModeTime;
bool g_bGodMode;
Handle g_hGodModeTimer;

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char [] error, int err_max)
{
	CreateNative("JB_GetGodModeTime", GetGodModeTime);
}

public void OnDayMode(int iOldDayMode, int iNewDayMode)
{
	if(iOldDayMode == WARM_UP)
	{
		SetGodMode(false);
		
		UnhookEvent("player_spawn", PlayerSpawnEvent);
	}
	
	if(iNewDayMode == WARM_UP)
	{
		SetGodMode(true);
		
		HookEvent("player_spawn", PlayerSpawnEvent);
	}
}

public Action PlayerSpawnEvent(Event event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	SetGodModeClient(iClient, g_bGodMode)
	
	return Plugin_Continue;
}

public Action GodModeTimer(Handle timer)
{
	if(--g_iGodModeTime <= 0)
	{
		KillTimer(g_hGodModeTimer);
		g_hGodModeTimer = INVALID_HANDLE;
		
		SetGodMode(false);
	}
	
	return Plugin_Continue;
}

void SetGodMode(bool bGodMode)
{
	if(bGodMode == g_bGodMode)
		return;
	
	g_bGodMode = bGodMode;
	for (int i = 1; i <= MAXPLAYERS; i++)
	{
		if(!IsUserValid(i) || !IsPlayerAlive(i))
			continue;
		
		SetGodModeClient(i, bGodMode);
	}
	
	if(bGodMode)
	{
		g_iGodModeTime = GODMODE_TIME;
		g_hGodModeTimer = CreateTimer(1.0, GodModeTimer, _, TIMER_REPEAT);
	}
	else
	{
		if(g_hGodModeTimer != INVALID_HANDLE)
		{
			KillTimer(g_hGodModeTimer);
			g_hGodModeTimer = INVALID_HANDLE;
		}
	}
}

void SetGodModeClient(int iClient, bool bGodMode)
{
	SetEntProp(iClient, Prop_Data, "m_takedamage", bGodMode ? 0 : 2, 1);
}

/////////////////////////////////////////////////////////////
////////////////////////// NATIVES //////////////////////////
/////////////////////////////////////////////////////////////

public int GetGodModeTime(Handle plugin, int argc)
{
	return g_iGodModeTime;
}
