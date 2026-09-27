/* ---------- 3D forge scene (three.js r128) ---------- */
const Scene = (() => {
  let renderer, scene, camera, coil, core, sparks, tokens = [], ground, raf = 0, running = false;
  let mode = 'home', t0 = performance.now(), last = t0;
  const mouse = { x: 0, y: 0, tx: 0, ty: 0 };
  const cam = { x: 0, y: 1.1, z: 11.5, tx: 0, ty: 1.1, tz: 11.5 };
  const coilPos = { x: 2.6, y: 0, tx: 2.6, ty: 0, s: 1, ts: 1 };
  let scrollY = 0;
  const reduced = window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches;

  function cssColor(name, fallback) {
    const v = getComputedStyle(document.documentElement).getPropertyValue(name).trim();
    return v || fallback;
  }

  function makeEnv() {
    // A small "photo studio" rendered into a PMREM environment map: gives the metal real reflections.
    const env = new THREE.Scene();
    const room = new THREE.Mesh(new THREE.BoxGeometry(20, 12, 20),
      new THREE.MeshBasicMaterial({ color: 0x1a1d24, side: THREE.BackSide }));
    env.add(room);
    const box = (w, h, color, x, y, z, ry) => {
      const m = new THREE.Mesh(new THREE.PlaneGeometry(w, h), new THREE.MeshBasicMaterial({ color, side: THREE.DoubleSide }));
      m.position.set(x, y, z); m.rotation.y = ry || 0; m.lookAt(0, 0, 0); env.add(m);
    };
    box(6, 4, new THREE.Color(5, 3.2, 1.6), -7, 2, 4);      // warm softbox
    box(5, 3, new THREE.Color(1.2, 3.2, 3.0), 7, 1, -3);     // cool rim
    box(12, 1.2, new THREE.Color(4, 4, 4), 0, 5.8, 0);       // top strip
    box(4, 6, new THREE.Color(1.4, 1.2, 1.1), 0, 0, 9.5);    // front fill
    const pm = new THREE.PMREMGenerator(renderer);
    const tex = pm.fromScene(env, 0.035).texture;
    pm.dispose();
    return tex;
  }

  function makeCoil() {
    const turns = 3.15;
    class Helix extends THREE.Curve {
      getPoint(t, target = new THREE.Vector3()) {
        const a = t * turns * Math.PI * 2;
        const r = 1.75 - 0.55 * t;
        return target.set(Math.cos(a) * r, (t - 0.5) * 3.6, Math.sin(a) * r);
      }
    }
    const path = new Helix();
    const seg = 420, rad = 24, R = 0.36;
    const geo = new THREE.TubeGeometry(path, seg, R, rad, false);
    // Taper the tube: thin tail at t=0, full body, slight swell near the head.
    const pos = geo.attributes.position, c = new THREE.Vector3(), v = new THREE.Vector3();
    for (let i = 0; i <= seg; i++) {
      const t = i / seg;
      path.getPointAt(t, c);
      const k = Math.min(1, Math.pow(t / 0.35, 0.8)) * (t > 0.9 ? 1 + (t - 0.9) * 2.2 : 1);
      const scale = Math.max(0.05, k);
      for (let j = 0; j <= rad; j++) {
        const idx = i * (rad + 1) + j;
        v.fromBufferAttribute(pos, idx).sub(c).multiplyScalar(scale).add(c);
        pos.setXYZ(idx, v.x, v.y, v.z);
      }
    }
    geo.computeVertexNormals();
    const mat = new THREE.MeshPhysicalMaterial({
      color: 0xE9A24C, metalness: 1, roughness: 0.24, clearcoat: 0.7, clearcoatRoughness: 0.18, envMapIntensity: 1.25
    });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.castShadow = true;
    // Head cap
    const end = path.getPointAt(1), tan = path.getTangentAt(1);
    const head = new THREE.Mesh(new THREE.SphereGeometry(R * 1.22, 40, 28), mat);
    head.scale.set(1, 1, 1.35);
    head.position.copy(end);
    head.lookAt(end.clone().add(tan));
    head.castShadow = true;
    const g = new THREE.Group(); g.add(mesh); g.add(head);
    // Glowing ember eye
    const eye = new THREE.Mesh(new THREE.SphereGeometry(0.07, 16, 12), new THREE.MeshBasicMaterial({ color: 0xFFE2A8 }));
    eye.position.copy(end).add(tan.clone().multiplyScalar(R * 0.9)).add(new THREE.Vector3(0, R * 0.5, 0));
    g.add(eye);
    return g;
  }

  function makeCore() {
    const m = new THREE.MeshPhysicalMaterial({
      color: 0x9FE8DE, metalness: 0, roughness: 0.04, clearcoat: 1, transparent: true, opacity: 0.42, envMapIntensity: 2.2
    });
    const mesh = new THREE.Mesh(new THREE.IcosahedronGeometry(0.62, 0), m);
    mesh.castShadow = true;
    return mesh;
  }

  function sparkTexture() {
    const c = document.createElement('canvas'); c.width = c.height = 64;
    const x = c.getContext('2d');
    const g = x.createRadialGradient(32, 32, 0, 32, 32, 32);
    g.addColorStop(0, 'rgba(255,240,210,1)'); g.addColorStop(0.25, 'rgba(255,180,90,.85)'); g.addColorStop(1, 'rgba(255,120,30,0)');
    x.fillStyle = g; x.fillRect(0, 0, 64, 64);
    return new THREE.CanvasTexture(c);
  }

  function makeSparks() {
    const n = 360, geo = new THREE.BufferGeometry(), p = new Float32Array(n * 3), speed = new Float32Array(n);
    for (let i = 0; i < n; i++) {
      p[i * 3] = (Math.random() - 0.5) * 16; p[i * 3 + 1] = Math.random() * 10 - 4; p[i * 3 + 2] = (Math.random() - 0.5) * 10 - 1;
      speed[i] = 0.25 + Math.random() * 0.7;
    }
    geo.setAttribute('position', new THREE.BufferAttribute(p, 3));
    geo.userData.speed = speed;
    const mat = new THREE.PointsMaterial({ size: 0.11, map: sparkTexture(), transparent: true, depthWrite: false, blending: THREE.AdditiveBlending, opacity: 0.85 });
    return new THREE.Points(geo, mat);
  }

  function tokenSprite(text, accent) {
    const c = document.createElement('canvas'), x = c.getContext('2d');
    const fs = 44; x.font = `600 ${fs}px "JetBrains Mono", Menlo, monospace`;
    const w = Math.ceil(x.measureText(text).width) + 56, h = 84;
    c.width = w; c.height = h;
    x.font = `600 ${fs}px "JetBrains Mono", Menlo, monospace`;
    const r = 20;
    x.beginPath(); x.moveTo(r, 0); x.arcTo(w, 0, w, h, r); x.arcTo(w, h, 0, h, r); x.arcTo(0, h, 0, 0, r); x.arcTo(0, 0, w, 0, r); x.closePath();
    x.fillStyle = 'rgba(20,26,36,0.78)'; x.fill();
    x.lineWidth = 3; x.strokeStyle = accent ? 'rgba(255,190,110,.7)' : 'rgba(130,220,205,.55)'; x.stroke();
    x.fillStyle = accent ? '#FFC67E' : '#9FE8DE'; x.textBaseline = 'middle'; x.fillText(text, 28, h / 2 + 2);
    const tex = new THREE.CanvasTexture(c); tex.encoding = THREE.sRGBEncoding; tex.anisotropy = 4;
    const s = new THREE.Sprite(new THREE.SpriteMaterial({ map: tex, transparent: true, depthWrite: false }));
    const k = 0.0095; s.scale.set(w * k, h * k, 1);
    return s;
  }

  function init(canvas) {
    if (!window.THREE) return false;
    try {
      renderer = new THREE.WebGLRenderer({ canvas, antialias: true, powerPreference: 'high-performance' });
    } catch (e) { return false; }
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 1.75));
    renderer.outputEncoding = THREE.sRGBEncoding;
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.05;
    renderer.physicallyCorrectLights = true;
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;

    scene = new THREE.Scene();
    camera = new THREE.PerspectiveCamera(34, 1, 0.1, 100);
    scene.environment = makeEnv();
    applyTheme();

    const key = new THREE.DirectionalLight(0xFFE2BE, 3.2);
    key.position.set(4, 7, 5); key.castShadow = true;
    key.shadow.mapSize.set(1024, 1024); key.shadow.camera.near = 1; key.shadow.camera.far = 25;
    key.shadow.camera.left = -6; key.shadow.camera.right = 6; key.shadow.camera.top = 6; key.shadow.camera.bottom = -6;
    key.shadow.radius = 6; key.shadow.bias = -0.0005;
    scene.add(key);
    const rim = new THREE.PointLight(0x52C8B9, 40, 20, 2); rim.position.set(-4, 2, -4); scene.add(rim);
    const warm = new THREE.PointLight(0xFF8A2A, 28, 14, 2); warm.position.set(0, -2.3, 1.5); scene.add(warm);
    scene.add(new THREE.HemisphereLight(0xBFD4FF, 0x1A1208, 0.5));

    coil = makeCoil(); scene.add(coil);
    core = makeCore(); coil.add(core);

    ground = new THREE.Mesh(new THREE.CircleGeometry(9, 64), new THREE.ShadowMaterial({ opacity: 0.28 }));
    ground.rotation.x = -Math.PI / 2; ground.position.y = -2.9; ground.receiveShadow = true;
    scene.add(ground);

    sparks = makeSparks(); scene.add(sparks);

    const words = [['def', 1], ['print()', 0], ['import json', 1], ['yield', 0], ['GET /api', 0], ['200 OK', 1], ['class', 1], ['>>>', 0], ['[x for x]', 0], ['@decorator', 1], ['{ "id": 101 }', 0], ['async', 1]];
    const addTokens = () => words.forEach(([w, a], i) => {
      const s = tokenSprite(w, a);
      const ang = (i / words.length) * Math.PI * 2;
      s.userData = { ang, r: 3.4 + (i % 3) * 0.7, y: -1.6 + ((i * 7) % 12) / 12 * 3.6, sp: 0.05 + (i % 4) * 0.012, bob: Math.random() * 6 };
      tokens.push(s); scene.add(s);
    });
    if (document.fonts && document.fonts.ready) document.fonts.ready.then(addTokens, addTokens); else addTokens();

    window.addEventListener('resize', resize);
    window.addEventListener('pointermove', e => {
      mouse.tx = (e.clientX / window.innerWidth) * 2 - 1;
      mouse.ty = (e.clientY / window.innerHeight) * 2 - 1;
    }, { passive: true });
    window.addEventListener('scroll', () => { scrollY = window.scrollY || 0; }, { passive: true });
    document.addEventListener('visibilitychange', () => { document.hidden ? stop() : (mode !== 'off' && start()); });
    resize();
    return true;
  }

  function applyTheme() {
    if (!scene) return;
    const bg = new THREE.Color(cssColor('--scene-bg', '#0A0D12'));
    scene.background = bg;
    scene.fog = new THREE.Fog(bg.clone().convertSRGBToLinear(), 13, 30);
    if (ground) ground.material.opacity = bg.getHSL({}).l > 0.5 ? 0.18 : 0.32;
  }

  function resize() {
    if (!renderer) return;
    const w = window.innerWidth, h = window.innerHeight;
    renderer.setSize(w, h, false);
    camera.aspect = w / h; camera.updateProjectionMatrix();
    setMode(mode, true);
  }

  function setMode(m, snap) {
    mode = m;
    const narrow = window.innerWidth < 900;
    if (m === 'home') {
      coilPos.tx = narrow ? 1.9 : 2.7; coilPos.ty = narrow ? 2.4 : 0.1; coilPos.ts = narrow ? 0.6 : 1;
      cam.tz = narrow ? 14 : 11.5; cam.ty = 1.1;
    } else if (m === 'app') {
      coilPos.tx = narrow ? 1.7 : 3.9; coilPos.ty = narrow ? -1.6 : -0.2; coilPos.ts = narrow ? 0.55 : 0.85;
      cam.tz = narrow ? 15 : 13; cam.ty = 0.8;
    } else if (m === 'login') {
      coilPos.tx = narrow ? 0 : -3.4; coilPos.ty = narrow ? -1.2 : -0.4; coilPos.ts = narrow ? 0.7 : 0.95;
      cam.tz = narrow ? 15 : 12.5; cam.ty = 0.6;
    }
    if (snap) { coilPos.x = coilPos.tx; coilPos.y = coilPos.ty; coilPos.s = coilPos.ts; cam.z = cam.tz; cam.y = cam.ty; }
    if (m === 'off') stop(); else start();
  }

  function frame(now) {
    raf = requestAnimationFrame(frame);
    const dt = Math.min(0.05, (now - last) / 1000); last = now;
    const t = (now - t0) / 1000;
    const ease = 1 - Math.pow(0.001, dt);            // frame-rate independent smoothing
    const slow = reduced ? 0 : 1;
    mouse.x += (mouse.tx - mouse.x) * ease * 0.9; mouse.y += (mouse.ty - mouse.y) * ease * 0.9;
    const sc = mode === 'home' ? Math.min(scrollY / 900, 1) : 0;
    const spin = scrollY * 0.0022;                    // every page: the coil turns as you scroll
    coilPos.x += (coilPos.tx - coilPos.x) * ease * 0.6;
    coilPos.y += (coilPos.ty - sc * 1.2 - coilPos.y) * ease * 0.6;
    coilPos.s += (coilPos.ts - coilPos.s) * ease * 0.6;
    cam.z += (cam.tz - cam.z) * ease * 0.6; cam.y += (cam.ty - cam.y) * ease * 0.6;

    coil.position.set(coilPos.x, coilPos.y + Math.sin(t * 0.8) * 0.12 * slow, 0);
    coil.scale.setScalar(coilPos.s);
    coil.rotation.y = t * 0.22 * slow + spin + mouse.x * 0.35;
    coil.rotation.x = -0.12 + mouse.y * 0.12;
    coil.rotation.z = 0.08;
    core.rotation.x = t * 0.5 * slow; core.rotation.y = t * 0.7 * slow;

    camera.position.set(mouse.x * 0.7, cam.y - mouse.y * 0.35, cam.z);
    camera.lookAt(coilPos.x * 0.35, coilPos.y * 0.3, 0);

    tokens.forEach(s => {
      const u = s.userData; const a = u.ang + t * u.sp * slow;
      s.position.set(coil.position.x + Math.cos(a) * u.r, u.y + coil.position.y * 0.6 + Math.sin(t * 0.9 + u.bob) * 0.18 * slow, Math.sin(a) * u.r * 0.8);
      s.material.opacity = 0.35 + 0.65 * (0.5 + 0.5 * Math.sin(a));   // fade as they pass behind
    });

    if (slow) {
      const p = sparks.geometry.attributes.position, sp = sparks.geometry.userData.speed;
      for (let i = 0; i < sp.length; i++) {
        let y = p.getY(i) + sp[i] * dt;
        let x = p.getX(i) + Math.sin(t * 0.7 + i) * 0.0025;
        if (y > 6) { y = -3.5; x = (Math.random() - 0.5) * 16; }
        p.setXY(i, x, y);
      }
      p.needsUpdate = true;
    }
    renderer.render(scene, camera);
  }

  function start() { if (!renderer || running) return; running = true; last = performance.now(); raf = requestAnimationFrame(frame); }
  function stop() { running = false; cancelAnimationFrame(raf); }

  return { init, setMode, applyTheme, get ok() { return !!renderer; } };
})();
