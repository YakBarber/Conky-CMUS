--
--This is a lua script to build an on-screen now-playing display of CMUS, using conky.
--
--Written by Barry Van Tassell, released into the public domain.
--This script comes with no warranty or guarantee of anything, so if your computer self-immolates,
----do not blame the author.
--
--Usage:
--Put this BEFORE the "TEXT" section of your conkyrc: lua_load /path/to/conky-cmus.lua
----replacing /path/to/ with the location of this script.
--Put this within the "TEXT" section of your conkyrc: ${lua_parse nowplaying 5}
--Replace the number "5" with the number of seconds between calls to cmus-remote you want.
--The smaller it is, the more CPU time this script will use. I suggest being frugal.
--It is ok to make the number largeish, as this script will estimate the time played between
----calls so that it appears smooth.
--If you want it to call cmus-remote everytime conky updates for some reason, just set it to 0.
--To change the look of the output, go down to line 92.



--unix time of our last cmus-remote call
local last_read = 0
--our "database"
cmus_info = {}

--takes a value in seconds and converts it to the x:xx format
--prettyize(63) --> 1:03
--prettyize(4)  --> 0:04
local function prettyize(number)
	local min,sec
	min = math.floor(number/60)
	sec = number%60
	if sec<10 then
		sec = "0"..sec
	end
	return min..":"..sec
end

--just to make constructing the output less of a mess
--(if you want/need a different font, change it here)
local function font(val)
	return "${font DejaVu Sans Mono:size="..val.."}"
end

--same deal as above (you don't have to change this one, though)
local function color(val)
	return "${color "..val.."}"
end

--does all the work.
--the argument refresh is the number of seconds we're requiring between our cmus-remote calls.
--In between those times, we estimate the time. The accuracy of this depends on how fast your conky refresh rate is.
--Note: we ignore the refresh time if the estimation thinks the track has changed (like if it's going to report 4:23/4:19 as a time)
function conky_nowplaying(refresh)
	local t = os.time()
	--call cmus-remote if we just started up, if the track just ended, or if it's been <refresh> seconds since the last call.
	if not cmus_info.duration or ((t-last_read)>(cmus_info.duration-cmus_info.position)) or (t>(refresh+last_read)) then
		--if we need to call cmus-remote, we do this block
		last_read = t
		local f = io.popen("cmus-remote -Q")
		local line
		--this parses the output and collects the relevant bits. built with regex and character-counting.
		while true do
			line = f:read("*l")
			if not line then break end
			if string.find(line,"^status playing") then
				cmus_info.status = "Playing" --not used presently
			elseif string.find(line,"^status paused") then
				cmus_info.status = "Paused" --not used presently
			elseif string.find(line,"^duration") then
				cmus_info.duration = tonumber(string.match(line,"%d*",10))
			elseif string.find(line,"^position") then
				cmus_info.position = tonumber(string.match(line,"%d*",10))
				cmus_info.realpos = tonumber(string.match(line,"%d*",10))
			elseif string.find(line,"^tag title") then
				cmus_info.title = string.match(line,"[%s%w%d]*",11)
			elseif string.find(line,"^tag artist") then
				cmus_info.artist = string.match(line,"[%s%w%d]*",12)
			elseif string.find(line,"^tag album ") then
				cmus_info.album = string.match(line,"[%s%w%d]*",11)
			elseif string.find(line,"^tag date") then
				cmus_info.date = string.match(line,"[%s%w%d]*",10)
			elseif string.find(line,"^tag tracknumber") then
				cmus_info.tracknumber = string.match(line,"[%s%w%d]*",17)
			end
		end
		f:close()
	else
		--we didn't call cmus-remote, so guess the time
		cmus_info.position = cmus_info.realpos+math.floor(t-last_read)
	end
	--construct the output. each individual thing is on its own line for easy modification etc
	local string=""
	if cmus_info.title then string=string .. font(50)..cmus_info.title.." "..font(20) end
	if cmus_info.artist then string=string .. cmus_info.artist end
	string = string.."\n$hr\n"
	if cmus_info.position and cmus_info.duration then 
		string=string..prettyize(cmus_info.position).."/"..prettyize(cmus_info.duration).." ${lua_bar 20 playingbar}".."\n"
	end
	if cmus_info.album then string=string..color("lightgrey")..font(17).."Album: "..color("black")..font(20)..cmus_info.album.."\n" end
	if cmus_info.date then string=string..color("lightgrey")..font(17).."Date: "..color("black")..font(20)..cmus_info.date.."\n" end
	if cmus_info.tracknumber then string=string..color("lightgrey")..font(17).."Track: "..color("black")..font(20)..cmus_info.tracknumber.."\n" end
	
	return string
end

--Is placed within the output string from conky_nowplaying for conky to call.
--This feels cludgy but I didn't see a "generic_bar" option in conky's docs.
function conky_playingbar()
	return (cmus_info.position/cmus_info.duration*100)
end
