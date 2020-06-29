#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"
#include "voiceannounce_ex.inc"

#define PLUGIN_NAME "[JB] Voice"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

bool g_bHasAccess[MAXPLAYERS + 1];
bool g_bVoiceStatus;

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
	HookEvent("round_end", RoundEndEvent);
	HookEvent("player_death", PlayerDeathEvent);
}

public void OnMapStart()
{
	g_bVoiceStatus = false;
	for (int i = 1; i <= MaxClients; i++)
		g_bHasAccess[i] = false;
}

public Action RoundEndEvent(Event event, const char[] name, bool dontBroadcast)
{
	g_bVoiceStatus = false;
	for (int i = 1; i <= MaxClients; i++)
		g_bHasAccess[i] = false;
	
	return Plugin_Continue;
}

public Action PlayerDeathEvent(Event event, const char[] name, bool dontBroadcast)
{
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	g_bHasAccess[iVictim] = false;
		
	return Plugin_Continue;
}

public void OnClientSpeakingEx(int iClient)
{
	if(IsPlayerAlive(iClient) && GetClientTeam(iClient) == CS_TEAM_T)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if(!IsUserValid(i) || i == iClient)
				continue;
				
			SetListenOverride(i, iClient, g_bVoiceStatus ? Listen_Yes : Listen_No);
		}
	}
}

public void OnClientDisconnect_Post(int iClient)
{
	g_bHasAccess[iClient] = false;
}

public void OnAddSimon(int iClient)
{
	g_bHasAccess[iClient] = true;
}

public void OnRemoveSimon(int iClient)
{
	g_bHasAccess[iClient] = false;
}

/////////////////////////////////////////////////////////////
////////////////////////// NATIVES //////////////////////////
/////////////////////////////////////////////////////////////

public int ChangeVoiceStatus(Handle plugin, int argc)
{
	bool bStatus = GetNativeCell(1);
	g_bVoiceStatus = bStatus;
}