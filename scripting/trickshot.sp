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
float roundTime = 0.0;

public OnPluginStart(){

	RegAdminCmd("sm_myslap", Command_MySlap, ADMFLAG_SLAY);
	RegAdminCmd("send_to_team",Command_SendToTeam, ADMFLAG_SLAY);

	HookEvent("round_prestart", Event_OnRoundPreStart);
	HookEvent("round_poststart", Event_OnRoundPostStart);
	HookEvent("round_end", Event_OnRoundEnd);

}

public OnPluginEnd(){

}

public OnClientConnected(client){

}

public OnClientDisconnect_Post(client){
	if(client <= currentThrower){
		currentThrower--;
	}
}

public OnMapStart(){

}

public OnMapEnd(){

}

public Action Event_OnRoundPreStart(Handle event, const char[] name, bool dontBroadcast){
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
	new String:buffer[60], ent = -1;
	while((ent = FindEntityByClassname(ent, "trigger_multiple")) != -1){

		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(StrContains(buffer, "hoop_trigger", false)){
			HookSingleEntityOutput(ent, "OnTrigger", HoopOnTrigger, false);
		}

	}
}

public Action Event_OnRoundPostStart(Handle event, const char[] name, bool dontBroadcast){
	CreateTimer(GetConVarFloat(FindConVar("mp_roundtime_defuse")) * 60, RoundTimeExpire);
}

public Action Event_OnRoundEnd(Handle event, const char[] name, bool dontBroadcast){
	
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

public RoundTimeExpire(){

}


public Action Command_MySlap(client, args){
	new String:arg1[32], String:arg2[32];
	new damage;

	//Get second argument
	GetCmdArg(1, arg1, sizeof(arg1));

	if( args >= 2 && GetCmdArg(2, arg2, sizeof(arg2)))
		damage = StringToInt(arg2);

	new target = FindTarget(client, arg1);
	if(target == -1)
		return Plugin_Handled; // FindTarget() will print out the error

	SlapPlayer(target, damage);

	new String:name[MAX_NAME_LENGTH];
	GetClientName(target, name, sizeof(name));
	ReplyToCommand(client, "[SM] You slapped %s for %d damage!", name, damage);

	return Plugin_Handled;
}