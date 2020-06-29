#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Prisoner"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

#define PRISONERMENU_HATS "hats"
#define PRISONERMENU_ROULETTE "roulette"
#define PRISONERMENU_SHOP "shop"
#define PRISONERMENU_STEALGUN "steal_gun"
#define PRISONERMENU_OTHERS "others"
#define PRISONERMENU_ADMINMENU "admin_menu"

char g_szPrisonerModels[][MAX_TEXT_LENGTH] = 
{
	{"models/player/custom_player/kuristaja/jailbreak/prisoner1/prisoner1.mdl"},
};

char g_szPrisonerModelsAll[][MAX_TEXT_LENGTH] = 
{
	{"models/player/custom_player/kuristaja/jailbreak/prisoner1/prisoner1.dx90.vtx"},
	{"models/player/custom_player/kuristaja/jailbreak/prisoner1/prisoner1.mdl"},
	{"models/player/custom_player/kuristaja/jailbreak/prisoner1/prisoner1.phy"},
	{"models/player/custom_player/kuristaja/jailbreak/prisoner1/prisoner1.vvd"},
	{"models/player/custom_player/kuristaja/jailbreak/prisoner1/prisoner1_arms.dx90.vtx"},
	{"models/player/custom_player/kuristaja/jailbreak/prisoner1/prisoner1_arms.mdl"},
	{"models/player/custom_player/kuristaja/jailbreak/prisoner1/prisoner1_arms.vvd"},
	{"materials/models/player/kuristaja/jailbreak/prisoner1/eye_d.vmt"},
	{"materials/models/player/kuristaja/jailbreak/prisoner1/prisoner_lt_bottom_d.vmt"},
	{"materials/models/player/kuristaja/jailbreak/prisoner1/prisoner_lt_head_d.vmt"},
	{"materials/models/player/kuristaja/jailbreak/prisoner1/prisoner_lt_top_d.vmt"},
	{"materials/models/player/kuristaja/jailbreak/prisoner1/prisoners_torso_d.vmt"},
	{"materials/models/player/kuristaja/jailbreak/prisoner1/eye_d.vtf"},
	{"materials/models/player/kuristaja/jailbreak/prisoner1/prisoner_lt_bottom_d.vtf"},
	{"materials/models/player/kuristaja/jailbreak/prisoner1/prisoner_lt_bottom_normal.vtf"},
	{"materials/models/player/kuristaja/jailbreak/prisoner1/prisoner_lt_head_normal.vtf"},
	{"materials/models/player/kuristaja/jailbreak/prisoner1/prisoner_lt_top_d.vtf"},
	{"materials/models/player/kuristaja/jailbreak/prisoner1/prisoner_lt_top_normal.vtf"},
	{"materials/models/player/kuristaja/jailbreak/prisoner1/prisoners_torso_d.vtf"},
	
	{"materials/models/player/kuristaja/jailbreak/shared/brown_eye01_an_d.vmt"},
	{"materials/models/player/kuristaja/jailbreak/shared/police_body_d.vmt"},
	{"materials/models/player/kuristaja/jailbreak/shared/prisoner1_body.vmt"},
	{"materials/models/player/kuristaja/jailbreak/shared/tex_0086_0.vmt"},
	{"materials/models/player/kuristaja/jailbreak/shared/brown_eye_normal.vtf"},
	{"materials/models/player/kuristaja/jailbreak/shared/brown_eye01_an_d.vtf"},
	{"materials/models/player/kuristaja/jailbreak/shared/police_body_d.vtf"},
	{"materials/models/player/kuristaja/jailbreak/shared/police_body_normal.vtf"},
	{"materials/models/player/kuristaja/jailbreak/shared/prisoner1_body.vtf"},
	{"materials/models/player/kuristaja/jailbreak/shared/prisoner1_body_normal.vtf"},
	{"materials/models/player/kuristaja/jailbreak/shared/tex_0086_0.vtf"},
	{"materials/models/player/kuristaja/jailbreak/shared/tex_0086_1.vtf"}
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
	for (int i = 0; i < sizeof(g_szPrisonerModelsAll); i++)
		AddFileToDownloadsTable(g_szPrisonerModelsAll[i]);
	
	for (int i = 0; i < sizeof(g_szPrisonerModels); i++)
		PrecacheModel(g_szPrisonerModels[i], true);
}

public Action PlayerSpawnEvent(Event event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	if (GetClientTeam(iClient) == CS_TEAM_T)
	{
		SetEntityModel(iClient, g_szPrisonerModels[0][0]);
		
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
	if(GetClientTeam(iClient) == CS_TEAM_T)
		DisplayPrisonerMenu(iClient);
	
	return Plugin_Continue;
}

public void DisplayPrisonerMenu(int iClient)
{
	if(!IsUserValid(iClient) || !IsPlayerAlive(iClient) || GetClientTeam(iClient) != CS_TEAM_T)
		return;
	
	Menu menu = CreateMenu(PrisonerMenuHandler, MENU_ACTIONS_ALL);
	menu.AddItem(PRISONERMENU_HATS, "Czapki");
	menu.AddItem(PRISONERMENU_ROULETTE, "Ruletka");
	menu.AddItem(PRISONERMENU_SHOP, "Sklep");
	menu.AddItem(PRISONERMENU_STEALGUN, "Kradnij broń");
	menu.AddItem(PRISONERMENU_OTHERS, "Inne informacje");
	menu.AddItem(PRISONERMENU_ADMINMENU, "Menu Admina");
	menu.SetTitle("[Menu] Więzień");
	menu.Display(iClient, MENU_TIME_FOREVER);
}

public int PrisonerMenuHandler(Menu menu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(!IsUserValid(iClient) || !IsPlayerAlive(iClient) || GetClientTeam(iClient) != CS_TEAM_T)
				return -1;
			
			char szItemInfo[MAX_TEXT_LENGTH];
			menu.GetItem(iItem, szItemInfo, sizeof(szItemInfo)); 
			if(StrEqual(szItemInfo, PRISONERMENU_STEALGUN))
			{
				FakeClientCommand(iClient, "steal");
				DisplayPrisonerMenu(iClient);
			}
			else if(StrEqual(szItemInfo, PRISONERMENU_ADMINMENU))
			{
				if(GetAdminFlag(GetUserAdmin(iClient), Admin_Ban))
					JB_DisplayAdminMenu(iClient);
				else
					DisplayPrisonerMenu(iClient);
			}
		}
		
		case MenuAction_DrawItem:
		{
			char szItemInfo[MAX_TEXT_LENGTH];
			menu.GetItem(iItem, szItemInfo, sizeof(szItemInfo)); 
			
			if(StrEqual(szItemInfo, PRISONERMENU_ADMINMENU) && !GetAdminFlag(GetUserAdmin(iClient), Admin_Ban))
				return ITEMDRAW_DISABLED;
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}