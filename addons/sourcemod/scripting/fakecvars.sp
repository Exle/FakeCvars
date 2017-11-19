/**
 * =============================================================================
 * FakeCvars
 * Fake console variables for client side.
 *
 * File: fakecvars.sp
 * Author: Exle / http://steamcommunity.com/profiles/76561198013509278/
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

StringMap Cvars;

public Plugin myinfo =
{
	name		= "FakeCvars",
	author		= "Exle",
	version		= "1.0.0",
	url			= "http://steamcommunity.com/id/ex1e/"
};

public void OnPluginStart()
{
	Cvars = new StringMap();
}

public void OnPluginEnd()
{
	delete Cvars;
}

public void OnMapStart()
{
	LoadConfiguration("configs/fakecvars.cfg");

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}

		OnClientPutInServer(i);
	}
}

public void OnClientPutInServer(int client)
{
	int length = Cvars.Size;
	if (IsFakeClient(client) || !length)
	{
		return;
	}

	StringMapSnapshot Cvars_Snapshot = Cvars.Snapshot();
	char value[PLATFORM_MAX_PATH];
	DataPack dp;
	ConVar fakecvar;
	for (int i; i < length; i++)
	{
		Cvars_Snapshot.GetKey(i, value, PLATFORM_MAX_PATH);
		Cvars.GetValue(value, dp);

		dp.Reset();
		fakecvar = dp.ReadCell();
		dp.ReadString(value, PLATFORM_MAX_PATH);

		if (fakecvar != null)
		{
			fakecvar.ReplicateToClient(client, value);
		}
	}
}

bool LoadConfiguration(const char[] path)
{
	Cvars.Clear();
	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, PLATFORM_MAX_PATH, path);

	if (!FileExists(buffer))
	{
		delete OpenFile(buffer, "w");
		return false;
	}

	File file = OpenFile(buffer, "r");

	if (file == null)
	{
		return false;
	}

	int position;
	while (!file.EndOfFile() && file.ReadLine(buffer, PLATFORM_MAX_PATH))
	{
		if ((position = StrContains(buffer, "//")) != -1)
		{
			buffer[position] = '\0';
		}
		if ((position = StrContains(buffer, "#")) != -1)
		{
			buffer[position] = '\0';
		}
		if ((position = StrContains(buffer, ";")) != -1)
		{
			buffer[position] = '\0';
		}

		if (!buffer[0])
		{
			continue;
		}

		ReplaceString(buffer, PLATFORM_MAX_PATH, "	", " ");
		PushToStringMap(buffer);
	}

	delete file;
	return true;
}

void PushToStringMap(char[] buffer)
{
	char cvar[64], value[PLATFORM_MAX_PATH];
	strcopy(value, PLATFORM_MAX_PATH, buffer);

	SplitString(value, " ", cvar, 64);
	TrimString(cvar);

	ReplaceString(value, PLATFORM_MAX_PATH, cvar, "");
	TrimString(value);

	ConVar fakecvar = FindConVar(cvar);
	if (fakecvar == null)
	{
		return;
	}

	fakecvar.Flags &= ~FCVAR_REPLICATED;

	ReplaceString(value, PLATFORM_MAX_PATH, "\"", "");
	DataPack dp = new DataPack();
	dp.WriteCell(fakecvar);
	dp.WriteString(value);
	dp.Reset();

	Cvars.SetValue(cvar, dp);
}