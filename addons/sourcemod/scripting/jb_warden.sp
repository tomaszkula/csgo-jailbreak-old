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

char g_szWardenModels[MAX_SKINS_COUNT][MAX_TEXT_LENGTH];
int g_iWardenModelsCount;
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
	g_iWardenModelsCount = 0;
	
	char szConfigPath[MAX_TEXT_LENGTH];
	BuildPath(Path_SM, szConfigPath, sizeof(szConfigPath), "configs/tomkul777/jailbreak/models/warden_models.cfg");
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
						g_szWardenModels[g_iWardenModelsCount] = szModelPath;
						g_iWardenModelsCount++;
						
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
	if (GetClientTeam(iClient) == CS_TEAM_CT)
	{
		if(g_iWardenModelsCount > 0)
		{
			int iSkin = GetRandomInt(0, g_iWardenModelsCount - 1);
			SetEntityModel(iClient, g_szWardenModels[iSkin]);
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
	if(!IsUserValid(iClient) || !IsPlayerAlive(iClient) || GetClientTeam(iClient) != CS_TEAM_CT)
		return Plugin_Continue;
	
	DisplayWardenMenu(iClient);
	return Plugin_Handled;
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
	menu.SetTitle("[Menu] Strażnik");
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
			
			if(g_bIsBlocked)
			{
				if(StrEqual(szItemInfo, WARDENMENU_BECOMESIMON))
					return -1;
				else if(StrEqual(szItemInfo, WARDENMENU_SIMONMENU))
					return -1;
				else if(StrEqual(szItemInfo, WARDENMENU_SEARCH))
					return -1;
			}
			else
			{
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
			}
			
			if(!GetAdminFlag(GetUserAdmin(iClient), Admin_Ban))
			{
				if(StrEqual(szItemInfo, WARDENMENU_ADMINMENU))
					return -1;
			}
			else
			{
				if(StrEqual(szItemInfo, WARDENMENU_ADMINMENU))
					JB_DisplayAdminMenu(iClient);
			}
		}
		
		case MenuAction_DrawItem:
		{
			char szItemInfo[MAX_TEXT_LENGTH];
			menu.GetItem(iItem, szItemInfo, sizeof(szItemInfo)); 
			
			if(g_bIsBlocked)
			{
				if(StrEqual(szItemInfo, WARDENMENU_BECOMESIMON))
					return ITEMDRAW_DISABLED;
				else if(StrEqual(szItemInfo, WARDENMENU_SIMONMENU))
					return ITEMDRAW_DISABLED;
				else if(StrEqual(szItemInfo, WARDENMENU_SEARCH))
					return ITEMDRAW_DISABLED;
			}
			
			if(StrEqual(szItemInfo, WARDENMENU_BECOMESIMON) && !JB_IsSimon(0))
				return ITEMDRAW_DISABLED;
			else if(StrEqual(szItemInfo, WARDENMENU_ADMINMENU) && !GetAdminFlag(GetUserAdmin(iClient), Admin_Ban))
				return ITEMDRAW_DISABLED;
		}
		
		case MenuAction_End:
			delete menu;
	}
	
	return 0;
}