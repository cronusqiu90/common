import os
import sys

path = sys.argv[1]
MB = 1 << 20
MAX_MB = 100 * MB

def walk(directory):
    for root, dirs, names in os.walk(directory):
        for name in names:
            dot = name.rfind(".")
            if dot < 0:
                continue
            ext = name[dot + 1:]
            if ext == "log" or str(ext).isnumeric():
                if str(name[0]).isnumeric(): continue
                fpath = os.path.join(root, name)
                #if "/venv/" in fpath: continue
                fsize = os.path.getsize(fpath)
                yield fsize, fpath

for fsize, fpath in walk(path):
    if "2021-" in fpath or "2022-" in fpath or "2023-" in fpath or "2024-0":
        print("deleting %s" % fpath)
        os.remove(fpath)
    if fsize == 0:
        print("deleting %s" % fpath)
        os.remove(fpath)
    elif fsize > MAX_MB:
        print("truncating %s" % fpath)
        os.popen("/usr/bin/truncate -s 0 %s" % fpath).read()
