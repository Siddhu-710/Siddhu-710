#!/usr/bin/env python3
"""
PyForge local server
====================

Serves the PyForge learning site on http://localhost:8000 and gives it a real
Python backend:

  * POST /api/run          runs learner code with *your* installed Python
  * /api/applications ...  the "Approval API" used in the API lessons

Only the Python standard library is used, so there is nothing to install.

    python3 server.py            # then open http://localhost:8000
    python3 server.py --port 9000 --no-browser

The server listens on 127.0.0.1 only, so nobody else on your network can reach it.
"""
import argparse
import json
import os
import subprocess
import sys
import tempfile
import threading
import time
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

HERE = os.path.dirname(os.path.abspath(__file__))
VERSION = "1.0.0"
RUN_TIMEOUT = 5          # seconds a learner program may run
MAX_CODE = 50_000        # characters
MAX_OUTPUT = 100_000     # characters returned to the page
PORT = 8000

DEMO_USER = {"email": "demo@pyforge.dev", "password": "Python@123", "name": "Demo Learner"}

# --------------------------------------------------------------------------
# Approval API data (identical to the in-browser mock inside index.html)
# --------------------------------------------------------------------------
RULES = {"min_age": 16, "min_score": 70, "min_attendance": 80}

APPLICATIONS = [
    {"id": 101, "name": "Aarav Sharma", "age": 19, "score": 88, "attendance": 92, "country": "Nepal"},
    {"id": 102, "name": "Mei Lin", "age": 22, "score": 67, "attendance": 95, "country": "Singapore"},
    {"id": 103, "name": "Lucas Silva", "age": 17, "score": 91, "attendance": 78, "country": "Brazil"},
    {"id": 104, "name": "Fatima Noor", "age": 24, "score": 74, "attendance": 85, "country": "Pakistan"},
    {"id": 105, "name": "Ethan Brooks", "age": 15, "score": 95, "attendance": 99, "country": "USA"},
    {"id": 106, "name": "Sofia Rossi", "age": 20, "score": 82, "attendance": 81, "country": "Italy"},
    {"id": 107, "name": "Kwame Mensah", "age": 28, "score": 70, "attendance": 80, "country": "Ghana"},
    {"id": 108, "name": "Anika Rai", "age": 18, "score": 59, "attendance": 88, "country": "Nepal"},
]
DECISIONS = {}           # id -> {"id", "decision", "reason"}
LOCK = threading.Lock()


def expected_decision(app):
    ok = (app["age"] >= RULES["min_age"] and app["score"] >= RULES["min_score"]
          and app["attendance"] >= RULES["min_attendance"])
    return "approved" if ok else "rejected"


def with_status(app):
    item = dict(app)
    item["status"] = DECISIONS.get(app["id"], {}).get("decision", "pending")
    return item


def api(method, path, query, body):
    """Route one API call. Returns (status_code, json_object)."""
    parts = [p for p in path.split("/") if p]          # e.g. ["applications", "101"]
    with LOCK:
        if parts == ["health"] and method == "GET":
            return 200, {"status": "ok", "mode": "localhost", "python": sys.version.split()[0], "version": VERSION}

        if parts == ["applications"] and method == "GET":
            items = [with_status(a) for a in APPLICATIONS]
            status = (query.get("status") or [None])[0]
            if status:
                items = [a for a in items if a["status"] == status]
            return 200, {"count": len(items), "items": items}

        if len(parts) == 2 and parts[0] == "applications" and method == "GET":
            try:
                app_id = int(parts[1])
            except ValueError:
                return 400, {"error": "id must be a number"}
            for a in APPLICATIONS:
                if a["id"] == app_id:
                    return 200, with_status(a)
            return 404, {"error": f"application {app_id} not found"}

        if parts == ["rules"] and method == "GET":
            return 200, dict(RULES)

        if parts == ["decisions"] and method == "GET":
            return 200, {"count": len(DECISIONS), "items": list(DECISIONS.values())}

        if parts == ["decisions"] and method == "POST":
            if not isinstance(body, dict):
                return 400, {"error": "send a JSON object like {\"id\": 101, \"decision\": \"approved\"}"}
            app_id, decision = body.get("id"), body.get("decision")
            if not any(a["id"] == app_id for a in APPLICATIONS):
                return 404, {"error": f"application {app_id} not found"}
            if decision not in ("approved", "rejected"):
                return 400, {"error": "decision must be 'approved' or 'rejected'"}
            DECISIONS[app_id] = {"id": app_id, "decision": decision, "reason": str(body.get("reason", ""))}
            return 201, {"saved": True, "id": app_id, "decision": decision}

        if parts == ["report"] and method == "GET":
            decided = list(DECISIONS.values())
            by_id = {a["id"]: a for a in APPLICATIONS}
            correct = sum(1 for d in decided if expected_decision(by_id[d["id"]]) == d["decision"])
            return 200, {
                "total": len(APPLICATIONS),
                "approved": sum(1 for d in decided if d["decision"] == "approved"),
                "rejected": sum(1 for d in decided if d["decision"] == "rejected"),
                "pending": len(APPLICATIONS) - len(decided),
                "correct": correct,
                "accuracy": round(100 * correct / len(decided)) if decided else 0,
            }

        if parts == ["reset"] and method == "POST":
            DECISIONS.clear()
            return 200, {"reset": True}

        if parts == ["login"] and method == "POST":
            body = body if isinstance(body, dict) else {}
            if body.get("email", "").strip().lower() == DEMO_USER["email"] and body.get("password") == DEMO_USER["password"]:
                return 200, {"ok": True, "user": {"name": DEMO_USER["name"], "email": DEMO_USER["email"]}}
            return 401, {"ok": False, "error": "wrong email or password"}

    return 404, {"error": f"no route for {method} /api/{'/'.join(parts)}"}


# --------------------------------------------------------------------------
# Running learner code
# --------------------------------------------------------------------------
RUNNER = r'''
import json, os, sys, traceback, urllib.error, urllib.request

BASE = os.environ.get("PYFORGE_API", "http://127.0.0.1:8000/api")
_opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))


class Api:
    """Tiny client for the PyForge Approval API: api.get(path), api.post(path, data)."""

    def _call(self, method, path, data=None):
        if not path.startswith("/"):
            path = "/" + path
        body = None if data is None else json.dumps(data).encode()
        req = urllib.request.Request(BASE + path, data=body, method=method,
                                     headers={"Content-Type": "application/json"})
        try:
            with _opener.open(req, timeout=4) as r:
                return json.loads(r.read().decode() or "null")
        except urllib.error.HTTPError as e:
            try:
                return json.loads(e.read().decode())
            except Exception:
                return {"error": str(e)}

    def get(self, path):
        return self._call("GET", path)

    def post(self, path, data=None):
        return self._call("POST", path, {} if data is None else data)


api = Api()
src = open(sys.argv[1], encoding="utf-8").read()
sys.argv = ["main.py"]
g = {"__name__": "__main__", "__file__": "main.py", "api": api}
try:
    exec(compile(src, "main.py", "exec"), g)
except SystemExit as e:
    sys.exit(e.code if isinstance(e.code, int) else (0 if e.code is None else 1))
except BaseException as e:
    frames = [f for f in traceback.extract_tb(e.__traceback__) if f.filename == "main.py"]
    out = []
    if frames:
        out.append("Traceback (most recent call last):\n")
        out.extend(traceback.format_list(frames))
    out.extend(traceback.format_exception_only(type(e), e))
    sys.stdout.flush()
    sys.stderr.write("".join(out))
    sys.exit(1)
'''


def run_code(code, stdin):
    with tempfile.TemporaryDirectory(prefix="pyforge-") as d:
        main = os.path.join(d, "main.py")
        runner = os.path.join(d, "_pyforge_runner.py")
        with open(main, "w", encoding="utf-8") as f:
            f.write(code)
        with open(runner, "w", encoding="utf-8") as f:
            f.write(RUNNER)
        env = dict(os.environ, PYFORGE_API=f"http://127.0.0.1:{PORT}/api",
                   PYTHONIOENCODING="utf-8", PYTHONUNBUFFERED="1")
        t0 = time.perf_counter()
        try:
            p = subprocess.run([sys.executable, runner, main], input=stdin or "", capture_output=True,
                               text=True, encoding="utf-8", errors="replace",
                               timeout=RUN_TIMEOUT, cwd=d, env=env)
            stdout, stderr, rc = p.stdout, p.stderr, p.returncode
        except subprocess.TimeoutExpired as e:
            def _s(x):
                return x.decode("utf-8", "replace") if isinstance(x, bytes) else (x or "")
            stdout = _s(e.stdout)
            stderr = _s(e.stderr) + f"TimeoutError: the program ran longer than {RUN_TIMEOUT} seconds (is there an endless loop?)\n"
            rc = -1
        ms = round((time.perf_counter() - t0) * 1000)
    return {"stdout": stdout[:MAX_OUTPUT], "stderr": stderr[:MAX_OUTPUT], "exit_code": rc,
            "time_ms": ms, "runtime": f"CPython {sys.version.split()[0]}"}


# --------------------------------------------------------------------------
# HTTP layer
# --------------------------------------------------------------------------
class Handler(BaseHTTPRequestHandler):
    server_version = "PyForge/" + VERSION

    def log_message(self, fmt, *args):
        sys.stderr.write("  %s  %s\n" % (time.strftime("%H:%M:%S"), fmt % args))

    def send_json(self, status, obj):
        data = json.dumps(obj).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(data)

    def read_body(self):
        n = int(self.headers.get("Content-Length") or 0)
        raw = self.rfile.read(n) if n else b""
        if not raw:
            return None
        try:
            return json.loads(raw.decode("utf-8"))
        except ValueError:
            return "__invalid__"

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def handle_any(self, method):
        url = urlparse(self.path)
        if url.path.startswith("/api/") or url.path == "/api":
            body = self.read_body() if method == "POST" else None
            if body == "__invalid__":
                return self.send_json(400, {"error": "request body is not valid JSON"})
            sub = url.path[len("/api"):]
            if sub.strip("/") == "run" and method == "POST":
                body = body if isinstance(body, dict) else {}
                code = str(body.get("code", ""))
                if len(code) > MAX_CODE:
                    return self.send_json(413, {"error": "code is too long"})
                return self.send_json(200, run_code(code, str(body.get("stdin", ""))))
            status, obj = api(method, sub, parse_qs(url.query), body)
            return self.send_json(status, obj)

        if method == "GET" and url.path in ("/", "/index.html"):
            with open(os.path.join(HERE, "index.html"), "rb") as f:
                data = f.read()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
            return
        self.send_json(404, {"error": "not found"})

    def do_GET(self):
        self.handle_any("GET")

    def do_POST(self):
        self.handle_any("POST")


def main():
    global PORT
    ap = argparse.ArgumentParser(description="Run the PyForge learning site locally.")
    ap.add_argument("--port", type=int, default=8000)
    ap.add_argument("--no-browser", action="store_true", help="don't open a browser tab")
    args = ap.parse_args()
    PORT = args.port
    httpd = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    url = f"http://localhost:{PORT}"
    print(f"\n  PyForge is running at {url}")
    print(f"  Code runs with {sys.executable} (Python {sys.version.split()[0]})")
    print(f"  Demo login: {DEMO_USER['email']} / {DEMO_USER['password']}")
    print("  Press Ctrl+C to stop.\n")
    if not args.no_browser:
        threading.Timer(0.8, lambda: webbrowser.open(url)).start()
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n  Stopped.")


if __name__ == "__main__":
    main()
