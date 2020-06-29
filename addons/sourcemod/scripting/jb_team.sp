#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Team"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

#define TEAMMENU_BLANK "blank"
#define TEAMMENU_PRISONERS "prisoners"
#define TEAMMENU_WARDENS "wardens"
#define TEAMMENU_SPEC "spectators"

#define TT_CT_RATIO 5.0

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	HookEvent("player_connect_full", PlayerConnectFullEvent);
	HookEvent("player_team", PlayerTeamEvent, EventHookMode_Pre);
	
	AddCommandListener(JoinTeamCmd, "jointeam");
	AddCommandListener(TeamMenuCmd, "xd");
	AddCommandListener(TeamMenuCmd, "teammenu");
	//AddCommandListener(TeamMenuCmd, "teammenu1");
	
	//RegConsoleCmd("teammenu", Command_Test);
}

public void OnMapStart()
{
	GameRules_SetProp("m_bIsQueuedMatchmaking", 1);
}

public Action PlayerConnectFullEvent(Event event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	DisplayTeamMenu(iClient);
	
	return Plugin_Continue;
}

public Action PlayerTeamEvent(Event event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	int iTeam = event.GetInt("team");
	char szTeamName[MAX_TEXT_LENGTH];
	if(iTeam == CS_TEAM_CT)
		szTeamName = "strażników";
	else if(iTeam == CS_TEAM_T)
		szTeamName = "więźniów";
	else if(iTeam == CS_TEAM_SPECTATOR)
		szTeamName = "obserwatorów";
	else
		szTeamName = "BRAK";
	PrintToChat(iClient, "%s Dołączyłeś do drużyny %s.", JB_PREFIX, szTeamName);
	
	event.SetBool("silent", true);
	return Plugin_Changed;
}

public Action JoinTeamCmd(int iClient, const char[] command, int argc)
{
	return Plugin_Stop;
}

public Action TeamMenuCmd(int iClient, const char[] command, int argc)
{
	DisplayTeamMenu(iClient);
	PrintToConsole(iClient, "teammenu");
	
	return Plugin_Changed;
}

public void DisplayTeamMenu(int iClient)
{
	Menu menu = new Menu(TeamMenuHandler, MENU_ACTIONS_ALL);
	menu.AddItem(TEAMMENU_PRISONERS, "Dołącz do więźniów");
	menu.AddItem(TEAMMENU_WARDENS, "Dołącz do strażników");
	menu.AddItem(TEAMMENU_BLANK, "");
	menu.AddItem(TEAMMENU_BLANK, "");
	menu.AddItem(TEAMMENU_SPEC, "Dołącz do obserwatorów");
	menu.Display(iClient, MENU_TIME_FOREVER);
}

public int TeamMenuHandler(Menu menu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char szItemInfo[MAX_TEXT_LENGTH];
			menu.GetItem(iItem, szItemInfo, sizeof(szItemInfo)); 
			
			if(StrEqual(szItemInfo, TEAMMENU_PRISONERS))
				ChangeClientTeam(iClient, CS_TEAM_T);
			else if(StrEqual(szItemInfo, TEAMMENU_WARDENS))
			{
				float ratio = JB_GetPrisonersCount() / (JB_GetWardensCount() > 0 ? float(JB_GetWardensCount()) : 0.1);
				if(ratio > TT_CT_RATIO || ratio < 0.01)
					ChangeClientTeam(iClient, CS_TEAM_CT);
				else
				{
					PrintToChat(iClient, "%s Za mało więźniów, aby dołączyć do strażników.", JB_PREFIX);
					ChangeClientTeam(iClient, CS_TEAM_T);
				}
			}
			else if(StrEqual(szItemInfo, TEAMMENU_SPEC))
				ChangeClientTeam(iClient, CS_TEAM_SPECTATOR);
		}
		
		case MenuAction_DrawItem:
		{
			char szItemInfo[MAX_TEXT_LENGTH];
			menu.GetItem(iItem, szItemInfo, sizeof(szItemInfo)); 
			
			if(StrEqual(szItemInfo, TEAMMENU_BLANK))
				return ITEMDRAW_SPACER;
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}