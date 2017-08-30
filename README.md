# SimpleStats
 
## SimpleStats Plugin
- [x] OnClientDisconnect update stats.
- [x] OnRoundEnd update stats.
- [x] Admin command to reset players stats.
- [x] Player command to check his stats.
- [x] Added top x menu players.

Admin Commands
-- 
- sm_ssreset - Command for flag z to reset player stats - ADMFLAG_ROOT

Player Commands
--
- sm_stats - Command for client to open menu with his stats.
- sm_top - - sm_stats - Command for client to open menu with his stats.


#  Installation:
1. If you want to use this plugin you must use MySQL add a database entry in addons/sourcemod/configs/databases.cfg, call it "simplestats".
```
"Databases"
{
	"simplestats"
	{
		"driver"         "mysql"
		"host"           "localhost"
		"database"       "simplestats"
		"user"           "root"
		"pass"           ""
	}
}
```
2. Copy the .smx file to your plugins (addons/sourcemod/plugins) folder
3. Restart your server.

### Include File (For Developers) :
-- 
```
/**
 * Retrieve the amount of kills.
 *
 * @param client					Client index.
 * @return                          Amount of kills.
 */
native int SS_GetKillsAmount(int client);

/**
 * Retrieve the amount of deaths.
 *
 * @param client					Client index.
 * @return                          Amount of deaths.
 */
native int SS_GetDeathsAmount(int client);

/**
 * Retrieve the amount of shots.
 *
 * @param client					Client index.
 * @return                          Amount of shots.
 */
native int SS_GetShotsAmount(int client);

/**
 * Retrieve the amount of hits.
 *
 * @param client					Client index.
 * @return                          Amount of hits.
 */
native int SS_GetHitsAmount(int client);

/**
 * Retrieve the amount of headshots.
 *
 * @param client					Client index.
 * @return                          Amount of headshots.
 */
native int SS_GetHeadshotsAmount(int client);

/**
 * Retrieve the amount of assists.
 *
 * @param client					Client index.
 * @return                          Amount of assists.
 */
native int SS_GetAssistsAmount(int client);

/**
 * Retrieve the total amount of seconds played on the server.
 *
 * @param client					Client index.
 * @return                          Amount of seconds played.
 */
native int SS_GetPlayTimeAmount(int client);
```


## Database
DB Name : 'players'
- [0] SteamID (SteamID64)
- [1] Name
- [2] IP
- [3] Kills
- [4] Deaths
- [5] Shots
- [6] Hits
- [7] Headshots
- [8] Assists
- [9] SecondsOnServer
- [10] LastConn
