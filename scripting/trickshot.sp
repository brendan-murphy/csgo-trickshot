#include <sourcemod>
#include <sdktools>
#include <cstrike>

 //Plugin public information.
public Plugin:myinfo = {
	name = "Test Plugin",
	author = "Brendan Murphy",
	description = "Test Plugin",
	version = "0.00",
	url = ""
}

int currentThrower = 0;
int roundCount = 0;
Handle g_hCvarRestartGame;
bool warmupRound = true;
Handle roundEndTimeHandle;

public OnPluginStart(){

	RegAdminCmd("send_to_team",Command_SendToTeam, ADMFLAG_SLAY);

	HookEvent("round_prestart", Hook_OnRoundPreStart);
	HookEvent("round_poststart", Hook_OnRoundPostStart);
	HookEvent("round_end", Hook_OnRoundEnd);

	g_hCvarRestartGame = FindConVar("mp_restartgame");
	HookConVarChange(g_hCvarRestartGame, CvarChange_RestartGame);

}

public OnPluginEnd(){

}

public OnClientConnected(client){
	PrintToChatAll("%d", GetClientCount());
	if(GetClientCount() > 0 && warmupRound){
		//CreateTimer(2.5,EndWarmupHelper);
		PrintToChatAll("WARMUP ENDED");
		ServerCommand("mp_warmup_end");
		warmupRound = false;
	}
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

	PrintToChatAll("%d", currentThrower);
	currentThrower = (currentThrower + 1) % (GetClientCount() + 1);

	if(currentThrower == 0)
		currentThrower = 1;

	CS_SwitchTeam(currentThrower, 3);

	// hook hoop trigger event
	new String:buffer[60];
	int ent = -1;
	while((ent = FindEntityByClassname(ent, "trigger_multiple")) != -1){

		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(StrContains(buffer, "hoop_trigger", false)){
			HookSingleEntityOutput(ent, "OnTrigger", EntityOutput:HoopOnTrigger);
		}

	}
}

public Hook_OnRoundPostStart(Handle event, const char[] name, bool dontBroadcast){
	if(roundCount > 0){ // Dont do it on warmup
	roundEndTimeHandle = CreateTimer((GetConVarFloat(FindConVar("mp_roundtime_defuse")) * 60.0), RoundTimeExpire);
	PrintToChatAll("Round end timer started");
	}
}

public Hook_OnRoundEnd(Handle event, const char[] name, bool dontBroadcast){
	if (roundEndTimeHandle != INVALID_HANDLE)
	{
		KillTimer(roundEndTimeHandle);
		PrintToChatAll("Round end timer ended");
		roundEndTimeHandle = INVALID_HANDLE;
	}
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
	PrintToServer("output %s, caller %i, activator %i, delay %0.1f", output, caller, activator, delay);
	CS_TerminateRound(GetConVarFloat(FindConVar("mp_round_restart_delay")), CSRoundEnd_CTWin);
}

public Action RoundTimeExpire(Handle timer){
	// Time has run out so the T side wins
	CS_TerminateRound(GetConVarFloat(FindConVar("mp_round_restart_delay")), CSRoundEnd_TerroristsEscaped);
}

public CvarChange_RestartGame(Handle:convar, const String:oldValue[], const String:newValue[])// If mp_restartgame is changed, roundCount will be 0
{
    if (StringToInt(newValue) > 0)
    {
        roundCount = 0;

    }
    if (roundEndTimeHandle != INVALID_HANDLE)
	{
		KillTimer(roundEndTimeHandle);
		roundEndTimeHandle = INVALID_HANDLE;
		PrintToChatAll("Round end timer ended");
	}
}

