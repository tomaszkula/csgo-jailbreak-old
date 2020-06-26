#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Menu"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

#define MENU_ADMINMENU "admin_menu"
#define WARDENMENU_BECOMESIMON "become_simon"
#define WARDENMENU_SIMONMENU "simon_menu"

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
	CreateNative("JB_DisplayMainMenu", DisplayMainMenu);
}

public void OnPluginStart()
{
	RegConsoleCmd("menu", MenuCmd);
}

public Action MenuCmd(int iClient, int args)
{
	JB_DisplayMainMenu(iClient);
	
	return Plugin_Handled;
}

public void DisplayWardenMenu(int iClient)
{
	Menu menu = CreateMenu(WardenMenuHandler, MENU_ACTIONS_ALL);
	menu.SetTitle("[Menu] Strażnik");
	if(JB_IsSimon(iClient)) menu.AddItem(WARDENMENU_SIMONMENU, "Menu Prowadzącego")
	else menu.AddItem(WARDENMENU_BECOMESIMON, "Zostań Prowadzącym")
	menu.AddItem(MENU_ADMINMENU, "Menu Admina")
	menu.Display(iClient, MENU_TIME_FOREVER);
}

public int WardenMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char szInfo[MAX_TEXT_LENGTH];
			menu.GetItem(param2, szInfo, sizeof(szInfo)); 
			
			if(StrEqual(szInfo, WARDENMENU_BECOMESIMON))
			{
				if(JB_IsSimon(0))
					JB_AddSimon(param1);
				
				JB_DisplayMainMenu(param1);
			}
			else if(StrEqual(szInfo, WARDENMENU_SIMONMENU))
			{
				if(JB_IsSimon(param1))
					JB_DisplaySimonMenu(param1);
				else
					JB_DisplayMainMenu(param1);
			}
			else if(StrEqual(szInfo, MENU_ADMINMENU))
			{
				JB_DisplayAdminMenu(param1);
			}
		}
		
		case MenuAction_Display:
		{
			/*if(StrEqual(szInfo, WARDENMENU_BECOMESIMON))
			{
				if(JB_IsSomeoneSimon())
					return ITEMDRAW_DISABLED;
			}*/
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

public int DisplayMainMenu(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	if(!IsUserValid(iClient))
		return;
	
	switch(GetClientTeam(iClient))
	{
		case CS_TEAM_CT:
		{
			DisplayWardenMenu(iClient);
		}
	}
}