-- demlo script

local osseparator = ossep or '/'
-- Relative paths are OK, but '~' does not get expanded.
local library = lib or osseparator .. 'AnomalyRealm' .. osseparator .. 'media' .. osseparator .. 'music' .. osseparator .. 'ready_to_stream' .. osseparator .. 'sam_library'
local pathsubstitute = pathsub or {}

help([==[
Set the output path according to tags.

Note that 'track' refers to the track number, not the title.

GLOBAL OPTIONS

- ossep: string (default: ']] .. osseparator .. [[')
  OS path separator.
  Separators are replaced by ' - ' in folder names.

- lib: string (default: ']] .. library .. [[')
  Path to the music library.

- pathsub: array of {[[regular expression]], [[replacement string]]}
  Replace all filename elements matching the regex with the replacement string.
  pathsub is not an associative array since order must be guaranteed.

EXAMPLES

	demlo -pre 'pathsub={{[=[["*?:/\|<>]]=], ""}}' AUDIO-FILES...

Some filesystems don't accept some special characters, so we remove them.
It can be useful to sync music on external devices.  For intance, store the
above in "59-path-sync" and run the following example.

	demlo -r '' -pre 'lib="/media/device"' -s path AUDIO-FILES...

Run 59-path-sync and 60-path, music is copied over to the /media/device library.

RULES

We make sure no unnecessary subfolders are created.
Extension is set from format.
We pad zeros (2 digits) in track number for file browsers without numeric sorting capabilities.
]==])

local function empty(s)
	if type(s) ~= 'string' or s == '' then
		return true
	else
		return false
	end
end

local function normalize_spaces(s)
	if empty(s) then
		return ''
	end
	s = s:gsub('%s+', ' ')
	s = s:gsub('^%s+', '')
	s = s:gsub('%s+$', '')
	return s
end

local function sane(s)
	s = normalize_spaces(s)
	for _, j in ipairs(pathsubstitute) do
		local r = s:gsub(j[1], j[2])
		if r ~= s then
			debug("'" .. s .. "':gsub('" .. j[1] .."', '" .. j[2] .. "')='" .. r .. "'")
		end
		s = r
	end
	s = s:gsub([[\s*]] .. osseparator .. [[\s*]], ' - ')
	return s
end

-- Append arguments to path if they or not empty.
-- Strip them with the 'sane' function before appending.
local function appendpath(...)
	local path_elements = {...}
	for _, v in pairs(path_elements) do
		if not empty(v) then
			output.path = output.path .. sane(v)
		end
	end
end

local track_padded = ''
if not empty (o.track) and tonumber(o.track) then
	track_padded = string.format('%02d', o.track)
end


help("We try to guess if the genre belongs to classical music.")
local genre = o.genre and o.genre:lower():gsub([[\s]],'_')
local classical = false
if genre then
	local genre_conv = {
		medieval = 'Medieval',
		renaissance = 'Renaissance',
		baro = 'Renaissance',
		classic = 'Classical',
		romantic = 'Romantic',
		modern = 'Modern',
		contemp = 'Contemporary',
	}
	for search, _ in pairs(genre_conv) do
		if genre:match(search) then
			classical = true
			break
		end
	end
end

-- Output path.
output.path = library .. osseparator
local album_artist = not empty(o.album_artist) and o.album_artist or
	(not empty(o.artist) and o.artist or 'Unknown Artist')
appendpath(album_artist)
-- 'osseparator' cannot be appended with 'appendpath'.
-- path = library/album_artist/
output.path = output.path .. osseparator

help([[
Since classical pieces usually get recorded several times, the date is not
very relevant. Thus it is preferable to sort classical albums by name on the filesystem.
]])
if not empty(o.album) then
	if classical then
-- path = library/album_artist/album
		appendpath(o.album)
		if not empty(o.performer) then
-- path = library/album_artist/album (performer, date)
			appendpath(' (' .. o.performer ..
									 (not empty(o.date) and (', ' .. sane(o.date)) or '')
									 .. ')'
			)
		end
	else
		if not empty(o.date) then
-- path = library/album_artist/year -
			appendpath(o.date .. ' - ')
		end
-- path = library/album_artist/year - album
		appendpath(o.album)
	end
-- path = library/album_artist/year - album/
	output.path = output.path .. osseparator
	if not empty(o.disc) then
-- path = library/album_artist/year - album/discNumber
		appendpath(o.disc)
	end
	if not empty(track_padded) then
-- path = library/album_artist/year - album/discNumberTrackNumber
		appendpath(track_padded .. ' - ')
	end
end

appendpath(o.artist .. ' - ')
appendpath(o.title)

local ext = empty(output.format) and input.format.format_name or output.format
appendpath('.' .. ext)

output.path = output.path:gsub("[%*%?:]",'_')
