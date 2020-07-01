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

char g_szPrisonerModels[MAX_SKINS_COUNT][MAX_TEXT_LENGTH];
int g_iPrisonerModelsCount;
bool g_bIsBlocked = true;

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
	g_iPrisonerModelsCount = 0;
	
	char szConfigPath[MAX_TEXT_LENGTH];
	BuildPath(Path_SM, szConfigPath, sizeof(szConfigPath), "configs/tomkul777/jailbreak/models/prisoner_models.cfg");
	if (FileExists(szConfigPath))
	{
		char szModelsDlPath[MAX_TEXT_LENGTH], szMaterialsDlPath[MAX_TEXT_LENGTH], szModelPath[MAX_TEXT_LENGTH], szArmsPath[MAX_TEXT_LENGTH], szFilePath[MAX_TEXT_LENGTH];
		Handle kv = CreateKeyValues("Models");
		if(FileToKeyValues(kv, szConfigPath))
		{
			KvGotoFirstSubKey(kv);
			do
			{
				if(KvGetString(kv, "models_dl", szModelsDlPath, sizeof(szModelsDlPath)) && DirExists(szModelsDlPath) &&
					KvGetString(kv, "materials_dl", szMaterialsDlPath, sizeof(szMaterialsDlPath)) && DirExists(szMaterialsDlPath))
				{
					Handle hDir = OpenDirectory(szModelsDlPath);
					while(ReadDirEntry(hDir, szFilePath, sizeof(szFilePath)))
					{
						Format(szFilePath, sizeof(szFilePath), "%s/%s", szModelsDlPath, szFilePath);
						AddFileToDownloadsTable(szFilePath);
					}
					CloseHandle(hDir);
					
					hDir = OpenDirectory(szMaterialsDlPath);
					while(ReadDirEntry(hDir, szFilePath, sizeof(szFilePath)))
					{
						Format(szFilePath, sizeof(szFilePath), "%s/%s", szMaterialsDlPath, szFilePath);
						AddFileToDownloadsTable(szFilePath);
					}
					CloseHandle(hDir);
					
					if (KvGetString(kv, "model", szModelPath, sizeof(szModelPath)))
					{
						g_szPrisonerModels[g_iPrisonerModelsCount] = szModelPath;
						g_iPrisonerModelsCount++;
						
						PrecacheModel(szModelPath, true);
					}
				}
			} while (KvGotoNextKey(kv));
			KvRewind(kv);
		}
		CloseHandle(kv);
	}
}

public void OnDayMode(int iOldDayMode, int iNewDayMode)
{
	if(iOldDayMode == NORMAL)
		g_bIsBlocked = true;
	
	if(iNewDayMode == NORMAL)
		g_bIsBlocked = false;
}

public Action PlayerSpawnEvent(Event event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	if (GetClientTeam(iClient) == CS_TEAM_T)
	{
		if(g_iPrisonerModelsCount > 0)
		{
			int iSkin = GetRandomInt(0, g_iPrisonerModelsCount - 1);
			SetEntityModel(iClient, g_szPrisonerModels[iSkin]);
		}
		
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
	if(!IsUserValid(iClient) || !IsPlayerAlive(iClient) || GetClientTeam(iClient) != CS_TEAM_T)
		return Plugin_Continue;
	
	DisplayPrisonerMenu(iClient);
	return Plugin_Handled;
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
			
			if(g_bIsBlocked)
			{
				if(StrEqual(szItemInfo, PRISONERMENU_HATS))
					return -1;
				else if(StrEqual(szItemInfo, PRISONERMENU_ROULETTE))
					return -1;
				else if(StrEqual(szItemInfo, PRISONERMENU_SHOP))
					return -1;
				else if(StrEqual(szItemInfo, PRISONERMENU_STEALGUN))
					return -1;
			}
			else
			{
				if(StrEqual(szItemInfo, PRISONERMENU_STEALGUN))
				{
					FakeClientCommand(iClient, "steal");
					DisplayPrisonerMenu(iClient);
				}
			}
			
			if(!GetAdminFlag(GetUserAdmin(iClient), Admin_Ban))
			{
				if(StrEqual(szItemInfo, PRISONERMENU_ADMINMENU))
					return -1;
			}
			else
			{
				if(StrEqual(szItemInfo, PRISONERMENU_ADMINMENU))
					JB_DisplayAdminMenu(iClient);
			}
		}
		
		case MenuAction_DrawItem:
		{
			char szItemInfo[MAX_TEXT_LENGTH];
			menu.GetItem(iItem, szItemInfo, sizeof(szItemInfo)); 
			
			if(g_bIsBlocked)
			{
				if(StrEqual(szItemInfo, PRISONERMENU_HATS))
					return ITEMDRAW_DISABLED;
				else if(StrEqual(szItemInfo, PRISONERMENU_ROULETTE))
					return ITEMDRAW_DISABLED;
				else if(StrEqual(szItemInfo, PRISONERMENU_SHOP))
					return ITEMDRAW_DISABLED;
				else if(StrEqual(szItemInfo, PRISONERMENU_STEALGUN))
					return ITEMDRAW_DISABLED;
			}
			
			if(StrEqual(szItemInfo, PRISONERMENU_ADMINMENU) && !GetAdminFlag(GetUserAdmin(iClient), Admin_Ban))
				return ITEMDRAW_DISABLED;
		}
		
		case MenuAction_End:
			delete menu;
	}
	
	return 0;
}