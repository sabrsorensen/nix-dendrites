local function empty(value) return type(value) ~= 'string' or value == '' end
local function trim(value)
  if empty(value) then return '' end
  value = value:gsub('^%s+', ''):gsub('%s+$', ''):gsub('%s+', ' ')
  value = value:gsub('%s+([%]%):;,%.])', '%1'):gsub('([%[%(])%s+', '%1')
  return value
end
local function first(...)
  for _, value in ipairs({...}) do if not empty(value) then return value end end
end
local function feature(value)
  value = trim(value):gsub('[Ff]eaturing%s+', 'feat. '):gsub('[Ff]eat%.?%s+', 'feat. '):gsub('[Ff][Tt]%.?%s+', 'feat. ')
  return value
end
local function dedupe(values)
  local out, seen = {}, {}
  for _, value in ipairs(values) do
    local key = stringnorm(value)
    if value ~= '' and not seen[key] then seen[key] = true; table.insert(out, value) end
  end
  return out
end
local function remix(group)
  local open, content = group:sub(1, 1), trim(group:sub(2, -2))
  content = content:gsub('%f[%a][Rr][Mm][Xx]%f[%A]', 'Remix'):gsub('%f[%a][Rr]emix%f[%A]', 'Remix'):gsub('%f[%a][Mm]ix%f[%A]', 'Mix')
  return open == '[' and ('[' .. content .. ']') or ('(' .. content .. ')')
end
local function pop_remix(value)
  local groups = {}
  while true do
    local base, group = value:match('^(.-)%s*(%b())%s*$')
    if not group then base, group = value:match('^(.-)%s*(%b[])%s*$') end
    local content = group and group:sub(2, -2):lower() or ''
    if not group or not (content:match('%f[%a]remix%f[%A]') or content:match('%f[%a]rmx%f[%A]') or content:match('%f[%a]mix%f[%A]')) then break end
    value = trim(base); table.insert(groups, 1, remix(group))
  end
  return trim(value), groups
end
local function split_feature(value)
  local base, suffix = feature(value):match('^(.-)%s*%(%s*(feat%. .-)%s*%)%s*$')
  if base then return trim(base), trim(suffix) end
  base, suffix = feature(value):match('^(.-)%s*%[%s*(feat%. .-)%s*%]%s*$')
  if base then return trim(base), trim(suffix) end
  base, suffix = feature(value):match('^(.-)%s+(feat%. .-)%s*$')
  return trim(base or value), trim(suffix or '')
end
local function feature_names(suffix)
  local names = {}
  suffix = suffix:gsub('^[Ff]eat%.%s*', ''):gsub('%s*[&/]%s*', ', '):gsub('%s+[Aa][Nn][Dd]%s+', ', ')
  for name in suffix:gmatch('[^,;]+') do name = trim(name); if name ~= '' then table.insert(names, name) end end
  return dedupe(names)
end

tags.album = o.album
tags.performer = first(o.performer, o.conductor, o.orchestra, o.arranger)
local artist, featured = split_feature(first(o.artist, o.composer, o.album_artist, tags.performer, 'Unknown Artist'))
tags.title = trim(first(o.title, 'Unknown Title'))
tags.title, title_remixes = pop_remix(tags.title)
local title, title_feature = split_feature(tags.title)
local title_feature_base, feature_remixes = pop_remix(title_feature)
local names = feature_names(featured)
for _, name in ipairs(feature_names(title_feature_base)) do table.insert(names, name) end
names = dedupe(names)
featured = #names > 0 and ('feat. ' .. table.concat(names, ', ')) or ''
tags.artist = trim(artist .. (featured ~= '' and (' ' .. featured) or ''))
tags.title = title
for _, group in ipairs(feature_remixes) do tags.title = trim(tags.title .. ' ' .. group) end
for _, group in ipairs(title_remixes) do tags.title = trim(tags.title .. ' ' .. group) end
tags.album_artist = first(o.album_artist, artist)
if not empty(o.album_artist) and stringrel(stringnorm(o.album_artist), 'variousartist') > .7 then tags.album_artist = o.album end
tags.genre = o.genre
local genres = {'Medieval', 'Renaissance', 'Baroque', 'Classical', 'Romantic', 'Modern', 'Contemporary', 'Soundtrack', 'Humour'}
local best, normalized = 0, tags.genre
for _, genre in ipairs(genres) do
  local relation = stringrel(stringnorm(genre), stringnorm(tags.genre))
  if relation > best then best, normalized = relation, genre end
end
if best < .7 then tags.genre, tags.performer = nil, nil
else
  tags.genre = normalized
  if normalized == 'Soundtrack' or normalized == 'Humour' then tags.performer = nil end
end
tags.disc = not empty(o.album) and not empty(o.disc) and o.disc:match([[0*(\d*)]]) or nil
tags.track = not empty(o.album) and not empty(o.track) and o.track:match([[0*(\d*)]]) or nil
tags.date = o.date and o.date:match([[\d\d\d\d+]]) or nil
tags.date = tags.date or (o.year and o.year:match([[\d\d\d\d+]]) or '')
output.tags = tags
o = output.tags
