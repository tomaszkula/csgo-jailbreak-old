#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Hud"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

#define FORUM_URL "forum.pl"

Handle g_hMainHud;

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
	g_hMainHud = CreateHudSynchronizer();
	CreateTimer(1.0, UpdateMainHudTimer, _, TIMER_REPEAT);
}

public Action UpdateMainHudTimer(Handle timer)
{
	char[] format = 
				"[ Forum | %s ]\n\n"
				..."[ %i Dzień | %s ]\n"
				..."[ Więźniowie | %i / %i ]\n"
				..."[ Prowadzący | %s ]";
	
	int iDay = JB_GetDay();
	char szDayName[MAX_TEXT_LENGTH];
	JB_GetDayName(iDay, szDayName);
	
	char szSimonName[MAX_TEXT_LENGTH] = "BRAK";
	if(!JB_IsSimon(0)) GetClientName(JB_GetSimon(), szSimonName, sizeof(szSimonName));
	
	SetHudTextParams(0.16, 0.05, 1.1, 255, 255, 110, 0);
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsUserValid(i))
			continue;
		
		ShowSyncHudText(i, g_hMainHud, format, FORUM_URL, iDay, szDayName, JB_GetPrisonersCount(true), JB_GetPrisonersCount(), szSimonName);
	}
	
	return Plugin_Continue;
}