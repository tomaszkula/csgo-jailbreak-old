#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Client Info"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

Handle g_hClientInfoHud;

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
	g_hClientInfoHud = CreateHudSynchronizer();
	CreateTimer(0.2, UpdateClientInfoHud, _, TIMER_REPEAT);
}

public Action UpdateClientInfoHud(Handle timer)
{
	SetHudTextParams(-1.0, 0.8, 0.3, 255, 255, 110, 0);
	for(int i = 1; i <= MaxClients; i++)
    {
        if (!IsUserValid(i) || !IsPlayerAlive(i))
        	continue;
        
        int iTarget = TraceClientViewEntity(i);
        if(!IsUserValid(iTarget) || !IsPlayerAlive(iTarget))
        	continue;
        
        char szTargetName[MAX_TEXT_LENGTH];
        GetClientName(iTarget, szTargetName, sizeof(szTargetName));
        
        int iTargetHealth = GetClientHealth(iTarget);
        
        switch(GetClientTeam(i))
        {
        	case CS_TEAM_CT:
        	{
        		switch(GetClientTeam(iTarget))
        		{
        			case CS_TEAM_CT:
        				ShowSyncHudText(i, g_hClientInfoHud, "Strażnik : %s\nHP : %i", szTargetName, iTargetHealth);
        				
        			case CS_TEAM_T:
        				ShowSyncHudText(i, g_hClientInfoHud, "Więzień : %s\nHP : %i", szTargetName, iTargetHealth);
        		}
        	}
        	
        	case CS_TEAM_T:
        	{
        		switch(GetClientTeam(iTarget))
        		{
        			case CS_TEAM_CT:
        				ShowSyncHudText(i, g_hClientInfoHud, "Strażnik : %s", szTargetName, iTargetHealth);
        				
        			case CS_TEAM_T:
        				ShowSyncHudText(i, g_hClientInfoHud, "Więzień : %s\nHP : %i", szTargetName, iTargetHealth);
        		}
        	}
       	}
    }
    
   	return Plugin_Continue;
}