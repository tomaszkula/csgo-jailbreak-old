#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Gun Steal"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

#define STEAL_DISTANCE 80.0
#define STEAL_CHANCE 1.0
#define STEAL_COOLDOWN 180

int g_iStealCooldown[MAXPLAYERS + 1];
Handle g_hStealGunTimer[MAXPLAYERS + 1];

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
	HookEvent("round_end", RoundEndEvent);
	HookEvent("player_death", PlayerDeathEvent);
	
	RegConsoleCmd("+steal", StealCmd);
	RegConsoleCmd("+kradnij", StealCmd);
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(g_hStealGunTimer[i] != INVALID_HANDLE)
		{
			KillTimer(g_hStealGunTimer[i]);
			g_hStealGunTimer[i] = INVALID_HANDLE;
	    }
		
		g_iStealCooldown[i] = 0;
	}
}

public void OnClientDisconnect_Post(int iClient)
{
	if(g_hStealGunTimer[iClient] != INVALID_HANDLE)
	{
		KillTimer(g_hStealGunTimer[iClient]);
		g_hStealGunTimer[iClient] = INVALID_HANDLE;
    }
	
	g_iStealCooldown[iClient] = 0;
}

public Action RoundEndEvent(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(g_hStealGunTimer[i] != INVALID_HANDLE)
		{
			KillTimer(g_hStealGunTimer[i]);
			g_hStealGunTimer[i] = INVALID_HANDLE;
	    }
	    
		g_iStealCooldown[i] = 0;
	}
	
	return Plugin_Continue;
}

public Action PlayerDeathEvent(Event event, const char[] name, bool dontBroadcast)
{
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	
	if(g_hStealGunTimer[iVictim] != INVALID_HANDLE)
	{
		KillTimer(g_hStealGunTimer[iVictim]);
		g_hStealGunTimer[iVictim] = INVALID_HANDLE;
    }
	
	g_iStealCooldown[iVictim] = 0;
		
	return Plugin_Continue;
}

public Action StealCmd(int iClient, int args)
{
	if(!IsUserValid(iClient) || !IsPlayerAlive(iClient) || GetClientTeam(iClient) != CS_TEAM_T || JB_HasFreeDay(iClient))
		return Plugin_Handled;
		
	if(g_iStealCooldown[iClient] > 0)
	{
		PrintToChat(iClient, "%s Musisz poczekać jeszcze \x04%is\x01, aby ponownie spróbować kradzieży.", JB_PREFIX, g_iStealCooldown[iClient]);
		return Plugin_Handled;
	}
	
	int iTarget = TraceClientViewEntity(iClient);
	if(!IsUserValid(iTarget) || !IsPlayerAlive(iTarget) || GetClientTeam(iTarget) != CS_TEAM_CT)
	{
		PrintToChat(iClient, "%s Namierz któregoś ze strażników, aby spróbować ukraść mu pistolet.", JB_PREFIX);
		return Plugin_Handled;
	}
		
	float vClientOrigin[3], vTargetOrigin[3];
	GetClientAbsOrigin(iClient, vClientOrigin);
	GetClientAbsOrigin(iTarget, vTargetOrigin);
	float distance = GetVectorDistance(vClientOrigin, vTargetOrigin);
	if(distance <= STEAL_DISTANCE)
	{
		char szTargetName[MAX_TEXT_LENGTH];
		GetClientName(iTarget, szTargetName, sizeof(szTargetName));
		
		int iTargetWeapon = GetPlayerWeaponSlot(iTarget, 1);
		if(iTargetWeapon == -1)
			PrintToChat(iClient, "%s Strażnik \x0b%s \x01nie ma żadnego pistoletu.", JB_PREFIX, szTargetName);
		else
		{
			if(GetRandomFloat() <= STEAL_CHANCE)
			{
				RemovePlayerItem(iTarget, iTargetWeapon);
				
				int iClientWeapon = GetPlayerWeaponSlot(iClient, 1);
				if(iClientWeapon != -1)
					RemovePlayerItem(iClient, iClientWeapon);
				
				char szTargetWeaponName[MAX_TEXT_LENGTH];
				GetEntityClassname(iTargetWeapon, szTargetWeaponName, sizeof(szTargetWeaponName));
				GivePlayerItem(iClient, szTargetWeaponName);
				
				PrintToChat(iClient, "%s Ukradłes broń strażnikowi \x0b%s\x01.", JB_PREFIX, szTargetName);
			}
			else
			{
				JB_AddRebel(iClient);
				PrintToChat(iClient, "%s Kradzież broni strażnikowi \x0b%s \x01zakończona niepowodzeniem. Jesteś buntownikiem!", JB_PREFIX, szTargetName);
			}
			
			g_iStealCooldown[iClient] = STEAL_COOLDOWN;
			g_hStealGunTimer[iClient] = CreateTimer(1.0, StealGunTimer, iClient, TIMER_REPEAT);
			PrintToChat(iClient, "%s Ponowna próba kradzieży dostępna za \x04%is\x01.", JB_PREFIX, STEAL_COOLDOWN);
			
		}
	}
	else
		PrintToChat(iClient, "%s Musisz podejść bliżej, by ukraść broń.", JB_PREFIX);
	
	return Plugin_Continue;
}

public Action StealGunTimer(Handle timer, any iClient)
{
	if(--g_iStealCooldown[iClient] <= 0)
	{
		KillTimer(g_hStealGunTimer[iClient]);
		g_hStealGunTimer[iClient] = INVALID_HANDLE;
	}
	
	return Plugin_Continue;
}