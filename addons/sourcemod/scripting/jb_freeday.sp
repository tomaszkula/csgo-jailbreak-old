#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] FreeDay"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

#define FREEDAY_TIME 300

GlobalForward g_OnAddFreeDayForward;
bool g_bIsBlocked = true, g_bHasFreeDay[MAXPLAYERS + 1], g_bNextRoundFreeDay[MAXPLAYERS + 1];
int g_iGlowEntity[MAXPLAYERS + 1], g_iFreeDayTime[MAXPLAYERS + 1];
Handle g_hFreeDayTimer[MAXPLAYERS + 1];

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
	CreateNative("JB_DisplayFreeDayMenu", DisplayFreeDayMenu);
	CreateNative("JB_AddFreeDay", AddFreeDay);
	CreateNative("JB_RemoveFreeDay", RemoveFreeDay);
	CreateNative("JB_HasFreeDay", HasFreeDay);
	CreateNative("JB_GetFreeDayTime", GetFreeDayTime);
}

public void OnPluginStart()
{
	g_OnAddFreeDayForward = CreateGlobalForward("OnAddFreeDay", ET_Event, Param_Cell);
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
		if(JB_HasFreeDay(i))
			JB_RemoveFreeDay(i);
}

public void OnDayMode(int iOldDayMode, int iNewDayMode)
{
	if(iOldDayMode == NORMAL)
	{
		g_bIsBlocked = true;
		for (int i = 1; i <= MaxClients; i++)
			if(JB_HasFreeDay(i))
				JB_RemoveFreeDay(i);
		
		UnhookEvent("player_connect_full", PlayerConnectFullEvent);
		UnhookEvent("round_prestart", RoundPrestartEvent);
		UnhookEvent("player_team", PlayerTeamEvent);
		UnhookEvent("player_death", PlayerDeathEvent);
	}
	
	if(iNewDayMode == NORMAL)
	{
		g_bIsBlocked = false;
		
		HookEvent("player_connect_full", PlayerConnectFullEvent);
		HookEvent("round_prestart", RoundPrestartEvent);
		HookEvent("player_team", PlayerTeamEvent);
		HookEvent("player_death", PlayerDeathEvent);
	}
}

public void OnAddRebel(int iClient)
{
	if(JB_HasFreeDay(iClient))
		JB_RemoveFreeDay(iClient);
}

public Action PlayerConnectFullEvent(Event event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamageSDKHook);
	
	return Plugin_Continue;
}

public Action RoundPrestartEvent(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
		if(JB_HasFreeDay(i))
			JB_RemoveFreeDay(i);
	
	return Plugin_Continue;
}

public Action PlayerTeamEvent(Event event, const char[] name, bool dontBroadcast)
{
	bool disconnected = event.GetBool("disconnect");
	if(disconnected)
	{
		int iClient = GetClientOfUserId(event.GetInt("userid"));
		if(JB_HasFreeDay(iClient))
			JB_RemoveFreeDay(iClient);
		
		//CheckLastFreeDay();
	}
	
	return Plugin_Continue;
}

public Action PlayerDeathEvent(Event event, const char[] name, bool dontBroadcast)
{
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	if(JB_HasFreeDay(iVictim))
		JB_RemoveFreeDay(iVictim);
	
	//CheckLastFreeDay();
		
	return Plugin_Continue;
}

public Action OnTakeDamageSDKHook(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if(IsUserValid(attacker) && JB_HasFreeDay(attacker))
		return Plugin_Handled;
		
	return Plugin_Continue;
}

public int FreeDayMenuHandler(Menu menu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(g_bIsBlocked || !IsUserValid(iClient) || !JB_IsSimon(iClient))
				return -1;
			
			char szItemInfo[MAX_TEXT_LENGTH];
			menu.GetItem(iItem, szItemInfo, sizeof(szItemInfo)); 
			int iTarget = StringToInt(szItemInfo);
			if(!IsUserValid(iTarget) || !IsPlayerAlive(iTarget) || GetClientTeam(iTarget) != CS_TEAM_T || JB_IsRebel(iTarget))
			{
        		JB_DisplayFreeDayMenu(iClient);
        		return -1;
        	}
			
			if(g_bHasFreeDay[iTarget])
				JB_RemoveFreeDay(iTarget);
			else
				JB_AddFreeDay(iTarget);
			
			JB_DisplayFreeDayMenu(iClient);
		}
		
		case MenuAction_Cancel:
			JB_DisplayPrisonersManagerMenu(iClient);
		
		case MenuAction_End:
			delete menu;
	}
	
	return 0;
}

public Action RemoveFreeDayTimer(Handle timer, int iClient)
{
	if(--g_iFreeDayTime[iClient] <= 0)
	{
		KillTimer(g_hFreeDayTimer[iClient]);
		g_hFreeDayTimer[iClient] = INVALID_HANDLE;
		
		JB_RemoveFreeDay(iClient, true);
	}
	
	return Plugin_Continue;
}

public void CheckLastFreeDay()
{
	int iFreeDaysClients[MAXPLAYERS], iFreeDaysCount = 0, iCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsUserValid(i) || !IsPlayerAlive(i) || GetClientTeam(i) != CS_TEAM_T)
			continue;
		
		if(JB_HasFreeDay(i))
		{
			iFreeDaysClients[iFreeDaysCount] = i;
			iFreeDaysCount++;
		}
		else
		{
			iCount++;
			if(iCount > 1)
				return;
		}
	}
	
	for (int i = 0; i < iFreeDaysCount; i++)
		ForcePlayerSuicide(iFreeDaysClients[i]);
}

/////////////////////////////////////////////////////////////
////////////////////////// NATIVES //////////////////////////
/////////////////////////////////////////////////////////////

public int DisplayFreeDayMenu(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	if(g_bIsBlocked || !IsUserValid(iClient) || !JB_IsSimon(iClient))
		return;
	
	Menu menu = CreateMenu(FreeDayMenuHandler, MENU_ACTIONS_ALL);
	char szItemInfo[MAX_TEXT_LENGTH], szItemTitle[MAX_TEXT_LENGTH], szTargetName[MAX_TEXT_LENGTH];
	for(int i = 1; i <= MaxClients; i++)
	{
    	if(!IsUserValid(i) || !IsPlayerAlive(i) || GetClientTeam(i) != CS_TEAM_T || JB_IsRebel(i))
        	continue;
        
        GetClientName(i, szTargetName, sizeof(szTargetName));
        Format(szItemInfo, sizeof(szItemInfo), "%i", i);
        Format(szItemTitle, sizeof(szItemTitle), "%s %s", szTargetName, g_bHasFreeDay[i] ? "[ZABIERZ]" : "[DAJ]");
        menu.AddItem(szItemInfo, szItemTitle);
	} 
	menu.SetTitle("[Menu] Daj/Zabierz FreeDay'a");
	menu.ExitBackButton = true;
	menu.Display(iClient, MENU_TIME_FOREVER);
}

public int AddFreeDay(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	
	g_bHasFreeDay[iClient] = true;
	g_iFreeDayTime[iClient] = FREEDAY_TIME;
	g_iGlowEntity[iClient] = RenderDynamicGlow(iClient, "0 255 0");
	
	g_hFreeDayTimer[iClient] = CreateTimer(1.0, RemoveFreeDayTimer, iClient, TIMER_REPEAT);
	
	Call_StartForward(g_OnAddFreeDayForward);
	Call_PushCell(iClient);
	Call_Finish();
	
	CheckLastFreeDay();
}

public int RemoveFreeDay(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	bool bSpawn = GetNativeCell(2);
	
	if(g_hFreeDayTimer[iClient] != INVALID_HANDLE)
	{
		KillTimer(g_hFreeDayTimer[iClient]);
		g_hFreeDayTimer[iClient] = INVALID_HANDLE;
	}
	
	g_bHasFreeDay[iClient] = false;
	g_iFreeDayTime[iClient] = 0;
	
	RemoveDynamicGlow(g_iGlowEntity[iClient]);
	g_iGlowEntity[iClient] = -1;
	
	if(bSpawn)
		CS_RespawnPlayer(iClient);
}

public int HasFreeDay(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	return g_bHasFreeDay[iClient];
}

public int GetFreeDayTime(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	return g_iFreeDayTime[iClient];
}