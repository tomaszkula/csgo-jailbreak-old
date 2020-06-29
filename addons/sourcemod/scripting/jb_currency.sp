#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Currency"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

#define MONEY_PER_ROUND 20

int g_iMoney[MAXPLAYERS + 1];

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
	CreateNative("JB_GetCurrency", GetCurrency);
}

public void OnPluginStart()
{
	HookEvent("round_start", RoundStartEvent);
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

/////////////////////////////////////////////////////////////
////////////////////////// NATIVES //////////////////////////
/////////////////////////////////////////////////////////////

public int GetCurrency(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	return g_iMoney[iClient];
}