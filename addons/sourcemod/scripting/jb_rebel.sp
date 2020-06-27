#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Rebel"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

GlobalForward g_OnAddRebelForward;

bool g_bHasAccess[MAXPLAYERS + 1][3], g_bIsRebel[MAXPLAYERS + 1];
int g_iGlowEntity[MAXPLAYERS + 1];

Handle g_hRebelHud;

public APLRes AskPluginLoad2(Handle myself, bool late, char [] error, int err_max)
{
	CreateNative("JB_DisplayRebelMenu", DisplayRebelMenu);
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
	
	g_OnAddRebelForward = CreateGlobalForward("OnAddRebel", ET_Event, Param_Cell);
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bHasAccess[i][ADD] = false;
		g_bHasAccess[i][REMOVE] = false;
		g_bHasAccess[i][BOTH] = false;
		
		g_bIsRebel[i] = false;
	}
}

public void OnClientDisconnect_Post(int iClient)
{
	g_bHasAccess[iClient][ADD] = false;
	g_bHasAccess[iClient][REMOVE] = false;
	g_bHasAccess[iClient][BOTH] = false;
	
	g_bIsRebel[iClient] = false;
}

public void OnAddSimon(int iClient)
{
	g_bHasAccess[iClient][REMOVE] = true;
}

public void OnRemoveSimon(int iClient)
{
	g_bHasAccess[iClient][REMOVE] = false;
}

public Action RoundEndEvent(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bHasAccess[i][ADD] = false;
		g_bHasAccess[i][REMOVE] = false;
		g_bHasAccess[i][BOTH] = false;
		
		g_bIsRebel[i] = false;
	}
	
	return Plugin_Continue;
}

public Action PlayerDeathEvent(Event event, const char[] name, bool dontBroadcast)
{
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	int iKiller = GetClientOfUserId(event.GetInt("attacker"));
	g_bHasAccess[iVictim][ADD] = false;
	g_bHasAccess[iVictim][REMOVE] = false;
	g_bHasAccess[iVictim][BOTH] = false;
	
	if(GetClientTeam(iVictim) == CS_TEAM_CT && GetClientTeam(iKiller) == CS_TEAM_T && !JB_IsRebel(iKiller))
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

public int RemoveRebelMenuHandler(Menu menu, MenuAction action, int iClient, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(!g_bHasAccess[iClient][REMOVE])
				return -1;
			
			char szInfo[MAX_TEXT_LENGTH];
			menu.GetItem(param2, szInfo, sizeof(szInfo)); 
			int iTarget = StringToInt(szInfo);
			if(!IsUserValid(iTarget) || !IsPlayerAlive(iTarget) || GetClientTeam(iTarget) != CS_TEAM_T || !JB_IsRebel(iTarget))
			{
        		JB_DisplayRebelMenu(iClient, REMOVE);
        		return -1;
        	}
			
			JB_RemoveRebel(iTarget);
			
			JB_DisplayRebelMenu(iClient, REMOVE);
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

public int DisplayRebelMenu(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	if(!IsUserValid(iClient))
		return;
	
	int iMode = GetNativeCell(2);
	if(!g_bHasAccess[iClient][iMode])
		return;
	
	switch(iMode)
	{
		case REMOVE:
		{
			Menu menu = CreateMenu(RemoveRebelMenuHandler, MENU_ACTIONS_ALL);
			char szItemInfo[MAX_TEXT_LENGTH], szItemTitle[MAX_TEXT_LENGTH];
			for(int i = 1; i <= MaxClients; i++)
			{
		    	if(!IsUserValid(i) || !IsPlayerAlive(i) || GetClientTeam(i) != CS_TEAM_T || !JB_IsRebel(i))
		        	continue;
		        
		        char szTargetName[MAX_TEXT_LENGTH];
		        GetClientName(i, szTargetName, sizeof(szTargetName));
		        
		        Format(szItemInfo, sizeof(szItemInfo), "%i", i);
		        Format(szItemTitle, sizeof(szItemTitle), "%s", szTargetName);
		        menu.AddItem(szItemInfo, szItemTitle);
			} 
			menu.SetTitle("[Menu] Zabierz buntownika");
			menu.Display(iClient, MENU_TIME_FOREVER);
		}
	}
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
	RemoveDynamicGlow(g_iGlowEntity[iClient]);
}

public int IsRebel(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	return g_bIsRebel[iClient];
}