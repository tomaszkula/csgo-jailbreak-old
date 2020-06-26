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

public void OnPluginStart()
{
	RegAdminCmd("jb_revive_menu", ReviveMenuCmd, ADMFLAG_BAN);
}

public Action ReviveMenuCmd(int iClient, int args)
{
	JB_DisplayReviveMenu(iClient);
	
	return Plugin_Handled;
}

public int ReviveMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (!GetAdminFlag(GetUserAdmin(param1), Admin_Ban))
				return -1;
			
			char szInfo[MAX_TEXT_LENGTH];
			menu.GetItem(param2, szInfo, sizeof(szInfo)); 
			int iTarget = StringToInt(szInfo);
			int iTeam = GetClientTeam(iTarget);
			if(!IsUserValid(iTarget) || IsPlayerAlive(iTarget) || iTeam == CS_TEAM_NONE || iTeam == CS_TEAM_SPECTATOR)
			{
        		JB_DisplayReviveMenu(param1);
        		return -1;
        	}
			
			CS_RespawnPlayer(iTarget);
			
			char szClientName[MAX_TEXT_LENGTH];
			GetClientName(iTarget, szClientName, sizeof(szClientName));
			if(iTeam == CS_TEAM_CT)
				PrintToChatAll("%s Strażnik \x0b%s \x01został ożywiony.", JB_PREFIX, szClientName);
			else
				PrintToChatAll("%s Więzień \x07%s \x01został ożywiony.", JB_PREFIX, szClientName);
			
			JB_DisplayReviveMenu(param1);
		}
		
		case MenuAction_Cancel:
		{
			JB_DisplayAdminMenu(param1);
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

/////////////////////////////////////////////////////////////
////////////////////////// NATIVES //////////////////////////
/////////////////////////////////////////////////////////////

public int DisplayReviveMenu(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	if(!IsUserValid(iClient))
		return;
	
	Menu menu = CreateMenu(ReviveMenuHandler, MENU_ACTIONS_ALL);
	char szItemInfo[MAX_TEXT_LENGTH], szItemTitle[MAX_TEXT_LENGTH];
	for(int i = 1; i <= MaxClients; i++)
	{
    	if(!IsUserValid(i) || IsPlayerAlive(i))
        	continue;
        	
        int iTeam = GetClientTeam(i);
        if(iTeam == CS_TEAM_NONE || iTeam == CS_TEAM_SPECTATOR)
        	continue;
        
        char szClientName[MAX_TEXT_LENGTH];
        GetClientName(i, szClientName, sizeof(szClientName));
        
        Format(szItemInfo, sizeof(szItemInfo), "%i", i);
        Format(szItemTitle, sizeof(szItemTitle), "%s [%s]", szClientName, iTeam == CS_TEAM_CT ? "CT" : "TT");
        menu.AddItem(szItemInfo, szItemTitle);
	} 
	menu.SetTitle("[Menu] Ożyw gracza");
	menu.ExitBackButton = true;
	menu.Display(iClient, MENU_TIME_FOREVER);
}