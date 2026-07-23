local sentencecase = scase or false
local custom = const or {'ANN', 'TKO', 'LUZCID', 'Macntaj', 'HAILO', 'RJD2', 'M1A1', 'LP4', 'MGMT', 'REVOFEV', 'UK', 'NYC', 'MSK', 'AVIA', 'VIP', 'SBTRKT', 'GMO', 'ATL', 'PBS', 'TRON', 'TN', 'CPU', 'OnFlow', 'JME', 'IPlayYouListen', 'PDA', 'SUN_MONX', 'SUN:MONX', 'JP', 'SpVce', 'saQi', 'VLA', 'MB', 'BT', 'DFRNT', 'SubDivision', 'OST', 'DYL', 'HLZ', 'JS16', 'y', 'MF', 'DOOM', 'ARF', 'GUNSHIP', 'PDX'}
local constants = {}
for _, value in ipairs(custom) do constants[value:upper()] = value end
for _, value in ipairs({'CD', 'CD1', 'CD2', 'CD3', 'CD4', 'CD5', 'CD6', 'CD7', 'CD8', 'CD9', 'DJ', 'EP', 'feat', 'ft', 'FX', 'LP', 'KO', 'OK', 'TV', 'vs', 'bps', 'Gbps', 'GHz', 'h', 'Hz', 'kbps', 'kg', 'kHz', 'km', 'kph', 'Mbps', 'MHz', 'ms', 's'}) do constants[value:upper()] = value end
local ordinary_mac = {'Mache', 'Machete', 'Machicolate', 'Machicolation', 'Machinate', 'Machination', 'Machine', 'Machinery', 'Machinist', 'Machismo', 'Macho', 'Machzor', 'Mackerel', 'Mackinaw', 'Mackintosh', 'Mackle', 'Macle', 'Macrame', 'Macro', 'Macrobiotics', 'Macrocephaly', 'Macroclimate', 'Macrocode', 'Macrocosm', 'Macrocyte', 'Macrocytosis', 'Macroeconomics', 'Macroevolution', 'Macrofossil', 'Macrogamete', 'Macroglobulin', 'Macroglobulinemia', 'Macrograph', 'Macrography', 'Macroinstruction', 'Macromere', 'Macromolecule', 'Macron', 'Macronucleus', 'Macronutrient', 'Macrophage', 'Macrophysics', 'Macrophyte', 'Macropterous', 'Macroscopic', 'Macrosporangium', 'Macrospore'}
for _, value in ipairs(ordinary_mac) do
  constants[value:upper()] = sentencecase and value:lower() or value
  local plural = value:sub(-1) == 'y' and (value:sub(1, -2) .. 'ies') or (value:sub(-1) == 's' and value or value .. 's')
  constants[plural:upper()] = sentencecase and plural:lower() or plural
end
local small = { a=true, an=true, and=true, as=true, at=true, but=true, by=true, for=true, if=true, in=true, nor=true, not=true, of=true, on=true, so=true, the=true, to=true, via=true }
local function case(value)
  if type(value) ~= 'string' then return value end
  local output, first = {}, true
  for nonword, word in value:gmatch([[([^\pL\pN]*)([\pL\pN][\pL\pN'´’]*[\pL\pN]|[\pL\pN])]]) do
    table.insert(output, nonword)
    local fixed = constants[word:upper()]
    local lower = word:lower()
    local result
    if fixed then result = fixed
    elseif word:match('^[IVXLCDM]+$') then result = word
    elseif not sentencecase and word:match("^[dDoO]['´’][\pL\pN]") then
      result = word:sub(1, 1):upper() .. word:sub(2, 3) .. lower:sub(4)
    elseif word:upper():match('^MA?C[B-DF-HJ-NP-TV-Z]') then
      if word:upper():sub(2, 2) == 'A' then
        result = word:sub(1, 1):upper() .. 'ac' .. word:sub(4, 4):upper() .. lower:sub(5)
      else
        result = word:sub(1, 1):upper() .. 'c' .. word:sub(3, 3):upper() .. lower:sub(4)
      end
    else
      result = sentencecase and lower or (first or not small[lower]) and (lower:sub(1, 1):upper() .. lower:sub(2)) or lower
    end
    first = false
    table.insert(output, result)
  end
  table.insert(output, value:match([[([^\pL\pN]*)$]]))
  value = table.concat(output)
  value = value:gsub([=[[\pL\pN]=], function(character) return character:upper() end, 1)
  value = value:gsub([[([{}[\]?!():.-/][^\pL\pN]*)(\p{Ll})]], function(prefix, character) return prefix .. character:upper() end)
  if not sentencecase then value = value:gsub([[(&[^\pL\pN]*)(\p{Ll})]], function(prefix, character) return prefix .. character:upper() end) end
  return value
end
tags.artist = case(tags.artist)
tags.album_artist = case(tags.album_artist)
tags.album = case(tags.album)
tags.title = case(tags.title)
tags.performer = case(tags.performer)
