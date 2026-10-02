#!/usr/bin/env python3
import re, subprocess, sys, json, itertools
from concurrent.futures import ThreadPoolExecutor

BASE = ('CONFIG.lib_patterns = {["Overlay-Library"]="Library", ["luarmor.net/library.lua"]="Luarmor"} '
        'CONFIG.plain_numbers=true CONFIG.place_id=6035872082 ')

def enc(k): return "[" + ",".join(str((ord(c) + 137 + i) % 256) for i, c in enumerate(k, 1)) + "]"
def files(content): return "CONFIG.files={['Perseus/Key.json']='%s',['Perseus/']=true} " % content

SCEN = {}
for code in ["KEY_VALID", "KEY_INCORRECT", "KEY_INVALID", "KEY_HWID_LOCKED", "KEY_EXPIRED", "KEY_BANNED", "WEIRD"]:
    SCEN["manual/" + code] = "CONFIG.luarmor_code='%s' " % code
    SCEN["saved/" + code] = "CONFIG.luarmor_code='%s' " % code + files(enc("SAVEDKEY12345678"))
SCEN["saved/none-sentinel"] = "CONFIG.luarmor_code='KEY_VALID' " + files(enc("none"))
SCEN["saved/NONE-upper"] = "CONFIG.luarmor_code='KEY_VALID' " + files(enc("NONE"))
SCEN["saved/empty-array"] = "CONFIG.luarmor_code='KEY_VALID' " + files("[]")
SCEN["saved/corrupt"] = "CONFIG.luarmor_code='KEY_VALID' " + files("not json")
SCEN["saved/high-bytes"] = "CONFIG.luarmor_code='KEY_VALID' " + files(enc("zzzz~~~~\x7f"))
SCEN["folder-exists-no-file"] = "CONFIG.luarmor_code='KEY_VALID' CONFIG.files={['Perseus/']=true} "
SCEN["unsupported-game"] = "CONFIG.luarmor_code='KEY_VALID' CONFIG.place_id=1 "
SCEN["game2"] = "CONFIG.luarmor_code='KEY_VALID' CONFIG.place_id=7633926880 "
SCEN["gameid-only"] = "CONFIG.luarmor_code='KEY_VALID' CONFIG.place_id=1111 CONFIG.game_id=6035872082 "
SCEN["placeid-only(unsupported)"] = "CONFIG.luarmor_code='KEY_VALID' CONFIG.place_id=6035872082 CONFIG.game_id=1111 "
SCEN["studio"] = "CONFIG.luarmor_code='KEY_VALID' CONFIG.studio=true "
SCEN["gethui"] = "CONFIG.luarmor_code='KEY_VALID' CONFIG.with_gethui=true "
SCEN["protect-only"] = "CONFIG.luarmor_code='KEY_VALID' CONFIG.with_protect_only=true "
SCEN["key-empty"] = "CONFIG.luarmor_code='KEY_VALID' CONFIG.test_key='' "
SCEN["key-whitespace"] = "CONFIG.luarmor_code='KEY_VALID' CONFIG.test_key='   ' "
SCEN["key-padded"] = "CONFIG.luarmor_code='KEY_VALID' CONFIG.test_key='  ABC DEF  ' "
SCEN["key-highbytes"] = "CONFIG.luarmor_code='KEY_VALID' CONFIG.test_key='zzzzzzzzzzzzzzzzzzzzzzzz' "
SCEN["toggle-minimize"] = "CONFIG.luarmor_code='KEY_VALID' CONFIG.rerun_nth_click=2 "
SCEN["drag-touch"] = "CONFIG.luarmor_code='KEY_VALID' CONFIG.begin_kind='Touch' CONFIG.change_kind='Touch' CONFIG.end_kind='Touch' "
SCEN["drag-rmb"] = "CONFIG.luarmor_code='KEY_VALID' CONFIG.begin_kind='MouseButton2' CONFIG.end_kind='MouseButton2' "
SCEN["drag-no-begin"] = "CONFIG.luarmor_code='KEY_VALID' CONFIG.skip_desc='InputBegan' "
SCEN["req-no-syn"] = "CONFIG.luarmor_code='KEY_VALID' CONFIG.no_syn=true "
SCEN["req-http-only"] = "CONFIG.luarmor_code='KEY_VALID' CONFIG.no_syn=true CONFIG.no_request=true CONFIG.no_http_request=true "
SCEN["req-request-only"] = "CONFIG.luarmor_code='KEY_VALID' CONFIG.no_syn=true CONFIG.no_http=true CONFIG.no_http_request=true "
SCEN["req-http_request-only"] = "CONFIG.luarmor_code='KEY_VALID' CONFIG.no_syn=true CONFIG.no_http=true CONFIG.no_request=true "
SCEN["req-none"] = "CONFIG.luarmor_code='KEY_VALID' CONFIG.no_syn=true CONFIG.no_http=true CONFIG.no_request=true CONFIG.no_http_request=true "

def run(script, name, cfg):
    safe = re.sub(r'[^A-Za-z0-9]+', '_', name)
    out = 'dt_%s_%s.log' % (script.split('.')[0].replace('KeySystem', 'orig' if script == 'KeySystem.lua' else 'recon'), safe)
    r = subprocess.run(['timeout', '170', 'python3', 'run_trace.py', script, out, BASE + cfg], capture_output=True, text=True)
    return out, r.stdout.strip().splitlines()[0] if r.stdout.strip() else r.stderr.strip()[-200:]

# ------------------------------------------------------------------ normalisation
DEF = re.compile(r'^\s*local (\w+) = (.*)$')
TOK = re.compile(r'\b(?:[A-Za-z0-9]+_\d+)\b')
def normalise(path):
    lines = open(path, encoding='latin-1').read().split('\n')
    env = {}; inst_n = 0; out = []
    def subst(s):
        for _ in range(8):
            n = TOK.sub(lambda m: env.get(m.group(0), m.group(0)), s)
            if n == s: break
            s = n
        return s
    for ln in lines:
        if 'GLOBAL (nil)' in ln or ln.strip().startswith('-- loadstring('):
            continue
        m = DEF.match(ln)
        if m:
            var, expr = m.group(1), subst(m.group(2))
            mi = re.match(r'Instance\.new\("(\w+)"\)$', expr)
            if mi:
                inst_n += 1; env[var] = '#%d' % inst_n
                out.append('Instance.new(%s)->#%d' % (mi.group(1), inst_n)); continue
            if var in ('TweenService', 'Players', 'RunService', 'HttpService', 'UserInputService', 'CoreGui') and expr.startswith('game:GetService'):
                continue
            env[var] = '(%s)' % expr
            out.append('%s' % expr)
            continue
        out.append(subst(ln.strip()))
    return out

EFFECT = re.compile(r'HTTP|writefile\(|readfile\(|isfile\(|isfolder\(|makefolder\(|setclipboard\(|luarmor_api|getgenv\(\)|shared\.|KICK|Kick|Notify|Library:|JSON|wait\(|request via|mocking remote|invoking callback|IsStudio|gethui|protectgui|PlayerGui')
def effects(lines):
    res = []
    for ln in lines:
        if not EFFECT.search(ln): continue
        if ln.startswith('-- >>> invoking callback') or ln.startswith('-- >>> RE-invoking'):
            ln = re.sub(r'fn_\d+', 'fn', ln)
            ln = re.sub(r'registered on [A-Za-z]+_\d+', lambda m: 'registered on ' + m.group(0).split(' ')[-1], ln)
        if 'Notify(' in ln:
            c = re.search(r'Content = "([^"]*)"', ln); t = re.search(r'Title = "([^"]*)"', ln)
            ln = 'Notify(title=%s, content=%s)' % (t and t.group(1), c and c.group(1))
        ln = re.sub(r'fn_\d+', 'fn', ln)
        ln = re.sub(r'\(\(.*?\)\)', '(..)', ln) if False else ln
        res.append(ln)
    return res

def main():
    names = sys.argv[1:] or list(SCEN)
    jobs = []
    with ThreadPoolExecutor(max_workers=6) as ex:
        for n in names:
            jobs.append((n, ex.submit(run, 'KeySystem.lua', n, SCEN[n]), ex.submit(run, 'KeySystem.deobfuscated.lua', n, SCEN[n])))
        results = [(n, a.result(), b.result()) for n, a, b in jobs]
    bad = 0
    for n, (oa, sa), (ob, sb) in results:
        status = []
        if 'main ok: True' not in sa: status.append('ORIG-RUN: ' + sa[:90])
        if 'main ok: True' not in sb: status.append('RECON-RUN: ' + sb[:120])
        ea, eb = effects(normalise(oa)), effects(normalise(ob))
        # callback bookkeeping lines are order dependent; compare effects without them first
        ea2 = [x for x in ea if not x.startswith('-- >>>')]; eb2 = [x for x in eb if not x.startswith('-- >>>')]
        snap_a = open(oa + '.snap', encoding='latin-1').read(); snap_b = open(ob + '.snap', encoding='latin-1').read()
        if ea2 != eb2: status.append('EFFECTS DIFFER (%d vs %d lines)' % (len(ea2), len(eb2)))
        if snap_a != snap_b: status.append('SNAPSHOT DIFFERS')
        print(('OK   ' if not status else 'FAIL ') + n + ('' if not status else '  :: ' + ' | '.join(status)))
        bad += bool(status)
    print('\n%d/%d scenarios identical' % (len(results) - bad, len(results)))
main()
