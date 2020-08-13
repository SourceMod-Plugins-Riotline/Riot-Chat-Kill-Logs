#include <sourcemod>
#include <tf2jail>
#include <morecolors>

public Plugin myinfo = {
	name = "[TF2Jail] Chat Kill Logs",
	author = "Riotline",
	description = "",
	version = "3.1",
	url = ""
};

// Tranlsation help from 'Scarletteous & friends'

public OnAllPluginsLoaded()
{
	//Handle:
	Handle TF2Jail = FindPluginByFile("TF2Jail.smx");
	if(TF2Jail != INVALID_HANDLE) 
	{
		if(GetPluginStatus(TF2Jail) != Plugin_Running)
		{
			//Fail State:
			SetFailState("Requires TF2Jail to be installed and running.");
		}
	}
	//Override:
	else
	{
		//Fail State:
		SetFailState("Invalid Plugin Handles. (OnAllPluginsLoaded: TF2Jail)");
	}
} 

public void OnPluginStart() {
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	LoadTranslations("tf2jail_chatkills.phrases.txt")
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
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
		// Print the message and continue
		ck_CPrintToChatAll(iKiller, iVictim, sKillerName, sVictimName);
	}
	return Plugin_Continue;
}

stock ck_CPrintToChatAll(int iKiller, int iVictim, char sKillerName[MAX_NAME_LENGTH], char sVictimName[MAX_NAME_LENGTH]) {
	CCheckTrie();
	char buffer[MAX_BUFFER_LENGTH], buffer2[MAX_BUFFER_LENGTH];
	// The roles of each player involved (WARDEN, GUARD, REBEL, PRISONER, or FREEDAY)
	char sVictimRole[64];
	char sKillerRole[64];
	for(int i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || CSkipList[i]) {
			CSkipList[i] = false;
			continue;
		}
		if (GetPlayerJailStatus(iKiller, 3)) {
			Format(sKillerRole, sizeof(sKillerRole), "%T", "Role_Warden", i);
		} else {
			Format(sKillerRole, sizeof(sKillerRole), "%T", "Role_Guard", i);
		}
		switch (GetClientTeam(iVictim)) {
			case 2: { // red die				
				if (GetPlayerJailStatus(iVictim, 2)) {
					Format(sVictimRole, sizeof(sVictimRole), "%T", "Role_Freeday", i);
				} else if (GetPlayerJailStatus(iVictim, 1)) {
					Format(sVictimRole, sizeof(sVictimRole), "%T", "Role_Rebel", i);
				} else {
					Format(sVictimRole, sizeof(sVictimRole), "%T", "Role_Prisoner", i);
				}
			}
			case 3: { // blue dead
				if (GetPlayerJailStatus(iVictim, 3)) {
					Format(sVictimRole, sizeof(sVictimRole), "%T", "Role_Warden", i);
				} else {
					Format(sVictimRole, sizeof(sVictimRole), "%T", "Role_Guard", i);
				}
			}
		}
		char newMessage[MAX_BUFFER_LENGTH];
		Format(newMessage, sizeof(newMessage), "%T %T", "prefix", i, "OnDeath_Messages", i, sKillerRole , sKillerName, sVictimRole, sVictimName);
		SetGlobalTransTarget(i);
		Format(buffer, sizeof(buffer), "\x01%s", newMessage);
		VFormat(buffer2, sizeof(buffer2), buffer, 2);
		CReplaceColorCodes(buffer2);
		CSendMessage(i, buffer2);
	}
}

bool GetPlayerJailStatus(int client, int type) {
    switch(type) {
        case 1: {
            return TF2Jail_IsRebel(client);
        }
        case 2: {
            return TF2Jail_IsFreeday(client);
        }
        case 3: {
            return TF2Jail_IsWarden(client);
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