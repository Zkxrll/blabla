import re, sys
log = open(sys.argv[1], encoding='latin-1').read()
legend = {}
for ln in open(sys.argv[1] + '.legend', encoding='latin-1').read().split('\n'):
    if '\t' in ln:
        n, s = ln.split('\t', 1); legend[n] = s
def sub(m):
    return legend.get(m.group(0), m.group(0))
# only annotate numbers that look like placeholders (>= 1111) and are in the legend
out = re.sub(r'(?<![\w.])\d{4,7}(?![\w.])', sub, log)
sys.stdout.write(out)
