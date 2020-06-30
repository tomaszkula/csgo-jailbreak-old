#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Cells"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

#define CELL_BUTTONS_CONFIG_PATH "configs/tomkul777/jailbreak/cell_buttons"
#define CELL_BUTTONS_SLOTS 3
#define KV_ROOT "cell_buttons"
#define KV_KEY "slot"
#define KV_VALUE "id_entity"

char szFilePath[MAX_TEXT_LENGTH];
int g_iButtons[CELL_BUTTONS_SLOTS];
KeyValues kv;

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
	CreateNative("JB_DisplayBindButtonsMenu", DisplayBindButtonsMenu);
	CreateNative("JB_OpenCells", OpenCells);
}

public void OnPluginStart()
{
	char szDirPath[MAX_TEXT_LENGTH];
	BuildPath(Path_SM, szDirPath, sizeof(szDirPath), "%s", CELL_BUTTONS_CONFIG_PATH);
	if(!DirExists(szDirPath))
		CreateDirectories(szDirPath, 511);
}

public void OnMapStart()
{
	char szMapName[MAX_TEXT_LENGTH];
	GetCurrentMap(szMapName, sizeof(szMapName));
	BuildPath(Path_SM, szFilePath, sizeof(szFilePath), "%s/%s.cfg", CELL_BUTTONS_CONFIG_PATH, szMapName);
	
	kv = CreateKeyValues(KV_ROOT);
	if(FileToKeyValues(kv, szFilePath))
	{
		for (int i = 0; i < CELL_BUTTONS_SLOTS; i++)
		{
			char key[MAX_TEXT_LENGTH];
			Format(key, sizeof(key), "%s%i", KV_KEY, i + 1);
			
			if(KvJumpToKey(kv, key))
				g_iButtons[i] = KvGetNum(kv, KV_VALUE, -1);
			else
				g_iButtons[i] = -1;
			KvGoBack(kv);
		}
		KvRewind(kv);
	}
	else
	{
		for (int i = 0; i < CELL_BUTTONS_SLOTS; i++)
			g_iButtons[i] = -1;
	}
}

public void OnMapEnd()
{
	CloseHandle(kv);
}

public int BindButtonsMenuHandler(Menu menu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (!IsUserValid(iClient) || !GetAdminFlag(GetUserAdmin(iClient), Admin_Ban))
				return -1;

			char szItemInfo[MAX_TEXT_LENGTH];
			menu.GetItem(iItem, szItemInfo, sizeof(szItemInfo)); 
			BindCellButton(iClient, iItem, szItemInfo);
			JB_DisplayBindButtonsMenu(iClient);
		}
		
		case MenuAction_Cancel:
			JB_DisplayAdminMenu(iClient);
		
		case MenuAction_End:
			delete menu;
	}
	
	return 0;
}

public void BindCellButton(int iClient, int iSlot, char[] szSlot)
{
	if(IsValidEntity(g_iButtons[iSlot]))
	{
		g_iButtons[iSlot] = -1;
		
		if(KvJumpToKey(kv, szSlot))
		{
			KvSetNum(kv, KV_VALUE, -1);
			KvRewind(kv);
			kv.ExportToFile(szFilePath);
		}
	}
	else
	{
		int iEntity = GetClientAimTarget(iClient, false);
		if(IsValidEntity(iEntity))
		{
			char szEntityClassname[MAX_TEXT_LENGTH];
			GetEntityClassname(iEntity, szEntityClassname, sizeof(szEntityClassname));
			if(!StrEqual(szEntityClassname, "func_button"))
				return;
				
			float vEntityOrigin[3], vClientOrigin[3];
			GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", vEntityOrigin);
			GetClientAbsOrigin(iClient, vClientOrigin);
			float distance = GetVectorDistance(vEntityOrigin, vClientOrigin);
			if(distance < 200)
			{
				g_iButtons[iSlot] = iEntity;
				KvJumpToKey(kv, szSlot, true);
				KvSetNum(kv, KV_VALUE, iEntity);
				KvRewind(kv);
				kv.ExportToFile(szFilePath);
			}
		}
	}
}

/////////////////////////////////////////////////////////////
////////////////////////// NATIVES //////////////////////////
/////////////////////////////////////////////////////////////

public int DisplayBindButtonsMenu(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	if (!IsUserValid(iClient) || !GetAdminFlag(GetUserAdmin(iClient), Admin_Ban))
		return;
	
	Menu menu = CreateMenu(BindButtonsMenuHandler, MENU_ACTIONS_ALL);
	char szItemInfo[MAX_TEXT_LENGTH], szItemTitle[MAX_TEXT_LENGTH];
	for (int i = 0; i < CELL_BUTTONS_SLOTS; i++)
	{
		Format(szItemInfo, sizeof(szItemInfo), "%s%i", KV_KEY, i + 1);
		Format(szItemTitle, sizeof(szItemTitle), "Slot %i", i + 1);
		if(IsValidEntity(g_iButtons[i]))
			Format(szItemTitle, sizeof(szItemTitle), "[Zresetuj] %s, id=%i", szItemTitle, g_iButtons[i]);
		else
			Format(szItemTitle, sizeof(szItemTitle), "[Ustaw] %s", szItemTitle);
		menu.AddItem(szItemInfo, szItemTitle);
	}
	menu.SetTitle("[Menu] Ustaw przyciski cel");
	menu.ExitBackButton = true;
	menu.Display(iClient, MENU_TIME_FOREVER);
}

public int OpenCells(Handle plugin, int argc)
{
	for (int i = 0; i < CELL_BUTTONS_SLOTS; i++)
	{
		if(!IsValidEntity(g_iButtons[i]))
			continue;
		
		AcceptEntityInput(g_iButtons[i], "Press");
	}
}