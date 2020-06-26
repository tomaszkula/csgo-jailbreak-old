#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Currency"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

#define CURRENCY "$"
#define MONEY_PER_ROUND 20

Handle g_hMoneyHud;
int g_iMoney[MAXPLAYERS + 1];

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
	HookEvent("round_start", RoundStartEvent);
	
	g_hMoneyHud = CreateHudSynchronizer();
	CreateTimer(1.0, UpdateMoneyHudTimer, _, TIMER_REPEAT);
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
		g_iMoney[i] = MONEY_PER_ROUND;
}

public Action RoundStartEvent(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsUserValid(i))
			continue;
		
		g_iMoney[i] += MONEY_PER_ROUND;
	}
	
	return Plugin_Continue;
}

public Action UpdateMoneyHudTimer(Handle timer)
{
	SetHudTextParams(0.25, 0.96, 1.1, 255, 255, 110, 0);
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsUserValid(i))
			continue;
		
		ShowSyncHudText(i, g_hMoneyHud, "%i %s", g_iMoney[i], CURRENCY);
	}
}