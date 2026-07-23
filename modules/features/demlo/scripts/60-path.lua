local sep = ossep or '/'
local library = lib or sep .. 'AnomalyRealm' .. sep .. 'media' .. sep .. 'music' .. sep .. 'ready_to_stream' .. sep .. 'sam_library'
local substitutions = pathsub or {}

local function empty(value) return type(value) ~= 'string' or value == '' end
local function clean(value)
  if empty(value) then return '' end
  value = value:gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '')
  for _, rule in ipairs(substitutions) do value = value:gsub(rule[1], rule[2]) end
  return value:gsub([[\s*]] .. sep .. [[\s*]], ' - ')
end
local function append(...)
  for _, value in pairs({...}) do
    if not empty(value) then output.path = output.path .. clean(value) end
  end
end

local track = ''
if not empty(o.track) and tonumber(o.track) then track = string.format('%02d', o.track) end
local genre = o.genre and o.genre:lower():gsub([[%s]], '_')
local classical = false
if genre then
  for needle, _ in pairs({ medieval=true, renaissance=true, baro=true, classic=true, romantic=true, modern=true, contemp=true }) do
    if genre:match(needle) then classical = true; break end
  end
end

output.path = library .. sep
local album_artist = not empty(o.album_artist) and o.album_artist or (not empty(o.artist) and o.artist or 'Unknown Artist')
append(album_artist)
output.path = output.path .. sep
if not empty(o.album) then
  if classical then
    append(o.album)
    if not empty(o.performer) then append(' (' .. o.performer .. (not empty(o.date) and (', ' .. clean(o.date)) or '') .. ')') end
  else
    if not empty(o.date) then append(o.date .. ' - ') end
    append(o.album)
  end
  output.path = output.path .. sep
  if not empty(o.disc) then append(o.disc) end
  if not empty(track) then append(track .. ' - ') end
end
append(o.artist .. ' - ')
append(o.title)
local ext = empty(output.format) and input.format.format_name or output.format
append('.' .. ext)
output.path = output.path:gsub('[%*%?:]', '_')
