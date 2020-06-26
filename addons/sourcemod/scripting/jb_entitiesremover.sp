#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Entities Remover"
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
	HookEvent("item_pickup", ItemPickUpEvent);
}

public void OnMapStart()
{
	int iEntity = -1;
	while((iEntity = FindEntityByClassname(iEntity, "func_bomb_target")) != -1)
		RemoveEntity(iEntity);
	
	while((iEntity = FindEntityByClassname(iEntity, "func_buyzone")) != -1)
		RemoveEntity(iEntity);
		
	while((iEntity = FindEntityByClassname(iEntity, "func_hostage_rescue")) != -1)
		RemoveEntity(iEntity);
}

public Action RoundStartEvent(Event event, const char[] name, bool dontBroadcast)
{
	int iEntity = -1;
	while((iEntity = FindEntityByClassname(iEntity, "hostage_entity")) != -1)
		RemoveEntity(iEntity);
	
	return Plugin_Continue;
}

public Action ItemPickUpEvent(Event event, const char[] name, bool dontBroadcast)
{
	char item[MAX_TEXT_LENGTH];
	event.GetString("item", item, sizeof(item));

	if(StrEqual(item, "weapon_c4"))
	{
		int iClient = GetClientOfUserId(event.GetInt("userid"));
		int iWeapon = GetPlayerWeaponSlot(iClient, 4);
		RemovePlayerItem(iClient, iWeapon);
	}
	
	return Plugin_Continue;
}