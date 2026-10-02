#!/usr/bin/env python3
"""Turn the UI-construction part of a sandbox trace into clean, readable Lua.

- instance variables are named after the Instance's first non-empty Name
- single-use constructor temporaries (UDim2.new(...), Color3.fromRGB(...), ...) are inlined
- the VM's "Name = real name; Name = ''" pair is collapsed to the original name in a comment
"""
import re, sys, collections

LOG = sys.argv[1] if len(sys.argv) > 1 else 'main_phase.log'
KEEP_TEMPS = {}           # temp var -> readable name (temps that later code reuses)
if len(sys.argv) > 2:
    for pair in sys.argv[2].split(','):
        k, v = pair.split('=')
        KEEP_TEMPS[k] = v

lines = [l for l in open(LOG, encoding='latin-1').read().split('\n')]

# ---- locate the UI region ---------------------------------------------------------------
start = next(i for i, l in enumerate(lines) if re.match(r'^local \w+ = Instance\.new\("ScreenGui"\)', l))
# include the constructor temporaries directly above the first instance (none for ScreenGui)
end = next(i for i, l in enumerate(lines) if '.InputBegan:Connect(' in l)
region = lines[start:end]

temps = {}      # v_N -> expr
insts = {}      # var -> dict(class, props[list of (k, expr)], parent, order)
order = []
for ln in region:
    if ln.startswith('--') or not ln.strip():
        continue
    m = re.match(r'^local (v_\d+) = (.+)$', ln)
    if m:
        temps[m.group(1)] = m.group(2)
        continue
    m = re.match(r'^local (\w+) = Instance\.new\("(\w+)"\)$', ln)
    if m:
        insts[m.group(1)] = {'class': m.group(2), 'props': [], 'parent': None}
        order.append(m.group(1))
        continue
    m = re.match(r'^(\w+)\.(\w+) = (.+)$', ln)
    if m and m.group(1) in insts:
        insts[m.group(1)]['props'].append((m.group(2), m.group(3)))
        continue
    print('-- unparsed:', ln, file=sys.stderr)

# ---- naming -----------------------------------------------------------------------------
LUA_RESERVED = {'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for', 'function', 'if', 'in', 'local',
                'nil', 'not', 'or', 'repeat', 'return', 'then', 'true', 'until', 'while'}
RESERVED_NAMES = {'Players', 'TweenService', 'RunService', 'HttpService', 'UserInputService', 'CoreGui', 'Library'}
def ident_of(base, cls):
    ident = re.sub(r'[^A-Za-z0-9_]', '', base) or cls
    if ident[0].isdigit():
        ident = 'N' + ident
    if ident in LUA_RESERVED or ident in RESERVED_NAMES:
        ident += 'Obj'
    return ident

bases = {}
orig_name = {}
for v in order:
    nm = [x for k, x in insts[v]['props'] if k == 'Name' and x != '""']
    base = nm[0].strip('"') if nm else insts[v]['class']
    orig_name[v] = base
    bases[v] = base
count = collections.Counter(bases.values())
parent_of = {}
for v in order:
    pe = [e for k, e in insts[v]['props'] if k == 'Parent']
    parent_of[v] = pe[-1] if pe else None

OVERRIDE = {
    'ScreenGui_4': 'KeySystem', 'Frame_9': 'Window', 'Folder_12': 'IgnoreLayout',
    'Frame_65': 'LeftContent', 'Frame_124': 'RightContent', 'Frame_95': 'KeyBox', 'TextBox_104': 'KeyInput',
    'TextButton_37': 'CloseButton', 'TextButton_45': 'MinimizeButton',
    'TextButton_130': 'CheckKeyButton', 'TextLabel_136': 'CheckKeyLabel',
    'TextButton_141': 'GetKeyButton', 'TextLabel_147': 'GetKeyLabel',
    'TextButton_161': 'DiscordButton', 'Frame_213': 'DragBar', 'Frame_111': 'EyeButton',
    'Frame_127': 'ButtonRow', 'ScrollingFrame_176': 'ChangelogScroll', 'Frame_178': 'AnnouncementBox',
    'TextLabel_30': 'TitleLabel', 'TextLabel_33': 'SubtitleLabel',
}
taken = set()
names = {}
for v in order:
    if v in OVERRIDE:
        names[v] = OVERRIDE[v]; taken.add(OVERRIDE[v]); continue
    base, cls = bases[v], insts[v]['class']
    generic = (base == cls) or base.startswith('UI') or count[base] > 1
    cand = ident_of(base, cls)
    par = parent_of[v]
    if generic and par in names:
        cand = names[par] + cand
    n, final = 1, cand
    while final in taken:
        n += 1
        final = '%s%d' % (cand, n)
    taken.add(final)
    names[v] = final
# make first occurrence of a repeated name carry no suffix, later ones numbered (already so)

# ---- resolve temps (inline single use) --------------------------------------------------
def use_count(tmp):
    n = 0
    for v in order:
        for _, e in insts[v]['props']:
            n += len(re.findall(r'\b%s\b' % tmp, e))
    for t, e in temps.items():
        n += len(re.findall(r'\b%s\b' % tmp, e))
    return n

def resolve(expr):
    # replace v_N with its (already-resolved) constructor expression
    def sub(m):
        t = m.group(0)
        if t in KEEP_TEMPS:
            return KEEP_TEMPS[t]
        if t in temps:
            return resolve(temps[t])
        return t
    expr = re.sub(r'\bv_\d+\b', sub, expr)
    for v in names:
        expr = re.sub(r'\b%s\b' % re.escape(v), names[v], expr)
    return expr

def resolve_temp(t):
    expr = temps[t]
    def sub(m):
        x = m.group(0)
        return resolve(temps[x]) if x in temps and x not in KEEP_TEMPS else x
    return re.sub(r'\bv_\d+\b', sub, expr)

declared = set()
# ---- emit -------------------------------------------------------------------------------
out = []
for v in order:
    info = insts[v]
    nm = names[v]
    props = [(k, e) for k, e in info['props']]
    # collapse the VM's Name pair: keep only the final blank, note the real name
    final = []
    for k, e in props:
        if k == 'Name':
            continue
        final.append((k, e))
    for k, e in final:
        for t in re.findall(r'\bv_\d+\b', e):
            if t in KEEP_TEMPS and t not in declared:
                declared.add(t)
                out.append('local %s = %s' % (KEEP_TEMPS[t], resolve_temp(t)))
    out.append('local %s = New("%s")' % (nm, info['class']))
    for k, e in final:
        e2 = resolve(e)
        if k == 'Parent' and e2 == 'CoreGui':
            e2 = 'GuiParent'
        out.append('%s.%s = %s' % (nm, k, e2))
    out.append('%s.Name = ""  -- original name: %s' % (nm, orig_name[v]))
    out.append('')

kept = {k: resolve(temps[k]) for k in KEEP_TEMPS if k in temps}
sys.stdout.buffer.write('\n'.join(out).encode('latin-1'))

# side output for debugging/verification
with open('ui_names.txt', 'w') as f:
    for v in order:
        f.write('%s\t%s\t%s\t%s\n' % (v, names[v], insts[v]['class'], orig_name[v]))
with open('ui_kept.txt', 'w') as f:
    for k, e in kept.items():
        f.write('%s\t%s\n' % (k, e))
print('-- instances: %d  temps: %d' % (len(order), len(temps)), file=sys.stderr)
