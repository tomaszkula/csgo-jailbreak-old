#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Prisoner"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

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
	HookEvent("player_spawn", PlayerSpawnEvent);
}

public Action PlayerSpawnEvent(Event event, const char[] name, bool dontBroadcast)
{
	return Plugin_Continue;
}