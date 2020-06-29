#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Divide"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

#define DIVIDEMENU_BLANK "blank"
#define DIVIDEMENU_TEAMS2 "teams_2"
#define DIVIDEMENU_TEAMS3 "teams_3"
#define DIVIDEMENU_TEAMS4 "teams_4"
#define DIVIDEMENU_TEAMS0 "teams_0"

char g_szColors[][MAX_TEXT_LENGTH] = {"255 255 0", "255 0 255", "0 255 255", "255 255 255"}
char g_szColorsNames[][MAX_TEXT_LENGTH] = {"żółty", "różowy", "aqua", "biały"}

bool g_bIsDivided[MAXPLAYERS + 1];
int g_iGlowEntity[MAXPLAYERS + 1];

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
}

public void OnPluginStart()
{
	HookEvent("round_end", RoundEndEvent);
	HookEvent("player_death", PlayerDeathEvent);
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
		RemoveDivision(i);
}

public void OnClientDisconnect_Post(int iClient)
{
	RemoveDivision(iClient);
}

public void OnAddFreeDay(int iClient)
{
	if(IsDivided(iClient))
		RemoveDivision(iClient);
}

public void OnAddRebel(int iClient)
{
	if(IsDivided(iClient))
		RemoveDivision(iClient);
}

public Action RoundEndEvent(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
		RemoveDivision(i);
	
	return Plugin_Continue;
}

public Action PlayerDeathEvent(Event event, const char[] name, bool dontBroadcast)
{
	int iVictim = GetClientOfUserId(event.GetInt("userid"));

	if(IsDivided(iVictim))
		RemoveDivision(iVictim);
		
	return Plugin_Continue;
}

public int DivideMenuHandler(Menu menu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(!IsUserValid(iClient) || !JB_IsSimon(iClient))
				return -1;
			
			char szItemInfo[MAX_TEXT_LENGTH];
			menu.GetItem(iItem, szItemInfo, sizeof(szItemInfo)); 
			if(StrEqual(szItemInfo, DIVIDEMENU_TEAMS2))
				DividePrisoners(2);
			else if(StrEqual(szItemInfo, DIVIDEMENU_TEAMS3))
				DividePrisoners(3);
			else if(StrEqual(szItemInfo, DIVIDEMENU_TEAMS4))
				DividePrisoners(4);
			else if(StrEqual(szItemInfo, DIVIDEMENU_TEAMS0))
				DividePrisoners(0);
			
			JB_DisplayDivideMenu(iClient);
		}
		
		case MenuAction_DrawItem:
		{
			char szItemInfo[MAX_TEXT_LENGTH];
			menu.GetItem(iItem, szItemInfo, sizeof(szItemInfo)); 
			
			if(StrEqual(szItemInfo, DIVIDEMENU_BLANK))
				return ITEMDRAW_SPACER;
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

public int DividePrisoners(int iTeamsCount)
{
	if(iTeamsCount > 0)
	{
		int iClients[MAXPLAYERS], iCount;
		for (int i = 1; i <= MaxClients; i++)
		{
			if(!IsUserValid(i) || !IsPlayerAlive(i) || GetClientTeam(i) != CS_TEAM_T || JB_HasFreeDay(i) || JB_IsRebel(i))
				continue;
				
			iClients[iCount] = i;
			iCount++;
		}
		
		Permute(iClients, iCount);
		
		for (int i = 0; i < iCount; i++)
		{
			if(IsDivided(iClients[i]))
				RemoveDivision(iClients[i]);
			
			AddDivision(iClients[i], i % iTeamsCount);
		}
	}
	else
	{
		for (int i = 1; i < MaxClients; i++)
		{
			if(IsDivided(i))
				RemoveDivision(i);
		}
	}
}

public void AddDivision(int iClient, int iColorType)
{
	g_bIsDivided[iClient] = true;
	g_iGlowEntity[iClient] = RenderDynamicGlow(iClient, g_szColors[iColorType]);
	
	PrintCenterText(iClient, "Twój kolor to : %s", g_szColorsNames[iColorType]);
}

public void RemoveDivision(int iClient)
{
	g_bIsDivided[iClient] = false;
	if(g_iGlowEntity[iClient] != -1)
	{
		RemoveDynamicGlow(g_iGlowEntity[iClient]);
		g_iGlowEntity[iClient] = -1;
	}
}

public bool IsDivided(int iClient)
{
	return g_bIsDivided[iClient];
}

/////////////////////////////////////////////////////////////
////////////////////////// NATIVES //////////////////////////
/////////////////////////////////////////////////////////////

public int DisplayDivideMenu(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	if(!IsUserValid(iClient) || !JB_IsSimon(iClient))
		return;
	
	Menu menu = CreateMenu(DivideMenuHandler, MENU_ACTIONS_ALL);
	menu.AddItem(DIVIDEMENU_TEAMS2, "2 drużyny");
	menu.AddItem(DIVIDEMENU_TEAMS3, "3 drużyny");
	menu.AddItem(DIVIDEMENU_TEAMS4, "4 drużyny");
	menu.AddItem(DIVIDEMENU_BLANK, "");
	menu.AddItem(DIVIDEMENU_TEAMS0, "Usuń podział");
	menu.SetTitle("[Menu] Podziel więźniów");
	menu.Display(iClient, MENU_TIME_FOREVER);
}