#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <smlib>


 //Plugin public information.
public Plugin:myinfo = {
	name = "Test Plugin",
	author = "Brendan Murphy",
	description = "Test Plugin",
	version = "0.00",
	url = ""
}

#define Slot_HEgrenade 11

ConVar g_cvSpawnType;

int currentThrower = 0;
int roundCount = 0;
Handle g_hCvarRestartGame;
bool warmupRound = true;
Handle roundEndTimeHandle;
int madeShots = 0;

// Handles to array
Handle tSpawns = INVALID_HANDLE;
Handle ctSpawns = INVALID_HANDLE;

#include <spawn.sp>

public OnPluginStart(){

	RegAdminCmd("send_to_team",Command_SendToTeam, ADMFLAG_SLAY);

	HookEvent("round_prestart", Hook_OnRoundPreStart);
	HookEvent("round_poststart", Hook_OnRoundPostStart);
	HookEvent("round_end", Hook_OnRoundEnd);
	HookEvent("player_spawn",Hook_PlayerSpawn);

	g_hCvarRestartGame = FindConVar("mp_restartgame");
	HookConVarChange(g_hCvarRestartGame, CvarChange_RestartGame);

	g_cvSpawnType = CreateConVar("spawn_type", "1", "Sets if there is on T spawn location or multiple");
}

public Hook_PlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast){
	if(GetClientCount() > 1 && warmupRound){
		//CreateTimer(2.5,EndWarmupHelper);
		PrintToChatAll("WARMUP ENDED");
		ServerCommand("mp_warmup_end");
		warmupRound = false;
	}
}

public OnPluginEnd(){


}

public OnClientConnected(client){
	
}

public Action EndWarmupHelper(Handle timer){
	PrintToChatAll("WARMUP ENDED");
	ServerCommand("mp_warmup_end");
	warmupRound = false;
}

public OnClientDisconnect_Post(client){
	if(client <= currentThrower){
		currentThrower--;
	}
}

public OnMapStart(){
	roundCount = 0;
	warmupRound = true;
	//FindSpawns();
}

public OnMapEnd(){

}

public Hook_OnRoundPreStart(Handle event, const char[] name, bool dontBroadcast){

	if(warmupRound){
		//warmupRound = false;
		return;
	}

	roundCount++;

 	if (roundCount == 1) // First round, game just started
    {
        currentThrower = 0;
    }

	//put all players on T side
	for (int i = 1; i < GetClientCount() + 1; i++){
		CS_SwitchTeam(i, 2);
	}

	currentThrower = (currentThrower + 1) % (GetClientCount() + 1);

	if(currentThrower == 0)
		currentThrower = 1;

	CS_SwitchTeam(currentThrower, 3);
	PrintToChatAll("%d current thrower ", currentThrower);
}

public Hook_OnRoundPostStart(Handle event, const char[] name, bool dontBroadcast){
	if(roundCount < 1)// Dont do it on warmup
		return;
	roundEndTimeHandle = CreateTimer((GetConVarFloat(FindConVar("mp_roundtime")) * 60.0), RoundTimeExpire);
	PrintToChatAll("Round end timer started");

	for(int i = 1; i < GetClientCount() + 1; i++){
		Client_RemoveAllWeapons(i);
		GivePlayerItem(i, "weapon_knife");
	}

	for(int i = 0; i < 4; i++){
		GivePlayerItem(currentThrower, "weapon_hegrenade");
	}

	HookEntityOutput("trigger_multiple", "OnTrigger", HoopOnTrigger);

}

public Hook_OnRoundEnd(Handle event, const char[] name, bool dontBroadcast){
	if (roundEndTimeHandle != INVALID_HANDLE)
	{
		KillTimer(roundEndTimeHandle);
		PrintToChatAll("Round end timer ended");
		roundEndTimeHandle = INVALID_HANDLE;
	}
	UnhookEntityOutput("trigger_multiple","OnTrigger",HoopOnTrigger);
	madeShots = 0;

}


public Action Command_SendToTeam(client, args){
	new String:name[32];
	new String:arg[32];
	new team;
	ReplyToCommand(client, "%d", args);
	if(args >= 2){
		GetCmdArg(1,name, sizeof(name));
		GetCmdArg(2,arg, sizeof(arg)); // buffer team to be on in a String
		team = StringToInt(arg);

	}
	else{
		ReplyToCommand(client, "Not enought parameters");
		return Plugin_Handled;
	}

	new target = FindTarget(client, name);

	// 2 is T, 3 is CT
	CS_SwitchTeam(target, team);

	ReplyToCommand(client, "Sent %s to team %d", name, team);

	return Plugin_Handled;
}

public HoopOnTrigger(const String:output[], caller, activator, float delay){
	new String:name[256];
	GetEntityClassname(activator, name, 256);
	
	if(warmupRound || !StrEqual(name,"hegrenade_projectile"))
		return;

	PrintToChatAll("Hoop triggered!");
	FindSpawns();

	madeShots++;

	if(Client_GetWeaponPlayerAmmo(currentThrower, "weapon_hegrenade") == 0){
		if(madeShots > 0)
			CS_TerminateRound(GetConVarFloat(FindConVar("mp_round_restart_delay")), CSRoundEnd_CTWin);
		else
			CS_TerminateRound(GetConVarFloat(FindConVar("mp_round_restart_delay")), CSRoundEnd_TerroristsEscaped);
	}

}

public Action RoundTimeExpire(Handle timer){
	// Time has run out so the T side wins
	CS_TerminateRound(GetConVarFloat(FindConVar("mp_round_restart_delay")), CSRoundEnd_TerroristsEscaped);
}

public CvarChange_RestartGame(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (StringToInt(newValue) > 0)
    {
    	// If mp_restartgame is changed, roundCount will be 0
        roundCount = 0;

    }
    if (roundEndTimeHandle != INVALID_HANDLE)
	{
		KillTimer(roundEndTimeHandle);
		roundEndTimeHandle = INVALID_HANDLE;
		PrintToChatAll("Round end timer ended");
	}
}

public GetWeaponAmmo(client, slot)
{
    new ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
    return GetEntData(client, ammoOffset+(slot*4));
}

public SetWeaponAmmo(client, slot, amount)
{
    new ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
    return SetEntData(client, ammoOffset+(slot*4), amount);
}