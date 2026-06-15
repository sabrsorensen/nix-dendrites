-- demlo script
help([[
Sanitize tags dynamically.

RULES

- Unknown tag fields are removed.

- Tags 'album_artist', 'artist', and 'composer' are easily mixed up. You may
  need to switch their values from command-line on a per-album basis.

- Note that the term "classical" refers to both western art music from 1000 AD
  to present time, and the era from 1750 to 1820. In this script the genre
  "Classical" refers to the 1750-1820 era.

EXAMPLES

	demlo -pre 'o.artist=o.composer; o.title=o.artist .. " - " .. o.title' audio.file

Set 'artist' to the value of 'composer', and 'title' to be preceded by the new
value of 'artist', then apply the default script. Mind the double quotes.
]])

local tags = {}

local function empty(s)
	if type(s) ~= 'string' or s == '' then
		return true
	else
		return false
	end
end

local function trim(s)
	if empty(s) then
		return ''
	end
	return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function normalize_spaces(s)
	s = trim(s)
	if s == '' then
		return s
	end
	s = s:gsub('%s+', ' ')
	s = s:gsub('%s+([%]%):;,%.])', '%1')
	s = s:gsub('([%[%(])%s+', '%1')
	return trim(s)
end

local function first_non_empty(...)
	local args = { ... }
	for _, v in ipairs(args) do
		if not empty(v) then
			return v
		end
	end
end

local function dedupe_list(values)
	local out = {}
	local seen = {}
	for _, value in ipairs(values) do
		local normalized = stringnorm(value)
		if value ~= '' and not seen[normalized] then
			seen[normalized] = true
			out[#out + 1] = value
		end
	end
	return out
end

local function standardize_feat_keyword(s)
	if empty(s) then
		return ''
	end
	s = s:gsub('[Ff]eaturing%s+', 'feat. ')
	s = s:gsub('[Ff]eat%.?%s+', 'feat. ')
	s = s:gsub('[Ff][Tt]%.?%s+', 'feat. ')
	return s
end

local function normalize_trailing_remix_group(group)
	if empty(group) then
		return ''
	end
	local open_char = group:sub(1, 1)
	local content = group:sub(2, -2)
	content = normalize_spaces(content)
	content = content:gsub('%f[%a][Rr][Mm][Xx]%f[%A]', 'Remix')
	content = content:gsub('%f[%a][Rr]emix%f[%A]', 'Remix')
	content = content:gsub('%f[%a][Mm]ix%f[%A]', 'Mix')
	if open_char == '[' then
		return '[' .. content .. ']'
	end
	return '(' .. content .. ')'
end

local function pop_trailing_group(s, matcher)
	local base, group = s:match('^(.-)%s*(%b())%s*$')
	if group and matcher(group) then
		return trim(base), group
	end
	base, group = s:match('^(.-)%s*(%b[])%s*$')
	if group and matcher(group) then
		return trim(base), group
	end
	return s, nil
end

local function is_remix_group(group)
	local content = group:sub(2, -2):lower()
	return content:match('%f[%a]remix%f[%A]') ~= nil
		or content:match('%f[%a]rmx%f[%A]') ~= nil
		or content:match('%f[%a]mix%f[%A]') ~= nil
end

local function pop_all_trailing_remix_groups(s)
	local groups = {}
	while true do
		local base, group = pop_trailing_group(s, is_remix_group)
		if not group then
			break
		end
		s = base
		table.insert(groups, 1, normalize_trailing_remix_group(group))
	end
	return normalize_spaces(s), groups
end

local function split_feature_suffix(s)
	if empty(s) then
		return '', ''
	end
	s = normalize_spaces(standardize_feat_keyword(s))

	local base, feat = s:match('^(.-)%s*%(%s*(feat%. .-)%s*%)%s*$')
	if base and feat then
		return normalize_spaces(base), normalize_spaces(feat)
	end

	base, feat = s:match('^(.-)%s*%[%s*(feat%. .-)%s*%]%s*$')
	if base and feat then
		return normalize_spaces(base), normalize_spaces(feat)
	end

	base, feat = s:match('^(.-)%s+(feat%. .-)%s*$')
	if base and feat then
		return normalize_spaces(base), normalize_spaces(feat)
	end

	return normalize_spaces(s), ''
end

local function feature_names_from_suffix(feat_suffix)
	if empty(feat_suffix) then
		return {}
	end
	local raw = feat_suffix:gsub('^[Ff]eat%.%s*', '')
	raw = raw:gsub('%s*[&/]%s*', ', ')
	raw = raw:gsub('%s+[Aa][Nn][Dd]%s+', ', ')
	raw = normalize_spaces(raw)

	local names = {}
	for part in raw:gmatch('[^,;]+') do
		part = normalize_spaces(part)
		if part ~= '' then
			names[#names + 1] = part
		end
	end
	return dedupe_list(names)
end

local function build_feature_suffix(names)
	if #names == 0 then
		return ''
	end
	return 'feat. ' .. table.concat(names, ', ')
end

local function append_feature_suffix(artist, feat_suffix)
	artist = normalize_spaces(artist)
	feat_suffix = normalize_spaces(feat_suffix)
	if feat_suffix == '' then
		return artist
	end
	return normalize_spaces(artist .. ' ' .. feat_suffix)
end

tags.album = o.album

-- Mostly used for classical music.
tags.performer = first_non_empty(o.performer, o.conductor, o.orchestra, o.arranger)

local raw_artist = first_non_empty(o.artist, o.composer, o.album_artist, tags.performer, 'Unknown Artist')
local artist_base, artist_feat_suffix = split_feature_suffix(raw_artist)

tags.title = empty(o.title) and 'Unknown Title' or o.title
tags.title = normalize_spaces(tags.title)

local remix_groups
tags.title, remix_groups = pop_all_trailing_remix_groups(tags.title)
local title_base, title_feat_suffix = split_feature_suffix(tags.title)
local feat_base, feat_remix_groups = pop_all_trailing_remix_groups(title_feat_suffix)

local feature_names = dedupe_list(feature_names_from_suffix(artist_feat_suffix))
for _, name in ipairs(feature_names_from_suffix(feat_base)) do
	feature_names[#feature_names + 1] = name
end
feature_names = dedupe_list(feature_names)

tags.artist = append_feature_suffix(artist_base, build_feature_suffix(feature_names))
tags.album_artist = first_non_empty(o.album_artist, artist_base)
if not empty(o.album_artist) and stringrel(stringnorm(o.album_artist), 'variousartist') > 0.7 then
	tags.album_artist = o.album
end

tags.title = title_base
for _, group in ipairs(feat_remix_groups) do
	tags.title = normalize_spaces(tags.title .. ' ' .. group)
end
for _, group in ipairs(remix_groups) do
	tags.title = normalize_spaces(tags.title .. ' ' .. group)
end

help([[
- Genre: since this is not universal by nature, we avoid setting a genre in
  tags, except for special cases like soundtracks and classical music. We
  analyse the input genre and make sure it fits an era. This is sometimes
  ambiguous. You may be better off leaving it empty. We convert to lowercase
  and spaces to underscores to ease matching.
]])
tags.genre = o.genre
local relmax = 0
local genre_classical = {
	'Medieval',
	'Renaissance',
	'Baroque',
	'Classical',
	'Romantic',
	'Modern',
	'Contemporary',
}
local genre_others = {
	'Soundtrack',
	'Humour'
}
local genre = tags.genre
for _, g in pairs(genre_classical) do
	local rel = stringrel(stringnorm(g), stringnorm(tags.genre))
	if rel > relmax then
		relmax = rel
		genre = g
	end
end
for _, g in pairs(genre_others) do
	local rel = stringrel(stringnorm(g), stringnorm(tags.genre))
	if rel > relmax then
		relmax = rel
		genre = g
		tags.performer = nil
	end
end
if relmax < 0.7 then
	tags.genre = nil
	tags.performer = nil
else
	tags.genre = genre
end

help([[
- Disc and track numbers only matter if the file is part of an album. Remove
  the leading zeros and consider the first number only (e.g. convert "01/17" to
  "1".
]])
tags.disc = not empty(o.album) and not empty(o.disc) and o.disc:match([[0*(\d*)]]) or nil
tags.track = not empty(o.album) and not empty(o.track) and o.track:match([[0*(\d*)]]) or nil

help([[
- Date: Only use the full year. Extract from the date the first number
  with 4 digits or more.
]])
tags.date = o.date and o.date:match([[\d\d\d\d+]]) or nil
tags.date = tags.date and tags.date or (o.year and o.year:match([[\d\d\d\d+]]) or '')

output.tags = tags
o = output.tags

help([[
REFERENCES

- http://musicbrainz.org/doc/MusicBrainz_Picard/Tags/Mapping
- http://musicbrainz.org/doc/Classical_Music_FAQ
]])
