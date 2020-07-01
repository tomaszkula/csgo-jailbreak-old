#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Search for Weapons"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

#define SEARCH_DISTANCE 80.0
#define SEARCH_TIME 3

int g_iSearchTarget[MAXPLAYERS + 1], g_iSearcher[MAXPLAYERS + 1];
bool g_bIsBlocked = true;
Handle g_hProgressBarTime, g_hSearchTimer[MAXPLAYERS + 1], g_hCheckDistanceTimer[MAXPLAYERS + 1];

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
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetSignature(SDKLibrary_Server, "\x55\x89\xE5\x83\xEC\x48\x89\x5D\xF4\x8B\x5D\x08\x89\x75\xF8\x8B\x75\x0C\x89\x7D\xFC\x39\xB3\x00\x28\x00\x00", 27);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hProgressBarTime = EndPrepSDKCall();
	
	RegConsoleCmd("przeszukaj", SearchCmd);
	RegConsoleCmd("search", SearchCmd);
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
		RefuseSearchForWeaponsTimer(i);
}

public void OnDayMode(int iOldDayMode, int iNewDayMode)
{
	if(iOldDayMode == NORMAL)
	{
		g_bIsBlocked = true;
		for (int i = 1; i <= MaxClients; i++)
			RefuseSearchForWeaponsTimer(i);
		
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
		RefuseSearchForWeaponsTimer(i);
	
	return Plugin_Continue;
}

public Action PlayerTeamEvent(Event event, const char[] name, bool dontBroadcast)
{
	bool disconnected = event.GetBool("disconnect");
	if(disconnected)
	{
		int iClient = GetClientOfUserId(event.GetInt("userid"));
		RefuseSearchForWeaponsTimer(iClient);
		RefuseSearchForWeaponsTimer(g_iSearcher[iClient]);
	}
	
	return Plugin_Continue;
}

public Action PlayerDeathEvent(Event event, const char[] name, bool dontBroadcast)
{
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	RefuseSearchForWeaponsTimer(iVictim);
	RefuseSearchForWeaponsTimer(g_iSearcher[iVictim]);
		
	return Plugin_Continue;
}

public Action SearchForWeaponsTimer(Handle timer, int iClient)
{
	g_hSearchTimer[iClient] = INVALID_HANDLE;
	
	int iTarget = g_iSearchTarget[iClient];
	StopSearch(iClient, iTarget);
	
	char szWeaponsInfo[MAX_TEXT_LENGTH] = "|", szWeapon[MAX_TEXT_LENGTH];
	int iWeapon = -1;
	for (int i = 0; i < 5; i++)
	{
		if((iWeapon = GetPlayerWeaponSlot(iTarget, i)) == -1)
			continue;
		
		GetEntityClassname(iWeapon, szWeapon, sizeof(szWeapon));
		Format(szWeaponsInfo, sizeof(szWeaponsInfo), "%s %s |", szWeaponsInfo, szWeapon);
	}
	
	char szTargetName[MAX_TEXT_LENGTH];
	GetClientName(iTarget, szTargetName, sizeof(szTargetName));
	PrintToChat(iClient, "%s Ekwipunek więźnia \x07%s\x01: \x04%s", JB_PREFIX, szTargetName, szWeaponsInfo);
	
	return Plugin_Continue;
}

public Action CheckDistanceTimer(Handle timer, any iClient)
{
	int iTarget = g_iSearchTarget[iClient];
	
	float vClientOrigin[3], vTargetOrigin[3];
	GetClientAbsOrigin(iClient, vClientOrigin);
	GetClientAbsOrigin(iTarget, vTargetOrigin);
	float distance = GetVectorDistance(vClientOrigin, vTargetOrigin);
	if(distance > SEARCH_DISTANCE)
		RefuseSearchForWeaponsTimer(iClient);
	
	return Plugin_Continue;
}

void StopSearch(int iClient, int iTarget)
{
	KillTimer(g_hCheckDistanceTimer[iClient]);
	g_hCheckDistanceTimer[iClient] = INVALID_HANDLE;
	
	SetEntityFlags(iTarget, (GetEntityFlags(iTarget) ^ FL_ATCONTROLS));
	SDKCall(g_hProgressBarTime, iClient, 0);
	SDKCall(g_hProgressBarTime, iTarget, 0);
	
	g_iSearchTarget[iClient] = 0;
	g_iSearcher[iTarget] = 0;
}

void RefuseSearchForWeaponsTimer(int iClient)
{
	if(g_hSearchTimer[iClient] != INVALID_HANDLE)
	{
		KillTimer(g_hSearchTimer[iClient]);
		g_hSearchTimer[iClient] = INVALID_HANDLE;
		
		StopSearch(iClient, g_iSearchTarget[iClient]);
	}
}

public Action SearchCmd(int iClient, int args)
{
	if(g_bIsBlocked || !IsUserValid(iClient) || !IsPlayerAlive(iClient) || GetClientTeam(iClient) != CS_TEAM_CT)
		return Plugin_Continue;
		
	int iTarget = TraceClientViewEntity(iClient);
	if(!IsUserValid(iTarget) || !IsPlayerAlive(iTarget) || GetClientTeam(iTarget) != CS_TEAM_T)
	{
		PrintToChat(iClient, "%s Namierz więźnia, aby go przeszukać.", JB_PREFIX);
		return Plugin_Continue;
	}
	
	float vClientOrigin[3], vTargetOrigin[3];
	GetClientAbsOrigin(iClient, vClientOrigin);
	GetClientAbsOrigin(iTarget, vTargetOrigin);
	float distance = GetVectorDistance(vClientOrigin, vTargetOrigin);
	if(distance <= SEARCH_DISTANCE)
	{
		/*if(JB_HasFreeDay(iTarget))
		{
			PrintToChat(iClient, "%s Nie możesz przeszukać FreeDay'a.", JB_PREFIX);
			return Plugin_Continue;
		}*/
		
		g_iSearchTarget[iClient] = iTarget;
		g_iSearcher[iTarget] = iClient;
		
		PrintToChat(iClient, "PRZESZUKUJESZ WIĘŹNIA");
		PrintToChat(iTarget, "JESTEŚ PRZESZUKIWANY");
		g_hCheckDistanceTimer[iClient] = CreateTimer(0.1, CheckDistanceTimer, iClient, TIMER_REPEAT);
		SetEntityFlags(iTarget, (GetEntityFlags(iTarget) | FL_ATCONTROLS));
		SDKCall(g_hProgressBarTime, iClient, SEARCH_TIME);
		SDKCall(g_hProgressBarTime, iTarget, SEARCH_TIME);
		g_hSearchTimer[iClient] = CreateTimer(float(SEARCH_TIME), SearchForWeaponsTimer, iClient);
	}
	else
		PrintToChat(iClient, "%s Musisz podejść bliżej, by przeszukać więźnia.", JB_PREFIX);
	
	return Plugin_Continue;
}