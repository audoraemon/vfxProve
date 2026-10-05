"""Run several tools/dev/pixellab_api.py jobs, at most MAX at once, re-queueing any PixelLab refused for too many
concurrent jobs (429). Each job's output is printed when it ends.

Usage (from the project root): python tools/dev/pixellab_batch.py <jobs.json> [--max N]
jobs.json is a list of argument lists for pixellab_api.py, e.g.
  [["edit", "--image", "a.png", "--desc", "...", "--out", "out/a"],
   ["char-anim", "--id", "<character id>", "--template", "walking-4-frames", "--out", "out/b"]]
"""
import json
import subprocess
import sys
import time

MAX = int(sys.argv[sys.argv.index("--max") + 1]) if "--max" in sys.argv else 4


def main():
    jobs = [list(j) for j in json.load(open(sys.argv[1], encoding="utf-8"))]
    queue = list(enumerate(jobs))
    running = {}
    results = {}
    while queue or running:
        while queue and len(running) < MAX:
            i, args = queue.pop(0)
            running[i] = (args, subprocess.Popen([sys.executable, "-u", "tools/dev/pixellab_api.py"] + args,
                                                 stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True))
        time.sleep(3)
        for i in list(running):
            args, p = running[i]
            if p.poll() is None:
                continue
            out = p.stdout.read()
            del running[i]
            if p.returncode != 0 and "(429)" in out:
                print("job %d refused (429), queued again" % i, flush=True)
                time.sleep(10)
                queue.append((i, args))
                continue
            results[i] = (p.returncode, out)
            label = args[args.index("--out") + 1].replace("\\", "/").split("/")[-1] if "--out" in args else args[0]
            print("=== job %d (%s) exit %d\n%s" % (i, label, p.returncode, out.strip()), flush=True)
    ok = sum(1 for r in results.values() if r[0] == 0)
    print("all done: %d ok, %d failed" % (ok, len(results) - ok))


if __name__ == "__main__":
    main()
