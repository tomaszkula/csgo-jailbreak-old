#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Random"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

#define RANDOMMENU_BLANK "blank"
#define RANDOMMENU_REPEAT "repeat"
#define RANDOMMENU_NOREPEAT "no_repeat"
#define RANDOMMENU_NOREPEAT_RESET "no_repeat_reset"

bool g_bIsBlocked = true, g_bIsRandom[MAXPLAYERS + 1];

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
	CreateNative("JB_DisplayRandomMenu", DisplayRandomMenu);
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
		g_bIsRandom[i] = false;
}

public void OnDayMode(int iOldDayMode, int iNewDayMode)
{
	if(iOldDayMode == NORMAL)
	{
		g_bIsBlocked = true;
		for (int i = 1; i <= MaxClients; i++)
			g_bIsRandom[i] = false;
		
		UnhookEvent("round_prestart", RoundPrestartEvent);
		UnhookEvent("player_team", PlayerTeamEvent);
		UnhookEvent("player_death", PlayerDeathEvent);
	}
	
	if(iNewDayMode == NORMAL)
	{
		g_bIsBlocked = false;
		
		HookEvent("round_prestart", RoundPrestartEvent);
		HookEvent("player_team", PlayerTeamEvent);
		HookEvent("player_death", PlayerDeathEvent);
	}
}

public Action RoundPrestartEvent(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
		g_bIsRandom[i] = false;
	
	return Plugin_Continue;
}

public Action PlayerTeamEvent(Event event, const char[] name, bool dontBroadcast)
{
	bool disconnected = event.GetBool("disconnect");
	if(disconnected)
	{
		int iClient = GetClientOfUserId(event.GetInt("userid"));
		g_bIsRandom[iClient] = false;
	}
	
	return Plugin_Continue;
}

public Action PlayerDeathEvent(Event event, const char[] name, bool dontBroadcast)
{
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	g_bIsRandom[iVictim] = false;
		
	return Plugin_Continue;
}

public int RandomMenuHandler(Menu menu, MenuAction action, int iClient, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(g_bIsBlocked || !IsUserValid(iClient) || !JB_IsSimon(iClient))
				return -1;
				
			char szInfo[MAX_TEXT_LENGTH];
			menu.GetItem(param2, szInfo, sizeof(szInfo)); 
			if(StrEqual(szInfo, RANDOMMENU_REPEAT))
			{
				char szRandomName[MAX_TEXT_LENGTH];
				int iRandom = RandomPrisoner();
				if(iRandom == -1)
					PrintToChat(iClient, "%s Brak więźniów do wylosowania.", JB_PREFIX);
				else
				{
					GetClientName(iRandom, szRandomName, sizeof(szRandomName));
					PrintCenterTextAll("Wylosowano %s", szRandomName);
				}
			}
			else if(StrEqual(szInfo, RANDOMMENU_NOREPEAT))
			{
				char szRandomName[MAX_TEXT_LENGTH];
				int iRandom = RandomPrisoner(false);
				if(iRandom == -1)
					PrintToChat(iClient, "%s Brak więźniów do wylosowania.", JB_PREFIX);
				else
				{
					g_bIsRandom[iRandom] = true;
					GetClientName(iRandom, szRandomName, sizeof(szRandomName));
					PrintCenterTextAll(" \x07Wylosowano %s", szRandomName);
				}
			}
			else if(StrEqual(szInfo, RANDOMMENU_NOREPEAT_RESET))
			{
				for (int i = 1; i <= MaxClients; i++)
					g_bIsRandom[i] = false;
			}
			
			JB_DisplayRandomMenu(iClient);
		}
		
		case MenuAction_Cancel:
			JB_DisplayPrisonersManagerMenu(iClient);
		
		case MenuAction_End:
			delete menu;
	}
	
	return 0;
}

int RandomPrisoner(bool bRepeat = true)
{
	int iClients[MAXPLAYERS], iCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsUserValid(i) || !IsPlayerAlive(i) || GetClientTeam(i) != CS_TEAM_T || JB_HasFreeDay(i) || JB_IsRebel(i))
			continue;
			
		if(!bRepeat && g_bIsRandom[i])
			continue;
		
		iClients[iCount] = i;
		iCount++;
	}
	
	if(iCount < 1)
		return -1;
	
	return iClients[GetRandomInt(0, iCount - 1)];
}

/////////////////////////////////////////////////////////////
////////////////////////// NATIVES //////////////////////////
/////////////////////////////////////////////////////////////

public int DisplayRandomMenu(Handle plugin, int argc)
{
	int iClient = GetNativeCell(1);
	if(g_bIsBlocked || !IsUserValid(iClient) || !JB_IsSimon(iClient))
		return;
	
	Menu menu = CreateMenu(RandomMenuHandler, MENU_ACTIONS_ALL);
	menu.AddItem(RANDOMMENU_REPEAT, "Losuj z powtórzeniami");
	menu.AddItem(RANDOMMENU_NOREPEAT, "Losuj bez powtórzeń");
	menu.AddItem(RANDOMMENU_NOREPEAT_RESET, "Zresetuj powtórzenia");
	menu.SetTitle("[Menu] Wylosuj więźnia");
	menu.ExitBackButton = true;
	menu.Display(iClient, MENU_TIME_FOREVER);
}