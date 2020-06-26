#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] FreeDay"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

#define FREEDAY_TIME 300

bool g_bHasAccess[MAXPLAYERS + 1], g_bHasFreeDay[MAXPLAYERS + 1], g_bNextRoundFreeDay[MAXPLAYERS + 1];
int g_iTimeFreeDay[MAXPLAYERS + 1], g_iGlowEntity[MAXPLAYERS + 1];
Handle g_hFreeDayHud;

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
}

public void OnPluginStart()
{
	HookEvent("round_end", RoundEndEvent);
	HookEvent("player_death", PlayerDeathEvent);
	
	g_hFreeDayHud = CreateHudSynchronizer();
	CreateTimer(1.0, UpdateFreeDayHudTimer, _, TIMER_REPEAT);
	
	RegConsoleCmd("jb_freeday_menu", FreeDayMenuCmd);
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bHasAccess[i] = false;
		g_bHasFreeDay[i] = false;
	}
}

public void OnClientPostAdminCheck(int iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamageSDKHook); 
}

public void OnClientDisconnect_Post(int iClient)
{
	g_bHasAccess[iClient] = false;
	g_bHasFreeDay[iClient] = false;
}

public void OnAddSimon(int iClient)
{
	g_bHasAccess[iClient] = true;
}

public void OnRemoveSimon(int iClient)
{
	g_bHasAccess[iClient] = false;
}

public Action RoundEndEvent(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bHasAccess[i] = false;
		g_bHasFreeDay[i] = false;
	}
	
	return Plugin_Continue;
}

public Action PlayerDeathEvent(Event event, const char[] name, bool dontBroadcast)
{
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	g_bHasAccess[iVictim] = false;
	
	if(JB_HasFreeDay(iVictim))
		JB_RemoveFreeDay(iVictim);
		
	return Plugin_Continue;
}

public Action UpdateFreeDayHudTimer(Handle timer)
{
	char format[MAX_TEXT_LENGTH] = "[FreeDay's]";
	int freeDaysCount = 0;
	char szClientName[MAX_TEXT_LENGTH];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!g_bHasFreeDay[i])
			continue;
			
		if(--g_iTimeFreeDay[i] > 0)
		{
			freeDaysCount++;
			GetClientName(i, szClientName, sizeof(szClientName));
			Format(format, sizeof(format), "%s\n[%i] %s", format, g_iTimeFreeDay[i], szClientName);
		}
		else
			JB_RemoveFreeDay(i, true);
	}
	
	if(freeDaysCount < 1)
		return Plugin_Continue;
	
	SetHudTextParams(0.6, 0.05, 1.1, 255, 255, 110, 0);
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsUserValid(i))
			continue;
		
		ShowSyncHudText(i, g_hFreeDayHud, format);
	}
	
	return Plugin_Continue;
}

public Action FreeDayMenuCmd(int iClient, int args)
{
	JB_DisplayFreeDayMenu(iClient);
	
	return Plugin_Continue;
}

public int FreeDayMenuHandler(Menu menu, MenuAction action, int iClient, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(!g_bHasAccess[iClient])
				return -1;
			
			char szInfo[MAX_TEXT_LENGTH];
			menu.GetItem(param2, szInfo, sizeof(szInfo)); 
			int iTarget = StringToInt(szInfo);
			if(!IsUserValid(iTarget) || !IsPlayerAlive(iTarget) || GetClientTeam(iTarget) != CS_TEAM_T)
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
		{
			JB_DisplayMainMenu(iClient);
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

public Action OnTakeDamageSDKHook(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if(IsUserValid(attacker) && g_bHasFreeDay[attacker])
		return Plugin_Handled;
		
	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////
////////////////////////// NATIVES //////////////////////////
/////////////////////////////////////////////////////////////

public int DisplayFreeDayMenu(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	if(!IsUserValid(iClient) || !g_bHasAccess[iClient])
		return;
	
	Menu menu = CreateMenu(FreeDayMenuHandler, MENU_ACTIONS_ALL);
	char szItemInfo[MAX_TEXT_LENGTH], szItemTitle[MAX_TEXT_LENGTH];
	for(int i = 1; i <= MaxClients; i++)
	{
    	if(!IsUserValid(i) || !IsPlayerAlive(i) || GetClientTeam(i) != CS_TEAM_T)
        	continue;
        
        char szTargetName[MAX_TEXT_LENGTH];
        GetClientName(i, szTargetName, sizeof(szTargetName));
        
        Format(szItemInfo, sizeof(szItemInfo), "%i", i);
        Format(szItemTitle, sizeof(szItemTitle), "%s %s", szTargetName, g_bHasFreeDay[i] ? "[ZABIERZ]" : "");
        menu.AddItem(szItemInfo, szItemTitle);
	} 
	menu.SetTitle("[Menu] Daj/Zabierz FreeDay'a");
	menu.ExitBackButton = true;
	menu.Display(iClient, MENU_TIME_FOREVER);
}

public int AddFreeDay(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	
	g_iTimeFreeDay[iClient] = FREEDAY_TIME;
	g_bHasFreeDay[iClient] = true;
	g_iGlowEntity[iClient] = RenderDynamicGlow(iClient, "0 255 0");
}

public int RemoveFreeDay(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	bool bSpawn = GetNativeCell(2);
	
	g_bHasFreeDay[iClient] = false;
	RemoveDynamicGlow(g_iGlowEntity[iClient]);
	
	if(bSpawn)
		CS_RespawnPlayer(iClient);
}

public int HasFreeDay(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	return g_bHasFreeDay[iClient];
}