#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Revive"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

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
	CreateNative("JB_DisplayReviveMenu", DisplayReviveMenu);
}

public int ReviveMenuHandler(Menu menu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (!IsUserValid(iClient) || !GetAdminFlag(GetUserAdmin(iClient), Admin_Ban))
				return -1;
			
			char szItemInfo[MAX_TEXT_LENGTH];
			menu.GetItem(iItem, szItemInfo, sizeof(szItemInfo)); 
			int iTarget = StringToInt(szItemInfo);
			int iTeam = GetClientTeam(iTarget);
			if(!IsUserValid(iTarget) || IsPlayerAlive(iTarget) || iTeam == CS_TEAM_NONE || iTeam == CS_TEAM_SPECTATOR)
			{
        		JB_DisplayReviveMenu(iClient);
        		return -1;
        	}
			
			CS_RespawnPlayer(iTarget);
			
			char szTargetName[MAX_TEXT_LENGTH];
			GetClientName(iTarget, szTargetName, sizeof(szTargetName));
			if(iTeam == CS_TEAM_CT)
				PrintToChatAll("%s Strażnik \x0b%s \x01został ożywiony.", JB_PREFIX, szTargetName);
			else
				PrintToChatAll("%s Więzień \x07%s \x01został ożywiony.", JB_PREFIX, szTargetName);
			
			JB_DisplayReviveMenu(iClient);
		}
		
		case MenuAction_Cancel:
			JB_DisplayAdminMenu(iClient);
		
		case MenuAction_End:
			delete menu;
	}
	
	return 0;
}

/////////////////////////////////////////////////////////////
////////////////////////// NATIVES //////////////////////////
/////////////////////////////////////////////////////////////

public int DisplayReviveMenu(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	if (!IsUserValid(iClient) || !GetAdminFlag(GetUserAdmin(iClient), Admin_Ban))
		return;
	
	Menu menu = CreateMenu(ReviveMenuHandler, MENU_ACTIONS_ALL);
	char szItemInfo[MAX_TEXT_LENGTH], szItemTitle[MAX_TEXT_LENGTH], szTargetName[MAX_TEXT_LENGTH];
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsUserValid(i) || IsPlayerAlive(i))
        	continue;
        
		int iTeam = GetClientTeam(i);
		if(iTeam == CS_TEAM_NONE || iTeam == CS_TEAM_SPECTATOR)
        	continue;
        
		GetClientName(i, szTargetName, sizeof(szTargetName));
		Format(szItemInfo, sizeof(szItemInfo), "%i", i);
		Format(szItemTitle, sizeof(szItemTitle), "%s [%s]", szTargetName, iTeam == CS_TEAM_CT ? "CT" : "TT");
		menu.AddItem(szItemInfo, szItemTitle);
	} 
	menu.SetTitle("[Menu] Ożyw gracza");
	menu.ExitBackButton = true;
	menu.Display(iClient, MENU_TIME_FOREVER);
}