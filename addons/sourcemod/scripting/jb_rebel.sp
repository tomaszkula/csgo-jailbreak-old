#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Rebel"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

GlobalForward g_OnAddRebelForward;
bool g_bIsRebel[MAXPLAYERS + 1];
int g_iGlowEntity[MAXPLAYERS + 1];

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
	CreateNative("JB_DisplayRebelMenu", DisplayRebelMenu);
	CreateNative("JB_AddRebel", AddRebel);
	CreateNative("JB_RemoveRebel", RemoveRebel);
	CreateNative("JB_IsRebel", IsRebel);
}

public void OnPluginStart()
{
	HookEvent("round_end", RoundEndEvent);
	HookEvent("player_death", PlayerDeathEvent);
	
	g_OnAddRebelForward = CreateGlobalForward("OnAddRebel", ET_Event, Param_Cell);
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
		JB_RemoveRebel(i);
}

public void OnClientDisconnect_Post(int iClient)
{
	JB_RemoveRebel(iClient);
}

public Action RoundEndEvent(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
		JB_RemoveRebel(i);
	
	return Plugin_Continue;
}

public Action PlayerDeathEvent(Event event, const char[] name, bool dontBroadcast)
{
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	int iKiller = GetClientOfUserId(event.GetInt("attacker"));
	
	if(GetClientTeam(iVictim) == CS_TEAM_CT && GetClientTeam(iKiller) == CS_TEAM_T && !JB_IsRebel(iKiller))
		JB_AddRebel(iKiller);
	else if(GetClientTeam(iVictim) == CS_TEAM_T && JB_IsRebel(iVictim))
		JB_RemoveRebel(iVictim);
		
	return Plugin_Continue;
}

public int RebelMenuHandler(Menu menu, MenuAction action, int iClient, int iItem)
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
			if(!IsUserValid(iTarget) || !IsPlayerAlive(iTarget) || GetClientTeam(iTarget) != CS_TEAM_T || !JB_IsRebel(iTarget))
			{
        		JB_DisplayRebelMenu(iClient);
        		return -1;
        	}
			
			JB_RemoveRebel(iTarget);
			
			JB_DisplayRebelMenu(iClient);
		}
		
		case MenuAction_Cancel:
			JB_DisplayPrisonersManagerMenu(iClient);
		
		case MenuAction_End:
			delete menu;
	}
	
	return 0;
}

/////////////////////////////////////////////////////////////
////////////////////////// NATIVES //////////////////////////
/////////////////////////////////////////////////////////////

public int DisplayRebelMenu(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	if(!IsUserValid(iClient) || !JB_IsSimon(iClient))
		return;
	
	Menu menu = CreateMenu(RebelMenuHandler, MENU_ACTIONS_ALL);
	char szItemInfo[MAX_TEXT_LENGTH], szItemTitle[MAX_TEXT_LENGTH], szTargetName[MAX_TEXT_LENGTH];
	for(int i = 1; i <= MaxClients; i++)
	{
    	if(!IsUserValid(i) || !IsPlayerAlive(i) || GetClientTeam(i) != CS_TEAM_T || !JB_IsRebel(i))
        	continue;
        
        GetClientName(i, szTargetName, sizeof(szTargetName));
        Format(szItemInfo, sizeof(szItemInfo), "%i", i);
        Format(szItemTitle, sizeof(szItemTitle), "%s", szTargetName);
        menu.AddItem(szItemInfo, szItemTitle);
	} 
	menu.SetTitle("[Menu] Zabierz buntownika");
	menu.ExitBackButton = true;
	menu.Display(iClient, MENU_TIME_FOREVER);
}

public int AddRebel(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	
	g_bIsRebel[iClient] = true;
	g_iGlowEntity[iClient] = RenderDynamicGlow(iClient, "255 0 0");
	
	Call_StartForward(g_OnAddRebelForward);
	Call_PushCell(iClient);
	Call_Finish();
}

public int RemoveRebel(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	
	g_bIsRebel[iClient] = false;
	if(g_iGlowEntity[iClient] != -1)
	{
		RemoveDynamicGlow(g_iGlowEntity[iClient]);
		g_iGlowEntity[iClient] = -1;
	}
}

public int IsRebel(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	return g_bIsRebel[iClient];
}