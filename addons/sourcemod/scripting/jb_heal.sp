#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Heal"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

bool g_bHasAccess[MAXPLAYERS + 1];

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
	CreateNative("JB_DisplayHealMenu", DisplayHealMenu);
}

public void OnPluginStart()
{
	HookEvent("round_end", RoundEndEvent);
	HookEvent("player_death", PlayerDeathEvent);
	
	RegConsoleCmd("jb_heal_menu", HealMenuCmd);
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
		g_bHasAccess[i] = false;
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

public Action RoundEndEvent(Event event, const char[] name, bool dontBroadcast)
{
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

public Action HealMenuCmd(int iClient, int args)
{
	JB_DisplayHealMenu(iClient);
	
	return Plugin_Handled;
}

public int HealMenuHandler(Menu menu, MenuAction action, int iClient, int param2)
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
			if(!IsUserValid(iTarget) || !IsPlayerAlive(iTarget) || GetClientTeam(iTarget) != CS_TEAM_T || GetClientHealth(iTarget) >= 100)
			{
        		JB_DisplayHealMenu(iClient);
        		return -1;
        	}
        	
			char szTargetName[MAX_TEXT_LENGTH];
			GetClientName(iTarget, szTargetName, sizeof(szTargetName));
			
			SetEntityHealth(iTarget, 100);
			PrintToChatAll("%s Więzień \x07%s \x01został uleczony.", JB_PREFIX, szTargetName);
			
			JB_DisplayHealMenu(iClient);
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

/////////////////////////////////////////////////////////////
////////////////////////// NATIVES //////////////////////////
/////////////////////////////////////////////////////////////

public int DisplayHealMenu(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	if(!IsUserValid(iClient) || !g_bHasAccess[iClient])
		return;
	
	Menu menu = CreateMenu(HealMenuHandler, MENU_ACTIONS_ALL);
	char szItemInfo[MAX_TEXT_LENGTH], szItemTitle[MAX_TEXT_LENGTH];
	for(int i = 1; i <= MaxClients; i++)
	{
    	if(!IsUserValid(i) || !IsPlayerAlive(i) || GetClientTeam(i) != CS_TEAM_T || GetClientHealth(i) >= 100)
        	continue;
        
        char szTargetName[MAX_TEXT_LENGTH];
        GetClientName(i, szTargetName, sizeof(szTargetName));
        
        Format(szItemInfo, sizeof(szItemInfo), "%i", i);
        Format(szItemTitle, sizeof(szItemTitle), "%s [%iHP]", szTargetName, GetClientHealth(i));
        menu.AddItem(szItemInfo, szItemTitle);
	} 
	menu.SetTitle("[Menu] Ulecz więźnia");
	menu.Display(iClient, MENU_TIME_FOREVER);
}