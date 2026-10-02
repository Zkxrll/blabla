import sys, resource, json
from lupa.lua51 import LuaRuntime

resource.setrlimit(resource.RLIMIT_AS, (3 * 1024**3, 3 * 1024**3))

src_path = sys.argv[1] if len(sys.argv) > 1 else 'KeySystem.lua'
out_path = sys.argv[2] if len(sys.argv) > 2 else 'trace.log'
extra = sys.argv[3] if len(sys.argv) > 3 else ''

code = open(src_path, 'rb').read()
lua = LuaRuntime(encoding=None, register_eval=False, register_builtins=False, unpack_returned_tuples=True)
lua.execute(b'CONFIG = {}\n' + extra.encode())
lua.execute(open('sandbox.lua', 'rb').read())
ok, err, _ = lua.eval(b'RUN')(code, 300000000)
print('main ok:', ok, '|', err)
lua.eval(b'CALLBACKS')(60)
log = lua.eval(b'GETLOG')()
open(out_path, 'wb').write(log)
open(out_path + '.snap', 'wb').write(lua.eval(b'SNAPSHOT')())
open(out_path + '.legend', 'wb').write(lua.eval(b'GETLEGEND')())
print('log bytes:', len(log), 'lines:', log.count(b'\n') + 1)
