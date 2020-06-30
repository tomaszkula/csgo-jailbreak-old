#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Heal"
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
	CreateNative("JB_DisplayHealMenu", DisplayHealMenu);
}

public int HealMenuHandler(Menu menu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(!IsUserValid(iClient) || !JB_IsSimon(iClient))
				return -1;
			
			char szItemInfo[MAX_TEXT_LENGTH];
			menu.GetItem(iItem, szItemInfo, sizeof(szItemInfo)); 
			int iTarget = StringToInt(szItemInfo);
			if(!IsUserValid(iTarget) || !IsPlayerAlive(iTarget) || GetClientTeam(iTarget) != CS_TEAM_T || JB_HasFreeDay(iTarget) || JB_IsRebel(iTarget) || GetClientHealth(iTarget) >= 100)
			{
        		JB_DisplayHealMenu(iClient);
        		return -1;
        	}
        	
			char szTargetName[MAX_TEXT_LENGTH];
			GetClientName(iTarget, szTargetName, sizeof(szTargetName));
			
			SetEntityHealth(iTarget, 100);
			PrintToChatAll("%s Więzień \x07%s \x01został uleczony.", JB_PREFIX, szTargetName);
			
			JB_DisplayHealMenu(iClient);
		}
		
		case MenuAction_Cancel:
			JB_DisplayPrisonersManagerMenu(iClient);
		
		case MenuAction_End:
			delete menu;
	}
	
	return 0;
}

/////////////////////////////////////////////////////////////
////////////////////////// NATIVES //////////////////////////
/////////////////////////////////////////////////////////////

public int DisplayHealMenu(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	if(!IsUserValid(iClient) || !JB_IsSimon(iClient))
		return;
	
	Menu menu = CreateMenu(HealMenuHandler, MENU_ACTIONS_ALL);
	char szItemInfo[MAX_TEXT_LENGTH], szItemTitle[MAX_TEXT_LENGTH];
	for(int i = 1; i <= MaxClients; i++)
	{
    	if(!IsUserValid(i) || !IsPlayerAlive(i) || GetClientTeam(i) != CS_TEAM_T || JB_HasFreeDay(i) || JB_IsRebel(i) || GetClientHealth(i) >= 100)
        	continue;
        
        char szTargetName[MAX_TEXT_LENGTH];
        GetClientName(i, szTargetName, sizeof(szTargetName));
        
        Format(szItemInfo, sizeof(szItemInfo), "%i", i);
        Format(szItemTitle, sizeof(szItemTitle), "%s [%iHP]", szTargetName, GetClientHealth(i));
        menu.AddItem(szItemInfo, szItemTitle);
	} 
	menu.SetTitle("[Menu] Ulecz więźnia");
	menu.ExitBackButton = true;
	menu.Display(iClient, MENU_TIME_FOREVER);
}