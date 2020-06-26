#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Admin Menu"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

#define ADMINMENU_REVIVE "revive"
#define ADMINMENU_BINDCELLS "bind_cells"

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
	CreateNative("JB_DisplayAdminMenu", DisplayAdminMenu);
}

public void OnPluginStart()
{
	RegAdminCmd("jb_admin_menu", AdminMenuCmd, ADMFLAG_BAN);
}

public Action AdminMenuCmd(int iClient, int args)
{
	JB_DisplayAdminMenu(iClient);
	
	return Plugin_Handled;
}

public int AdminMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (!GetAdminFlag(GetUserAdmin(param1), Admin_Ban))
				return -1;
			
			char szInfo[MAX_TEXT_LENGTH];
			menu.GetItem(param2, szInfo, sizeof(szInfo)); 
			if(StrEqual(szInfo, ADMINMENU_REVIVE))
			{
				JB_DisplayReviveMenu(param1);
			}
			else if(StrEqual(szInfo, ADMINMENU_BINDCELLS))
			{
				JB_DisplayBindCellButtonsMenu(param1);
			}
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

public int DisplayAdminMenu(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	if(!IsUserValid(iClient))
		return;
	
	Menu menu = CreateMenu(AdminMenuHandler, MENU_ACTIONS_ALL);
	menu.SetTitle("[Menu] Admin");
	menu.AddItem(ADMINMENU_REVIVE, "Ożyw gracza");
	menu.AddItem(ADMINMENU_BINDCELLS, "Ustaw przycisk cel");
	menu.Display(iClient, MENU_TIME_FOREVER);
}