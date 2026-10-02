import re
t = open('template.lua', encoding='latin-1').read()
ui = open('ui_generated.lua', encoding='latin-1').read().rstrip() + '\n'
names = [l.split('\t')[1] for l in open('ui_names.txt').read().strip().split('\n')]
lst = ',\n'.join('\t\t' + n for n in names) + ','
t = t.replace('--[[UI_BUILDER]]', ui)
open('KeySystem.deobfuscated.lua', 'wb').write(t.encode('latin-1'))
print('written, lines:', t.count('\n'))
