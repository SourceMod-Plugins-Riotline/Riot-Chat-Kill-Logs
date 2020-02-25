#include <sourcemod>
#include <tf2jailredux>
#include <morecolors>

public Plugin myinfo = {
	name = "[TF2Jail_Redux] Chat Kill Logs",
	author = "Riotline",
	description = "",
	version = "3.0",
	url = ""
};

public OnAllPluginsLoaded()
{
	//Handle:
	Handle TF2JailRedux = FindPluginByFile("TF2Jail_Redux.smx")
	if(TF2JailRedux != INVALID_HANDLE) 
	{
		if(GetPluginStatus(TF2JailRedux) != Plugin_Running)
		{
			//Fail State:
			SetFailState("Requires TF2Jail_Redux to be installed and running.");
		}
	}
	//Override:
	else
	{
		//Fail State:
		SetFailState("Invalid Plugin Handles. (OnAllPluginsLoaded: TF2JailRedux)");
	}
} 

public void OnPluginStart() {
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	LoadTranslations("tf2jail_chatkills.phrases.txt")
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	// The roles of each player involved (WARDEN, GUARD, REBEL, PRISONER, or FREEDAY)
	char sVictimRole[32];
	char sKillerRole[32];

	// Getting clients from the event
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	int iKiller = GetClientOfUserId(event.GetInt("attacker"));

	// Getting the client names
	char sVictimName[MAX_NAME_LENGTH];
	char sKillerName[MAX_NAME_LENGTH];
	GetClientName(iVictim, sVictimName, sizeof(sVictimName));
	GetClientName(iKiller, sKillerName, sizeof(sKillerName));

	// Broadcast to chat if the following conditions are met
	if (IsValidClient(iVictim) && IsValidClient(iKiller) && iKiller != iVictim && GetClientTeam(iKiller) == 3) { // victim and killer valid and killer is on blue and victim did not kill heself
		if (GetPlayerJailStatus(iKiller, 3)) {
			strcopy(sKillerRole, sizeof(sKillerRole), "{fullblue}WARDEN");
		} else {
			strcopy(sKillerRole, sizeof(sKillerRole), "{royalblue}GUARD");
		}
		switch (GetClientTeam(iVictim)) {
			case 2: { // red die				
				if (GetPlayerJailStatus(iVictim, 2)) {
					strcopy(sVictimRole, sizeof(sVictimRole), "{arcana}FREEDAY");
				} else if (GetPlayerJailStatus(iVictim, 1)) {
					strcopy(sVictimRole, sizeof(sVictimRole), "{axis}REBEL");
				} else {
					strcopy(sVictimRole, sizeof(sVictimRole), "{coral}NON-REBEL");
				}
			}
			case 3: { // blue dead
				if (GetPlayerJailStatus(iVictim, 3)) {
					strcopy(sVictimRole, sizeof(sVictimRole), "{fullblue}WARDEN");
				} else {
					strcopy(sVictimRole, sizeof(sVictimRole), "{royalblue}GUARD");
				}
			}
		}
		// Print the message and continue
		CPrintToChatAll("%t %s {default}%s killed %s {default}%s", "prefix", sKillerRole , sKillerName, sVictimRole, sVictimName);
	}
	return Plugin_Continue;
}

bool GetPlayerJailStatus(int client, int type) {
    switch(type) {
        case 1: {
            return JBPlayer(client).bIsRebel;
        }
        case 2: {
            return JBPlayer(client).bIsFreeday;
        }
        case 3: {
            return JBPlayer(client).bIsWarden;
        }
    }
    return false;
}

bool IsValidClient(int client, bool bAllowDead = true, bool bAllowAlive = true, bool bAllowBots = true) {
	if(	!(1 <= client <= MaxClients) || 			/* Is the client a player? */
		(!IsClientInGame(client)) ||				/* Is the client in-game? */
		(IsPlayerAlive(client) && !bAllowAlive) || 	/* Is the client allowed to be alive? */
		(!IsPlayerAlive(client) && !bAllowDead) || 	/* Is the client allowed to be dead? */
		(IsFakeClient(client) && !bAllowBots)) {	/* Is the client allowed to be a bot? */
			return false;
	}
	return true;	
}
