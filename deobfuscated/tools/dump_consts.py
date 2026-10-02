import re, json
from lupa.lua51 import LuaRuntime

src = open('KeySystem.lua', encoding='latin-1').read()
marker = 'return(function(y,m,w,K,o,M,q,I,V,h'
j = src.find(marker)
assert j > 0 and src.count(marker) == 1
# stop right after the string table has been decoded, before the VM interpreter starts
patched = src[:j] + '__DUMP(M) error("__STOP__") ' + src[j:]

lua = LuaRuntime(unpack_returned_tuples=True, register_eval=False, register_builtins=False, encoding=None)
out = []
lua.execute(b'''
function make_env(dump)
  local env = {}
  for _, k in ipairs{"string","table","math","type","select","unpack","setmetatable","getmetatable",
                     "tostring","tonumber","pairs","ipairs","next","error","pcall","rawget","rawset","newproxy"} do
    env[k] = _G[k]
  end
  env.__DUMP = dump
  env.getfenv = function() return env end
  env._G = env
  return env
end
function run(code, dump)
  local f, e = loadstring(code, "=KeySystem")
  if not f then return false, e end
  local env = make_env(dump)
  setfenv(f, env)
  return pcall(f)
end
''')
res = []
def dump(t):
    # t is a lua table: array of strings (decoded)
    for i in range(1, len(t) + 1):
        v = t[i]
        res.append(v)
ok, err = lua.eval('run')(patched.encode('latin-1'), dump)
print('run ok:', ok, '|', str(err)[:200])
print('entries:', len(res))
def to_bytes(v):
    if isinstance(v, bytes): return v
    if isinstance(v, str): return v.encode('latin-1', 'replace')
    return repr(v).encode()
rows = []
for i, v in enumerate(res, 1):
    b = to_bytes(v)
    rows.append((i, b))
json.dump([(i, b.decode('latin-1')) for i, b in rows], open('consts.json', 'w'))
printable = [(i, b) for i, b in rows if b and all(32 <= c < 127 or c in (9, 10, 13) for c in b)]
print('printable:', len(printable))
for i, b in printable:
    print(i, repr(b.decode()))
