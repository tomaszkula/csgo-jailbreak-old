#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Hud"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

#define FORUM_URL "forum.pl"

Handle g_hMainHud, g_hPrisonersInfoHud, g_hCurrencyHud;

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
	g_hPrisonersInfoHud = CreateHudSynchronizer();
	g_hCurrencyHud = CreateHudSynchronizer();
}

public void OnMapStart()
{
	CreateTimer(1.0, UpdateMainHudTimer, _, TIMER_REPEAT);
	CreateTimer(1.0, UpdatePrisonersInfoTimer, _, TIMER_REPEAT);
	CreateTimer(1.0, UpdateCurrencyTimer, _, TIMER_REPEAT);
}

public Action UpdateMainHudTimer(Handle timer)
{
	char[] format = 
				"[ Forum | %s ]\n\n"
				..."[ %i Dzień | %s ]\n\n"
				
				..."[ Strażnicy | %i / %i ]\n"
				..."[ Więźniowie | %i / %i ]\n"
				..."[ Prowadzący | %s ]";
	
	int iDay = JB_GetDay();
	char szDayName[MAX_TEXT_LENGTH];
	JB_GetDayName(iDay, szDayName);
	
	char szSimonName[MAX_TEXT_LENGTH] = "BRAK";
	if(!JB_IsSimon(0))
		GetClientName(JB_GetSimon(), szSimonName, sizeof(szSimonName));
	
	SetHudTextParams(0.16, 0.06, 1.1, 255, 255, 110, 0);
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsUserValid(i))
			continue;
		
		ShowSyncHudText(i, g_hMainHud, format, FORUM_URL, iDay, szDayName, JB_GetWardensCount(true), JB_GetWardensCount(), JB_GetPrisonersCount(true), JB_GetPrisonersCount(), szSimonName);
	}
	
	return Plugin_Continue;
}

public Action UpdatePrisonersInfoTimer(Handle timer)
{
	char szFormatFreeDay[MAX_TEXT_LENGTH] = "[ FreeDay'e ]", szFormatRebel[MAX_TEXT_LENGTH] = "[ Buntownicy ]", szClientName[MAX_TEXT_LENGTH];
	int iFreeDayCount = 0, iRebelCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsUserValid(i) || !IsPlayerAlive(i) || GetClientTeam(i) != CS_TEAM_T)
			continue;
			
		GetClientName(i, szClientName, sizeof(szClientName));
			
		if(JB_HasFreeDay(i))
		{
			iFreeDayCount++;
			Format(szFormatFreeDay, sizeof(szFormatFreeDay), "%s\n[%i] %s", szFormatFreeDay, JB_GetFreeDayTime(i), szClientName);
		}
		
		if(JB_IsRebel(i))
		{
			iRebelCount++;
			Format(szFormatRebel, sizeof(szFormatRebel), "%s\n%s", szFormatRebel, szClientName);
		}
	}
	
	char szFullFormat[2 * MAX_TEXT_LENGTH];
	if(iFreeDayCount < 1)
	{
		if(iRebelCount < 1)
			return Plugin_Continue;
		else
			Format(szFullFormat, sizeof(szFullFormat), "%s", szFormatRebel);
	}
	else
	{
		if(iRebelCount < 1)
			Format(szFullFormat, sizeof(szFullFormat), "%s", szFormatFreeDay);
		else
			Format(szFullFormat, sizeof(szFullFormat), "%s\n%s", szFormatFreeDay, szFormatRebel);
	}
	
	SetHudTextParams(0.5, 0.06, 1.1, 255, 255, 110, 0);
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsUserValid(i))
			continue;
		
		ShowSyncHudText(i, g_hPrisonersInfoHud, szFullFormat);
	}
	
	return Plugin_Continue;
}

public Action UpdateCurrencyTimer(Handle timer)
{
	SetHudTextParams(0.25, 0.96, 1.1, 255, 255, 110, 0);
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsUserValid(i))
			continue;
		
		ShowSyncHudText(i, g_hCurrencyHud, "%i $", JB_GetCurrency(i));
	}
	
	return Plugin_Continue;
}