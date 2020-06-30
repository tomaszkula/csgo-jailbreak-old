#include <sourcemod>
#include <sdktools>
#include "jail_go.inc"

#define PLUGIN_NAME "[JB] Day Mode"
#define PLUGIN_AUTHOR "tomkul777"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0"

GlobalForward g_OnDayModeForward;
int g_iDayMode;

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
	CreateNative("JB_GetDayMode", GetDayMode);
	CreateNative("JB_GetDayModeName", GetDayModeName);
}

public void OnPluginStart()
{
	g_OnDayModeForward = CreateGlobalForward("OnDayMode", ET_Event, Param_Cell, Param_Cell);
}

public void OnMapStart()
{
	SetDayMode(NONE);
}

public void OnDay(int iDay)
{
	if(iDay == -1)
		SetDayMode(NONE);
	else if(iDay == 0)
		SetDayMode(WARM_UP);
	else if(iDay % 7 == 6 || iDay % 7 == 0)
		SetDayMode(GAME);
	else
		SetDayMode(NORMAL);
}

void SetDayMode(int iDayMode)
{
	if(iDayMode == g_iDayMode)
		return;
	
	Call_StartForward(g_OnDayModeForward);
	Call_PushCell(g_iDayMode);
	Call_PushCell(iDayMode);
	Call_Finish();
	
	g_iDayMode = iDayMode;
}

/////////////////////////////////////////////////////////////
////////////////////////// NATIVES //////////////////////////
/////////////////////////////////////////////////////////////

public int GetDayMode(Handle plugin, int argc)
{
	return g_iDayMode;
}

public int GetDayModeName(Handle plugin, int argc)
{
	char szDayModeName[MAX_TEXT_LENGTH];
	switch(GetNativeCell(1))
	{
		case NONE: szDayModeName = "BRAK";
		case WARM_UP: szDayModeName = "ROZGRZEWKA";
		case GAME: szDayModeName = "LOSOWE ZABAWY";
		case NORMAL: szDayModeName = "NORMALNY";
	}
	
	SetNativeString(2, szDayModeName, sizeof(szDayModeName));
}