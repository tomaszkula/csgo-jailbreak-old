#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Divide"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

bool g_bHasAccess[MAXPLAYERS + 1], g_bIsDivided[MAXPLAYERS + 1];
int g_iGlowEntity[MAXPLAYERS + 1];

char g_szTeamsColors[][MAX_TEXT_LENGTH] = {"255 255 0", "255 0 255", "0 255 255", "255 255 255"}
char g_szTeamsColorsNames[][MAX_TEXT_LENGTH] = {"żółty", "różowy", "aqua", "biały"}

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
	CreateNative("JB_DisplayDivideMenu", DisplayDivideMenu);
	CreateNative("JB_AddDivision", AddDivision);
	CreateNative("JB_RemoveDivision", RemoveDivision);
	CreateNative("JB_IsDivided", IsDivided);
}

public void OnPluginStart()
{
	HookEvent("round_end", RoundEndEvent);
	HookEvent("player_death", PlayerDeathEvent);
	
	RegConsoleCmd("jb_divide_menu", DivideMenuCmd);
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bHasAccess[i] = false;
		g_bIsDivided[i] = false;
	}
}

public void OnClientDisconnect_Post(int iClient)
{
	g_bHasAccess[iClient] = false;
	g_bIsDivided[iClient] = false;
}

public void OnAddSimon(int iClient)
{
	g_bHasAccess[iClient] = true;
}

public void OnRemoveSimon(int iClient)
{
	g_bHasAccess[iClient] = false;
}

public Action RoundEndEvent(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bHasAccess[i] = false;
		g_bIsDivided[i] = false;
	}
	
	return Plugin_Continue;
}

public Action PlayerDeathEvent(Event event, const char[] name, bool dontBroadcast)
{
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	g_bHasAccess[iVictim] = false;
	if(JB_IsDivided(iVictim))
		JB_RemoveDivision(iVictim);
		
	return Plugin_Continue;
}

public Action DivideMenuCmd(int iClient, int args)
{
	JB_DisplayDivideMenu(iClient);
	
	return Plugin_Handled;
}

public int DivideMenuHandler(Menu menu, MenuAction action, int iClient, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(!g_bHasAccess[iClient])
				return -1;
			
			char szInfo[MAX_TEXT_LENGTH];
			menu.GetItem(param2, szInfo, sizeof(szInfo)); 
			int iTeamsCount = StringToInt(szInfo), count = 0;
			for (int i = 1; i <= MaxClients; i++)
			{
				if(!IsUserValid(i) || !IsPlayerAlive(i) || GetClientTeam(i) != CS_TEAM_T || JB_HasFreeDay(i) || JB_IsRebel(i))
        			continue;
        			
				if(JB_IsDivided(i))
					JB_RemoveDivision(i);
        		
				JB_AddDivision(i, g_szTeamsColors[count % iTeamsCount]);
				count++;
			}
			
			JB_DisplayDivideMenu(iClient);
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

public int DisplayDivideMenu(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	if(!IsUserValid(iClient) || !g_bHasAccess[iClient])
		return;
	
	Menu menu = CreateMenu(DivideMenuHandler, MENU_ACTIONS_ALL);
	menu.AddItem("2", "2 drużyny");
	menu.AddItem("3", "3 drużyny");
	menu.AddItem("4", "4 drużyny");
	menu.SetTitle("[Menu] Podziel więźniów");
	menu.Display(iClient, MENU_TIME_FOREVER);
}

public int AddDivision(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	char szColor[MAX_TEXT_LENGTH]; GetNativeString(2, szColor, sizeof(szColor));
	
	g_bIsDivided[iClient] = true;
	g_iGlowEntity[iClient] = RenderDynamicGlow(iClient, szColor);
}

public int RemoveDivision(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	
	g_bIsDivided[iClient] = false;
	RemoveDynamicGlow(g_iGlowEntity[iClient]);
}

public int IsDivided(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	return g_bIsDivided[iClient];
}