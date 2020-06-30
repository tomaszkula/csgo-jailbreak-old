#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"
#include "voiceannounce_ex.inc"

#define PLUGIN_NAME "[JB] Mute"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

bool g_bMute[MAXPLAYERS + 1][MAXPLAYERS + 1];

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
	CreateNative("JB_DisplayMuteMenu", DisplayMuteMenu);
}

public void OnPluginStart()
{
	RegConsoleCmd("wycisz", MuteCmd);
	RegConsoleCmd("mute", MuteCmd);
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
		for (int j = 1; j <= MaxClients; j++)
			g_bMute[i][j] = false;
}

public void OnClientDisconnect_Post(int iClient)
{
	for (int i = 1; i <= MaxClients; i++)
		g_bMute[iClient][i] = false;
		
	for (int i = 1; i <= MaxClients; i++)
		g_bMute[i][iClient] = false;
}

public void OnClientSpeakingEx(int iClient)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsUserValid(i) || i == iClient)
			continue;
		
		if(g_bMute[i][iClient])
			SetListenOverride(i, iClient, Listen_No);
		else
			SetListenOverride(i, iClient, Listen_Default);
	}
}

public Action MuteCmd(int iClient, int args)
{
	JB_DisplayMuteMenu(iClient);
	return Plugin_Continue;
}

public int MuteMenuHandler(Menu menu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char szItemInfo[MAX_TEXT_LENGTH];
			menu.GetItem(iItem, szItemInfo, sizeof(szItemInfo)); 
			
			int iTarget = StringToInt(szItemInfo);
			if(!IsUserValid(iTarget))
				return -1;
				
			g_bMute[iClient][iTarget] = !g_bMute[iClient][iTarget];
			JB_DisplayMuteMenu(iClient);
		}
		
		case MenuAction_End:
			delete menu;
	}
	
	return 0;
}

/////////////////////////////////////////////////////////////
////////////////////////// NATIVES //////////////////////////
/////////////////////////////////////////////////////////////

public int DisplayMuteMenu(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	if(!IsUserValid(iClient))
		return;
	
	Menu menu = CreateMenu(MuteMenuHandler, MENU_ACTIONS_ALL);
	char szItemInfo[MAX_TEXT_LENGTH], szItemTitle[MAX_TEXT_LENGTH], szClientName[MAX_TEXT_LENGTH];
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsUserValid(i) || i == iClient)
			continue;
		
		GetClientName(i, szClientName, sizeof(szClientName));
		
		Format(szItemInfo, sizeof(szItemInfo), "%i", i);
		Format(szItemTitle, sizeof(szItemTitle), "%s", szClientName);
		if(g_bMute[iClient][i])
			Format(szItemTitle, sizeof(szItemTitle), "%s %s", szItemTitle, "[ODMUTUJ]");
		menu.AddItem(szItemInfo, szItemTitle);
	}
	menu.SetTitle("[Menu] Wycisz/Odcisz gracza");
	menu.Display(iClient, MENU_TIME_FOREVER);
}