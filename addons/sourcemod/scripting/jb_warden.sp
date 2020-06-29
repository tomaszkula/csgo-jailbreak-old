#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Warden"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

#define WARDENMENU_BECOMESIMON "become_simon"
#define WARDENMENU_SIMONMENU "simon_menu"
#define WARDENMENU_SEARCH "search"
#define WARDENMENU_ADMINMENU "admin_menu"

char g_szWardenModels[][MAX_TEXT_LENGTH] = 
{
	{"models/player/custom_player/kuristaja/jailbreak/guard1/guard1.mdl"}
};

char g_szWardenModelsAll[][MAX_TEXT_LENGTH] = 
{
	{"models/player/custom_player/kuristaja/jailbreak/guard1/guard1.dx90.vtx"},
	{"models/player/custom_player/kuristaja/jailbreak/guard1/guard1.mdl"},
	{"models/player/custom_player/kuristaja/jailbreak/guard1/guard1.phy"},
	{"models/player/custom_player/kuristaja/jailbreak/guard1/guard1.vvd"},
	{"models/player/custom_player/kuristaja/jailbreak/guard1/guard1_arms.dx90.vtx"},
	{"models/player/custom_player/kuristaja/jailbreak/guard1/guard1_arms.mdl"},
	{"models/player/custom_player/kuristaja/jailbreak/guard1/guard1_arms.vvd"},
	{"materials/models/player/kuristaja/jailbreak/guard1/hair01_ao_d.vmt"},
	{"materials/models/player/kuristaja/jailbreak/guard1/hair01_ao_d2.vmt"},
	{"materials/models/player/kuristaja/jailbreak/guard1/sewell01_head01_au_d.vmt"},
	{"materials/models/player/kuristaja/jailbreak/guard1/hair01_ao_d.vtf"},
	{"materials/models/player/kuristaja/jailbreak/guard1/hair01_ao_normal.vtf"},
	{"materials/models/player/kuristaja/jailbreak/guard1/sewell01_head01_au_d.vtf"},
	{"materials/models/player/kuristaja/jailbreak/guard1/sewell01_head01_au_normal.vtf"}
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
	HookEvent("player_spawn", PlayerSpawnEvent);
	
	RegConsoleCmd("menu", MenuCmd);
}

public void OnMapStart()
{
	for (int i = 0; i < sizeof(g_szWardenModelsAll); i++)
		AddFileToDownloadsTable(g_szWardenModelsAll[i]);
	
	for (int i = 0; i < sizeof(g_szWardenModels); i++)
		PrecacheModel(g_szWardenModels[i], true);
}

public Action PlayerSpawnEvent(Event event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	if (GetClientTeam(iClient) == CS_TEAM_CT)
	{
		SetEntityModel(iClient, g_szWardenModels[0]);
		
		int iWeapon;
		for(int i = 0; i < 5; i++)
	    {
	        if(i != 2 && (iWeapon = GetPlayerWeaponSlot(iClient, i)) != -1)
	        {  
	            RemovePlayerItem(iClient, iWeapon);
	            RemoveEntity(iWeapon);
	        }
	    }
	    
		int iKnife = GetPlayerWeaponSlot(iClient, 2);
		SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iKnife);
	}
	
	return Plugin_Continue;
}

public Action MenuCmd(int iClient, int args)
{
	if(GetClientTeam(iClient) == CS_TEAM_CT)
		DisplayWardenMenu(iClient);
	
	return Plugin_Continue;
}

public void DisplayWardenMenu(int iClient)
{
	if(!IsUserValid(iClient) || !IsPlayerAlive(iClient) || GetClientTeam(iClient) != CS_TEAM_CT)
		return;
	
	Menu menu = CreateMenu(WardenMenuHandler, MENU_ACTIONS_ALL);
	if (JB_IsSimon(iClient))menu.AddItem(WARDENMENU_SIMONMENU, "Menu Prowadzącego");
	else menu.AddItem(WARDENMENU_BECOMESIMON, "Zostań Prowadzącym");
	menu.AddItem(WARDENMENU_SEARCH, "Przeszukaj więźnia");
	menu.AddItem(WARDENMENU_ADMINMENU, "Menu Admina");
	menu.SetTitle("[Menu] Więzień");
	menu.Display(iClient, MENU_TIME_FOREVER);
}

public int WardenMenuHandler(Menu menu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(!IsUserValid(iClient) || !IsPlayerAlive(iClient) || GetClientTeam(iClient) != CS_TEAM_CT)
				return -1;
			
			char szItemInfo[MAX_TEXT_LENGTH];
			menu.GetItem(iItem, szItemInfo, sizeof(szItemInfo)); 
			if(StrEqual(szItemInfo, WARDENMENU_BECOMESIMON))
			{
				if(JB_IsSimon(0))
					JB_AddSimon(iClient);
				
				DisplayWardenMenu(iClient);
			}
			else if(StrEqual(szItemInfo, WARDENMENU_SIMONMENU))
			{
				if(JB_IsSimon(iClient))
					JB_DisplaySimonMenu(iClient);
				else
					DisplayWardenMenu(iClient);
			}
			else if(StrEqual(szItemInfo, WARDENMENU_SEARCH))
			{
				FakeClientCommand(iClient, "search");
				DisplayWardenMenu(iClient);
			}
			else if(StrEqual(szItemInfo, WARDENMENU_ADMINMENU))
			{
				if(GetAdminFlag(GetUserAdmin(iClient), Admin_Ban))
					JB_DisplayAdminMenu(iClient);
				else
					DisplayWardenMenu(iClient);
			}
		}
		
		case MenuAction_DrawItem:
		{
			char szItemInfo[MAX_TEXT_LENGTH];
			menu.GetItem(iItem, szItemInfo, sizeof(szItemInfo)); 
			
			if(StrEqual(szItemInfo, WARDENMENU_BECOMESIMON) && !JB_IsSimon(0))
				return ITEMDRAW_DISABLED;
			else if(StrEqual(szItemInfo, WARDENMENU_ADMINMENU) && !GetAdminFlag(GetUserAdmin(iClient), Admin_Ban))
				return ITEMDRAW_DISABLED;
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}