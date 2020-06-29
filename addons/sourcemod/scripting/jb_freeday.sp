#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] FreeDay"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

#define FREEDAY_TIME 300

GlobalForward g_OnAddFreeDayForward;
bool g_bHasFreeDay[MAXPLAYERS + 1], g_bNextRoundFreeDay[MAXPLAYERS + 1];
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
	HookEvent("round_end", RoundEndEvent);
	HookEvent("player_death", PlayerDeathEvent);
	
	g_OnAddFreeDayForward = CreateGlobalForward("OnAddFreeDay", ET_Event, Param_Cell);
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		JB_RemoveFreeDay(i);
		g_bNextRoundFreeDay[i] = false;
	}
}

public void OnClientPostAdminCheck(int iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamageSDKHook); 
}

public void OnClientDisconnect_Post(int iClient)
{
	JB_RemoveFreeDay(iClient);
	g_bNextRoundFreeDay[iClient] = false;
}

public Action OnTakeDamageSDKHook(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if(IsUserValid(attacker) && JB_HasFreeDay(attacker))
		return Plugin_Handled;
		
	return Plugin_Continue;
}

public void OnAddRebel(int iClient)
{
	if(JB_HasFreeDay(iClient))
		JB_RemoveFreeDay(iClient);
}

public Action RoundEndEvent(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		JB_RemoveFreeDay(i);
		g_bNextRoundFreeDay[i] = false;
	}
	
	return Plugin_Continue;
}

public Action PlayerDeathEvent(Event event, const char[] name, bool dontBroadcast)
{
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	
	if(JB_HasFreeDay(iVictim))
		JB_RemoveFreeDay(iVictim);
		
	return Plugin_Continue;
}

public int FreeDayMenuHandler(Menu menu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(!IsUserValid(iClient) || !JB_IsSimon(iClient))
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
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

public Action UpdateFreeDayTimer(Handle timer, int iClient)
{
	if(--g_iFreeDayTime[iClient] <= 0)
	{
		KillTimer(g_hFreeDayTimer[iClient]);
		g_hFreeDayTimer[iClient] = INVALID_HANDLE;
		
		JB_RemoveFreeDay(iClient, true);
	}
	
	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////
////////////////////////// NATIVES //////////////////////////
/////////////////////////////////////////////////////////////

public int DisplayFreeDayMenu(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	if(!IsUserValid(iClient) || !JB_IsSimon(iClient))
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
	menu.Display(iClient, MENU_TIME_FOREVER);
}

public int AddFreeDay(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	
	g_bHasFreeDay[iClient] = true;
	g_iFreeDayTime[iClient] = FREEDAY_TIME;
	g_iGlowEntity[iClient] = RenderDynamicGlow(iClient, "0 255 0");
	
	g_hFreeDayTimer[iClient] = CreateTimer(1.0, UpdateFreeDayTimer, iClient, TIMER_REPEAT);
	
	Call_StartForward(g_OnAddFreeDayForward);
	Call_PushCell(iClient);
	Call_Finish();
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
	if(g_iGlowEntity[iClient] != -1)
	{
		RemoveDynamicGlow(g_iGlowEntity[iClient]);
		g_iGlowEntity[iClient] = -1;
	}
	
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