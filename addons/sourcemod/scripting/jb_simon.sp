#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Simon"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

#define SIMONMENU_OPENCELLS "open_cells"
#define SIMONMENU_RANDOMMENU "random_menu"
#define SIMONMENU_HEALMENU "heal_menu"
#define SIMONMENU_DIVIDEMENU "divide_menu"
#define SIMONMENU_FREEDAYMENU "freeday_menu"
#define SIMONMENU_REBELMENU_REMOVE "rebel_menu_remove"

GlobalForward g_OnAddSimonForward, g_OnRemoveSimonForward;
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
	CreateNative("JB_AddSimon", AddSimon);
	CreateNative("JB_RemoveSimon", RemoveSimon);
	CreateNative("JB_GetSimon", GetSimon);
	CreateNative("JB_IsSimon", IsSimon);
	CreateNative("JB_DisplaySimonMenu", DisplaySimonMenu);
}

public void OnPluginStart()
{
	HookEvent("round_freeze_end", RoundFreezeEndEvent);
	HookEvent("round_end", RoundEndEvent);
	HookEvent("player_death", PlayerDeathEvent);
	
	g_OnAddSimonForward = CreateGlobalForward("OnAddSimon", ET_Event, Param_Cell);
	g_OnRemoveSimonForward = CreateGlobalForward("OnRemoveSimon", ET_Event, Param_Cell);
}

public void OnMapStart()
{
	JB_RemoveSimon();
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
    
	JB_RemoveSimon();
	
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

public int SimonMenuHandler(Menu menu, MenuAction action, int iClient, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(!JB_IsSimon(iClient))
				return -1;
			
			char szInfo[MAX_TEXT_LENGTH];
			menu.GetItem(param2, szInfo, sizeof(szInfo));
			if(StrEqual(szInfo, SIMONMENU_OPENCELLS))
			{
				JB_OpenCells();
				JB_DisplaySimonMenu(iClient);
			}
			else if(StrEqual(szInfo, SIMONMENU_RANDOMMENU))
			{
				JB_DisplayRandomMenu(iClient);
			}
			else if(StrEqual(szInfo, SIMONMENU_HEALMENU))
			{
				JB_DisplayHealMenu(iClient);
			}
			else if(StrEqual(szInfo, SIMONMENU_DIVIDEMENU))
			{
				JB_DisplayDivideMenu(iClient);
			}
			else if(StrEqual(szInfo, SIMONMENU_FREEDAYMENU))
			{
				JB_DisplayFreeDayMenu(iClient, BOTH);
			}
			else if(StrEqual(szInfo, SIMONMENU_REBELMENU_REMOVE))
			{
				JB_DisplayRebelMenu(iClient, REMOVE);
			}
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

public void RandomAddSimon()
{
	int iRandom = JB_RandWarden();
	JB_AddSimon(iRandom);
}

/////////////////////////////////////////////////////////////
////////////////////////// NATIVES //////////////////////////
/////////////////////////////////////////////////////////////

public int AddSimon(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	g_iSimon = iClient;
	
	JB_DisplayMainMenu(iClient);
		
	Call_StartForward(g_OnAddSimonForward);
	Call_PushCell(iClient);
	Call_Finish();
}

public int RemoveSimon(Handle plugin, int argc)
{
	Call_StartForward(g_OnRemoveSimonForward);
	Call_PushCell(g_iSimon);
	Call_Finish();
	
	g_iSimon = 0;
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

public int DisplaySimonMenu(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	if(!JB_IsSimon(iClient))
		return;
	
	Menu menu = new Menu(SimonMenuHandler, MENU_ACTIONS_ALL);
	menu.AddItem(SIMONMENU_OPENCELLS, "Otwórz cele");
	menu.AddItem(SIMONMENU_RANDOMMENU, "Wylosuj więźnia");
	menu.AddItem(SIMONMENU_HEALMENU, "Ulecz więźnia");
	menu.AddItem(SIMONMENU_DIVIDEMENU, "Podziel więźniów");
	menu.AddItem(SIMONMENU_FREEDAYMENU, "Daj/Zabierz FreeDay'a");
	menu.AddItem(SIMONMENU_REBELMENU_REMOVE, "Zabierz buntownika");
	menu.SetTitle("[Menu] Prowadzący");
	menu.Display(iClient, MENU_TIME_FOREVER);
}