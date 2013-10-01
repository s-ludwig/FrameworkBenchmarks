import subprocess
import sys
import os
import setup_util

def start(args):
  setup_util.replace_text("vibe.d/source/app.d", "@.*:3306/", "@" + args.database_host + ":3306/")
  subprocess.call("set DUBPATH=vibe.d && dub upgrade", shell=True, cwd="vibe.d") 
  subprocess.Popen("dub", cwd="vibe.d")
  return 0
def stop():
  if os.name == 'nt':
    subprocess.call("taskkill /f /im dub.exe > NUL", shell=True)
    subprocess.call("taskkill /f /im techempower-vibed.exe > NUL", shell=True)
    return 0
  p = subprocess.Popen(['ps', 'aux'], stdout=subprocess.PIPE)
  out, err = p.communicate()
  for line in out.splitlines():
    if 'techempower-vibed' in line:
      pid = int(line.split(None, 2)[1])
      os.kill(pid, 9)
  return 0
