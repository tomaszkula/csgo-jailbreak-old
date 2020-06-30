#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Simon"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

#define SIMONMENU_OPENCELLS "open_cells"
#define SIMONMENU_RANDOMMENU "random_menu"
#define SIMONMENU_PRISONERSMANAGERMENU "prisoners_manager_menu"
#define SIMONMENU_MINIGAMESMENU "mini_games_menu"
#define SIMONMENU_GAMESMENU "games_menu"

#define PRISONERSMANAGERMENU_HEALMENU "heal_menu"
#define PRISONERSMANAGERMENU_DIVIDEMENU "divide_menu"
#define PRISONERSMANAGERMENU_FREEDAYMENU "freeday_menu"
#define PRISONERSMANAGERMENU_REBELMENU "rebel_menu"

int g_iSimon;
Handle g_hAddSimonTimer;

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
	CreateNative("JB_DisplaySimonMenu", DisplaySimonMenu);
	CreateNative("JB_DisplayPrisonersManagerMenu", DisplayPrisonersManagerMenu);
	CreateNative("JB_AddSimon", AddSimon);
	CreateNative("JB_GetSimon", GetSimon);
	CreateNative("JB_IsSimon", IsSimon);
}

public void OnPluginStart()
{
	HookEvent("round_freeze_end", RoundFreezeEndEvent);
	HookEvent("round_end", RoundEndEvent);
	HookEvent("player_death", PlayerDeathEvent);
}

public void OnMapStart()
{
	RemoveSimon();
}

public void OnClientDisconnect_Post(int iClient)
{
	if(JB_IsSimon(iClient))
		RandomAddSimon();
}

public Action RoundFreezeEndEvent(Event event, const char[] name, bool dontBroadcast)
{
	g_hAddSimonTimer = CreateTimer(15.0, AddSimonTimer);
	
	return Plugin_Continue;
}

public Action RoundEndEvent(Event event, const char[] name, bool dontBroadcast)
{
	if(g_hAddSimonTimer != INVALID_HANDLE)
	{
		KillTimer(g_hAddSimonTimer);
		g_hAddSimonTimer = INVALID_HANDLE;
    }
    
	RemoveSimon();
	
	return Plugin_Continue;
}

public Action PlayerDeathEvent(Event event, const char[] name, bool dontBroadcast)
{
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	if(JB_IsSimon(iVictim))
		RandomAddSimon();
		
	return Plugin_Continue;
}

public Action AddSimonTimer(Handle timer)
{
	g_hAddSimonTimer = INVALID_HANDLE;
	
	if(JB_IsSimon(0))
		RandomAddSimon();
	
	return Plugin_Continue;
}

public int SimonMenuHandler(Menu menu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(!IsUserValid(iClient) || !JB_IsSimon(iClient))
				return -1;
			
			char szItemInfo[MAX_TEXT_LENGTH];
			menu.GetItem(iItem, szItemInfo, sizeof(szItemInfo));
			if(StrEqual(szItemInfo, SIMONMENU_OPENCELLS))
			{
				JB_OpenCells();
				JB_DisplaySimonMenu(iClient);
			}
			else if(StrEqual(szItemInfo, SIMONMENU_RANDOMMENU))
				JB_DisplayRandomMenu(iClient);
			else if(StrEqual(szItemInfo, SIMONMENU_PRISONERSMANAGERMENU))
				JB_DisplayPrisonersManagerMenu(iClient);
		}
		
		case MenuAction_Cancel:
			FakeClientCommand(iClient, "menu");
		
		case MenuAction_End:
			delete menu;
	}
	
	return 0;
}

public int PrisonersManagerHandler(Menu menu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(!IsUserValid(iClient) || !JB_IsSimon(iClient))
				return -1;
			
			char szItemInfo[MAX_TEXT_LENGTH];
			menu.GetItem(iItem, szItemInfo, sizeof(szItemInfo));
			if(StrEqual(szItemInfo, PRISONERSMANAGERMENU_HEALMENU))
				JB_DisplayHealMenu(iClient);
			else if(StrEqual(szItemInfo, PRISONERSMANAGERMENU_DIVIDEMENU))
				JB_DisplayDivideMenu(iClient);
			else if(StrEqual(szItemInfo, PRISONERSMANAGERMENU_FREEDAYMENU))
				JB_DisplayFreeDayMenu(iClient);
			else if(StrEqual(szItemInfo, PRISONERSMANAGERMENU_REBELMENU))
				JB_DisplayRebelMenu(iClient);
		}
		
		case MenuAction_Cancel:
			JB_DisplaySimonMenu(iClient);
		
		case MenuAction_End:
			delete menu;
	}
	
	return 0;
}

public void RandomAddSimon()
{
	int iRandom = JB_RandWarden();
	if(iRandom != 0)
		JB_AddSimon(iRandom);
	else
		RemoveSimon();
}

public void RemoveSimon()
{
	g_iSimon = 0;
}

/////////////////////////////////////////////////////////////
////////////////////////// NATIVES //////////////////////////
/////////////////////////////////////////////////////////////

public int DisplaySimonMenu(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	if(!IsUserValid(iClient) || !JB_IsSimon(iClient))
		return;
	
	Menu menu = new Menu(SimonMenuHandler, MENU_ACTIONS_ALL);
	menu.AddItem(SIMONMENU_OPENCELLS, "Otwórz cele");
	menu.AddItem(SIMONMENU_RANDOMMENU, "Wylosuj więźnia");
	menu.AddItem(SIMONMENU_PRISONERSMANAGERMENU, "Menu zarządzania więźniami");
	menu.AddItem(SIMONMENU_MINIGAMESMENU, "Menu mini zabaw");
	menu.AddItem(SIMONMENU_GAMESMENU, "Menu zabaw");
	menu.SetTitle("[Menu] Prowadzący");
	menu.ExitBackButton = true;
	menu.Display(iClient, MENU_TIME_FOREVER);
}

public int DisplayPrisonersManagerMenu(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	if(!IsUserValid(iClient) || !JB_IsSimon(iClient))
		return;
	
	Menu menu = new Menu(PrisonersManagerHandler, MENU_ACTIONS_ALL);
	menu.AddItem(PRISONERSMANAGERMENU_HEALMENU, "Ulecz więźnia");
	menu.AddItem(PRISONERSMANAGERMENU_DIVIDEMENU, "Podziel więźniów");
	menu.AddItem(PRISONERSMANAGERMENU_FREEDAYMENU, "Daj/Zabierz FreeDay'a");
	menu.AddItem(PRISONERSMANAGERMENU_REBELMENU, "Zabierz buntownika");
	menu.SetTitle("[Menu] Zarządzanie więźniami");
	menu.ExitBackButton = true;
	menu.Display(iClient, MENU_TIME_FOREVER);
}

public int AddSimon(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	g_iSimon = iClient;
	FakeClientCommand(iClient, "menu");
}

public int GetSimon(Handle plugin, int argc)
{
	return g_iSimon
}

public int IsSimon(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	return g_iSimon == iClient;
}