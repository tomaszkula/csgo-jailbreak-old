#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Day"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

GlobalForward g_OnDayForward;
int g_iDay;

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
	CreateNative("JB_GetDay", GetDay);
	CreateNative("JB_GetDayName", GetDayName);
}

public void OnPluginStart()
{
	HookEvent("round_prestart", RoundPrestartEvent);
	
	g_OnDayForward = CreateGlobalForward("OnDay", ET_Event, Param_Cell);
}

public void OnMapStart()
{
	SetDay(-1);
}

public Action RoundPrestartEvent(Event event, const char[] name, bool dontBroadcast)
{
	SetDay(g_iDay + 1);
	
	return Plugin_Continue;
}

void SetDay(int iDay)
{
	g_iDay = iDay;
	
	Call_StartForward(g_OnDayForward);
	Call_PushCell(iDay);
	Call_Finish();
}

/////////////////////////////////////////////////////////////
////////////////////////// NATIVES //////////////////////////
/////////////////////////////////////////////////////////////

public int GetDay(Handle plugin, int argc)
{
	return g_iDay;
}

public int GetDayName(Handle plugin, int argc)
{
	char szDay[15];
	switch(GetNativeCell(1) % 7)
	{
		case 0: szDay = "Niedziela";
		case 1: szDay = "Poniedziałek";
		case 2: szDay = "Wtorek";
		case 3: szDay = "Środa";
		case 4: szDay = "Czwartek";
		case 5: szDay = "Piątek";
		case 6: szDay = "Sobota";
	}
	
	SetNativeString(2, szDay, sizeof(szDay));
}