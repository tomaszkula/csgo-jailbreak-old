#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Wishes"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

#define WISHESCONFIRMMENU_YES "yes"
#define WISHESCONFIRMMENU_NO "no"

int g_iLast;
bool g_bIsBlocked = true, g_bWish = false;

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
	RegConsoleCmd("zyczenie", CheckWishCmd);
	RegConsoleCmd("wish", CheckWishCmd);
	RegConsoleCmd("lr", CheckWishCmd);
}

public void OnMapStart()
{
	g_iLast = 0;
	g_bWish = false;
}

public void OnDayMode(int iOldDayMode, int iNewDayMode)
{
	if(iOldDayMode == NORMAL)
	{
		g_bIsBlocked = true;
		g_iLast = 0;
		g_bWish = false;
		
		UnhookEvent("round_prestart", RoundPrestartEvent);
		UnhookEvent("player_team", PlayerTeamEvent);
		UnhookEvent("player_death", PlayerDeathEvent);
		UnhookEvent("player_spawn", PlayerSpawnEvent);
	}
	
	if(iNewDayMode == NORMAL)
	{
		g_bIsBlocked = false;
		
		HookEvent("round_prestart", RoundPrestartEvent);
		HookEvent("player_team", PlayerTeamEvent);
		HookEvent("player_death", PlayerDeathEvent);
		HookEvent("player_spawn", PlayerSpawnEvent);
	}
}

public Action RoundPrestartEvent(Event event, const char[] name, bool dontBroadcast)
{
	g_iLast = 0;
	g_bWish = false;
	
	return Plugin_Continue;
}

public Action PlayerTeamEvent(Event event, const char[] name, bool dontBroadcast)
{
	if(g_bWish)
		return Plugin_Continue;
	
	bool disconnected = event.GetBool("disconnect");
	if(disconnected)
	{
		int iClient = GetClientOfUserId(event.GetInt("userid"));
		if(GetClientTeam(iClient) != CS_TEAM_T)
			return Plugin_Continue;
		
		CheckWish();
	}
	
	return Plugin_Continue;
}

public Action PlayerDeathEvent(Event event, const char[] name, bool dontBroadcast)
{
	if(g_bWish)
		return Plugin_Continue;
	
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	if(GetClientTeam(iVictim) != CS_TEAM_T)
		return Plugin_Continue;
	
	CheckWish();
		
	return Plugin_Continue;
}

public Action PlayerSpawnEvent(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_bWish)
		return Plugin_Continue;
	
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	if(GetClientTeam(iClient) == CS_TEAM_T)
	{
		if(JB_GetPrisonersCount(true) > 1)
		{
			g_iLast = 0;
			g_bWish = false;
		}
	}
	
	return Plugin_Continue;
}

public Action CheckWishCmd(int iClient, int args)
{
	if(g_bIsBlocked || !IsUserValid(iClient) || !IsPlayerAlive(iClient))
		return Plugin_Continue;
	
	if(JB_IsSimon(iClient) && !g_bWish && IsUserValid(g_iLast))
		DisplayWishesConfirmMenu(iClient);
	
	if(GetClientTeam(iClient) == CS_TEAM_T && g_bWish && iClient == g_iLast)
		DisplayWishesMenu(iClient);
	
	return Plugin_Handled;
}

void CheckWish()
{
	g_iLast = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsUserValid(i) || !IsPlayerAlive(i) || GetClientTeam(i) != CS_TEAM_T || JB_HasFreeDay(i) || JB_IsRebel(i))
			continue;
		
		if(g_iLast == 0)
			g_iLast = i;
		else
			return;
	}
	
	if(g_iLast != 0)
	{
		char szLastName[MAX_TEXT_LENGTH];
		GetClientName(g_iLast, szLastName, sizeof(szLastName));
		PrintToChatAll("%s Został ostatni więzień \x07%s\x01.", JB_PREFIX, szLastName);
		DisplayWishesConfirmMenu(JB_GetSimon());
	}
}

public void DisplayWishesConfirmMenu(int iClient)
{
	if(g_bIsBlocked || !IsUserValid(iClient) || !JB_IsSimon(iClient))
		return;
		
	if(!IsUserValid(g_iLast) || !IsPlayerAlive(g_iLast))
		return;
	
	Menu menu = CreateMenu(WishesConfirmMenuHandler, MENU_ACTIONS_ALL);
	menu.AddItem(WISHESCONFIRMMENU_YES, "Tak");
	menu.AddItem(WISHESCONFIRMMENU_NO, "Nie");
	menu.SetTitle("[ Czy ostatni więzień powinien dostać życzenia? ]");
	menu.ExitButton = false;
	menu.Display(iClient, MENU_TIME_FOREVER);
}

public int WishesConfirmMenuHandler(Menu menu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(g_bIsBlocked || !IsUserValid(iClient) || !JB_IsSimon(iClient))
				return -1;
			
			if(!IsUserValid(g_iLast) || !IsPlayerAlive(g_iLast))
				return -1;
			
			char szItemInfo[MAX_TEXT_LENGTH];
			menu.GetItem(iItem, szItemInfo, sizeof(szItemInfo));
			
			char szLastName[MAX_TEXT_LENGTH];
			GetClientName(g_iLast, szLastName, sizeof(szLastName));
			
			if(StrEqual(szItemInfo, WISHESCONFIRMMENU_YES))
			{
				g_bWish = true;
				DisplayWishesMenu(g_iLast);
				PrintToChatAll("%s Ostatni więzień \x07%s \x01otrzymał życzenie.", JB_PREFIX, szLastName);
			}
			else if(StrEqual(szItemInfo, WISHESCONFIRMMENU_NO))
			{
				g_bWish = false;
				PrintToChatAll("%s Ostatni więzień \x07%s \x01nie otrzymał życzenia", JB_PREFIX, szLastName);
			}
		}
		
		case MenuAction_End:
			delete menu;
	}
	
	return 0;
}

public void DisplayWishesMenu(int iClient)
{
	if(g_bIsBlocked || !IsUserValid(iClient) || !g_bWish || iClient != g_iLast)
		return;
	
	Menu menu = CreateMenu(WishesMenuHandler, MENU_ACTIONS_ALL);
	menu.SetTitle("[ Życzenie ]");
	menu.AddItem("p", "hah");
	menu.AddItem("v", "oh");
	menu.ExitButton = false;
	menu.Display(iClient, MENU_TIME_FOREVER);
}

public int WishesMenuHandler(Menu menu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(g_bIsBlocked || !IsUserValid(iClient) || !g_bWish || iClient != g_iLast)
				return -1;
			
			char szItemInfo[MAX_TEXT_LENGTH];
			menu.GetItem(iItem, szItemInfo, sizeof(szItemInfo));
		}
		
		case MenuAction_End:
			delete menu;
	}
	
	return 0;
}