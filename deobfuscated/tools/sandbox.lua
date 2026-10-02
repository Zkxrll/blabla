-- sandbox.lua : trace-based sandbox for Roblox-style Lua scripts (Lua 5.1)
-- Runs inside lupa.lua51. The target script only ever sees `env` (mock Roblox/exploit API with
-- logging proxies). No os/io/debug/require/package, loadstring is re-wrapped so nested chunks are
-- confined to `env` too. Everything the script does is written to LOG.

local R = {}
for _, k in ipairs({"type","tostring","tonumber","pairs","ipairs","next","select","unpack","pcall","xpcall",
                    "error","assert","setmetatable","getmetatable","rawget","rawset","rawequal","loadstring",
                    "newproxy","collectgarbage"}) do R[k] = _G[k] end
local string, table, math, coroutine = string, table, math, coroutine
local sethook, traceback = debug.sethook, debug.traceback
local type, tostring, tonumber, pairs, ipairs, select, pcall = R.type, R.tostring, R.tonumber, R.pairs, R.ipairs, R.select, R.pcall
local setmetatable, getmetatable, rawget, rawset, rawequal = R.setmetatable, R.getmetatable, R.rawget, R.rawset, R.rawequal
local newproxy, error, unpack = R.newproxy, R.error, R.unpack

do -- harden string library (shared with every string via its metatable)
  local rep = string.rep
  string.rep = function(s, n)
    if type(n) == "number" and #s * n > 4000000 then error("string.rep too large", 2) end
    return rep(s, n)
  end
  string.dump = nil
end

CONFIG = CONFIG or {}
local LOG, nlog, MAXLOG = {}, 0, 600000
local indent = 0
local function log(s)
  if nlog < MAXLOG then nlog = nlog + 1; LOG[nlog] = string.rep("  ", indent) .. s
  elseif nlog == MAXLOG then nlog = nlog + 1; LOG[nlog] = "-- LOG TRUNCATED" end
end

---------------------------------------------------------------- value printing
local paths   = setmetatable({}, {__mode = "k"})
local parentO = setmetatable({}, {__mode = "k"})
local nameO   = setmetatable({}, {__mode = "k"})
local kids    = setmetatable({}, {__mode = "k"})
local props   = setmetatable({}, {__mode = "k"})
local classO  = setmetatable({}, {__mode = "k"})
local fids    = setmetatable({}, {__mode = "k"})
local nfn = 0
local function fname(f)
  local id = fids[f]
  if not id then nfn = nfn + 1; id = nfn; fids[f] = id end
  return "fn_" .. id
end

local function q(s)
  local out = s:gsub('[%c\\"]', function(c)
    if c == "\\" then return "\\\\" elseif c == '"' then return '\\"'
    elseif c == "\n" then return "\\n" elseif c == "\r" then return "\\r" elseif c == "\t" then return "\\t"
    else return string.format("\\%03d", c:byte()) end
  end)
  return '"' .. out .. '"'
end

local repr
repr = function(v, depth)
  depth = depth or 0
  local t = type(v)
  if t == "string" then
    if #v > 60000 then return q(v:sub(1, 60000)) .. "--[[+" .. (#v - 60000) .. " bytes]]" end
    return q(v)
  elseif t == "number" or t == "boolean" or t == "nil" then return tostring(v)
  elseif t == "function" then return fname(v)
  elseif t == "table" then
    if depth > 3 then return "{...}" end
    local parts, n, len = {}, 0, #v
    for i = 1, len do
      n = n + 1
      if n > 16 then parts[#parts + 1] = "..."; break end
      parts[#parts + 1] = repr(v[i], depth + 1)
    end
    local cnt = 0
    for k, x in pairs(v) do
      if not (type(k) == "number" and k >= 1 and k <= len and k % 1 == 0) then
        cnt = cnt + 1
        if cnt > 24 then parts[#parts + 1] = "..."; break end
        local ks = (type(k) == "string" and k:match("^[%a_][%w_]*$")) and k or ("[" .. repr(k, depth + 1) .. "]")
        parts[#parts + 1] = ks .. " = " .. repr(x, depth + 1)
      end
    end
    return "{" .. table.concat(parts, ", ") .. "}"
  elseif paths[v] then return paths[v]
  else return tostring(v) end
end

---------------------------------------------------------------- virtual FS / state
local FS = {}
local clipboard
local callbacks, ncb = {}, 0
local deferred = {}
local waits = 0
local varN = 0
local services = {}

---------------------------------------------------------------- mini JSON
local function json_encode(v, d)
  d = d or 0
  local t = type(v)
  if t == "string" then return q(v)
  elseif t == "number" or t == "boolean" then return tostring(v)
  elseif t == "nil" then return "null"
  elseif t == "table" and d < 6 then
    local n = #v
    local out = {}
    if n > 0 then
      for i = 1, n do out[#out + 1] = json_encode(v[i], d + 1) end
      return "[" .. table.concat(out, ",") .. "]"
    end
    local ks = {}
    for k in pairs(v) do ks[#ks + 1] = tostring(k) end
    table.sort(ks)
    for _, k in ipairs(ks) do out[#out + 1] = q(k) .. ":" .. json_encode(v[k], d + 1) end
    return "{" .. table.concat(out, ",") .. "}"
  end
  return "null"
end

local function json_decode(s)
  local pos = 1
  local function ws() pos = s:find("%S", pos) or #s + 1 end
  local val
  local function str()
    local out, i = {}, pos + 1
    while true do
      local c = s:sub(i, i)
      if c == "" then error("bad json") end
      if c == '"' then pos = i + 1; return table.concat(out) end
      if c == "\\" then
        local n = s:sub(i + 1, i + 1)
        local map = {n = "\n", t = "\t", r = "\r", b = "\b", f = "\f"}
        if n == "u" then out[#out + 1] = string.char(tonumber(s:sub(i + 2, i + 5), 16) % 256); i = i + 6
        else out[#out + 1] = map[n] or n; i = i + 2 end
      else out[#out + 1] = c; i = i + 1 end
    end
  end
  val = function()
    ws()
    local c = s:sub(pos, pos)
    if c == "{" then
      local t = {}; pos = pos + 1; ws()
      if s:sub(pos, pos) == "}" then pos = pos + 1; return t end
      while true do
        ws(); local k = str(); ws()
        if s:sub(pos, pos) ~= ":" then error("bad json") end
        pos = pos + 1; t[k] = val(); ws()
        local d = s:sub(pos, pos); pos = pos + 1
        if d == "}" then return t elseif d ~= "," then error("bad json") end
      end
    elseif c == "[" then
      local t = {}; pos = pos + 1; ws()
      if s:sub(pos, pos) == "]" then pos = pos + 1; return t end
      while true do
        t[#t + 1] = val(); ws()
        local d = s:sub(pos, pos); pos = pos + 1
        if d == "]" then return t elseif d ~= "," then error("bad json") end
      end
    elseif c == '"' then return str()
    elseif s:sub(pos, pos + 3) == "true" then pos = pos + 4; return true
    elseif s:sub(pos, pos + 4) == "false" then pos = pos + 5; return false
    elseif s:sub(pos, pos + 3) == "null" then pos = pos + 4; return nil
    else
      local num = s:match("^-?%d+%.?%d*[eE]?[+-]?%d*", pos)
      if not num or num == "" then error("bad json") end
      pos = pos + #num; return tonumber(num)
    end
  end
  return val()
end

---------------------------------------------------------------- logging proxies
local base = newproxy(true)
local PM = getmetatable(base)
local newp

local function register_callback(f, desc)
  ncb = ncb + 1
  callbacks[#callbacks + 1] = {fn = f, desc = desc, done = false}
end

newp = function(path, par, nm, class)
  local u = newproxy(base)
  paths[u] = path; parentO[u] = par; nameO[u] = nm; classO[u] = class
  return u
end

local function newvar(hint)
  varN = varN + 1
  return (hint and (hint:gsub("[^%w_]", "")) or "v") .. "_" .. varN
end

local STRPROPS = {Name = "Player1", DisplayName = "Player1", Text = "", PlaceHolderText = "", JobId = "job-0000",
                  ClassName = "Instance", Version = "1.0.0"}
local NUMPROPS = {UserId = 1337, PlaceId = 1818, GameId = 1818, Value = 0, TextBounds = 100, AccountAge = 400}

NUMLEGEND = {}
local idc = setmetatable({}, {__mode = "k"})
local nidc = 0
local function nid(self)
  local i = idc[self]
  if not i then nidc = nidc + 1; i = nidc; idc[self] = i end
  return i
end
PM.__index = function(self, k)
  local pr = props[self]
  if pr and pr[k] ~= nil then return pr[k] end
  local ch = kids[self]
  if not ch then ch = {}; kids[self] = ch end
  local v = ch[k]
  if v ~= nil then return v end
  local p = paths[self]
  if type(k) == "string" and classO[self] == "Sym" then
    local sv = newp(p .. "." .. k, self, k, "Sym")
    ch[k] = sv
    return sv
  end
  if type(k) == "string" and (classO[self] == "Enum" or classO[self] == "EnumType") then
    local ev = newp(p .. "." .. k, self, k, classO[self] == "Enum" and "EnumType" or "EnumItem")
    ch[k] = ev
    return ev
  end
  if type(k) == "string" then
    if STRPROPS[k] and not (classO[self] == "Enum") then
      if k == "Text" then return "" end
      return STRPROPS[k]
    end
    if k == "PlaceId" then return CONFIG.place_id or NUMPROPS[k] end
    if k == "GameId" then return CONFIG.game_id or CONFIG.place_id or NUMPROPS[k] end
    if NUMPROPS[k] then return NUMPROPS[k] end
    local cls = classO[self]
    local GUI = {Frame = 1, TextButton = 1, TextLabel = 1, TextBox = 1, ImageLabel = 1, ImageButton = 1, ScrollingFrame = 1, CanvasGroup = 1}
    if (k == "Size" or k == "Position") and GUI[cls] then
      local kp2 = p .. "." .. k
      local v2 = newp(kp2, self, k, "UDim2")
      ch[k] = v2
      return v2
    end
    local NUMBYKEY = {X = 333, Y = 444, Z = 555, Scale = 111, Offset = 222, Width = 666, Height = 777, Magnitude = 888}
    if ((k == "X" or k == "Y" or k == "Z") and cls ~= "UDim2") or (NUMBYKEY[k] and k ~= "X" and k ~= "Y" and k ~= "Z") then
      local num = NUMBYKEY[k] + (CONFIG.plain_numbers and 0 or 1000 * nid(self))
      NUMLEGEND[num] = p .. "." .. k
      return num
    end
    local kp = k:match("^[%a_][%w_]*$") and (p .. "." .. k) or (p .. "[" .. q(k) .. "]")
    local ncls = nil
    if (k == "X" or k == "Y") and cls == "UDim2" then ncls = "UDim"
    elseif k == "AbsoluteSize" or k == "AbsolutePosition" or k == "TextBounds" or k == "ViewportSize" then ncls = "Vector2" end
    v = newp(kp, self, k, ncls)
  else
    v = newp(p .. "[" .. repr(k) .. "]", self, k, nil)
  end
  ch[k] = v
  return v
end

PM.__newindex = function(self, k, v)
  local pr = props[self]
  if not pr then pr = {}; props[self] = pr end
  pr[k] = v
  local ks = (type(k) == "string" and k:match("^[%a_][%w_]*$")) and ("." .. k) or ("[" .. repr(k) .. "]")
  log(paths[self] .. ks .. " = " .. repr(v))
  if type(v) == "function" then register_callback(v, paths[self] .. ks) end
end

PM.__tostring = function(self) return paths[self] end
PM.__concat = function(a, b) return (type(a) == "userdata" and paths[a] or tostring(a)) .. (type(b) == "userdata" and paths[b] or tostring(b)) end
PM.__len = function() return 0 end
INSTANCES = {}
local STRUCT, INSTIDX = setmetatable({}, {__mode = "k"}), setmetatable({}, {__mode = "k"})
local srepr
srepr = function(v, depth)
  depth = depth or 0
  local t = type(v)
  if t == "userdata" and paths[v] then
    if INSTIDX[v] then return "#" .. INSTIDX[v] end
    if STRUCT[v] then return STRUCT[v] end
    return paths[v]
  elseif t == "table" then
    if depth > 3 then return "{...}" end
    local parts = {}
    for i = 1, #v do parts[#parts + 1] = srepr(v[i], depth + 1) end
    local keys = {}
    for k in pairs(v) do if not (type(k) == "number" and k >= 1 and k <= #v) then keys[#keys + 1] = k end end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    for _, k in ipairs(keys) do parts[#parts + 1] = tostring(k) .. "=" .. srepr(v[k], depth + 1) end
    return "{" .. table.concat(parts, ",") .. "}"
  else return repr(v, depth) end
end
function SNAPSHOT()
  local out = {}
  for i, inst in ipairs(INSTANCES) do
    local pr = props[inst] or {}
    local keys = {}
    for k in pairs(pr) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    local parts = {}
    for _, k in ipairs(keys) do parts[#parts + 1] = tostring(k) .. "=" .. srepr(pr[k]) end
    out[#out + 1] = "#" .. i .. " " .. tostring(classO[inst]) .. " { " .. table.concat(parts, "; ") .. " }"
  end
  return table.concat(out, "\n")
end
local OPSYM = {add = "+", sub = "-", mul = "*", div = "/", mod = "%", pow = "^"}
for _, op in ipairs({"add", "sub", "mul", "div", "mod", "pow"}) do
  PM["__" .. op] = function(a, b) return newp("(" .. repr(a) .. " " .. OPSYM[op] .. " " .. repr(b) .. ")", nil, nil, "Sym") end
end
PM.__unm = function(a) return newp("(-" .. repr(a) .. ")", nil, nil, "Sym") end
PM.__lt = function() return false end
PM.__le = function() return true end

LIBMOCKS = {}
TEXTBOXES = {}
local function http_mock(url, extra)
  log("-- HTTP " .. (extra or "GET") .. " " .. repr(url))
  local body = CONFIG.http_body
  if type(CONFIG.lib_patterns) == "table" and type(url) == "string" then
    for pat, nm in pairs(CONFIG.lib_patterns) do
      if url:find(pat, 1, true) then
        local key = "__MOCK_" .. nm
        if not LIBMOCKS[key] then LIBMOCKS[key] = newp(nm, nil, nil, nil) end
        log("-- (mocking remote library " .. nm .. " from " .. url .. ")")
        return "return " .. key
      end
    end
  end
  if type(CONFIG.http_bodies) == "table" then
    for pat, b in pairs(CONFIG.http_bodies) do if type(url) == "string" and url:find(pat, 1, true) then body = b end end
  end
  return body or ""
end

local function service(name)
  local s = services[name]
  if not s then
    s = newp(name, nil, nil, "Service")
    services[name] = s
    log("local " .. name .. " = game:GetService(" .. q(name) .. ")")
  end
  return s
end

local function child_named(self, nm, how)
  local ch = kids[self]
  if not ch then ch = {}; kids[self] = ch end
  local key = "#" .. tostring(nm)
  if not ch[key] then
    local var = newvar(type(nm) == "string" and nm or "child")
    ch[key] = newp(var, self, nil, nil)
    log("local " .. var .. " = " .. paths[self] .. ":" .. how .. "(" .. repr(nm) .. ")")
  end
  return ch[key]
end

-- method handlers: (self, args-array, nargs) -> returns value(s)
local METHODS = {}
METHODS.GetService = function(self, a) return service(a[1]) end
METHODS.FindService = METHODS.GetService
METHODS.HttpGet = function(self, a) return http_mock(a[1]) end
METHODS.HttpGetAsync = METHODS.HttpGet
METHODS.HttpPost = function(self, a) return http_mock(a[1], "POST " .. repr(a[2])) end
METHODS.IsStudio = function() return CONFIG.studio and true or false end
METHODS.IsA = function() return true end
METHODS.IsDescendantOf = function() return true end
METHODS.GenerateGUID = function() return "{00000000-1111-2222-3333-444444444444}" end
METHODS.UrlEncode = function(self, a) return (tostring(a[1]):gsub("[^%w%-_%.~]", function(c) return string.format("%%%02X", c:byte()) end)) end
METHODS.JSONEncode = function(self, a) local s = json_encode(a[1]); log("-- JSONEncode -> " .. repr(s)); return s end
METHODS.JSONDecode = function(self, a)
  local ok, r = pcall(json_decode, a[1])
  log("-- JSONDecode(" .. repr(a[1]) .. ") -> " .. (ok and repr(r) or "ERROR"))
  if ok then return r end
  error("Can't parse JSON", 0)
end
METHODS.GetChildren = function() return {} end
METHODS.GetDescendants = function() return {} end
METHODS.GetPlayers = function() return {} end
METHODS.FindFirstChild = function(self, a) return child_named(self, a[1], "FindFirstChild") end
METHODS.WaitForChild = function(self, a) return child_named(self, a[1], "WaitForChild") end
METHODS.FindFirstChildOfClass = function(self, a) return child_named(self, a[1], "FindFirstChildOfClass") end
METHODS.FindFirstChildWhichIsA = METHODS.FindFirstChildOfClass
METHODS.GetFullName = function(self) return "Game." .. tostring(nameO[self] or "Instance") end
METHODS.Kick = function(self, a) log("!!! KICK: " .. paths[self] .. ":Kick(" .. repr(a[1]) .. ")"); if INTROSPECT then INTROSPECT("Kick " .. repr(a[1])) end end
METHODS.GetPropertyChangedSignal = nil
METHODS.IsLoaded = function() return true end

local function do_call(self, ...)
  local par, nm = parentO[self], nameO[self]
  local n = select("#", ...)
  local args = {...}
  local isMethod = par ~= nil and nm ~= nil and n >= 1 and rawequal(args[1], par)
  local first = isMethod and 2 or 1
  local a, parts = {}, {}
  for i = first, n do
    a[#a + 1] = args[i]
    parts[#parts + 1] = repr(args[i])
  end
  local callee = isMethod and (paths[par] .. ":" .. tostring(nm)) or paths[self]
  -- register callbacks nested in option tables (UI-library style: {Callback = function ... end})
  local function scan(t, where, depth)
    if depth > 3 then return end
    for k, x in pairs(t) do
      if type(x) == "function" then
        callbacks[#callbacks + 1] = {fn = x, desc = callee .. "{" .. tostring(k) .. "}", done = false, tbl = true}
      elseif type(x) == "table" then scan(x, where, depth + 1) end
    end
  end
  for i = first, n do if type(args[i]) == "table" then scan(args[i], callee, 1) end end
  local h = isMethod and METHODS[nm]
  if h then
    local r = h(par, a, #a)
    if nm ~= "FindFirstChild" and nm ~= "WaitForChild" and nm ~= "FindFirstChildOfClass" and nm ~= "FindFirstChildWhichIsA"
       and nm ~= "GetService" and nm ~= "FindService" and nm ~= "JSONDecode" and nm ~= "JSONEncode" and nm ~= "HttpGet" and nm ~= "HttpGetAsync" then
      log(callee .. "(" .. table.concat(parts, ", ") .. ")  --> " .. repr(r))
    end
    return r
  end
  -- connect-style callbacks
  if isMethod and (nm == "Connect" or nm == "Once" or nm == "ConnectParallel") then
    for i = 1, #a do if type(a[i]) == "function" then register_callback(a[i], paths[par]) end end
  end
  local hint
  if callee == "Instance.new" or (not isMethod and paths[self] and paths[self]:match("^Instance%.new$")) then hint = tostring(a[1]) end
  if not hint then
    local ctor = callee:match("^([%w_]+)%.[%w_]+$")
    if ctor == "UDim2" or ctor == "Vector2" or ctor == "UDim" or ctor == "Vector3" or ctor == "Color3" or ctor == "CFrame" or ctor == "Font" or ctor == "NumberSequence" or ctor == "NumberSequenceKeypoint" or ctor == "ColorSequence" or ctor == "ColorSequenceKeypoint" or ctor == "NumberRange" or ctor == "Rect" then hint = nil; CTORCLASS = ctor else CTORCLASS = nil end
  else CTORCLASS = nil end
  local var = newvar(hint)
  local result = newp(var, nil, nil, hint or CTORCLASS)
  if hint then INSTANCES[#INSTANCES + 1] = result; INSTIDX[result] = #INSTANCES
  else
    local sp = {}
    for i = 1, #a do sp[#sp + 1] = srepr(a[i]) end
    if isMethod then STRUCT[result] = srepr(par) .. ":" .. tostring(nm) .. "(" .. table.concat(sp, ", ") .. ")"
    else STRUCT[result] = srepr(self) .. "(" .. table.concat(sp, ", ") .. ")" end
  end
  if hint then
    props[result] = props[result] or {}
    if hint == "TextBox" then props[result].Text = ""; TEXTBOXES[#TEXTBOXES + 1] = result end
  end
  log("local " .. var .. " = " .. callee .. "(" .. table.concat(parts, ", ") .. ")")
  return result
end
PM.__call = do_call


---------------------------------------------------------------- stack introspection (debug lib stays out of the sandbox)
local dbg = debug
local function interesting(t)
  local n, numkeys, bigstr = 0, 0, 0
  for k, v in pairs(t) do
    n = n + 1
    if n > 300 then return false end
    if type(k) == "number" and k > 100000 then numkeys = numkeys + 1 end
  end
  return numkeys >= 1
end
function INTROSPECT(tag)
  log("-- [introspect] " .. tag)
  local seen = {}
  local function consider(origin, name, v)
    if type(v) ~= "table" or seen[v] then return end
    seen[v] = true
    if interesting(v) then log("--   " .. origin .. " " .. tostring(name) .. " = " .. repr(v)) end
    local n = 0
    for k, x in pairs(v) do
      n = n + 1
      if n > 500 then break end
      if type(x) == "table" and not seen[x] then
        seen[x] = true
        if interesting(x) then log("--   " .. origin .. " " .. tostring(name) .. "[" .. tostring(k) .. "] = " .. repr(x)) end
      end
    end
  end
  for level = 2, 40 do
    local info = dbg.getinfo(level, "f")
    if not info then break end
    local i = 1
    while true do
      local nm, val = dbg.getlocal(level, i)
      if not nm then break end
      consider("L" .. level, nm, val); i = i + 1
    end
    if info.func then
      local j = 1
      while true do
        local nm, val = dbg.getupvalue(info.func, j)
        if not nm then break end
        consider("U" .. level, nm, val); j = j + 1
      end
    end
  end
end


local function errdump(err)
  log("-- [error-introspect] " .. tostring(err))
  for level = 2, 6 do
    local info = dbg.getinfo(level, "S")
    if not info then break end
    if info.what == "Lua" then
      local parts, i = {}, 1
      while true do
        local nm, val = dbg.getlocal(level, i)
        if not nm then break end
        local t = type(val)
        if t == "string" then parts[#parts + 1] = nm .. "=" .. repr(#val > 80 and val:sub(1, 80) or val)
        elseif t == "number" or t == "boolean" then parts[#parts + 1] = nm .. "=" .. tostring(val)
        elseif t == "userdata" and paths[val] then parts[#parts + 1] = nm .. "=" .. paths[val]
        elseif t == "function" then parts[#parts + 1] = nm .. "=" .. fname(val) end
        i = i + 1
      end
      log("--   level " .. level .. ": " .. table.concat(parts, " "))
    end
  end
  return err
end
local function safe_call(f, ...)
  local args, n = {...}, select("#", ...)
  return R.xpcall(function() return f(unpack(args, 1, n)) end, errdump)
end

local function mk_luarmor()
  local store = {}
  local api
  api = setmetatable({}, {
    __index = function(_, k) local v = store[k]; if v == nil then log("-- luarmor_api." .. tostring(k) .. " read -> nil") end return v end,
    __newindex = function(_, k, v) store[k] = v; log("luarmor_api." .. tostring(k) .. " = " .. repr(v)) end})
  store.check_key = function(a, b)
    local key = rawequal(a, api) and b or a
    log("luarmor_api.check_key(" .. repr(key) .. ")   -- script_id=" .. repr(store.script_id))
    INTROSPECT("check_key")
    local code = CONFIG.luarmor_code or "KEY_VALID"
    log("--   (mock returns code=" .. code .. ")")
    return {code = code, message = CONFIG.luarmor_message or code, data = {auth_expire = 4102444800, note = "", total_executions = 1, status = "active"}}
  end
  store.load_script = function() log("luarmor_api.load_script()   -- script_id=" .. repr(store.script_id)) end
  return api
end
LIBMOCKS.__MOCK_Luarmor = mk_luarmor()


---------------------------------------------------------------- Luau compatibility helpers (added to the shared std tables)
function table.find(t, v, init) for i = init or 1, #t do if t[i] == v then return i end end return nil end
function table.clear(t) for k in pairs(t) do t[k] = nil end end
function table.create(n, v) local t = {} if v ~= nil then for i = 1, n do t[i] = v end end return t end
function table.pack(...) return {n = select("#", ...), ...} end
table.unpack = unpack
function table.move(a1, f, e, t, a2) a2 = a2 or a1; if t > f then for i = e, f, -1 do a2[t + i - f] = a1[i] end else for i = f, e do a2[t + i - f] = a1[i] end end return a2 end
function table.clone(t) local c = {} for k, v in pairs(t) do c[k] = v end return setmetatable(c, getmetatable(t)) end
function table.freeze(t) return t end
function table.isfrozen() return false end
function math.clamp(x, a, b) if x < a then return a elseif x > b then return b end return x end
function math.round(x) return x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5) end
function math.sign(x) return x > 0 and 1 or (x < 0 and -1 or 0) end
function math.lerp(a, b, t) return a + (b - a) * t end
function string.split(s, sep)
  local out, pos = {}, 1
  sep = sep or ","
  while true do
    local i, j = s:find(sep, pos, true)
    if not i then out[#out + 1] = s:sub(pos); break end
    out[#out + 1] = s:sub(pos, i - 1); pos = j + 1
  end
  return out
end
local function b32(n) n = math.floor(n) % 4294967296; return n end
local function bitop(a, b, f)
  a, b = b32(a), b32(b)
  local r, bit = 0, 1
  for _ = 1, 32 do
    if f(a % 2, b % 2) then r = r + bit end
    a, b, bit = math.floor(a / 2), math.floor(b / 2), bit * 2
  end
  return r
end
local bit32 = {
  band = function(a, b, ...) local r = bitop(a, b, function(x, y) return x == 1 and y == 1 end); if select("#", ...) > 0 then return bit32.band(r, ...) end return r end,
  bor  = function(a, b, ...) local r = bitop(a, b, function(x, y) return x == 1 or y == 1 end); if select("#", ...) > 0 then return bit32.bor(r, ...) end return r end,
  bxor = function(a, b, ...) local r = bitop(a, b, function(x, y) return x ~= y end); if select("#", ...) > 0 then return bit32.bxor(r, ...) end return r end,
  bnot = function(a) return 4294967295 - b32(a) end,
  lshift = function(a, n) return b32(b32(a) * 2 ^ n) end,
  rshift = function(a, n) return math.floor(b32(a) / 2 ^ n) end,
  arshift = function(a, n) a = b32(a); local r = math.floor(a / 2 ^ n); if a >= 2147483648 then r = r + (4294967296 - 2 ^ (32 - n)) end return b32(r) end,
}
bit32.btest = function(a, b) return bit32.band(a, b) ~= 0 end
BIT32 = bit32

---------------------------------------------------------------- environment
local env = {}
local missed = {}
setmetatable(env, {__index = function(_, k)
  if LIBMOCKS[k] then return LIBMOCKS[k] end
  if CONFIG.nodedupe or not missed[k] then missed[k] = true; log("-- GLOBAL (nil): " .. tostring(k)) end
  return nil
end})

for _, k in ipairs({"type","tostring","tonumber","pairs","ipairs","next","select","unpack","pcall","xpcall","error",
                    "assert","setmetatable","getmetatable","rawget","rawset","rawequal","newproxy"}) do env[k] = R[k] end
env.string, env.table, env.math = string, table, math
env.bit32, env.bit = BIT32, BIT32
env.print = function(...) local t = {} for i = 1, select("#", ...) do t[#t+1] = repr((select(i, ...))) end log("print(" .. table.concat(t, ", ") .. ")") end
env.warn = function(...) local t = {} for i = 1, select("#", ...) do t[#t+1] = repr((select(i, ...))) end log("warn(" .. table.concat(t, ", ") .. ")") end
env._G = env
env.getfenv = function() return env end
env.setfenv = function(f) return f end
env.collectgarbage = function() return 0 end
env.coroutine = coroutine
env.os = {time = function() return 1700000000 end, clock = function() return 12.5 end, date = function() return "2025-01-01 00:00:00" end}
env.tick = function() return 1700000000.5 end
env.time = function() return 12.5 end
env.elapsedTime = env.time
env.typeof = function(v) if paths[v] then return classO[v] or "Instance" end return type(v) end

local function sandbox_load(code, name)
  if type(code) ~= "string" then return nil, "loadstring: string expected" end
  log("-- loadstring(" .. #code .. " bytes): " .. repr(code:sub(1, 400)))
  CONFIG.loaded = CONFIG.loaded or {}
  CONFIG.loaded[#CONFIG.loaded + 1] = code
  local f, e = R.loadstring(code, name or "=loaded")
  if not f then log("-- loadstring compile error: " .. tostring(e)); return nil, e end
  setfenv(f, env)
  return f
end
env.loadstring = sandbox_load
env.load = nil

-- task / wait
local function budget() waits = waits + 1; if waits > (CONFIG.max_waits or 300) then error("WAIT BUDGET EXHAUSTED", 0) end end
local function runnow(f, ...)
  local ok, e = safe_call(f, ...)
  if not ok then log("-- (spawned fn error) " .. tostring(e)) end
end
env.wait = function(n) budget(); log("wait(" .. repr(n) .. ")"); return n or 0.03, 1 end
env.task = {
  wait = function(n) budget(); log("task.wait(" .. repr(n) .. ")"); return n or 0.03 end,
  spawn = function(f, ...) if type(f) == "function" then log("-- task.spawn(" .. fname(f) .. ")"); indent = indent + 1; runnow(f, ...); indent = indent - 1 end return newp("thread", nil, nil, "thread") end,
  defer = function(f, ...) if type(f) == "function" then deferred[#deferred + 1] = {f, {...}, "task.defer"} end end,
  delay = function(t, f, ...) if type(f) == "function" then deferred[#deferred + 1] = {f, {...}, "task.delay(" .. tostring(t) .. ")"} end end,
  cancel = function() end,
}
env.spawn = function(f, ...) if type(f) == "function" then log("-- spawn(" .. fname(f) .. ")"); indent = indent + 1; runnow(f, ...); indent = indent - 1 end end
env.delay = function(t, f, ...) if type(f) == "function" then deferred[#deferred + 1] = {f, {...}, "delay(" .. tostring(t) .. ")"} end end

-- Roblox globals
local game = newp("game", nil, nil, "DataModel")
env.game = game
env.Game = game
env.workspace = newp("workspace", nil, nil, "Workspace")
env.script = newp("script", nil, nil, "LocalScript")
env.shared = setmetatable({}, {__newindex = function(t, k, v) rawset(t, k, v); log("shared." .. tostring(k) .. " = " .. repr(v)) end})
for _, g in ipairs({"Enum", "Instance", "Vector2", "Vector3", "UDim", "UDim2", "Color3", "ColorSequence", "ColorSequenceKeypoint",
                    "NumberSequence", "NumberSequenceKeypoint", "NumberRange", "TweenInfo", "Font", "Rect", "CFrame", "Region3",
                    "Random", "Ray", "BrickColor", "DateTime", "RaycastParams", "OverlapParams", "Axes", "Faces", "PhysicalProperties"}) do
  env[g] = newp(g, nil, nil, g == "Enum" and "Enum" or nil)
end

-- executor API
local genv = setmetatable({}, {
  __index = function(_, k) log("-- getgenv()." .. tostring(k) .. " read -> nil"); return nil end,
  __newindex = function(t, k, v) rawset(t, k, v); log("getgenv()." .. tostring(k) .. " = " .. repr(v)) end})
env.getgenv = function() return genv end
env.identifyexecutor = function() return "Synapse Z", "1.0" end
if CONFIG.with_protect_only then
  rawset(genv, "protectgui", function(g) log("protectgui(" .. repr(g) .. ")") end)
end
if CONFIG.with_gethui then
  rawset(genv, "gethui", function() log("-- gethui() called"); return service("CoreGui") end)
  rawset(genv, "protectgui", function(g) log("protectgui(" .. repr(g) .. ")") end)
end
env.getexecutorname = nil
env.cloneref = function(x) return x end
env.clonefunction = function(f) return f end
env.checkcaller = function() return true end
env.newcclosure = function(f) return f end
env.setclipboard = function(s) clipboard = s; log("setclipboard(" .. repr(s) .. ")") end
env.toclipboard = env.setclipboard
env.queue_on_teleport = function(s) log("queue_on_teleport(" .. repr(s) .. ")") end
env.gethui = function() return service("CoreGui") end

local function request(opts)
  log("-- request(" .. repr(opts) .. ")")
  local url = type(opts) == "table" and opts.Url or opts
  local body = http_mock(url, "REQUEST " .. (type(opts) == "table" and tostring(opts.Method) or "GET"))
  return {Success = true, StatusCode = CONFIG.http_status or 200, StatusMessage = "OK", Body = body, Headers = {}}
end
local function tagged(tag) return function(opts) log("-- (request via " .. tag .. ")"); return request(opts) end end
if not CONFIG.no_request then env.request = tagged("request") end
if not CONFIG.no_http_request then env.http_request = tagged("http_request") end
if not CONFIG.no_syn then env.syn = {request = tagged("syn.request"), protect_gui = function() end} end
if not CONFIG.no_http then env.http = {request = tagged("http.request")} end

env.writefile = function(p, c) FS[p] = c; log("writefile(" .. repr(p) .. ", " .. repr(c) .. ")") end
env.readfile = function(p) log("readfile(" .. repr(p) .. ")"); if FS[p] == nil then error("file not found: " .. tostring(p), 0) end return FS[p] end
env.isfile = function(p) local r = FS[p] ~= nil; log("isfile(" .. repr(p) .. ") --> " .. tostring(r)); return r end
env.makefolder = function(p) FS[p .. "/"] = true; log("makefolder(" .. repr(p) .. ")") end
env.isfolder = function(p) local r = FS[p .. "/"] ~= nil; log("isfolder(" .. repr(p) .. ") --> " .. tostring(r)); return r end
env.delfile = function(p) FS[p] = nil; log("delfile(" .. repr(p) .. ")") end
env.listfiles = function() return {} end
if CONFIG.files then for k, v in pairs(CONFIG.files) do FS[k] = v end end

---------------------------------------------------------------- driver
local function drain_deferred(maxrounds)
  local rounds = 0
  while #deferred > 0 and rounds < (maxrounds or 50) do
    rounds = rounds + 1
    local d = table.remove(deferred, 1)
    log("-- >>> running " .. d[3] .. " " .. fname(d[1]))
    indent = indent + 1; waits = 0
    runnow(d[1], unpack(d[2]))
    indent = indent - 1
  end
end

local function run_callbacks(maxn)
  local ran = 0
  local i = 1
  while i <= #callbacks and ran < (maxn or 80) do
    local c = callbacks[i]
    if not c.done and CONFIG.skip_desc and tostring(c.desc):find(CONFIG.skip_desc, 1, true) then c.done = true end
    if not c.done then
      c.done = true; ran = ran + 1
      log("-- >>> invoking callback " .. fname(c.fn) .. " registered on " .. tostring(c.desc))
      indent = indent + 1; waits = 0
      local arg
      local d = tostring(c.desc)
      local function mkinput(kind, state)
        local inp = newp("input", nil, nil, "InputObject")
        props[inp] = {UserInputType = env.Enum.UserInputType[kind], UserInputState = env.Enum.UserInputState[state],
                      Position = newp("input.Position", inp, "Position", "Vector3")}
        return inp
      end
      if d:find("InputBegan", 1, true) then arg = mkinput(CONFIG.begin_kind or "MouseButton1", "Begin")
      elseif d:find("InputChanged", 1, true) then arg = mkinput(CONFIG.change_kind or "MouseMovement", "Change")
      elseif d:find("InputEnded", 1, true) then arg = mkinput(CONFIG.end_kind or "MouseButton1", "End")
      elseif d:find("Heartbeat", 1, true) or d:find("RenderStepped", 1, true) or d:find("Stepped", 1, true) then arg = 0.016
      elseif tostring(c.desc):find("FocusLost", 1, true) then arg = true
      elseif c.tbl then arg = CONFIG.test_key or "TESTKEY-AAAA-BBBB-CCCC"
      else arg = newp("arg", nil, nil, nil) end
      runnow(c.fn, arg, false)
      drain_deferred(20)
      indent = indent - 1
    end
    i = i + 1
  end
end

function RUN(code, instr_budget)
  local f, e = R.loadstring(code, "=target")
  if not f then return false, "compile error: " .. tostring(e), "" end
  setfenv(f, env)
  local count = 0
  sethook(function() count = count + 1; if count > 1 then error("INSTRUCTION BUDGET EXCEEDED", 0) end end, "", instr_budget or 200000000)
  local rets = {safe_call(f)}
  local ok = table.remove(rets, 1)
  local err
  if not ok then err = rets[1]; log("!!! main chunk error: " .. tostring(err)) end
  RESULTS = rets
  if ok then
    log("-- main chunk returned " .. #rets .. " value(s)")
    for i, v in ipairs(rets) do
      log("-- ret[" .. i .. "] (" .. type(v) .. ") = " .. repr(v))
      if type(v) == "table" then
        local keys = {}
        for k, x in pairs(v) do keys[#keys + 1] = tostring(k) .. ":" .. type(x) end
        table.sort(keys)
        log("--   keys: " .. table.concat(keys, ", "))
      end
    end
  end
  LIB = rets[1]
  sethook()
  return ok, err, nil
end

function STEP(label, fn, instr_budget)
  log("-- ======== " .. label)
  local count = 0
  waits = 0
  sethook(function() count = count + 1; if count > 1 then error("INSTRUCTION BUDGET EXCEEDED", 0) end end, "", instr_budget or 100000000)
  local ok, e = pcall(fn)
  sethook()
  if not ok then log("!!! " .. label .. " error: " .. tostring(e)) end
  return ok, e
end

function CALLBACKS(n)
  return STEP("callbacks", function()
    drain_deferred()
    for _, tb in ipairs(TEXTBOXES) do props[tb].Text = CONFIG.test_key or "TESTKEY-AAAA-BBBB-CCCC"; log("-- (user types into " .. paths[tb] .. ": " .. repr(props[tb].Text) .. ")") end
    run_callbacks(n); drain_deferred()
    if CONFIG.rerun_desc or CONFIG.rerun_nth_click then
      local clicks = 0
      for _, c in ipairs(callbacks) do
        local isclick = tostring(c.desc):find("MouseButton1Click", 1, true) ~= nil
        if isclick then clicks = clicks + 1 end
        if (CONFIG.rerun_desc and tostring(c.desc) == CONFIG.rerun_desc) or (CONFIG.rerun_nth_click and isclick and clicks == CONFIG.rerun_nth_click) then
          log("-- >>> RE-invoking callback " .. fname(c.fn) .. " registered on " .. tostring(c.desc))
          indent = indent + 1; waits = 0
          runnow(c.fn, newp("arg", nil, nil, nil), false)
          drain_deferred(20)
          indent = indent - 1
        end
      end
    end
  end)
end
function GETLOG() return table.concat(LOG, "\n") end
function GETLOADED() return CONFIG.loaded or {} end
function ENV() return env end
function MKPROXY(name) return newp(name, nil, nil, nil) end
function REPR(v) return repr(v) end
function CLASSOF(v) return classO[v] end

function GETLEGEND() local t = {} for n, s in pairs(NUMLEGEND) do t[#t + 1] = tostring(n) .. "\t" .. s end table.sort(t) return table.concat(t, "\n") end
