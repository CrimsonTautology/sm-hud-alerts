#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <tf2>
#include <tf2_stocks>
#include <tf2_hud>
#include <goomba>

#define PLUGIN_VERSION  "0.0.1custom"


public Plugin:myinfo = 
{
    name = "TF2 Hud Alerts",
    author = "Crimsontautology + GNCMatt",
    description = "Prints a message in a special TF2 HUD area during specific events.",
    version = PLUGIN_VERSION,
    url = "https://github.com/CrimsonTautology/sm_hud_alerts"
}


#define SOUND_ALERT     "vo/announcer_alert.wav"
#define SOUND_ATTENTION "vo/announcer_attention.wav"
#define SOUND_WARNING   "vo/announcer_warning.wav"

#define KILLSTREAK_SOUNDS_MAX 11
#define MAX_WEAPON_LENGTH 128

new String:g_KillStreakSounds[][] =
{
    "vo/announcer_am_killstreak01.wav",
    "vo/announcer_am_killstreak02.wav",
    "vo/announcer_am_killstreak03.wav",
    "vo/announcer_am_killstreak04.wav",
    "vo/announcer_am_killstreak05.wav",
    "vo/announcer_am_killstreak06.wav",
    "vo/announcer_am_killstreak07.wav",
    "vo/announcer_am_killstreak08.wav",
    "vo/announcer_am_killstreak09.wav",
    "vo/announcer_am_killstreak10.wav",
    "vo/announcer_am_killstreak11.wav"
};

public OnPluginStart()
{
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("achievement_earned", Event_AchievementEarned);
    HookEvent("scout_grand_slam", Event_ScoutGrandSlam);
    HookEvent("arrow_impact", Event_ArrowImpact);

    RegAdminCmd("sm_isay", Command_ISay, ADMFLAG_CHAT, "Usage: sm_isay <message> - Prints a message in a special TF2 HUD.");
}

public OnMapStart()
{
    for(new i=0; i < KILLSTREAK_SOUNDS_MAX; i++)
    {
        PrecacheSound(g_KillStreakSounds[i]);
    }

    PrecacheSound(SOUND_ALERT);
    PrecacheSound(SOUND_ATTENTION);
    PrecacheSound(SOUND_WARNING);
}


public Action:Command_ISay(client, args)
{
    if(args == 0)
    {
        ReplyToCommand(client, "[SM] Usage: sm_isay <message>");
        return Plugin_Handled;
    }
    else
    {
        new String:arg[256]; GetCmdArgString(arg, sizeof(arg));

        EmitSoundToAll(SOUND_ALERT);
        PrintToHudAll(arg);
    }

    return Plugin_Handled;
}

public OnStompPost(attacker, victim, Float:damageMultiplier, Float:damageBonus, Float:jumpPower)
{
    decl String:attacker_name[64], String:victim_name[64];
    GetClientName(attacker, attacker_name, sizeof(attacker_name));
    GetClientName(victim, victim_name, sizeof(attacker_name));

    EmitSoundToAll(g_KillStreakSounds[GetRandomInt(0, KILLSTREAK_SOUNDS_MAX - 1)]);
    PrintToHudAll("%s goomba stomped %s!", attacker_name, victim_name);
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));

    decl String:attacker_name[64], String:victim_name[64];

    /*
    if (IsAirShot(attacker, victim))
    {
        GetClientName(attacker, attacker_name, sizeof(attacker_name));
        GetClientName(victim, victim_name, sizeof(attacker_name));

        EmitSoundToAll(g_KillStreakSounds[GetRandomInt(0, KILLSTREAK_SOUNDS_MAX - 1)]);
        PrintToHudAll("%s shot %s out of the air!", attacker_name, victim_name);
    }
    */


    return Plugin_Continue;
}

public Action:Event_AchievementEarned(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "player"));

    decl String:client_name[64];

    GetClientName(client, client_name, sizeof(client_name));

    EmitSoundToAll(g_KillStreakSounds[GetRandomInt(0, KILLSTREAK_SOUNDS_MAX - 1)]);
    PrintToHudAll("%s earned an achievement! WOO HOO!", client_name);


    return Plugin_Continue;
}

public Action:Event_ScoutGrandSlam(Handle:event, const String:name[], bool:dontBroadcast)
{
    new attacker = GetClientOfUserId(GetEventInt(event, "scout_id"));
    new victim = GetClientOfUserId(GetEventInt(event, "target_id"));

    decl String:attacker_name[64], String:victim_name[64];

    GetClientName(attacker, attacker_name, sizeof(attacker_name));
    GetClientName(victim, victim_name, sizeof(attacker_name));

    EmitSoundToAll(g_KillStreakSounds[GetRandomInt(0, KILLSTREAK_SOUNDS_MAX - 1)]);
    PrintToHudAll("%s knocked %s out of the park!", attacker_name, victim_name);


    return Plugin_Continue;
}

public Action:Event_ArrowImpact(Handle:event, const String:name[], bool:dontBroadcast)
{
    new attacker = GetClientOfUserId(GetEventInt(event, "shooter"));
    new victim = GetClientOfUserId(GetEventInt(event, "attachedEntity"));

    if (IsAirShot(attacker, victim))
    {
        decl String:attacker_name[64], String:victim_name[64];

        GetClientName(attacker, attacker_name, sizeof(attacker_name));
        GetClientName(victim, victim_name, sizeof(attacker_name));

        EmitSoundToAll(g_KillStreakSounds[GetRandomInt(0, KILLSTREAK_SOUNDS_MAX - 1)]);
        PrintToHudAll("%s AIR-rowed %s", attacker_name, victim_name);
    }


    return Plugin_Continue;
}

public bool:IsAirShot(attacker, victim)
{
    if (!Client_IsValid(attacker) || !Client_IsValid(victim)) return false;
    if (attacker == victim) return false;

    // If they are not in the water and not in the air, they are airborne. And if they're not airborne, it's not an airshot.
    if ((GetEntityFlags(victim) & (FL_INWATER | FL_ONGROUND))) return false;

    // Check for the required height
    if (DistanceAboveGround(victim) < 100.0) return false;

    return true;
}

// DistanceAboveGround(): Calculate a player's distance above the ground.
// Code borrowed from MGE Mod, thanks to Lange!
Float:DistanceAboveGround(client)
{
    decl Float:vStart[3];
    decl Float:vEnd[3];
    new Float:vAngles[3] = {90.0, 0.0, 0.0};
    new Handle:trace;
    new Float:distance = -1.0;

    // Get the client's origin vector and start up the trace ray
    GetClientAbsOrigin(client, vStart);
    trace = TR_TraceRayFilterEx(vStart, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

    if (TR_DidHit(trace))
    {
        // Calculate the distance.
        TR_GetEndPosition(vEnd, trace);
        distance = GetVectorDistance(vStart, vEnd, false);
    }

    // Clean up and return
    CloseHandle(trace);
    return distance;
}

// TraceEntityFilterPlayer(): Ignore players in a trace ray
public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
    return !Client_IsValid(entity);
} 
