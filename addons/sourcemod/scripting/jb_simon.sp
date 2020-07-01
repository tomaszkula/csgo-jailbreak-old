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

bool g_bIsBlocked = true;
int g_iSimon;
Handle g_hAddAutoSimonTimer;

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
	CreateNative("JB_RemoveSimon", RemoveSimon);
	CreateNative("JB_GetSimon", GetSimon);
	CreateNative("JB_IsSimon", IsSimon);
}

public void OnMapStart()
{
	JB_RemoveSimon();
}

public void OnDayMode(int iOldDayMode, int iNewDayMode)
{
	if(iOldDayMode == NORMAL)
	{
		JB_RemoveSimon();
		RefuseAutoSimonTimer();
		g_bIsBlocked = true;
		
		UnhookEvent("round_prestart", RoundPrestartEvent);
		UnhookEvent("round_freeze_end", RoundFreezeEndEvent);
		UnhookEvent("player_team", PlayerTeamEvent);
		UnhookEvent("player_death", PlayerDeathEvent);
	}
	
	if(iNewDayMode == NORMAL)
	{
		JB_RemoveSimon();
		g_bIsBlocked = false;
		
		HookEvent("round_prestart", RoundPrestartEvent);
		HookEvent("round_freeze_end", RoundFreezeEndEvent);
		HookEvent("player_team", PlayerTeamEvent);
		HookEvent("player_death", PlayerDeathEvent);
	}
}

public Action RoundPrestartEvent(Event event, const char[] name, bool dontBroadcast)
{
	RefuseAutoSimonTimer();
	return Plugin_Continue;
}

public Action RoundFreezeEndEvent(Event event, const char[] name, bool dontBroadcast)
{
	g_hAddAutoSimonTimer = CreateTimer(15.0, AddAutoSimonTimer);
	return Plugin_Continue;
}

public Action PlayerTeamEvent(Event event, const char[] name, bool dontBroadcast)
{
	bool disconnected = event.GetBool("disconnect");
	if(disconnected)
	{
		int iClient = GetClientOfUserId(event.GetInt("userid"));
		if(JB_IsSimon(iClient))
		{
			JB_RemoveSimon();
			AddRandomSimon();
		}
	}
	
	return Plugin_Continue;
}

public Action PlayerDeathEvent(Event event, const char[] name, bool dontBroadcast)
{
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	if(JB_IsSimon(iVictim))
	{
		JB_RemoveSimon();
		AddRandomSimon();
	}
		
	return Plugin_Continue;
}

public Action AddAutoSimonTimer(Handle timer)
{
	g_hAddAutoSimonTimer = INVALID_HANDLE;
	
	if(JB_IsSimon(0))
		AddRandomSimon();
	
	return Plugin_Continue;
}

void RefuseAutoSimonTimer()
{
	if(g_hAddAutoSimonTimer != INVALID_HANDLE)
	{
		KillTimer(g_hAddAutoSimonTimer);
		g_hAddAutoSimonTimer = INVALID_HANDLE;
    }
}

void AddRandomSimon()
{
	int iWardens[MAXPLAYERS], iWardensCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsUserValid(i) || !IsPlayerAlive(i) || GetClientTeam(i) != CS_TEAM_CT)
			continue;
		
		iWardens[iWardensCount] = i;
		iWardensCount++;
	}
	
	if(iWardensCount > 0)
		JB_AddSimon(iWardens[GetRandomInt(0, iWardensCount - 1)]);
}

public int SimonMenuHandler(Menu menu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(g_bIsBlocked || !IsUserValid(iClient) || !JB_IsSimon(iClient))
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
			if(g_bIsBlocked || !IsUserValid(iClient) || !JB_IsSimon(iClient))
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

/////////////////////////////////////////////////////////////
////////////////////////// NATIVES //////////////////////////
/////////////////////////////////////////////////////////////

public int DisplaySimonMenu(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	if(g_bIsBlocked || !IsUserValid(iClient) || !JB_IsSimon(iClient))
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
	if(g_bIsBlocked || !IsUserValid(iClient) || !JB_IsSimon(iClient))
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
	
	RefuseAutoSimonTimer();
}

public int RemoveSimon(Handle plugin, int argc)
{
	g_iSimon = 0;
}

public int GetSimon(Handle plugin, int argc)
{
	return g_iSimon;
}

public int IsSimon(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	return g_iSimon == iClient;
}