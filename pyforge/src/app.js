/* ================= PyForge app ================= */
const LESSONS = /*LESSONS_JSON*/[];
const $ = (s, r = document) => r.querySelector(s);
const $$ = (s, r = document) => Array.from(r.querySelectorAll(s));
const esc = s => String(s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const REDUCED = window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches;
const icon = (id, cls = '') => `<svg class="${cls}" aria-hidden="true"><use href="#${id}"/></svg>`;

const LEVELS = [
  { name: 'Beginner', blurb: 'Syntax, data types, decisions, loops and collections.', xp: 50 },
  { name: 'Intermediate', blurb: 'Functions, errors, modules, formatting and classes.', xp: 75 },
  { name: 'Advanced', blurb: 'Inheritance, generators, decorators, dataclasses and data tools.', xp: 100 },
  { name: 'Pro', blurb: 'Context managers, testing, algorithms and real APIs.', xp: 150 },
];
const RANKS = [[0, 'Hatchling'], [250, 'Apprentice'], [800, 'Builder'], [1500, 'Engineer'], [2400, 'Pythonista']];
const xpFor = l => l.id === 'p6' ? 250 : LEVELS.find(v => v.name === l.level).xp;
const DEMO = { email: 'demo@pyforge.dev', password: 'Python@123', name: 'Demo Learner' };
const DAY = 86400000;
const dayKey = ts => { const d = new Date(ts); return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`; };

/* ---------------- storage (per browser) ---------------- */
const Store = (() => {
  const KEY = 'pyforge.v1'; let mem = null;
  function data() {
    if (mem) return mem;
    try { mem = JSON.parse(localStorage.getItem(KEY) || 'null'); } catch (e) { mem = null; }
    if (!mem || typeof mem !== 'object') mem = {};
    mem.users = mem.users || {}; mem.progress = mem.progress || {}; mem.prefs = mem.prefs || {};
    if (!('session' in mem)) mem.session = null;
    return mem;
  }
  function save() { try { localStorage.setItem(KEY, JSON.stringify(data())); } catch (e) { /* private mode: keep in memory */ } }
  return { data, save };
})();

async function hashPw(email, pw) {
  const text = `pyforge:${email}:${pw}`;
  try {
    const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
    return Array.from(new Uint8Array(buf)).map(b => b.toString(16).padStart(2, '0')).join('');
  } catch (e) {
    let h = 5381; for (let i = 0; i < text.length; i++) h = ((h * 33) ^ text.charCodeAt(i)) >>> 0;
    return 'djb2-' + h.toString(16);
  }
}

function currentUser() {
  const d = Store.data(); const e = d.session;
  if (!e) return null;
  if (e === DEMO.email) return { email: DEMO.email, name: DEMO.name, demo: true };
  const u = d.users[e]; return u ? { email: u.email, name: u.name } : null;
}

function seedDemo() {
  const d = Store.data(); if (d.progress[DEMO.email]) return;
  const now = Date.now();
  d.progress[DEMO.email] = {
    done: { b1: now - 3 * DAY, b2: now - 3 * DAY, b3: now - 2 * DAY, b4: now - DAY, b5: now - DAY },
    xp: 250, code: {}, ran: true,
    days: [dayKey(now - 3 * DAY), dayKey(now - 2 * DAY), dayKey(now - DAY)],
    activity: [
      { t: now - DAY, text: 'Completed “Input and type conversion”' },
      { t: now - DAY, text: 'Completed “Working with strings”' },
      { t: now - 2 * DAY, text: 'Completed “Numbers and math”' },
      { t: now - 3 * DAY, text: 'Completed “Variables and data types”' },
      { t: now - 3 * DAY, text: 'Completed “Your first program”' },
    ],
  };
  Store.save();
}

function prog() {
  const d = Store.data(), u = currentUser(); if (!u) return null;
  if (!d.progress[u.email]) d.progress[u.email] = { done: {}, xp: 0, code: {}, days: [], activity: [], ran: false };
  return d.progress[u.email];
}
function touchDay() { const p = prog(); if (!p) return; const k = dayKey(Date.now()); if (!p.days.includes(k)) { p.days.push(k); Store.save(); } }
function streak(p) {
  const set = new Set(p.days); let n = 0; let t = Date.now();
  if (!set.has(dayKey(t))) t -= DAY;
  while (set.has(dayKey(t))) { n++; t -= DAY; }
  return n;
}
function rankOf(xp) { let r = RANKS[0], next = null; for (let i = 0; i < RANKS.length; i++) { if (xp >= RANKS[i][0]) { r = RANKS[i]; next = RANKS[i + 1] || null; } } return { name: r[1], floor: r[0], next }; }
function levelStats(p, level) { const ls = LESSONS.filter(l => l.level === level); return { total: ls.length, done: ls.filter(l => p.done[l.id]).length }; }
const BADGES = [
  { id: 'first', name: 'First run', icon: 'i-play', test: p => p.ran },
  { id: 'streak', name: '3-day streak', icon: 'i-flame', test: p => streak(p) >= 3 },
  { id: 'beg', name: 'Beginner cleared', icon: 'i-medal', test: p => levelStats(p, 'Beginner').done === 9 },
  { id: 'int', name: 'Intermediate cleared', icon: 'i-medal', test: p => levelStats(p, 'Intermediate').done === 7 },
  { id: 'adv', name: 'Advanced cleared', icon: 'i-medal', test: p => levelStats(p, 'Advanced').done === 6 },
  { id: 'api', name: 'API caller', icon: 'i-api', test: p => !!p.done.p4 },
  { id: 'cap', name: 'Capstone at 100%', icon: 'i-target', test: p => !!p.done.p6 },
  { id: 'all', name: 'Pythonista', icon: 'i-bolt', test: p => Object.keys(p.done).length >= LESSONS.length },
];
function logActivity(text) { const p = prog(); p.activity.unshift({ t: Date.now(), text }); p.activity = p.activity.slice(0, 30); }

function markDone(lesson) {
  const p = prog(); if (p.done[lesson.id]) return false;
  const before = new Set(BADGES.filter(b => b.test(p)).map(b => b.id));
  p.done[lesson.id] = Date.now(); p.xp += xpFor(lesson);
  logActivity(`Completed “${lesson.title}”`);
  touchDay(); Store.save();
  toast(`+${xpFor(lesson)} XP · ${lesson.title} complete`, 'xp');
  BADGES.filter(b => b.test(p) && !before.has(b.id)).forEach(b => setTimeout(() => toast(`Badge unlocked: ${b.name}`, 'xp'), 900));
  return true;
}

function toast(msg, kind = '') {
  const t = document.createElement('div'); t.className = 'toast ' + kind; t.textContent = msg;
  $('#toasts').appendChild(t); setTimeout(() => t.remove(), 3600);
}

/* ---------------- theme ---------------- */
function effectiveDark() {
  const a = document.documentElement.getAttribute('data-theme');
  if (a) return a === 'dark';
  return window.matchMedia && matchMedia('(prefers-color-scheme: dark)').matches;
}
function syncThemeIcons() { $$('.theme-toggle use').forEach(u => u.setAttribute('href', effectiveDark() ? '#i-sun' : '#i-moon')); }
function toggleTheme() {
  const next = effectiveDark() ? 'light' : 'dark';
  document.documentElement.setAttribute('data-theme', next);
  Store.data().prefs.theme = next; Store.save();
  syncThemeIcons(); Scene.applyTheme();
}

/* ---------------- Approval API (in-browser mock, mirrors server.py) ---------------- */
const MockApi = (() => {
  const RULES = { min_age: 16, min_score: 70, min_attendance: 80 };
  const APPS = [
    { id: 101, name: 'Aarav Sharma', age: 19, score: 88, attendance: 92, country: 'Nepal' },
    { id: 102, name: 'Mei Lin', age: 22, score: 67, attendance: 95, country: 'Singapore' },
    { id: 103, name: 'Lucas Silva', age: 17, score: 91, attendance: 78, country: 'Brazil' },
    { id: 104, name: 'Fatima Noor', age: 24, score: 74, attendance: 85, country: 'Pakistan' },
    { id: 105, name: 'Ethan Brooks', age: 15, score: 95, attendance: 99, country: 'USA' },
    { id: 106, name: 'Sofia Rossi', age: 20, score: 82, attendance: 81, country: 'Italy' },
    { id: 107, name: 'Kwame Mensah', age: 28, score: 70, attendance: 80, country: 'Ghana' },
    { id: 108, name: 'Anika Rai', age: 18, score: 59, attendance: 88, country: 'Nepal' },
  ];
  const DEC = new Map();
  const expected = a => (a.age >= RULES.min_age && a.score >= RULES.min_score && a.attendance >= RULES.min_attendance) ? 'approved' : 'rejected';
  const withStatus = a => Object.assign({}, a, { status: DEC.has(a.id) ? DEC.get(a.id).decision : 'pending' });
  const pyRound = x => { const r = Math.round(x); return (Math.abs(x % 1) === 0.5 && r % 2 !== 0) ? r - 1 : r; };
  function call(method, fullPath, body) {
    const [path, qs] = String(fullPath).split('?');
    const q = new URLSearchParams(qs || '');
    const parts = path.split('/').filter(Boolean);
    const key = parts.join('/');
    if (key === 'health' && method === 'GET') return [200, { status: 'ok', mode: 'browser', python: 'Brython', version: '1.0.0' }];
    if (key === 'applications' && method === 'GET') {
      let items = APPS.map(withStatus); const st = q.get('status');
      if (st) items = items.filter(a => a.status === st);
      return [200, { count: items.length, items }];
    }
    if (parts.length === 2 && parts[0] === 'applications' && method === 'GET') {
      const id = Number(parts[1]);
      if (!/^-?\d+$/.test(parts[1])) return [400, { error: 'id must be a number' }];
      const a = APPS.find(x => x.id === id);
      return a ? [200, withStatus(a)] : [404, { error: `application ${id} not found` }];
    }
    if (key === 'rules' && method === 'GET') return [200, Object.assign({}, RULES)];
    if (key === 'decisions' && method === 'GET') return [200, { count: DEC.size, items: Array.from(DEC.values()) }];
    if (key === 'decisions' && method === 'POST') {
      if (!body || typeof body !== 'object' || Array.isArray(body)) return [400, { error: 'send a JSON object like {"id": 101, "decision": "approved"}' }];
      const id = body.id, decision = body.decision;
      if (typeof id !== 'number' || !APPS.some(a => a.id === id)) return [404, { error: `application ${id === undefined ? 'None' : id} not found` }];
      if (decision !== 'approved' && decision !== 'rejected') return [400, { error: "decision must be 'approved' or 'rejected'" }];
      DEC.set(id, { id, decision, reason: String(body.reason === undefined ? '' : body.reason) });
      return [201, { saved: true, id, decision }];
    }
    if (key === 'report' && method === 'GET') {
      const d = Array.from(DEC.values());
      const correct = d.filter(x => expected(APPS.find(a => a.id === x.id)) === x.decision).length;
      return [200, { total: APPS.length, approved: d.filter(x => x.decision === 'approved').length, rejected: d.filter(x => x.decision === 'rejected').length, pending: APPS.length - d.length, correct, accuracy: d.length ? pyRound(100 * correct / d.length) : 0 }];
    }
    if (key === 'reset' && method === 'POST') { DEC.clear(); return [200, { reset: true }]; }
    if (key === 'login' && method === 'POST') {
      const b = body && typeof body === 'object' ? body : {};
      if (String(b.email || '').trim().toLowerCase() === DEMO.email && b.password === DEMO.password) return [200, { ok: true, user: { name: DEMO.name, email: DEMO.email } }];
      return [401, { ok: false, error: 'wrong email or password' }];
    }
    return [404, { error: `no route for ${method} /api/${key}` }];
  }
  return { call };
})();
window.pfApi = (method, path, bodyStr) => {
  let body = null; try { body = bodyStr ? JSON.parse(bodyStr) : null; } catch (e) { return JSON.stringify({ error: 'request body is not valid JSON' }); }
  return JSON.stringify(MockApi.call(String(method).toUpperCase(), String(path), body)[1]);
};

/* ---------------- Python runner ---------------- */
const PY_RUNNER = String.raw`
from browser import window
import sys, json, traceback

class _Out:
    def __init__(self, kind):
        self.kind = kind
    def write(self, s):
        window.pfWrite(self.kind, str(s))
    def flush(self):
        pass

class Api:
    """Tiny client for the PyForge Approval API: api.get(path), api.post(path, data)."""
    def _call(self, method, path, data=None):
        if not path.startswith("/"):
            path = "/" + path
        raw = window.pfApi(method, path, "" if data is None else json.dumps(data))
        return json.loads(raw)
    def get(self, path):
        return self._call("GET", path)
    def post(self, path, data=None):
        return self._call("POST", path, {} if data is None else data)

_api = Api()

def _run(src, stdin_text):
    lines = str(stdin_text).split("\n") if stdin_text else []
    def _input(prompt=""):
        if prompt:
            sys.stdout.write(str(prompt))
        if not lines:
            raise EOFError("EOF when reading a line (type values into the Input box)")
        return lines.pop(0)
    old_out, old_err = sys.stdout, sys.stderr
    sys.stdout, sys.stderr = _Out("out"), _Out("err")
    g = {"__name__": "__main__", "api": _api, "input": _input}
    try:
        exec(src, g)
    except SystemExit:
        pass
    except BaseException as e:
        try:
            msg = traceback.format_exc()
        except Exception:
            msg = ""
        if type(e).__name__ not in msg:
            msg = msg + type(e).__name__ + ": " + str(e) + "\n"
        sys.stderr.write(msg)
    finally:
        sys.stdout, sys.stderr = old_out, old_err

window.pfPyRun = _run
window.pfPyReady()
`;

const Runner = (() => {
  let mode = 'detecting', label = 'checking…', loading = null;
  const subs = [];
  const BRY = [
    'https://cdnjs.cloudflare.com/ajax/libs/brython/3.14.3/',
    'https://cdn.jsdelivr.net/npm/brython@3.12.3/',
  ];
  function notify() { subs.forEach(f => f(mode, label)); }
  function onChange(f) { subs.push(f); f(mode, label); }
  async function detect() {
    if (/^https?:$/.test(location.protocol)) {
      try {
        const ctl = new AbortController(); const tm = setTimeout(() => ctl.abort(), 1800);
        const r = await fetch('/api/health', { signal: ctl.signal, cache: 'no-store' });
        clearTimeout(tm);
        if (r.ok) { const j = await r.json(); if (j && j.mode === 'localhost') { mode = 'localhost'; label = `CPython ${j.python} · localhost`; notify(); return; } }
      } catch (e) { /* not on localhost */ }
    }
    mode = 'browser'; label = 'Brython · in browser'; notify();
  }
  function loadScript(src) {
    return new Promise((res, rej) => {
      const s = document.createElement('script'); s.src = src; s.async = false;
      s.onload = res; s.onerror = () => rej(new Error('could not load ' + src));
      document.head.appendChild(s);
    });
  }
  function ensureBrython() {
    if (loading) return loading;
    loading = (async () => {
      let lastErr;
      for (const base of BRY) {
        try { await loadScript(base + 'brython.min.js'); await loadScript(base + 'brython_stdlib.js'); lastErr = null; break; }
        catch (e) { lastErr = e; }
      }
      if (lastErr || typeof window.brython !== 'function') throw new Error('The Python interpreter could not be downloaded. Check your connection, or use the localhost kit.');
      const ready = new Promise((res, rej) => { window.pfPyReady = res; setTimeout(() => rej(new Error('Python took too long to start in this browser. Try reloading, or use the localhost kit.')), 30000); });
      const s = document.createElement('script'); s.type = 'text/python'; s.id = 'pf_runner'; s.textContent = PY_RUNNER;
      document.body.appendChild(s);
      try { window.brython({ debug: 1, ids: ['pf_runner'] }); }
      catch (e) {
        try { window.__BRYTHON__.runPythonSource(PY_RUNNER, 'pf_runner'); }
        catch (e2) { throw new Error('This page is not allowed to start the in-browser interpreter (' + (e2.message || e.message) + '). The localhost kit runs the same lessons with real CPython.'); }
      }
      await ready;
      return true;
    })();
    loading.catch(() => { loading = null; });
    return loading;
  }
  async function run(code, stdin) {
    if (mode === 'detecting') await detect();
    const p = prog(); if (p && !p.ran) { p.ran = true; Store.save(); }
    if (mode === 'localhost') {
      try {
        const r = await fetch('/api/run', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ code, stdin: stdin || '' }) });
        const j = await r.json();
        return { chunks: [['out', j.stdout || ''], ['err', j.stderr || '']], stdout: j.stdout || '', stderr: j.stderr || '', ms: j.time_ms, runtime: j.runtime };
      } catch (e) {
        return { chunks: [['err', 'Could not reach the local server. Is python3 server.py still running?\n']], stdout: '', stderr: 'x', ms: 0, runtime: 'localhost' };
      }
    }
    try { await ensureBrython(); }
    catch (e) { return { chunks: [['err', e.message + '\n']], stdout: '', stderr: e.message, ms: 0, runtime: 'Brython', failed: true }; }
    const chunks = [];
    window.pfWrite = (k, s) => { const last = chunks[chunks.length - 1]; if (last && last[0] === k) last[1] += s; else chunks.push([k, s]); };
    const t = performance.now();
    try { window.pfPyRun(code, stdin || ''); }
    catch (e) { chunks.push(['err', String(e && e.message || e) + '\n']); }
    const stdout = chunks.filter(c => c[0] === 'out').map(c => c[1]).join('');
    const stderr = chunks.filter(c => c[0] === 'err').map(c => c[1]).join('');
    return { chunks, stdout, stderr, ms: Math.round(performance.now() - t), runtime: 'Brython' };
  }
  function preload() { if (mode === 'browser') ensureBrython().catch(() => { }); }
  return { detect, run, onChange, preload, get mode() { return mode; } };
})();

/* ---------------- code editor ---------------- */
const editors = new Set();
function makeEditor(host, value, opts = {}) {
  host.innerHTML = '';
  let api;
  if (window.CodeMirror) {
    const run = () => { opts.onRun && opts.onRun(); };
    const cm = window.CodeMirror(host, {
      value, mode: 'python', lineNumbers: true, indentUnit: 4, tabSize: 4, indentWithTabs: false,
      viewportMargin: Infinity, readOnly: !!opts.readOnly, matchBrackets: true, autoCloseBrackets: true, styleActiveLine: true,
      extraKeys: {
        Tab: c => c.somethingSelected() ? c.indentSelection('add') : c.replaceSelection('    ', 'end'),
        'Shift-Tab': c => c.indentSelection('subtract'),
        'Ctrl-Enter': run, 'Cmd-Enter': run,
      },
    });
    if (opts.onChange) cm.on('change', () => opts.onChange(cm.getValue()));
    api = { get: () => cm.getValue(), set: v => cm.setValue(v), focus: () => cm.focus(), refresh: () => cm.refresh() };
  } else {
    const ta = document.createElement('textarea'); ta.className = 'fallback'; ta.spellcheck = false; ta.value = value;
    ta.setAttribute('autocapitalize', 'off'); ta.setAttribute('autocomplete', 'off'); ta.setAttribute('autocorrect', 'off');
    ta.rows = Math.max(6, value.split('\n').length + 1);
    ta.addEventListener('keydown', e => {
      if (e.key === 'Tab') { e.preventDefault(); const s = ta.selectionStart; ta.setRangeText('    ', s, ta.selectionEnd, 'end'); }
      if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) { e.preventDefault(); opts.onRun && opts.onRun(); }
    });
    if (opts.onChange) ta.addEventListener('input', () => opts.onChange(ta.value));
    host.appendChild(ta);
    api = { get: () => ta.value, set: v => { ta.value = v; }, focus: () => ta.focus(), refresh: () => { } };
  }
  api.host = host; editors.add(api);
  return api;
}
function refreshEditors() { editors.forEach(e => { if (document.body.contains(e.host)) e.refresh(); else editors.delete(e); }); }

function ideHTML({ id, file, buttons, stdin, stdinValue }) {
  return `<div class="ide" id="${id}">
    <div class="ide-bar"><span class="file">${icon('i-code')}${esc(file)}</span>${buttons}</div>
    <div class="editor-host"></div>
    ${stdin ? `<div class="stdin-row"><label for="${id}-stdin">Input</label><textarea id="${id}-stdin" spellcheck="false" placeholder="One value per line, read by input()">${esc(stdinValue || '')}</textarea></div>` : ''}
    <div class="console"><div class="c-head"><span>Output</span><span class="c-meta"></span></div><pre aria-live="polite"><span class="sys">Press Run to see the output here.</span></pre></div>
  </div>`;
}
function showOutput(ide, res) {
  const pre = $('.console pre', ide), meta = $('.c-meta', ide);
  if (!res) { pre.innerHTML = '<span class="sys">Running…</span>'; meta.textContent = ''; return; }
  const html = res.chunks.filter(c => c[1]).map(([k, s]) => k === 'err' ? `<span class="err">${esc(s)}</span>` : esc(s)).join('');
  pre.innerHTML = html || '<span class="sys">(no output)</span>';
  meta.textContent = `${res.runtime || ''}${res.ms != null ? ' · ' + res.ms + ' ms' : ''}`;
}
const norm = s => String(s).replace(/\r/g, '').split('\n').map(l => l.replace(/\s+$/, '')).join('\n').replace(/^\n+|\n+$/g, '');

/* ---------------- routing ---------------- */
const state = { view: null, pane: 'dashboard', lesson: null, authMode: 'login' };
function go(target, opts = {}) {
  const user = currentUser();
  let view = target, pane = null, lesson = null;
  if (['dashboard', 'learn', 'playground', 'lab', 'cheatsheet'].includes(target) || /^learn-/.test(target)) {
    if (/^learn-/.test(target)) { lesson = target.slice(6); target = 'learn'; }
    pane = target; view = 'app';
    if (!user) { view = 'login'; pane = null; }
  }
  if (view === 'signup') { view = 'login'; opts.signup = true; }
  if (view === 'login' && user && !opts.force) { view = 'app'; pane = 'dashboard'; }
  if (!['home', 'login', 'app'].includes(view)) view = 'home';

  state.view = view;
  $('#view-home').hidden = view !== 'home';
  $('#view-login').hidden = view !== 'login';
  $('#view-app').hidden = view !== 'app';
  document.body.classList.toggle('app-mode', view === 'app');
  Scene.setMode(view === 'app' ? 'off' : view);
  if (view === 'login') { Login.open(opts); } else { Login.close(); }
  if (view === 'app') showPane(pane || state.pane, lesson);
  let hash = view === 'app' ? (pane === 'learn' && state.lesson ? 'learn-' + state.lesson : (pane || state.pane)) : view;
  if (location.hash.slice(1) !== hash) { try { history.replaceState(null, '', '#' + hash); } catch (e) { } }
  if (!opts.keepScroll) window.scrollTo(0, 0);
}

function showPane(pane, lessonId) {
  state.pane = pane;
  $$('.app-tabs button').forEach(b => b.setAttribute('aria-current', b.dataset.pane === pane ? 'page' : 'false'));
  $$('.pane').forEach(p => { p.hidden = p.id !== 'pane-' + pane; });
  const u = currentUser();
  $('#avatar').textContent = u.name.split(/\s+/).map(w => w[0]).join('').slice(0, 2).toUpperCase();
  $('#menu-name').textContent = u.name; $('#menu-email').textContent = u.email;
  if (pane === 'dashboard') renderDashboard();
  if (pane === 'learn') renderLearn(lessonId || state.lesson || nextLesson().id);
  if (pane === 'playground') renderPlayground();
  if (pane === 'lab') renderLab();
  if (pane === 'cheatsheet') renderCheatsheet();
  requestAnimationFrame(refreshEditors);
}
function nextLesson() { const p = prog(); return LESSONS.find(l => !p.done[l.id]) || LESSONS[LESSONS.length - 1]; }

/* ---------------- home ---------------- */
function renderRoadmap() {
  $('#roadmap').innerHTML = LEVELS.map(lv => {
    const ls = LESSONS.filter(l => l.level === lv.name);
    return `<div class="level-col"><header><div class="lv-bar" style="width:${25 * (LEVELS.indexOf(lv) + 1)}%"></div><h3>${lv.name}</h3><p>${lv.blurb}</p><span class="pill accent" style="justify-self:start">${ls.length} lessons · ${lv.xp} XP each</span></header><ol>${ls.map(l => `<li>${esc(l.title)}</li>`).join('')}</ol></div>`;
  }).join('');
}
function heroTerminal() {
  const out = $('#hero-out'); if (!out) return;
  const lines = ["{'total': 8, 'approved': 5, 'rejected': 3, 'pending': 0, 'correct': 7, 'accuracy': 88}", '# 88%: one approval rule is missing. Can you spot it?'];
  const full = '$ python capstone.py\n' + lines.join('\n');
  if (REDUCED) { out.textContent = full; return; }
  let i = '$ python capstone.py\n'.length;
  const tick = () => {
    i += 2; out.innerHTML = esc(full.slice(0, i)) + (i < full.length ? '<span class="caret"></span>' : '');
    if (i < full.length) setTimeout(tick, 22);
  };
  setTimeout(tick, 1400);
}

/* ---------------- hanging login ---------------- */
const Login = (() => {
  const view = () => $('#view-login');
  let rig, card, tag, svg, raf = 0, running = false, last = 0;
  let theta = 0, omega = 0, drop = 0, dropV = 0, psi = 0, psiV = 0, vxPrev = 0, xPrev = 0;
  let L = 140, hookY = 18, W = 380, H = 520, focused = false;
  let drag = null, done = false;
  const W2 = 8.4;                          // g / L for the main cords (≈ 2.2 s swing)

  function measure() {
    hookY = $('.ceiling').offsetHeight;
    L = clamp(window.innerHeight * 0.13, 84, 140);
    W = card.offsetWidth; H = card.offsetHeight;
    const need = hookY + L + H + 200;
    view().style.minHeight = Math.max(window.innerHeight, need) + 'px';
  }
  function cx() { return view().clientWidth / 2; }
  function draw() {
    const x = L * Math.sin(theta), top = hookY + L * Math.cos(theta) + drop - 19;
    const tilt = theta * 0.1;
    rig.style.transform = `translate(${-W / 2 + x}px, ${top}px) rotate(${tilt}rad)`;
    rig.style.transformOrigin = '50% 0';
    tag.style.transform = `rotate(${psi}rad)`;
    const c = cx(), inset = W / 2 - 29;
    const ends = [-1, 1].map(s => {
      const gx = s * inset, gy = 19;
      return [c + x + gx * Math.cos(tilt) - gy * Math.sin(tilt), top + gx * Math.sin(tilt) + gy * Math.cos(tilt)];
    });
    const hooks = [[c - inset, hookY], [c + inset, hookY]];
    const slack = Math.max(0, -drop) * 0.25;
    svg.innerHTML = hooks.map((h, i) => {
      const e = ends[i]; const mx = (h[0] + e[0]) / 2 + (i ? slack : -slack) * 0.4, my = (h[1] + e[1]) / 2 + slack;
      const d = `M${h[0]},${h[1]} Q${mx},${my} ${e[0]},${e[1]}`;
      return `<path d="${d}" stroke="#7A5A30" stroke-width="3.2" fill="none" stroke-linecap="round"/>
              <path d="${d}" stroke="#D9AE6E" stroke-width="3.2" fill="none" stroke-dasharray="3 3" stroke-linecap="round"/>
              <circle cx="${h[0]}" cy="${h[1] + 3}" r="6" fill="none" stroke="#C9A36A" stroke-width="2.5"/>
              <circle cx="${h[0]}" cy="${h[1] - 2}" r="4" fill="#8E97A6"/>`;
    }).join('');
  }
  function step(now) {
    raf = requestAnimationFrame(step);
    const dt = Math.min(0.033, (now - last) / 1000 || 0.016); last = now;
    if (!drag) {
      const c = focused ? 3.2 : 0.3;
      const sub = 4, h = dt / sub;
      for (let i = 0; i < sub; i++) { omega += (-W2 * Math.sin(theta) - c * omega) * h; theta += omega * h; }
    }
    dropV += (-95 * drop - 11 * dropV) * dt; drop += dropV * dt;
    // tag: pendulum driven by the card's sideways acceleration
    const x = L * Math.sin(theta), vx = (x - xPrev) / dt, ax = (vx - vxPrev) / dt; xPrev = x; vxPrev = vx;
    const l2 = 95, g = W2 * L;
    psiV += (-(g / l2) * Math.sin(psi) - 2.4 * psiV - clamp(ax, -4000, 4000) / l2 * Math.cos(psi)) * dt; psi += psiV * dt;
    psi = clamp(psi, -1.2, 1.2);
    draw();
  }
  function start() { if (running) return; running = true; last = performance.now(); raf = requestAnimationFrame(step); }
  function stop() { running = false; cancelAnimationFrame(raf); }

  function setMode(m) {
    state.authMode = m;
    $('#tab-login').setAttribute('aria-selected', m === 'login'); $('#tab-signup').setAttribute('aria-selected', m === 'signup');
    $('#f-name').hidden = m !== 'signup';
    $('#login-title').textContent = m === 'login' ? 'Welcome back' : 'Create your account';
    $('#login-sub').textContent = m === 'login' ? 'Log in to continue your Python path.' : 'Free, and saved in this browser.';
    $('#auth-submit').textContent = m === 'login' ? 'Log in' : 'Create account';
    $('#in-pass').setAttribute('autocomplete', m === 'login' ? 'current-password' : 'new-password');
    $('#form-err').textContent = '';
    requestAnimationFrame(measure);
  }
  function fillDemo() { $('#in-email').value = DEMO.email; $('#in-pass').value = DEMO.password; setMode('login'); omega += 0.9; psiV += 3; }
  function fail(msg) {
    $('#form-err').textContent = msg;
    card.classList.remove('shake'); void card.offsetWidth; card.classList.add('shake');
    omega += (Math.random() > 0.5 ? 1 : -1) * 1.3;
  }
  async function submit(e) {
    if (e) e.preventDefault();
    const email = $('#in-email').value.trim().toLowerCase(), pw = $('#in-pass').value, name = $('#in-name').value.trim();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return fail('Enter a valid email address, like you@example.com.');
    if (pw.length < 6) return fail('Passwords are at least 6 characters.');
    const d = Store.data();
    if (state.authMode === 'signup') {
      if (!name) return fail('Add your name so we can greet you.');
      if (email === DEMO.email || d.users[email]) return fail('That email already has an account. Switch to Log in.');
      d.users[email] = { email, name, hash: await hashPw(email, pw), created: Date.now() };
    } else if (email === DEMO.email) {
      if (pw !== DEMO.password) return fail('Wrong password for the demo account. It is Python@123.');
      seedDemo();
    } else {
      const u = d.users[email];
      if (!u || u.hash !== await hashPw(email, pw)) return fail('That email and password don’t match an account in this browser.');
    }
    d.session = email; Store.save(); touchDay();
    const p = prog(); if (!p.activity.length) { logActivity('Joined PyForge'); Store.save(); }
    success();
  }
  function success() {
    if (done) return; done = true;
    stop();
    if (REDUCED) { enter(); return; }
    svg.style.transition = 'opacity .4s'; svg.style.opacity = '0';
    const x = L * Math.sin(theta), top = hookY + L * Math.cos(theta) + drop - 19;
    rig.classList.add('drop');
    rig.style.transform = `translate(${-W / 2 + x + 60}px, ${top + window.innerHeight}px) rotate(${0.35}rad)`;
    setTimeout(enter, 700);
  }
  function enter() { toast(`Welcome, ${currentUser().name.split(' ')[0]}!`); go('dashboard'); }
  function open(opts = {}) {
    rig = $('#rig'); card = $('#hang-card'); tag = $('#tag'); svg = $('#cords');
    done = false; rig.classList.remove('drop'); svg.style.opacity = '1';
    setMode(opts.signup ? 'signup' : 'login');
    if (opts.demo) { $('#in-email').value = DEMO.email; $('#in-pass').value = DEMO.password; }
    measure();
    if (REDUCED) { theta = omega = drop = dropV = psi = psiV = 0; draw(); return; }
    theta = opts.signup ? -0.34 : 0.34; omega = 0; psi = 0; psiV = 0; xPrev = L * Math.sin(theta); vxPrev = 0;
    drop = -(hookY + L + H + 80); dropV = 0;
    start();
  }
  function close() { stop(); }
  function bind() {
    rig = $('#rig'); card = $('#hang-card'); tag = $('#tag'); svg = $('#cords');
    $('#auth-form').addEventListener('submit', submit);
    $('#tab-login').addEventListener('click', () => setMode('login'));
    $('#tab-signup').addEventListener('click', () => setMode('signup'));
    $('#pw-toggle').addEventListener('click', () => { const i = $('#in-pass'); const show = i.type === 'password'; i.type = show ? 'text' : 'password'; $('#pw-toggle').textContent = show ? 'Hide' : 'Show'; });
    $('#demo-login').addEventListener('click', () => { fillDemo(); setTimeout(submit, 380); });
    $('#tag-fill').addEventListener('click', fillDemo);
    card.addEventListener('focusin', () => { focused = true; });
    card.addEventListener('focusout', () => { focused = false; });
    card.addEventListener('pointerdown', e => {
      if (REDUCED || done || e.target.closest('input,button,a,label,textarea,select,dd')) return;
      card.setPointerCapture(e.pointerId); card.classList.add('grabbing');
      const r = card.getBoundingClientRect();
      drag = { off: e.clientX - (r.left + r.width / 2), t: performance.now(), th: theta };
      drop = 0; dropV = 0;
    });
    card.addEventListener('pointermove', e => {
      if (!drag) return;
      const target = clamp((e.clientX - drag.off - cx()) / L, -0.9, 0.9);
      const th = Math.asin(target), now = performance.now(), dt = Math.max(0.008, (now - drag.t) / 1000);
      omega = omega * 0.5 + ((th - drag.th) / dt) * 0.5; theta = th; drag.th = th; drag.t = now;
    });
    const release = () => { if (!drag) return; drag = null; card.classList.remove('grabbing'); omega = clamp(omega, -4, 4); };
    card.addEventListener('pointerup', release); card.addEventListener('pointercancel', release);
    window.addEventListener('resize', () => { if (state.view === 'login') { measure(); if (REDUCED) draw(); } });
  }
  return { bind, open, close };
})();

/* ---------------- dashboard ---------------- */
function renderDashboard() {
  const u = currentUser(), p = prog(), rank = rankOf(p.xp), nl = nextLesson();
  const doneCount = Object.keys(p.done).length, st = streak(p);
  const pct = rank.next ? Math.round(100 * (p.xp - rank.floor) / (rank.next[0] - rank.floor)) : 100;
  const hour = new Date().getHours(); const greet = hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening';
  const allDone = doneCount >= LESSONS.length;
  $('#pane-dashboard').innerHTML = `
    <div class="pane-head"><div><h1>${greet}, ${esc(u.name.split(' ')[0])}</h1><p>${u.demo ? 'You are using the demo account. Progress is saved in this browser.' : 'Your progress is saved in this browser.'}</p></div>
      <div id="reset-zone"><button class="btn sm ghost" type="button" id="reset-progress">Reset my progress</button></div></div>
    <div class="dash">
      <div class="span-12 stat-row">
        <div class="card stat"><span class="k">Experience</span><span class="v">${p.xp.toLocaleString()} XP</span><span class="s">Rank: ${rank.name}</span></div>
        <div class="card stat"><span class="k">Lessons done</span><span class="v">${doneCount}<span class="muted" style="font-size:18px"> / ${LESSONS.length}</span></span><span class="s">${Math.round(100 * doneCount / LESSONS.length)}% of the course</span></div>
        <div class="card stat"><span class="k">Streak</span><span class="v">${st} day${st === 1 ? '' : 's'}</span><span class="s">Practise daily to keep it</span></div>
        <div class="card stat"><span class="k">Badges</span><span class="v">${BADGES.filter(b => b.test(p)).length}<span class="muted" style="font-size:18px"> / ${BADGES.length}</span></span><span class="s">Unlocked so far</span></div>
      </div>
      <div class="card continue span-8">
        <span class="eyebrow">${allDone ? 'Course complete' : 'Up next · ' + nl.level}</span>
        <h2>${allDone ? 'You finished every lesson. Try the API Lab next.' : esc(nl.title)}</h2>
        <div class="row"><span class="pill">${nl.mins} min</span><span class="pill accent">+${xpFor(nl)} XP</span></div>
        <div style="display:grid;gap:6px;max-width:520px"><div class="xpbar"><i style="width:${pct}%"></i></div>
          <span class="muted" style="font-size:13px">${rank.next ? `${rank.next[0] - p.xp} XP to ${rank.next[1]}` : 'Top rank reached'}</span></div>
        <div class="row"><button class="btn primary" type="button" data-go="learn-${nl.id}">${allDone ? 'Review lessons' : (doneCount ? 'Continue learning' : 'Start lesson 1')}</button>
          <button class="btn" type="button" data-go="playground">Open the playground</button></div>
      </div>
      <div class="card span-4"><div class="card-h"><h3>Levels</h3><span class="muted" style="font-size:13px">${doneCount}/${LESSONS.length}</span></div>
        <div class="lvl-list">${LEVELS.map(lv => { const s = levelStats(p, lv.name); return `<div class="lvl-row"><div class="top"><b>${lv.name}</b><span>${s.done}/${s.total}</span></div><div class="xpbar"><i style="width:${100 * s.done / s.total}%"></i></div></div>`; }).join('')}</div></div>
      <div class="card span-6"><div class="card-h"><h3>Badges</h3></div>
        <div class="badges">${BADGES.map(b => `<div class="badge ${b.test(p) ? 'on' : ''}">${icon(b.icon)}<span>${b.name}</span></div>`).join('')}</div></div>
      <div class="card span-6"><div class="card-h"><h3>Recent activity</h3></div>
        <ul class="activity">${(p.activity.length ? p.activity.slice(0, 7) : [{ t: Date.now(), text: 'Nothing yet. Start your first lesson.' }]).map(a => `<li><span>${esc(a.text)}</span><time>${new Date(a.t).toLocaleDateString(undefined, { month: 'short', day: 'numeric' })}</time></li>`).join('')}</ul></div>
    </div>`;
  $('#reset-progress').addEventListener('click', () => {
    $('#reset-zone').innerHTML = `<div class="inline-confirm"><span>Clear all XP, lessons and saved code?</span><button class="btn sm" type="button" id="rp-no">Keep</button><button class="btn sm primary" type="button" id="rp-yes">Clear progress</button></div>`;
    $('#rp-no').onclick = renderDashboard;
    $('#rp-yes').onclick = () => { const d = Store.data(); delete d.progress[currentUser().email]; if (currentUser().demo) seedDemo(); Store.save(); toast('Progress cleared'); renderDashboard(); };
  });
}

/* ---------------- learn ---------------- */
let saveTimer = 0;
function renderLearn(id) {
  const lesson = LESSONS.find(l => l.id === id) || LESSONS[0];
  state.lesson = lesson.id;
  try { history.replaceState(null, '', '#learn-' + lesson.id); } catch (e) { }
  const p = prog(), idx = LESSONS.indexOf(lesson), done = !!p.done[lesson.id];
  const prev = LESSONS[idx - 1], next = LESSONS[idx + 1];
  const navHTML = LEVELS.map(lv => {
    const ls = LESSONS.filter(l => l.level === lv.name), s = levelStats(p, lv.name);
    return `<h4><span>${lv.name}</span><span>${s.done}/${s.total}</span></h4>` + ls.map(l => `<button type="button" data-lesson="${l.id}" aria-current="${l.id === lesson.id}"><span class="st ${p.done[l.id] ? 'done' : ''}">${p.done[l.id] ? icon('i-check') : ''}</span><span>${esc(l.title)}</span><small>${l.mins}m</small></button>`).join('');
  }).join('');
  const selectHTML = `<select class="input lesson-select" id="lesson-select" aria-label="Choose a lesson">${LEVELS.map(lv => `<optgroup label="${lv.name}">${LESSONS.filter(l => l.level === lv.name).map(l => `<option value="${l.id}" ${l.id === lesson.id ? 'selected' : ''}>${p.done[l.id] ? '✓ ' : ''}${LESSONS.indexOf(l) + 1}. ${esc(l.title)}</option>`).join('')}</optgroup>`).join('')}</select>`;
  const saved = p.code[lesson.id];
  $('#pane-learn').innerHTML = `
    <div class="learn">
      <aside class="lesson-nav" aria-label="Lessons">${navHTML}</aside>
      <div class="lesson">
        ${selectHTML}
        <div class="lesson-head">
          <div class="meta"><span class="pill accent">${lesson.level} · Lesson ${idx + 1} of ${LESSONS.length}</span><span class="pill">${lesson.mins} min</span>${done ? `<span class="pill ok">${icon('i-check')}Completed</span>` : `<span class="pill">+${xpFor(lesson)} XP</span>`}${lesson.api ? '<span class="pill steel">Uses the Approval API</span>' : ''}</div>
          <h1>${esc(lesson.title)}</h1>
        </div>
        <article class="card theory">${lesson.body}</article>
        <section>
          <div class="block-title"><h2>Example</h2><span class="muted" style="font-size:14px">Change it and run it as often as you like.</span></div>
          ${ideHTML({ id: 'ex-ide', file: 'example.py', stdin: !!lesson.example_stdin, stdinValue: lesson.example_stdin, buttons: `<button class="btn sm" type="button" id="ex-reset">Reset</button><button class="btn sm primary" type="button" id="ex-run">${icon('i-play')}Run <kbd>⌘↵</kbd></button>` })}
        </section>
        <section>
          <div class="block-title"><h2>Your task</h2>${done ? `<span class="pill ok">${icon('i-check')}Solved</span>` : `<span class="pill accent">+${xpFor(lesson)} XP</span>`}</div>
          <div class="task-text">${lesson.task}</div>
          ${ideHTML({ id: 'task-ide', file: 'main.py', stdin: true, stdinValue: lesson.stdin, buttons: `<button class="btn sm" type="button" id="t-reset">Reset</button><button class="btn sm" type="button" id="t-hint">Hint</button><button class="btn sm" type="button" id="t-sol">Solution</button><button class="btn sm" type="button" id="t-run">${icon('i-play')}Run</button><button class="btn sm steel" type="button" id="t-check">${icon('i-check')}Check answer</button>` })}
          <div id="t-result"></div><div id="t-extra"></div>
        </section>
        <div class="lesson-foot">
          ${prev ? `<button class="btn" type="button" data-lesson="${prev.id}">← ${esc(prev.title)}</button>` : '<span></span>'}
          ${next ? `<button class="btn" type="button" data-lesson="${next.id}">${esc(next.title)} →</button>` : '<button class="btn" type="button" data-go="lab">Go to the API Lab →</button>'}
        </div>
      </div>
    </div>`;
  $$('.theory table.ref', $('#pane-learn')).forEach(t => { const w = document.createElement('div'); w.className = 'table-scroll'; t.parentNode.insertBefore(w, t); w.appendChild(t); });

  const exIde = $('#ex-ide'), tIde = $('#task-ide');
  const runEx = async () => { showOutput(exIde, null); const stdin = $('#ex-ide-stdin'); showOutput(exIde, await Runner.run(ex.get(), stdin ? stdin.value : '')); };
  const ex = makeEditor($('.editor-host', exIde), lesson.example, { onRun: runEx });
  const task = makeEditor($('.editor-host', tIde), saved != null ? saved : lesson.starter, {
    onRun: () => check(),
    onChange: v => { clearTimeout(saveTimer); saveTimer = setTimeout(() => { prog().code[lesson.id] = v; Store.save(); }, 400); },
  });
  $('#ex-run').onclick = runEx;
  $('#ex-reset').onclick = () => ex.set(lesson.example);
  const runTask = async () => { showOutput(tIde, null); const r = await Runner.run(task.get(), $('#task-ide-stdin').value); showOutput(tIde, r); return r; };
  async function check() {
    const btn = $('#t-check'); btn.disabled = true;
    const r = await runTask(); btn.disabled = false;
    if (r.failed) { $('#t-result').innerHTML = ''; return; }
    const got = norm(r.stdout), want = norm(lesson.expected);
    const pass = !r.stderr.trim() && (lesson.check === 'contains' ? got.includes(want) : got === want);
    if (pass) {
      const first = markDone(lesson);
      $('#t-result').innerHTML = `<div class="result pass"><div class="rt">${icon('i-check')}Correct! ${first ? `+${xpFor(lesson)} XP earned.` : 'You already solved this one.'}</div>
        <div style="display:flex;gap:8px;flex-wrap:wrap">${next ? `<button class="btn primary sm" type="button" data-lesson="${next.id}">Next: ${esc(next.title)} →</button>` : '<button class="btn primary sm" type="button" data-go="dashboard">See my dashboard</button>'}</div></div>`;
      $$('.lesson-nav button[data-lesson="' + lesson.id + '"] .st').forEach(s => { s.classList.add('done'); s.innerHTML = icon('i-check'); });
    } else {
      const why = r.stderr.trim() ? 'Your program stopped with an error. Read the red message above: it names the line and the problem.' : (lesson.check === 'contains' ? `Your output should contain <code>${esc(want)}</code>.` : 'The output doesn’t match yet. Compare the two below line by line.');
      $('#t-result').innerHTML = `<div class="result fail"><div class="rt">${icon('i-x')}Not yet</div><p>${why}</p>
        <div class="diff"><div><h5>Expected</h5><pre>${esc(want)}</pre></div><div><h5>Your output</h5><pre>${esc(got) || '(nothing printed)'}</pre></div></div></div>`;
    }
  }
  $('#t-run').onclick = runTask;
  $('#t-check').onclick = check;
  $('#t-reset').onclick = () => { task.set(lesson.starter); $('#task-ide-stdin').value = lesson.stdin || ''; $('#t-result').innerHTML = ''; };
  $('#t-hint').onclick = () => { $('#t-extra').innerHTML = `<div class="hint"><b>Hint:</b> ${esc(lesson.hint)}</div>`; };
  $('#t-sol').onclick = () => {
    $('#t-extra').innerHTML = `<div class="hint"><div class="inline-confirm"><span>See the full solution? Try the hint first if you haven’t.</span><button class="btn sm" type="button" id="sol-yes">Show solution</button></div></div>`;
    $('#sol-yes').onclick = () => {
      $('#t-extra').innerHTML = `<div class="hint" style="display:grid;gap:10px"><b>Solution</b><div class="ide"><pre style="margin:0;padding:14px 16px;color:var(--code-text);font-size:13px;line-height:1.65;overflow-x:auto">${esc(lesson.solution)}</pre></div><div><button class="btn sm" type="button" id="sol-use">Put it in my editor</button></div></div>`;
      $('#sol-use').onclick = () => { task.set(lesson.solution); task.focus(); };
    };
  };
  const sel = $('#lesson-select'); sel.onchange = () => renderLearn(sel.value);
  if (!REDUCED) window.scrollTo({ top: 0 });
  requestAnimationFrame(refreshEditors);
}

/* ---------------- playground ---------------- */
const SNIPPETS = {
  'Hello': 'name = input("Your name: ")\nprint(f"Hello, {name}! Welcome to PyForge.")\nfor i in range(3):\n    print("🐍" * (i + 1))',
  'FizzBuzz': 'for n in range(1, 21):\n    if n % 15 == 0:\n        print("FizzBuzz")\n    elif n % 3 == 0:\n        print("Fizz")\n    elif n % 5 == 0:\n        print("Buzz")\n    else:\n        print(n)',
  'Class': 'from dataclasses import dataclass\n\n@dataclass\nclass Planet:\n    name: str\n    moons: int\n\nplanets = [Planet("Earth", 1), Planet("Mars", 2), Planet("Jupiter", 95)]\nfor p in sorted(planets, key=lambda p: p.moons, reverse=True):\n    print(f"{p.name:<8} {p.moons:>3} moons")',
  'Generators': 'def primes():\n    found = []\n    n = 2\n    while True:\n        if all(n % p for p in found):\n            found.append(n)\n            yield n\n        n += 1\n\ngen = primes()\nprint([next(gen) for _ in range(15)])',
  'API call': 'data = api.get("/applications")\nprint("Applications:", data["count"])\nfor app in data["items"]:\n    flag = "✓" if app["score"] >= 70 else "✗"\n    print(flag, app["id"], app["name"])',
  'Word count': 'from collections import Counter\ntext = input()\nwords = [w.strip(".,!?").lower() for w in text.split()]\nfor word, n in Counter(words).most_common(3):\n    print(word, n)',
};
let pg = null;
function renderPlayground() {
  if (pg) return;
  const d = Store.data(), start = (prog().code.__playground) || SNIPPETS.Hello;
  $('#pane-playground').innerHTML = `
    <div class="pane-head"><div><h1>Playground</h1><p>A free editor for trying ideas. Your code is saved as you type. <kbd class="mono">Ctrl/⌘ + Enter</kbd> runs it.</p></div>
      <div class="snips">${Object.keys(SNIPPETS).map(k => `<button class="btn sm" type="button" data-snip="${esc(k)}">${esc(k)}</button>`).join('')}</div></div>
    ${ideHTML({ id: 'pg-ide', file: 'playground.py', stdin: true, stdinValue: 'Asha\nPython is fun. Python is fast! Fun, fun, fun.', buttons: `<button class="btn sm" type="button" id="pg-copy">Copy code</button><button class="btn sm" type="button" id="pg-clear">Clear output</button><button class="btn sm primary" type="button" id="pg-run">${icon('i-play')}Run <kbd>⌘↵</kbd></button>` })}`;
  const ide = $('#pg-ide');
  const run = async () => { showOutput(ide, null); showOutput(ide, await Runner.run(pg.get(), $('#pg-ide-stdin').value)); };
  pg = makeEditor($('.editor-host', ide), start, { onRun: run, onChange: v => { clearTimeout(saveTimer); saveTimer = setTimeout(() => { prog().code.__playground = v; Store.save(); }, 400); } });
  $('#pg-run').onclick = run;
  $('#pg-clear').onclick = () => { $('.console pre', ide).innerHTML = '<span class="sys">Cleared.</span>'; $('.c-meta', ide).textContent = ''; };
  $('#pg-copy').onclick = e => { const t = pg.get(); navigator.clipboard && navigator.clipboard.writeText(t).then(() => toast('Code copied'), () => toast('Copy was blocked here. Select the code and copy it.')); };
  $$('[data-snip]', $('#pane-playground')).forEach(b => b.onclick = () => { pg.set(SNIPPETS[b.dataset.snip]); pg.focus(); });
}

/* ---------------- API lab ---------------- */
const ENDPOINTS = [
  { m: 'GET', p: '/health', d: 'Is the API up, and which Python serves it.' },
  { m: 'GET', p: '/applications', d: 'All 8 scholarship applications with their status.' },
  { m: 'GET', p: '/applications?status=pending', d: 'Filter by status: pending, approved or rejected.' },
  { m: 'GET', p: '/applications/104', d: 'One application by its id.' },
  { m: 'GET', p: '/rules', d: 'The thresholds an approval must meet.' },
  { m: 'POST', p: '/decisions', d: 'Approve or reject one application.', body: { id: 101, decision: 'approved', reason: 'meets all rules' } },
  { m: 'GET', p: '/decisions', d: 'Every decision made so far.' },
  { m: 'GET', p: '/report', d: 'Totals and accuracy against the rules.' },
  { m: 'POST', p: '/reset', d: 'Clear every decision and start over.', body: {} },
  { m: 'POST', p: '/login', d: 'Check an email and password pair.', body: { email: 'demo@pyforge.dev', password: 'Python@123' } },
  { m: 'POST', p: '/run', d: 'Run Python code and return its output.', body: { code: 'nums = [3, 1, 4, 1, 5, 9]\nprint(sorted(nums), sum(nums))', stdin: '' } },
];
const LAB_CLIENT = `# The Approval API from Python. \`api\` is ready to use.
api.post("/reset")
apps = api.get("/applications")["items"]
print(f"{len(apps)} applications\\n")
for app in apps[:4]:
    print(f'{app["id"]}  {app["name"]:<14} score={app["score"]:<3} attendance={app["attendance"]}')

print()
print(api.post("/decisions", {"id": 101, "decision": "approved", "reason": "strong scores"}))
print(api.post("/decisions", {"id": 102, "decision": "approved"}))   # wrong on purpose
print(api.get("/report"))
`;
function jsonHTML(obj) {
  return esc(JSON.stringify(obj, null, 2)).replace(/(&quot;(?:[^&]|&(?!quot;))*?&quot;)(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?/g, (m, str, colon, lit) => {
    if (str) return colon ? `<span class="j-k">${str}</span>${colon}` : `<span class="j-s">${str}</span>`;
    if (lit) return `<span class="j-b">${m}</span>`;
    return `<span class="j-n">${m}</span>`;
  });
}
let labBuilt = false, labClient = null;
function renderLab() {
  if (labBuilt) { updateLabMode(); return; }
  labBuilt = true;
  $('#pane-lab').innerHTML = `
    <div class="pane-head"><div><h1>API Lab</h1><p>Send real requests to the Approval API, then drive it from Python. <span id="lab-mode"></span></p></div></div>
    <div class="lab">
      <div class="card"><div class="card-h"><h3>Endpoints</h3><span class="muted mono" style="font-size:12px">/api</span></div><div class="endpoints" id="ep-list">
        ${ENDPOINTS.map((e, i) => `<button type="button" data-ep="${i}"><span class="m m-${e.m}">${e.m}</span><span class="p">${esc(e.p)}</span><span class="d">${esc(e.d)}</span></button>`).join('')}
      </div></div>
      <div style="display:grid;gap:18px;min-width:0">
        <div class="card">
          <form class="req" id="req-form">
            <div class="line">
              <select id="req-method" aria-label="HTTP method"><option>GET</option><option>POST</option></select>
              <div class="path-wrap"><span>/api</span><input id="req-path" value="/applications" aria-label="Path" spellcheck="false" autocapitalize="off"></div>
              <button class="btn primary" type="submit">Send</button>
            </div>
            <textarea id="req-body" spellcheck="false" aria-label="JSON body" placeholder="JSON body (POST only)"></textarea>
            <pre class="curl" id="req-curl"></pre>
          </form>
          <div class="resp"><div class="rh" id="resp-head"><span class="pill">No request yet</span></div><pre id="resp-body"><span class="j-k">Pick an endpoint on the left, or type a path, then press Send.</span></pre></div>
        </div>
        <section>
          <div class="block-title"><h2>Python client</h2><span class="muted" style="font-size:14px">Same API, from code. The capstone lesson builds this out.</span></div>
          ${ideHTML({ id: 'lab-ide', file: 'client.py', buttons: `<button class="btn sm" type="button" id="lab-reset">Reset</button><button class="btn sm primary" type="button" id="lab-run">${icon('i-play')}Run</button>` })}
        </section>
      </div>
    </div>`;
  const pick = i => {
    const e = ENDPOINTS[i];
    $('#req-method').value = e.m; $('#req-path').value = e.p;
    $('#req-body').value = e.body ? JSON.stringify(e.body, null, 2) : '';
    $$('#ep-list button').forEach(b => b.setAttribute('aria-current', b.dataset.ep == i));
    updateCurl();
  };
  $$('#ep-list button').forEach(b => b.onclick = () => { pick(+b.dataset.ep); send(); });
  ['req-method', 'req-path', 'req-body'].forEach(id => $('#' + id).addEventListener('input', updateCurl));
  $('#req-method').addEventListener('change', updateCurl);
  $('#req-form').addEventListener('submit', e => { e.preventDefault(); send(); });
  const ide = $('#lab-ide');
  const runClient = async () => { showOutput(ide, null); showOutput(ide, await Runner.run(labClient.get(), '')); };
  labClient = makeEditor($('.editor-host', ide), LAB_CLIENT, { onRun: runClient });
  $('#lab-run').onclick = runClient;
  $('#lab-reset').onclick = () => labClient.set(LAB_CLIENT);
  pick(1); updateLabMode();
}
function updateLabMode() {
  const el = $('#lab-mode'); if (!el) return;
  el.innerHTML = Runner.mode === 'localhost' ? '<span class="pill ok"><span class="dot"></span>Live server on localhost</span>' : '<span class="pill steel"><span class="dot"></span>In-browser copy of the API</span>';
  updateCurl();
}
function updateCurl() {
  const m = $('#req-method').value, p = $('#req-path').value.trim() || '/', b = $('#req-body').value.trim();
  const base = Runner.mode === 'localhost' ? location.origin : 'http://localhost:8000';
  let c = `curl${m === 'GET' ? '' : ' -X ' + m} "${base}/api${p.startsWith('/') ? p : '/' + p}"`;
  if (m !== 'GET') c += ` \\\n  -H "Content-Type: application/json" \\\n  -d '${(b || '{}').replace(/\s*\n\s*/g, ' ')}'`;
  $('#req-curl').textContent = c;
}
async function send() {
  const m = $('#req-method').value; let p = $('#req-path').value.trim() || '/'; if (!p.startsWith('/')) p = '/' + p;
  const raw = $('#req-body').value.trim();
  let body = null;
  if (m === 'POST' && raw) { try { body = JSON.parse(raw); } catch (e) { return showResp(400, { error: 'The body is not valid JSON: ' + e.message }, 0); } }
  $('#resp-head').innerHTML = '<span class="pill">Sending…</span>';
  const t = performance.now();
  if (Runner.mode === 'localhost') {
    try {
      const r = await fetch('/api' + p, { method: m, headers: { 'Content-Type': 'application/json' }, body: m === 'POST' ? JSON.stringify(body || {}) : undefined });
      const j = await r.json(); showResp(r.status, j, Math.round(performance.now() - t));
    } catch (e) { showResp(0, { error: 'Could not reach the local server: ' + e.message }, 0); }
    return;
  }
  if (p.split('?')[0].replace(/\/+$/, '') === '/run' && m === 'POST') {
    const b = body || {}; const r = await Runner.run(String(b.code || ''), String(b.stdin || ''));
    return showResp(200, { stdout: r.stdout, stderr: r.stderr, exit_code: r.stderr ? 1 : 0, time_ms: r.ms, runtime: r.runtime }, Math.round(performance.now() - t));
  }
  const [status, obj] = MockApi.call(m, p, body);
  setTimeout(() => showResp(status, obj, Math.round(performance.now() - t) + 1), 120);
}
function showResp(status, obj, ms) {
  const ok = status >= 200 && status < 300;
  const text = { 200: 'OK', 201: 'Created', 400: 'Bad Request', 401: 'Unauthorized', 404: 'Not Found', 413: 'Too Large', 0: 'Network error' }[status] || '';
  $('#resp-head').innerHTML = `<span class="pill ${ok ? 'ok' : 'bad'}">${status} ${text}</span><span class="pill">${ms} ms</span><span class="pill">application/json</span>`;
  $('#resp-body').innerHTML = jsonHTML(obj);
}

/* ---------------- cheatsheet ---------------- */
const CHEATS = [
  ['Basics', 'x = 10          # int\npi = 3.14       # float\nname = "Asha"   # str\nok = True       # bool\nnothing = None\nprint(type(x), len(name))'],
  ['Strings', 's = "Hello World"\ns.lower(); s.upper(); s.title()\ns.split(" ")       # [\'Hello\', \'World\']\n"-".join(["a","b"]) # \'a-b\'\ns.replace("o", "0")\ns[0], s[-1], s[0:5]\nf"{name} is {x:>4}  {pi:.2f}"'],
  ['Lists', 'nums = [3, 1, 2]\nnums.append(4); nums.insert(0, 9)\nnums.pop(); nums.remove(9)\nnums.sort(); sorted(nums, reverse=True)\nnums[1:], nums[::-1]\n[n * 2 for n in nums if n > 1]'],
  ['Dictionaries', 'd = {"a": 1, "b": 2}\nd["c"] = 3\nd.get("z", 0)\nfor k, v in d.items(): ...\nd.keys(); d.values()\n{k: v for k, v in d.items() if v > 1}'],
  ['Control flow', 'if x > 0:\n    ...\nelif x == 0:\n    ...\nelse:\n    ...\nfor i in range(5): ...\nwhile cond: ...\nbreak / continue\nmatch cmd:\n    case "go": ...\n    case _: ...'],
  ['Functions', 'def add(a, b=0, *args, **kw):\n    """Docstring."""\n    return a + b\n\nsquare = lambda n: n * n\nmap(square, nums); filter(bool, items)'],
  ['Classes', 'class Dog(Animal):\n    kind = "canine"           # class attr\n    def __init__(self, name):\n        super().__init__()\n        self.name = name\n    def __str__(self):\n        return self.name'],
  ['Errors', 'try:\n    risky()\nexcept (ValueError, KeyError) as e:\n    print(e)\nelse:\n    ...\nfinally:\n    cleanup()\nraise ValueError("bad input")'],
  ['Files & JSON', 'from pathlib import Path\nimport json\ntext = Path("notes.txt").read_text()\nwith open("out.txt", "w") as f:\n    f.write("hi\\n")\ndata = json.loads(\'{"ok": true}\')\njson.dumps(data, indent=2)'],
  ['APIs with requests', 'import requests\nr = requests.get(url, params={"q": "py"},\n                 timeout=5)\nr.raise_for_status()\ndata = r.json()\nrequests.post(url, json={"id": 1})'],
  ['Terminal & pip', 'python3 --version\npython3 -m venv .venv\nsource .venv/bin/activate   # Windows: .venv\\Scripts\\activate\npip install requests fastapi\npip freeze > requirements.txt\npython3 main.py'],
  ['Useful built-ins', 'len  sum  min  max  abs  round\nsorted  reversed  enumerate  zip\nany  all  range  isinstance\nint  float  str  list  dict  set\ninput  print  open  help  dir'],
];
let cheatsBuilt = false;
function renderCheatsheet() {
  if (cheatsBuilt) return; cheatsBuilt = true;
  $('#pane-cheatsheet').innerHTML = `<div class="pane-head"><div><h1>Cheatsheet</h1><p>The syntax you'll reach for most, on one page.</p></div></div>
    <div class="cheats">${CHEATS.map(([h, c]) => `<div class="card cheat"><h3>${esc(h)}</h3><pre>${esc(c)}</pre></div>`).join('')}</div>`;
}

/* ---------------- boot ---------------- */
function boot() {
  const theme = Store.data().prefs.theme;
  if (theme === 'dark' || theme === 'light') document.documentElement.setAttribute('data-theme', theme);
  syncThemeIcons();
  if (window.matchMedia) { const mq = matchMedia('(prefers-color-scheme: dark)'); const f = () => { syncThemeIcons(); Scene.applyTheme(); }; mq.addEventListener ? mq.addEventListener('change', f) : mq.addListener(f); }
  const ok = Scene.init($('#scene'));
  if (ok) $('.scene-fallback').style.display = 'none'; else $('#scene').style.display = 'none';
  renderRoadmap(); heroTerminal(); Login.bind();

  document.addEventListener('click', e => {
    const t = e.target.closest('[data-go],[data-pane],[data-lesson],[data-scroll],.theme-toggle,#avatar,#logout');
    const menu = $('#user-menu');
    if (!e.target.closest('#user-menu,#avatar') && !menu.hidden) { menu.hidden = true; $('#avatar').setAttribute('aria-expanded', 'false'); }
    if (!t) return;
    if (t.classList.contains('theme-toggle')) return toggleTheme();
    if (t.id === 'avatar') { menu.hidden = !menu.hidden; t.setAttribute('aria-expanded', String(!menu.hidden)); return; }
    if (t.id === 'logout') { menu.hidden = true; Store.data().session = null; Store.save(); toast('Logged out'); pg = null; labBuilt = false; return go('home'); }
    if (t.dataset.scroll) { e.preventDefault(); const s = document.getElementById(t.dataset.scroll); if (s) s.scrollIntoView({ behavior: REDUCED ? 'auto' : 'smooth' }); return; }
    if (t.dataset.lesson) { e.preventDefault(); if (state.view !== 'app' || state.pane !== 'learn') go('learn-' + t.dataset.lesson); else renderLearn(t.dataset.lesson); return; }
    if (t.dataset.pane) { e.preventDefault(); menu.hidden = true; return go(t.dataset.pane); }
    if (t.dataset.go) { e.preventDefault(); return go(t.dataset.go, { demo: !!t.dataset.demo, signup: !!t.dataset.signup }); }
  });
  window.addEventListener('hashchange', () => { const h = location.hash.slice(1); if (h && h !== (state.view === 'app' ? (state.pane === 'learn' ? 'learn-' + state.lesson : state.pane) : state.view)) go(h); });

  Runner.onChange((mode, label) => {
    const pill = $('#runtime-pill');
    pill.className = 'pill runtime-pill ' + (mode === 'localhost' ? 'ok' : mode === 'browser' ? 'steel' : '');
    pill.lastElementChild.textContent = 'Python: ' + label;
    updateLabMode();
  });
  Runner.detect().then(() => { if (currentUser()) setTimeout(Runner.preload, 1200); });

  const h = location.hash.slice(1);
  go(h || (currentUser() ? 'dashboard' : 'home'), { keepScroll: true });
}
if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot); else boot();
