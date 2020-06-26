#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Rebel"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

bool g_bIsRebel[MAXPLAYERS + 1];
int g_iGlowEntity[MAXPLAYERS + 1];
Handle g_hRebelHud;

public APLRes AskPluginLoad2(Handle myself, bool late, char [] error, int err_max)
{
	CreateNative("JB_AddRebel", AddRebel);
	CreateNative("JB_RemoveRebel", RemoveRebel);
	CreateNative("JB_IsRebel", IsRebel);
}

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
	
	g_hRebelHud = CreateHudSynchronizer();
	CreateTimer(1.0, UpdateRebelHudTimer, _, TIMER_REPEAT);
}

public void OnClientDisconnect_Post(int iClient)
{
	g_bIsRebel[iClient] = false;
}

public Action RoundEndEvent(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bIsRebel[i] = false;
	}
	
	return Plugin_Continue;
}

public Action PlayerDeathEvent(Event event, const char[] name, bool dontBroadcast)
{
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	int iKiller = GetClientOfUserId(event.GetInt("attacker"));
	
	if(GetClientTeam(iVictim) == CS_TEAM_CT && GetClientTeam(iKiller) == CS_TEAM_T)
		JB_AddRebel(iKiller);
	else if(GetClientTeam(iVictim) == CS_TEAM_T && JB_IsRebel(iVictim))
		JB_RemoveRebel(iVictim);
		
	return Plugin_Continue;
}

public Action UpdateRebelHudTimer(Handle timer)
{
	char format[MAX_TEXT_LENGTH] = "[Buntownicy]";
	int rebelsCount = 0;
	char szClientName[MAX_TEXT_LENGTH];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!g_bIsRebel[i])
			continue;
			
		rebelsCount++;
		GetClientName(i, szClientName, sizeof(szClientName));
		Format(format, sizeof(format), "%s\n%s", format, szClientName);
	}
	
	if(rebelsCount < 1)
		return Plugin_Continue;
	
	SetHudTextParams(0.6, 0.05, 1.1, 255, 255, 110, 0);
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsUserValid(i))
			continue;
		
		ShowSyncHudText(i, g_hRebelHud, format);
	}
	
	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////
////////////////////////// NATIVES //////////////////////////
/////////////////////////////////////////////////////////////

public int AddRebel(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	
	g_bIsRebel[iClient] = true;
	g_iGlowEntity[iClient] = RenderDynamicGlow(iClient, "255 0 0");
}

public int RemoveRebel(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	
	g_bIsRebel[iClient] = false;
	RemoveDynamicGlow(g_iGlowEntity[iClient]);
}

public int IsRebel(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	return g_bIsRebel[iClient];
}