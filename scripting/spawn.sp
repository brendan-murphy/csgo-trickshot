
public void FindSpawns(){
	// These are arrays of spawn arrays
	tSpawns = CreateArray();
	ctSpawns = CreateArray();

	float spawnVector[3];

	char sClassName[64];

	// loop through all entities
	for (int i = GetMaxClients(); i < GetMaxEntities(); i++){

		bool valid = IsValidEdict(i) && IsValidEntity(i);

		// check if valid entity
		if (valid && GetEdictClassname(i, sClassName, sizeof(sClassName))) {

			// check if T spawn point
			if (StrEqual(sClassName, "info_player_terrorist")) {

				// store position of spawn point in spawnVector 
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", spawnVector);

				//Handle temp = CreateArray(3);
				//PushArrayArray(temp, spawnVector);
				//PushArrayCell(tSpawns, temp);

				PushArrayArray(tSpawns, spawnVector);
				SetArrayArray(tSpawns, GetArraySize(tSpawns) -1, spawnVector);
			}

			// check if CT spawn point
			else if(StrEqual(sClassName, "info_player_counterterrorist")){

				GetEntPropVector(i, Prop_Data, "m_vecOrigin", spawnVector);
			}

		}
	}
	for(int i = 0; i < GetArraySize(tSpawns); i++){
		float tempVector[3];
		GetArrayArray(tSpawns, i, tempVector);
		PrintToChatAll("%f %f %f", tempVector[0], tempVector[1], tempVector[2]);
	}
}

