import json, os, subprocess, sys, time, urllib.request, shutil, zipfile
HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.dirname(HERE)          # the pyforge/ folder
sys.path.insert(0, HERE)
from lessons import L

# 1) run each solution through the real server to capture expected output
port = 8799
srv = subprocess.Popen([sys.executable, os.path.join(KIT, "server.py"), "--port", str(port), "--no-browser"],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
op = urllib.request.build_opener(urllib.request.ProxyHandler({}))
for _ in range(50):
    try:
        op.open(f"http://127.0.0.1:{port}/api/health", timeout=0.3); break
    except Exception:
        time.sleep(0.1)
try:
    for l in L:
        req = urllib.request.Request(f"http://127.0.0.1:{port}/api/run", method="POST",
                                     data=json.dumps({"code": l["solution"], "stdin": l["stdin"]}).encode(),
                                     headers={"Content-Type": "application/json"})
        r = json.loads(op.open(req).read())
        assert not r["stderr"], (l["id"], r["stderr"])
        if "expected" not in l:
            l["expected"] = r["stdout"].rstrip("\n")
finally:
    srv.terminate()

keys = ["id", "level", "mins", "title", "body", "example", "example_stdin", "task", "starter", "hint", "solution", "expected", "stdin", "check", "api"]
lessons_js = json.dumps([{k: l[k] for k in keys if k in l} for l in L], ensure_ascii=False).replace("</", "<\\/")

read = lambda f: open(os.path.join(HERE, f), encoding="utf-8").read()
css, markup, scene, app = read("styles.css"), read("markup.html"), read("scene.js"), read("app.js")
app = app.replace("/*LESSONS_JSON*/[]", lessons_js)

FONTS = '<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>\n<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500..800&family=Instrument+Sans:wght@400..700&family=JetBrains+Mono:wght@400..700&display=swap">'
CM = "https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/"
LIBS = "\n".join(f'<script src="{u}"></script>' for u in [
    "https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js",
    CM + "codemirror.min.js", CM + "mode/python/python.min.js",
    CM + "addon/edit/matchbrackets.min.js", CM + "addon/edit/closebrackets.min.js", CM + "addon/selection/active-line.min.js",
])
title = "<title>PyForge</title>"
body = f"{markup}\n{LIBS}\n<script>\n{scene}\n{app}\n</script>\n"

artifact = f"{title}\n{FONTS}\n<style>\n{css}\n</style>\n{body}"
os.makedirs(os.path.join(HERE, "dist"), exist_ok=True)
open(os.path.join(HERE, "dist", "pyforge.html"), "w", encoding="utf-8").write(artifact)

full = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="description" content="PyForge: learn Python from beginner to pro with runnable lessons and an API lab.">
{title}
<link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Cpath d='M47.5 9.4a6 6 0 0 1 5.2 3l9.6 16.6a6 6 0 0 1 0 6l-9.6 16.6a6 6 0 0 1-5.2 3H16.5a6 6 0 0 1-5.2-3L1.7 35a6 6 0 0 1 0-6l9.6-16.6a6 6 0 0 1 5.2-3z' fill='%23F0A142'/%3E%3Cpath d='M18.5 23.5 28 32l-9.5 8.5' fill='none' stroke='%23221507' stroke-width='5' stroke-linecap='round' stroke-linejoin='round'/%3E%3Cpath d='M31 43h9.5c6 0 8.4-7.6 3.2-10.4' fill='none' stroke='%23221507' stroke-width='4.6' stroke-linecap='round'/%3E%3C/svg%3E">
{FONTS}
<style>
:root{{padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px)}}
body{{margin:0}} img{{max-width:100%}} [hidden]{{display:none!important}}
{css}
</style>
</head>
<body>
{body}</body>
</html>
"""
open(os.path.join(KIT, "index.html"), "w", encoding="utf-8").write(full)
print("artifact", len(artifact) // 1024, "KB; kit index", len(full) // 1024, "KB; lessons", len(L))
