#if defined _tf2_hud_included
 #endinput
#endif
#define _tf2_hud_included
 
#define MAX_MESSAGE_LENGTH 250


stock PrintToHud(client, const String:szMessage[], any:...)
{
	if (client <= 0 || client > MaxClients)
		ThrowError("Invalid client index %d", client);
	
	if (!IsClientInGame(client))
		ThrowError("Client %d is not in game", client);

	decl String:szBuffer[MAX_MESSAGE_LENGTH];
	
	
	SetGlobalTransTarget(client);
	VFormat(szBuffer, sizeof(szBuffer), szMessage, 3);
	ReplaceString(szBuffer, sizeof(szBuffer), "\"", "“");
	
	decl params[] = {0x76, 0x6F, 0x69, 0x63, 0x65, 0x5F, 0x73, 0x65, 0x6C, 0x66, 0x00, 0x00};
	new Handle:msg = StartMessageOne("HudNotifyCustom", client);
	BfWriteString(msg, szBuffer);
	
	for(new i = 0; i < sizeof(params); i++)
		BfWriteByte(msg, params[i]);
	
	EndMessage();
}


stock PrintToHudAll(const String:szMessage[], any:...)
{
	decl String:szBuffer[MAX_MESSAGE_LENGTH];
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			SetGlobalTransTarget(i);
			VFormat(szBuffer, sizeof(szBuffer), szMessage, 2);
			PrintToHud(i, szBuffer);
		}
	}
}