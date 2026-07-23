local low, high = 700, 3000
local dirname = output.path:match('^(.*)/') or '.'
local seen = {}

local function convert(cover, stream, file)
  local id = file and tostring(file) or (stream and ('stream ' .. tostring(stream)) or 'online')
  local result = { parameters = {} }
  if cover.width < low or cover.height < low then
    debug('Script cover: skip low quality: ' .. id)
    return result
  end
  if seen[cover.checksum] then
    debug('Script cover: skip duplicate: ' .. id)
    return result
  end
  seen[cover.checksum] = id
  local ratio = math.max(cover.width / high, cover.height / high)
  if ratio > 1 then
    result.parameters = { '-s', math.floor(cover.width / ratio + .5) .. 'x' .. math.floor(cover.height / ratio + .5) }
  elseif cover.format == 'jpeg' then
    result.parameters = nil
  else
    result.parameters = { '-c:' .. (stream or 0), 'mjpeg' }
  end
  result.format = 'mjpeg'
  result.path = dirname .. '/cover.jpg'
  return result
end

for stream, cover in pairs(input.embeddedcovers) do
  output.embeddedcovers[stream] = convert(cover, stream)
  output.parameters[#output.parameters + 1] = '-vn'
end
for file, cover in pairs(input.externalcovers) do output.externalcovers[file] = convert(cover, nil, file) end
if input.onlinecover.format ~= '' then output.onlinecover = convert(input.onlinecover) end
