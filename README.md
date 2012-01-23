###Conky-CMUS
*A short script to show CMUS track playtime and info on the desktop with Conky.*

To get track info, the script calls `cmus-remote -Q`, parses the output, stores it, and then generates Conky code to display it. Because calling `cmus-remote` every update would be outrageously wasteful in terms of CPU time, the track info is maintained and the playtime is estimated for each conky update. `cmus-remote` is only called when the current track finishes, or after a user-set wait period.

##Usage
Assuming Conky and CMUS are already installed, you need only add two lines to your .conkyrc:
    
	...
    lua_load /path/to/conky-cmus.lua
	...
    
    TEXT
	...
    ${lua_parse nowplaying 5}

Where `/path/to/` is the path to wherever you placed conky-cmus.lua. The number `5` in the last line is the refresh rate. A rate of 5 means that the script will only call `cmus-remote` once every 5 seconds. This is independent of your Conky update interval. The script will keep the playtime updating.
