# SimpleStats
 
## SimpleStats Plugin
- [x] OnClientDisconnect update stats.
- [x] OnRoundEnd update stats.
- [x] Admin command to reset players stats.
- [x] Player command to check his stats.

Admin Commands
-- 
- sm_ssreset - Command for flag z to reset player stats - ADMFLAG_ROOT

Player Commands
--
- sm_stats - Command for client to open menu with his stats.


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
