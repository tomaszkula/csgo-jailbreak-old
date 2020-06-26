#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Buttons Activation"
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
	HookEvent("round_start", RoundStartEvent);
}

public Action RoundStartEvent(Event event, const char[] name, bool dontBroadcast)
{
	int iEntity = -1;
	while ((iEntity = FindEntityByClassname(iEntity, "func_button")) != -1)
	{
		SetEntProp(iEntity, Prop_Data, "m_spawnflags", GetEntProp(iEntity, Prop_Data, "m_spawnflags") | 512);
		SDKHook(iEntity, SDKHook_OnTakeDamage, OnTakeDamageSDKHook);
	}
	
	return Plugin_Continue;
}

public Action OnTakeDamageSDKHook(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if(!JB_IsSimon(attacker))
		return Plugin_Handled;
	
	return Plugin_Continue;
}