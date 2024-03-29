#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Marker"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

int g_iBeamSprite;
bool g_bIsBlocked = true, g_bIsPainting[MAXPLAYERS + 1];
float g_fLastPosition[MAXPLAYERS + 1][3];
Handle g_hPaintTimer;

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	RegConsoleCmd("+maluj", PaintCmd);
	RegConsoleCmd("-maluj", PaintCmd);
}

public void OnMapStart()
{
	g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	
	for (int i = 1; i <= MaxClients; i++)
		g_bIsPainting[i] = false;
}

public void OnDayMode(int iOldDayMode, int iNewDayMode)
{
	if(iOldDayMode == NORMAL)
	{
		g_bIsBlocked = true;
		if(g_hPaintTimer != INVALID_HANDLE)
		{
			KillTimer(g_hPaintTimer);
			g_hPaintTimer = INVALID_HANDLE;
		}
		for (int i = 1; i <= MaxClients; i++)
			g_bIsPainting[i] = false;
		
		UnhookEvent("round_prestart", RoundPrestartEvent);
		UnhookEvent("player_team", PlayerTeamEvent);
		UnhookEvent("player_death", PlayerDeathEvent);
	}
	
	if(iNewDayMode == NORMAL)
	{
		g_bIsBlocked = false;
		g_hPaintTimer = CreateTimer(0.1, PaintTimer, _, TIMER_REPEAT);
		
		HookEvent("round_prestart", RoundPrestartEvent);
		HookEvent("player_team", PlayerTeamEvent);
		HookEvent("player_death", PlayerDeathEvent);
	}
}

public Action RoundPrestartEvent(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
		g_bIsPainting[i] = false;
	
	return Plugin_Continue;
}

public Action PlayerTeamEvent(Event event, const char[] name, bool dontBroadcast)
{
	bool disconnected = event.GetBool("disconnect");
	if(disconnected)
	{
		int iClient = GetClientOfUserId(event.GetInt("userid"));
		g_bIsPainting[iClient] = false;
	}
	
	return Plugin_Continue;
}

public Action PlayerDeathEvent(Event event, const char[] name, bool dontBroadcast)
{
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	g_bIsPainting[iVictim] = false;
		
	return Plugin_Continue;
}

public Action PaintTimer(Handle timer)
{
	float fPos[3];
	for(int i = 1; i <= MaxClients; i++) 
	{
		if(g_bIsBlocked || !IsUserValid(i) || !JB_IsSimon(i) || !g_bIsPainting[i])
			continue;
			
		TraceClientViewPosition(i, fPos);
		if(GetVectorDistance(fPos, g_fLastPosition[i]) > 3.0) {
			int color[4];
			color[0] = GetRandomInt(0, 255);
			color[1] = GetRandomInt(0, 255);
			color[2] = GetRandomInt(0, 255);
			color[3] = 255;
			
			TE_SetupBeamPoints(g_fLastPosition[i], fPos, g_iBeamSprite, 0, 0, 0, 25.0, 2.0, 3.0, 10, 0.0, color, 0);
			TE_SendToAll();
			
			g_fLastPosition[i] = fPos;
		}
	}
	
	return Plugin_Continue;
}

public Action PaintCmd(int iClient, int args)
{
	if(g_bIsBlocked || !IsUserValid(iClient) || !JB_IsSimon(iClient))
		return Plugin_Handled;
	
	char szCommand[MAX_TEXT_LENGTH];
	GetCmdArg(0, szCommand, sizeof(szCommand));

	if(szCommand[0] == '+')
	{
		TraceClientViewPosition(iClient, g_fLastPosition[iClient]);
		g_bIsPainting[iClient] = true;
	}
	else
	{
		g_fLastPosition[iClient][0] = 0.0;
		g_fLastPosition[iClient][1] = 0.0;
		g_fLastPosition[iClient][2] = 0.0;
		g_bIsPainting[iClient] = false;
	}
	
	return Plugin_Continue;
}