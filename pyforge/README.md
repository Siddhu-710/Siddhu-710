# PyForge

PyForge is a Python learning platform: 28 lessons from beginner to pro, a playground, an API Lab and a hanging-card login with a demo account. This folder runs the whole site on **your own computer**, with lesson code executed by **your installed Python (CPython)**.

## Open it online

If GitHub Pages is on for this repository (Settings → Pages → Deploy from branch → `main` / root), the site is at:

```
https://siddhu-710.github.io/Siddhu-710/pyforge/
```

Online, lesson code runs in a Python interpreter inside the browser. Run it locally (below) to use your own CPython instead.

## Start it on localhost

You need Python 3.8 or newer (`python3 --version`). Nothing to install with pip.

| System | How |
|---|---|
| macOS | Double-click **Start PyForge.command** (first time: right-click → Open), or run `python3 server.py` in Terminal |
| Windows | Double-click **start-windows.bat**, or run `py server.py` |
| Linux | `python3 server.py` |

Then open **http://localhost:8000** in Safari, Chrome, Firefox or Edge. The browser tab opens automatically.
The badge in the top bar should read **Python: CPython 3.x · localhost**.

Options: `python3 server.py --port 9000` (another port), `--no-browser` (don't open a tab). Stop with **Ctrl+C**.

## Demo account

- Email: `demo@pyforge.dev`
- Password: `Python@123`

The demo already has 5 lessons done. You can also create your own account on the login card. Accounts and progress are stored in your browser (localStorage), not on a server.

## What's inside

| File | Purpose |
|---|---|
| `index.html` | The whole website: 3D landing page, logo, hanging login, dashboard, lessons, playground, API Lab, cheatsheet |
| `server.py` | Standard-library web server: serves `index.html`, runs code (`POST /api/run`) and hosts the Approval API |

## The Approval API (http://localhost:8000/api)

| Method | Path | Does |
|---|---|---|
| GET | `/health` | Status and Python version |
| GET | `/applications` | All 8 scholarship applications (`?status=pending` to filter) |
| GET | `/applications/{id}` | One application |
| GET | `/rules` | Approval thresholds |
| POST | `/decisions` | `{"id": 101, "decision": "approved", "reason": "..."}` |
| GET | `/decisions` | Decisions so far |
| GET | `/report` | Approved, rejected, pending, correct, accuracy |
| POST | `/reset` | Clear all decisions |
| POST | `/login` | `{"email": "...", "password": "..."}` |
| POST | `/run` | `{"code": "print(1+1)", "stdin": ""}` → stdout, stderr, time |

Try it from a terminal:

```bash
curl http://localhost:8000/api/applications
curl -X POST http://localhost:8000/api/decisions -H "Content-Type: application/json" -d '{"id": 101, "decision": "approved"}'
```

Or from Python (`pip install requests`):

```python
import requests
print(requests.get("http://localhost:8000/api/report", timeout=5).json())
```

## Good to know

- Code runs with a 5-second limit, so an endless loop can't hang your machine.
- The server listens on 127.0.0.1 only; other devices on your network can't reach it. It runs any code typed into the page, so don't expose it to the internet.
- The page loads fonts, the 3D engine (three.js) and the code editor from public CDNs, so the first load needs internet. Offline, lessons still run, with a plain editor and no 3D.

## Editing the site

`index.html` is generated. Edit the files in `src/` and rebuild:

| File | Contents |
|---|---|
| `src/lessons.py` | All 28 lessons: text, examples, tasks, hints, solutions |
| `src/app.js` | Login, dashboard, lessons, runner, API Lab |
| `src/scene.js` | The three.js 3D scene |
| `src/styles.css`, `src/markup.html` | Look and page structure |
| `src/build.py` | Runs every solution with CPython to record expected output, then writes `index.html` |

```bash
cd src && python3 build.py
```
