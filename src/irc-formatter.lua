local sort = table.sort
local concat = table.concat

local find = string.find
local byte = string.byte
local gsub = string.gsub
local len  = string.len
local format = string.format

local pairs = pairs
local ipairs = ipairs
local setmetatable = setmetatable
local error = error
local tostring = tostring
local type = type

local Formatter = {
  missing = setmetatable({},{
    __tostring = function() return '' end,
  }),
}

local escapes = {
  ['\r'] = '\\r',
  ['\n'] = '\\n',
  [' '] = '\\s',
  [';'] = '\\:',
  ['\\'] = '\\\\',
}

local function grab_error(str)
  return nil, str
end

function Formatter._validate(t,f)
  f = f or grab_error
  if not t.command then
    return f('missing command')
  end

  local ct = type(t.command)
  if not (ct == 'number' or ct == 'string') then
    return f('command must be number or string')
  end

  if t.source then
    if t.source.user then
      if not t.source.nick then
        return f('source user requires nick')
      end
    end
  end

  if t.params then
    for i,p in ipairs(t.params) do
      if i ~= #t.params then -- we can only have a space or begin with a colon on the last param
        if byte(p,1) == 58 then
          return f('only the final param may begin with a colon')
        end

        if find(p,' ',1,true) then
          return f('only the final param may contain a space')
        end

        if len(p) == 0 then
          return f('only the final param may be empty')
        end
      end
    end
  end

  return true
end

function Formatter._format(t,force)
  local buf = {}
  if t.tags then
    local tags = {}
    local keys = {}
    for k in pairs(t.tags) do
      keys[#keys+1] = k
    end
    sort(keys)
    for _,k in ipairs(keys) do
      local v = t.tags[k]
      k = tostring(k)
      if v == Formatter.missing then
        tags[#tags+1] = k
      else
        tags[#tags+1] = k .. '=' .. gsub(tostring(v),'[\r\n ;\\]',escapes)
      end
    end
    buf[#buf + 1] = '@' .. concat(tags,';')
  end

  if t.source then
    local source = {}
    if t.source.nick then
      source[#source + 1] = t.source.nick
      if t.source.user then
        source[#source + 1] = '!' .. t.source.user
      end
      if t.source.host then
        source[#source + 1] = '@' .. t.source.host
      end
    else
      source[#source + 1] = t.source.host
    end
    buf[#buf + 1] = ':' .. concat(source)
  end

  local ct = type(t.command)
  if ct == 'number' then
    local fstring = '%d'
    if t.command < 100 then
      fstring = '%03d'
    end
    buf[#buf + 1] = format(fstring,t.command)
  else
    buf[#buf + 1] = t.command
  end

  if t.params then
    for i,p in ipairs(t.params) do
      p = tostring(p)
      if (i == #t.params and force) or byte(p,1) == 58 or find(p,' ',1,true) or len(p) == 0 then
        buf[#buf + 1] = ':' .. p
        break
      else
        buf[#buf + 1] = p
      end
    end
  end

  return concat(buf,' ') .. (t.eol or '')
end

local function merge(t1,t2)
  local t = {}
  t1 = t1 or {}
  t2 = t2 or {}

  for _,k in ipairs({'params'}) do
    local tmp = {}

    if t1[k] then
      for i=1,#t1[k] do
        tmp[i] = t1[k][i]
      end
    end

    if t2[k] then
      local o = #tmp
      for i=1,#t2[k] do
        tmp[o + i] = t2[k][i]
      end
    end

    if #tmp > 0 then
      t[k] = tmp
    end
  end

  for _,k in ipairs({'tags','source'}) do
    local keys = false
    t[k] = {}

    if t1[k] then
      keys = true
      for key,val in pairs(t1[k]) do
        t[k][key] = val
      end
    end

    if t2[k] then
      keys = true
      for key,val in pairs(t2[k]) do
        t[k][key] = val
      end
    end

    if not keys then
      t[k] = nil
    end
  end

  t.command = t2.command or t1.command
  t.eol = t2.eol or t1.eol
  return t
end

function Formatter:serialize(tbl,force)
  local t = merge(self,tbl)
  Formatter._validate(t,error)
  return Formatter._format(t,force)
end

Formatter.format = Formatter.serialize

function Formatter:validate(tbl)
  local t = merge(self,tbl)
  return Formatter._validate(t)
end

function Formatter:_tostring()
  local _, err = self:validate()
  if err then return '(error: ' .. err .. ')' end
  return self:_format()
end

local Formatter__mt = {
  __index    = Formatter,
  __tostring = Formatter._tostring,
}

local function new(msg)
  msg = msg or {}
  return setmetatable(msg,Formatter__mt)
end

local module = setmetatable({
  new = new,
  missing = Formatter.missing,
  _VERSION = '1.1.1',
}, {
  __call = function(_,msg)
    return new(msg)
  end,
})

return module
