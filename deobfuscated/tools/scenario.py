import sys, subprocess
# usage: scenario.py out.log "<lua config>"
out, cfg = sys.argv[1], sys.argv[2]
r = subprocess.run(['timeout', '170', 'python3', 'run_trace.py', 'KeySystem.lua', out, cfg], capture_output=True, text=True)
print(r.stdout.strip()[-400:], r.stderr.strip()[-600:])
