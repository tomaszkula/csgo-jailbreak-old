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
bool g_bWish;

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
}

public void OnMapStart()
{
	g_iLast = 0;
	g_bWish = false;
}

public void OnClientDisconnect(int iClient)
{
	if(GetClientTeam(iClient) != CS_TEAM_T)
		return;
	
	CheckWish();
}

public Action RoundEndEvent(Event event, const char[] name, bool dontBroadcast)
{
	g_iLast = 0;
	g_bWish = false;
	
	return Plugin_Continue;
}

public Action PlayerDeathEvent(Event event, const char[] name, bool dontBroadcast)
{
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	if(GetClientTeam(iVictim) != CS_TEAM_T)
		return Plugin_Continue;
	
	CheckWish();
	return Plugin_Continue;
}

public void DisplayWishesConfirmMenu(int iClient)
{
	if(!IsUserValid(iClient) || !JB_IsSimon(iClient))
		return;
	
	Menu menu = CreateMenu(WishesConfirmMenuHandler, MENU_ACTIONS_ALL);
	menu.AddItem(WISHESCONFIRMMENU_YES, "Tak");
	menu.AddItem(WISHESCONFIRMMENU_NO, "Nie");
	menu.SetTitle("[ Czy więzień powinien mieć życzenia? ]");
	menu.ExitButton = false;
	menu.Display(iClient, MENU_TIME_FOREVER);
}

public int WishesConfirmMenuHandler(Menu menu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(!IsUserValid(iClient) || !JB_IsSimon(iClient))
				return -1;
			
			char szItemInfo[MAX_TEXT_LENGTH];
			menu.GetItem(iItem, szItemInfo, sizeof(szItemInfo));
			if(StrEqual(szItemInfo, WISHESCONFIRMMENU_YES))
			{
				g_bWish = true;
				DisplayWishesMenu(g_iLast);
				PrintToChat(iClient, "%s Ostatni więzień otrzymał życzenie.", JB_PREFIX);
			}
			else if(StrEqual(szItemInfo, WISHESCONFIRMMENU_NO))
			{
				g_bWish = false;
				PrintToChat(iClient, "%s Ostatni więzień nie otrzymał życzenia", JB_PREFIX);
			}
		}
		
		case MenuAction_End:
			delete menu;
	}
	
	return 0;
}

public void DisplayWishesMenu(int iClient)
{
	if(!IsUserValid(iClient) || g_iLast != iClient || !g_bWish)
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
			if(!IsUserValid(iClient) || !JB_IsSimon(iClient))
				return -1;
			
			char szItemInfo[MAX_TEXT_LENGTH];
			menu.GetItem(iItem, szItemInfo, sizeof(szItemInfo));
		}
		
		case MenuAction_End:
			delete menu;
	}
	
	return 0;
}

public void CheckWish()
{
	g_iLast = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsUserValid(i) || !IsPlayerAlive(i) || GetClientTeam(i) != CS_TEAM_T)
			continue;
		
		if(!JB_HasFreeDay(i))
		{
			if(g_iLast == 0)
				g_iLast = i;
			else
				return;
		}
	}
	
	PrintToChatAll("%s Został ostatni więzień.", JB_PREFIX);
	DisplayWishesConfirmMenu(JB_GetSimon());
}