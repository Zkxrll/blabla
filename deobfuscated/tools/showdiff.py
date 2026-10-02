import sys, difflib, re
sys.argv_backup = sys.argv
name = sys.argv[1]
exec(open('difftest.py').read().split('def main():')[0])
safe = re.sub(r'[^A-Za-z0-9]+', '_', name)
oa, ob = 'dt_orig_%s.log' % safe, 'dt_recon_%s.log' % safe
ea = [x for x in effects(normalise(oa)) if not x.startswith('-- >>>')]
eb = [x for x in effects(normalise(ob)) if not x.startswith('-- >>>')]
print('--- effects diff')
for l in difflib.unified_diff(ea, eb, 'orig', 'recon', lineterm='', n=0): print(l[:260])
sa = open(oa + '.snap', encoding='latin-1').read().split('\n'); sb = open(ob + '.snap', encoding='latin-1').read().split('\n')
print('--- snapshot diff (%d vs %d instances)' % (len(sa), len(sb)))
for l in list(difflib.unified_diff(sa, sb, 'orig', 'recon', lineterm='', n=0))[:24]: print(l[:300])
