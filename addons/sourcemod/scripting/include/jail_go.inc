#include <cstrike>
#include <sdkhooks>

#define JB_PREFIX " \x04[JB]\x01"

#define MAX_TEXT_LENGTH 128

#define EF_BONEMERGE (1 << 0)
#define EF_NOSHADOWS (1 << 4)
#define EF_PARENT_ANIMATES (1 << 9)
#define EF_NORECEIVESHADOWS (1 << 6)

// Called when iClient got simon function
forward void OnAddSimon(int iClient);

// Called when iClient lost simon function
forward void OnRemoveSimon(int iClient);

// Called when iClient got freeday
forward void OnAddFreeDay(int iClient);

// Called when iClient came rebel
forward void OnAddRebel(int iClient);

// Returns day number
native int JB_GetDay();

/*
 * Returns week day name for day number
 *
 * @param day     		day number
 * @param dayName		returned day name
 */
native void JB_GetDayName(int day, char[] dayName);

// Adds simon
native void JB_AddSimon(int iClient);

// Removes simon
native void JB_RemoveSimon();

// Get simon client id
native int JB_GetSimon();

// Checks if client is simon
native bool JB_IsSimon(int iClient);

// Displays simon menu to client
native void JB_DisplaySimonMenu(int iClient)

// Displays admin menu to client
native void JB_DisplayAdminMenu(int iClient);

// Displays bind cell buttons menu to a client
native void JB_DisplayBindCellButtonsMenu(int iClient);

// Displays random menu to a client
native void JB_DisplayRandomMenu(int iClient);

// Displays mute menu to a client
native void JB_DisplayMuteMenu(int iClient);

// Open cells
native void JB_OpenCells();

// Displays freeday menu to a client in mode
native void JB_DisplayFreeDayMenu(int iClient);

// Adds freeday for client
native void JB_AddFreeDay(int iClient);

// Removes freeday for client
native void JB_RemoveFreeDay(int iClient, bool bSpawn = false);

// Checks if client has freeday
native void JB_HasFreeDay(int iClient);

// Returns time to end of freeday
native int JB_GetFreeDayTime(int iClient);





// Displays rebel menu to a client in mode
native void JB_DisplayRebelMenu(int iClient);

// Adds rebel for client
native void JB_AddRebel(int iClient);

// Removes rebel for client
native void JB_RemoveRebel(int iClient);

// Checks if client is rebel
native void JB_IsRebel(int iClient);





// Displays divide menu to a client
native void JB_DisplayDivideMenu(int iClient);





// Displays heal menu to a client
native void JB_DisplayHealMenu(int iClient);

// Displays revive menu to a client
native void JB_DisplayReviveMenu(int iClient);



// Returns an account
native int JB_GetCurrency(int iClient);





stock bool CreateDirectories(const char[] path, int mode, bool use_valve_fs = false, const char[] valve_path_id = "DEFAULT_WRITE_PATH") {
	char partialPathBuffer[PLATFORM_MAX_PATH];
	
	int currentSplit = 0;
	while (currentSplit < strlen(path)) {
		int subSplit = FindCharInString(path[currentSplit], '/', false);
		
		if (subSplit == -1) {
			// subsplit the remaining portion of the string
			subSplit = strlen(path[currentSplit]);
		}
		
		currentSplit += subSplit + 1; // subsplit + forward slash
		strcopy(partialPathBuffer, currentSplit + 1, path); // currentsplit + null
		
		if (!DirExists(partialPathBuffer, use_valve_fs, valve_path_id)
				&& !CreateDirectory(partialPathBuffer, mode, use_valve_fs, valve_path_id)) {
			return false;
		}
	}
	return true;
}

// Returns true if user is valid
stock bool IsUserValid(int iClient)
{
	if(iClient >= 1 && iClient <= MaxClients && IsClientInGame(iClient))
		return true;
	
	return false;
}

/*
 * Returns number of prisoners
 *
 * @param onlyAlive     Do count only alive prisoners
 * @return              Number of prisoners
 */
stock int JB_GetPrisonersCount(bool onlyAlive = false)
{
	int prisonersCount = 0;
	if(onlyAlive) 
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
				prisonersCount++;
		}
	}
	else prisonersCount = GetTeamClientCount(CS_TEAM_T);
	
	return prisonersCount;
}

/*
 * Returns number of wardens
 *
 * @param onlyAlive     Do count only alive wardens
 * @return              Number of wardens
 */
stock int JB_GetWardensCount(bool onlyAlive = false)
{
	int wardensCount = 0;
	if(onlyAlive) 
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT)
				wardensCount++;
		}
	}
	else wardensCount = GetTeamClientCount(CS_TEAM_CT);
	
	return wardensCount;
}

// Returns random warden, 0 if not possible
stock int JB_RandWarden()
{
	int[] wardens = new int [MaxClients];
	int wardensCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT)
		{
			wardens[wardensCount] = i;
			wardensCount++;
		}
	}
	
	if(wardensCount > 0)
		return wardens[GetRandomInt(0, wardensCount - 1)];
	else
		return 0;
}

// Returns entity id traced by client
stock int TraceClientViewEntity(int iClient)
{
    float vClientEyePosition[3], vClientEyeAngles[3];
    GetClientEyePosition(iClient, vClientEyePosition);
    GetClientEyeAngles(iClient, vClientEyeAngles);

    Handle tr = TR_TraceRayFilterEx(vClientEyePosition, vClientEyeAngles, MASK_VISIBLE, RayType_Infinite, TRDontHitSelf, iClient);
    int iEntity = TR_GetEntityIndex(tr);
    CloseHandle(tr);
    return iEntity;
}

stock void TraceClientViewPosition(int iClient, float fPos[3]) {
	float vClientEyePosition[3], vClientEyeAngles[3];
	GetClientEyePosition(iClient, vClientEyePosition);
	GetClientEyeAngles(iClient, vClientEyeAngles);
    
	Handle tr = TR_TraceRayFilterEx(vClientEyePosition, vClientEyeAngles, MASK_VISIBLE, RayType_Infinite, TRDontHitSelf, iClient);
	TR_GetEndPosition(fPos, tr);
	CloseHandle(tr);
}

stock bool TRDontHitSelf(int iEntity, int iMask, any data)
{
	return (IsUserValid(iEntity) && iEntity != data); 
}

/*
 * Sets dynamic glow for entity and returns prop id
 *
 * @param iClient     	Do count only alive prisoners
 * @param color			color, example "0 255 0"
 * @return              prop id
 */
stock int RenderDynamicGlow(int iClient, char[] color)
{
	char szClientModel[MAX_TEXT_LENGTH];
	GetClientModel(iClient, szClientModel, sizeof(szClientModel));
	
	int skin = CreateEntityByName("prop_dynamic_glow");
	SDKHook(skin, SDKHook_SetTransmit, SetTransmitSDKHook);
	DispatchKeyValue(skin, "model", szClientModel);
	DispatchKeyValue(skin, "disablereceiveshadows", "1");
	DispatchKeyValue(skin, "disableshadows", "1");
	DispatchKeyValue(skin, "solid", "0");
	DispatchKeyValue(skin, "spawnflags", "256");
	DispatchKeyValue(skin, "renderamt", "0");
	SetEntProp(skin, Prop_Send, "m_CollisionGroup", 0);
	DispatchSpawn(skin);
	
	int fEffects = GetEntProp(skin, Prop_Send, "m_fEffects");
	SetEntProp(skin, Prop_Send, "m_fEffects", fEffects | EF_BONEMERGE | EF_NOSHADOWS | EF_NORECEIVESHADOWS | EF_PARENT_ANIMATES);
	
	SetEntPropEnt(skin, Prop_Send, "m_hOwnerEntity", iClient); 
	SetEntProp(skin, Prop_Send, "m_bShouldGlow", true, true);
	SetEntProp(skin, Prop_Send, "m_nGlowStyle", 1);
	SetEntPropFloat(skin, Prop_Send, "m_flGlowMaxDist", 10000000.0);
	
	SetVariantString("!activator");
	AcceptEntityInput(skin, "SetParent", iClient, skin);
	
	SetVariantString("primary");
	AcceptEntityInput(skin, "SetParentAttachment", iClient, skin);
    
	SetVariantString(color);
	AcceptEntityInput(skin, "SetGlowColor", iClient, skin);
	
	return skin;
}

// Destroys dynamic glow
stock void RemoveDynamicGlow(int iEntity)
{
	SDKUnhook(iEntity, SDKHook_SetTransmit, SetTransmitSDKHook);
	RemoveEntity(iEntity);
}

stock Action SetTransmitSDKHook(int iEntity, int iClient)
{
	int iEntityOwner = GetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity");
	if(iEntityOwner == iClient)
		return Plugin_Handled;
		
	return Plugin_Continue;
}

// Permutes array
stock void Permute(int[] a, int length)
{
	int iRandom, iTemp;
	int count = 0;
	for (int i = 0; i < length - 1; i++)
	{
		iRandom = GetRandomInt(0, length - 1 - count);
		
		iTemp = a[iRandom];
		a[iRandom] = a[length - 1 - count];
		a[length - 1 - count] = iTemp;
		
		count++;
	}
}