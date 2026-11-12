import {
  ACESFilmicToneMapping,
  BackSide,
  BoxGeometry,
  CanvasTexture,
  Color,
  DirectionalLight,
  Group,
  LatheGeometry,
  Mesh,
  MeshBasicMaterial,
  MeshPhysicalMaterial,
  MeshStandardMaterial,
  VSMShadowMap,
  PerspectiveCamera,
  PlaneGeometry,
  PMREMGenerator,
  QuadraticBezierCurve3,
  RepeatWrapping,
  Scene,
  ShadowMaterial,
  SphereGeometry,
  Sprite,
  SpriteMaterial,
  SRGBColorSpace,
  Texture,
  TorusGeometry,
  TubeGeometry,
  Vector2,
  Vector3,
  WebGLRenderer,
} from 'three';

/** Гироскоп стоит в свободном месте над текстом: центр по ширине панели, доля этого места под его высоту. */
const ANCHOR = { x: 0.54, height: 0.6, centerY: 0.46 };
/** На низком экране места над текстом мало, фигура встаёт вровень с логотипом — сдвигаем её вправо от него. */
const TIGHT = { below: 360, x: 0.68 };
const FOV = 30;
const DISTANCE = 8;

/** Размеры в единицах сцены: ось от −AXLE до AXLE, нижнее остриё стоит на нити. */
const AXLE = 1.22;
const RING = 0.78;
const WHEEL = 0.64;
/** Нить: половина длины и провис. Концы уходят за края панели и растворяются. */
const ROPE = { half: 7, sag: 1.1, radius: 0.016 };

/** Шлифованный металл: тонкие продольные штрихи разной яркости — карта шероховатости и рельефа. */
function brushedTexture(): Texture {
  const c = document.createElement('canvas');
  c.width = c.height = 256;
  const g = c.getContext('2d')!;
  g.fillStyle = '#8c8c8c';
  g.fillRect(0, 0, 256, 256);
  for (let i = 0; i < 1400; i++) {
    const v = 90 + Math.floor(Math.random() * 110);
    g.fillStyle = `rgba(${v},${v},${v},${0.12 + Math.random() * 0.25})`;
    g.fillRect(Math.random() * 256, Math.random() * 256, 40 + Math.random() * 216, 1);
  }
  const t = new CanvasTexture(c);
  t.wrapS = t.wrapT = RepeatWrapping;
  t.repeat.set(3, 3);
  return t;
}

/** Кручёная нить: косые полосы двух красных. Бегут вдоль нити — так видно, что гироскоп едет. */
function ropeTexture(): Texture {
  const c = document.createElement('canvas');
  c.width = c.height = 64;
  const g = c.getContext('2d')!;
  g.fillStyle = '#e8281c';
  g.fillRect(0, 0, 64, 64);
  g.strokeStyle = '#a81209';
  g.lineWidth = 9;
  for (let x = -64; x < 128; x += 32) {
    g.beginPath();
    g.moveTo(x, 64);
    g.lineTo(x + 64, 0);
    g.stroke();
  }
  const t = new CanvasTexture(c);
  t.colorSpace = SRGBColorSpace;
  t.wrapS = t.wrapT = RepeatWrapping;
  t.repeat.set(150, 1);
  return t;
}

/** Прозрачность нити по длине: к концам она растворяется, как вне фокуса. */
function fadeTexture(): Texture {
  const c = document.createElement('canvas');
  c.width = 256;
  c.height = 1;
  const g = c.getContext('2d')!;
  const grad = g.createLinearGradient(0, 0, 256, 0);
  grad.addColorStop(0, '#000');
  grad.addColorStop(0.36, '#fff');
  grad.addColorStop(0.64, '#fff');
  grad.addColorStop(1, '#000');
  g.fillStyle = grad;
  g.fillRect(0, 0, 256, 1);
  return new CanvasTexture(c);
}

/**
 * Мягкое пятно света: ореол за гироскопом и размытые огоньки вне фокуса. Рисуются обычной прозрачностью:
 * сложение цветов на прозрачном холсте Safari показывает серыми дисками с жёстким краем.
 */
function glowTexture(): Texture {
  const c = document.createElement('canvas');
  c.width = c.height = 128;
  const g = c.getContext('2d')!;
  const grad = g.createRadialGradient(64, 64, 0, 64, 64, 64);
  grad.addColorStop(0, 'rgba(255,255,255,1)');
  grad.addColorStop(0.35, 'rgba(255,255,255,0.42)');
  grad.addColorStop(1, 'rgba(255,255,255,0)');
  g.fillStyle = grad;
  g.fillRect(0, 0, 128, 128);
  const t = new CanvasTexture(c);
  t.colorSpace = SRGBColorSpace;
  return t;
}

/** Огоньки вне фокуса проплывают назад: ближние быстрее и крупнее — так читается, что камера едет. */
const BOKEH = { count: 22, spanX: 9, speed: 0.55 };

/**
 * Студия для отражений: тёмный серо-синий зал и несколько светящихся панелей. Металл выглядит металлом,
 * когда в нём отражается контраст — яркие полосы софтбоксов на тёмном, а не ровно светлая комната.
 */
function studio(): Scene {
  const room = new Scene();
  const wall = new Mesh(new SphereGeometry(20, 32, 16), new MeshBasicMaterial({ color: new Color('#26313c'), side: BackSide }));
  room.add(wall);
  const panel = (w: number, h: number, power: number, tint: string, pos: [number, number, number]) => {
    const m = new Mesh(new PlaneGeometry(w, h), new MeshBasicMaterial({ color: new Color(tint).multiplyScalar(power) }));
    m.position.set(...pos);
    m.lookAt(0, 0, 0);
    room.add(m);
  };
  panel(14, 8, 9, '#fff3e2', [-4, 10, 6]); // большой верхний софтбокс, тёплый
  panel(4, 14, 7, '#ffffff', [-11, 1, 4]); // узкая вертикальная полоса слева
  panel(5, 11, 5, '#a9c8ff', [10, 2, -4]); // холодный контровой справа сзади
  panel(16, 6, 2.2, '#8ea6bd', [0, -8, 6]); // слабый отсвет снизу
  panel(7, 4, 6, '#ffffff', [4, 5, 10]); // небольшой блик спереди
  return room;
}

/** Тело вращения по контуру «радиус, высота». */
const lathe = (profile: [number, number][], segments = 96) => new LatheGeometry(profile.map(([r, y]) => new Vector2(r, y)), segments);

/**
 * Игрушечный гироскоп из шлифованной стали едет по красной нити. Сам он стоит на месте кадра — камера как будто
 * едет рядом с той же скоростью, — а движение видно по нити: бегут витки, меняется её наклон под остриём.
 * Маховик крутится, рамка медленно прецессирует, указатель чуть поворачивает сцену.
 * Объём дают тени (кольца на маховике, фигура на невидимом полу), свечение нити и огоньки вне фокуса.
 * Чисто декоративно, для диктора скрыто. `clearHeight` — сколько пикселей сверху свободно от текста.
 * Возвращает функцию, которая останавливает отрисовку и освобождает память видеокарты.
 */
export function mountGyroscope(host: HTMLElement, still: boolean, clearHeight: () => number): () => void {
  const renderer = new WebGLRenderer({ antialias: true, alpha: true, powerPreference: 'low-power' });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.toneMapping = ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.0;
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = VSMShadowMap;
  const canvas = renderer.domElement;
  canvas.setAttribute('aria-hidden', 'true');
  host.appendChild(canvas);

  const scene = new Scene();
  const pmrem = new PMREMGenerator(renderer);
  const room = studio();
  const env = pmrem.fromScene(room, 0.035);
  room.traverse((o) => {
    if (o instanceof Mesh) {
      o.geometry.dispose();
      o.material.dispose();
    }
  });
  scene.environment = env.texture;
  scene.environmentIntensity = 1.0;
  // Ключевой свет сверху слева даёт тени колец на маховике и тень всей фигуры на «полу».
  const key = new DirectionalLight(0xfff1de, 1.1);
  key.castShadow = true;
  key.shadow.mapSize.set(1024, 1024);
  key.shadow.camera.left = key.shadow.camera.bottom = -3;
  key.shadow.camera.right = key.shadow.camera.top = 3;
  key.shadow.camera.near = 1;
  key.shadow.camera.far = 30;
  key.shadow.bias = -0.0004;
  key.shadow.normalBias = 0.02;
  key.shadow.radius = 9;
  key.shadow.blurSamples = 20;
  const rim = new DirectionalLight(0x8fb8ff, 0.6);
  rim.position.set(4, 1.5, -3);
  scene.add(key, key.target, rim);

  const camera = new PerspectiveCamera(FOV, 1, 0.1, 60);
  camera.position.z = DISTANCE;

  const root = new Group();
  scene.add(root);

  const brushed = brushedTexture();
  const steel = new MeshPhysicalMaterial({
    color: new Color('#8d8880'),
    metalness: 1,
    roughness: 0.44,
    roughnessMap: brushed,
    bumpMap: brushed,
    bumpScale: 0.05,
    anisotropy: 0.75,
  });
  // Рамка: ось с остриями, вертикальное и горизонтальное кольца. Прецессирует целиком.
  const frame = new Group();
  root.add(frame);
  const axle = new Mesh(
    lathe(
      [
        [0, -AXLE],
        [0.05, -AXLE + 0.17],
        [0.05, -AXLE + 0.2],
        [0.026, -AXLE + 0.22],
        [0.026, -0.42],
        [0.05, -0.4],
        [0.05, -0.12],
        [0.075, -0.1],
        [0.075, 0.1],
        [0.05, 0.12],
        [0.05, 0.4],
        [0.026, 0.42],
        [0.026, AXLE - 0.26],
        [0.045, AXLE - 0.24],
        [0.058, AXLE - 0.17],
        [0, AXLE],
      ],
      48,
    ),
    steel,
  );
  const hoop = new Mesh(new TorusGeometry(RING, 0.03, 24, 160), steel);
  const belt = new Mesh(new TorusGeometry(RING, 0.036, 24, 160), steel);
  belt.rotation.x = Math.PI / 2;
  frame.add(axle, hoop, belt);
  // Узлы рамки: втулки там, где кольцо держит ось, и шарики на стыке колец.
  const collar = lathe(
    [
      [0.03, -0.07],
      [0.07, -0.055],
      [0.078, -0.02],
      [0.078, 0.02],
      [0.07, 0.055],
      [0.03, 0.07],
    ],
    40,
  );
  const joint = new SphereGeometry(0.05, 32, 24);
  for (const side of [-1, 1]) {
    const c = new Mesh(collar, steel);
    c.position.y = side * RING;
    const j = new Mesh(joint, steel);
    j.position.x = side * RING;
    frame.add(c, j);
  }

  // Маховик: ступица, тонкий диск со спицами и тяжёлый обод.
  const wheel = new Group();
  frame.add(wheel);
  wheel.add(
    new Mesh(
      lathe([
        [0.075, 0.075],
        [0.14, 0.075],
        [0.17, 0.03],
        [0.2, 0.02],
        [0.5, 0.02],
        [0.52, 0.055],
        [0.555, 0.055],
        [0.56, 0.042],
        [0.575, 0.042],
        [0.58, 0.055],
        [WHEEL - 0.02, 0.055],
        [WHEEL, 0.035],
        [WHEEL, 0.012],
        [WHEEL - 0.012, 0.006],
        [WHEEL - 0.012, -0.006],
        [WHEEL, -0.012],
        [WHEEL, -0.035],
        [WHEEL - 0.02, -0.055],
        [0.52, -0.055],
        [0.5, -0.02],
        [0.2, -0.02],
        [0.17, -0.03],
        [0.14, -0.075],
        [0.075, -0.075],
      ]),
      steel,
    ),
  );
  // Восемь тонких спиц, выдавленных на диске: по ним видно, что маховик крутится.
  const spoke = new BoxGeometry(0.31, 0.012, 0.02);
  for (let i = 0; i < 8; i++) {
    const a = (i / 8) * Math.PI * 2;
    for (const side of [-1, 1]) {
      const sp = new Mesh(spoke, steel);
      sp.position.set(Math.cos(a) * 0.345, side * 0.022, Math.sin(a) * 0.345);
      sp.rotation.y = -a;
      wheel.add(sp);
    }
  }

  // Нить провисает параболой; точка под остриём — её начало координат, вокруг него она и качается.
  const ropeMap = ropeTexture();
  const ropeFade = fadeTexture();
  const rope = new Mesh(
    new TubeGeometry(
      new QuadraticBezierCurve3(new Vector3(-ROPE.half, ROPE.sag, 0), new Vector3(0, -ROPE.sag, 0), new Vector3(ROPE.half, ROPE.sag, 0)),
      200,
      ROPE.radius,
      10,
    ),
    new MeshStandardMaterial({
      map: ropeMap,
      alphaMap: ropeFade,
      transparent: true,
      roughness: 0.5,
      metalness: 0,
      emissive: new Color('#ff2a1a'),
      emissiveMap: ropeMap,
      emissiveIntensity: 0.4,
    }),
  );
  const ropePivot = new Group();
  ropePivot.position.y = -AXLE - ROPE.radius;
  ropePivot.add(rope);
  root.add(ropePivot);
  frame.traverse((o) => {
    if (o instanceof Mesh) o.castShadow = o.receiveShadow = true;
  });
  rope.castShadow = true;

  // «Пол» невидим, на нём остаётся только мягкая тень гироскопа и нити.
  const floor = new Mesh(new PlaneGeometry(16, 10), new ShadowMaterial({ color: 0x000a18, opacity: 0.26 }));
  floor.rotation.x = -Math.PI / 2;
  floor.position.y = -AXLE - 0.62;
  floor.receiveShadow = true;
  root.add(floor);

  const glow = glowTexture();
  const halo = new Sprite(new SpriteMaterial({ map: glow, color: 0xd6e4ff, opacity: 0.1, depthWrite: false }));
  halo.position.set(0.1, 0.1, -1.4);
  halo.scale.setScalar(5.2);
  root.add(halo);

  // Тлеющая точка там, где остриё касается нити.
  const spark = new Sprite(new SpriteMaterial({ map: glow, color: 0xff4a30, opacity: 0.5, depthWrite: false }));
  spark.position.set(0, -AXLE - 0.02, -0.08);
  spark.scale.setScalar(0.34);
  root.add(spark);

  const bokeh = new Group();
  scene.add(bokeh);
  const lights = Array.from({ length: BOKEH.count }, (_, i) => {
    // Глубина от 0 (далеко) до 1 (близко): ближние крупнее, прозрачнее и быстрее.
    const depth = Math.random();
    const warm = i % 5 === 0;
    const sprite = new Sprite(
      new SpriteMaterial({
        map: glow,
        color: warm ? 0xff6a55 : 0xcfe0ff,
        opacity: 0.08 + (1 - depth) * 0.2,
        depthWrite: false,
      }),
    );
    sprite.scale.setScalar(0.07 + depth * 0.42);
    const y = (Math.random() - 0.35) * 3.4;
    sprite.position.set((Math.random() - 0.5) * BOKEH.spanX, y, -3 + depth * 4.5);
    bokeh.add(sprite);
    return { sprite, speed: BOKEH.speed * (0.35 + depth * 1.6), phase: Math.random() * 6.28, y };
  });

  let anchorX = ANCHOR.x;
  function layout() {
    const w = host.clientWidth;
    const h = host.clientHeight;
    if (w === 0 || h === 0) return;
    renderer.setSize(w, h, false);
    camera.aspect = w / h;
    camera.updateProjectionMatrix();
    const visH = 2 * DISTANCE * Math.tan((FOV * Math.PI) / 360);
    const visW = visH * camera.aspect;
    const unitsPerPx = visH / h;
    const clear = Math.min(h, Math.max(0, clearHeight()));
    anchorX = clear < TIGHT.below ? TIGHT.x : ANCHOR.x;
    root.position.set((anchorX - 0.5) * visW, (0.5 - (clear * ANCHOR.centerY) / h) * visH, 0);
    root.scale.setScalar((clear * ANCHOR.height * unitsPerPx) / (AXLE * 2));
    bokeh.position.copy(root.position);
    bokeh.scale.copy(root.scale);
    key.position.set(root.position.x - 2.4, root.position.y + 5, 3.6);
    key.target.position.copy(root.position);
  }

  // Указатель чуть поворачивает сцену, как будто зритель заглядывает сбоку.
  const target = { x: 0, y: 0 };
  const look = { x: 0, y: 0 };
  function onPointer(e: PointerEvent) {
    target.x = (e.clientX / window.innerWidth - 0.5) * 2;
    target.y = (e.clientY / window.innerHeight - 0.5) * 2;
  }

  /** Поза кадра: t — секунды от начала, appear — появление (0…1). */
  function pose(t: number, appear: number, dtPose = 0) {
    const k = 1 - Math.pow(1 - appear, 3);
    root.rotation.set(0.44 + look.y * 0.08, look.x * 0.22, 0);
    // Нить всегда поднимается вправо, но наклон гуляет: гироскоп проезжает то пологий, то крутой участок.
    const slope = 0.2 + Math.sin(t * 0.31) * 0.09 + Math.sin(t * 0.83) * 0.025;
    ropePivot.rotation.z = slope;
    ropePivot.rotation.y = -0.2;
    ropeMap.offset.x = t * 2.4;
    // Гироскоп держит вертикаль: только лёгкая прецессия оси и дрожь от нити.
    frame.rotation.set(Math.sin(t * 1.3) * 0.022, 0.9 + t * 0.22, Math.cos(t * 1.3) * 0.022 + (1 - k) * 0.5);
    frame.position.y = Math.sin(t * 2.1) * 0.006;
    wheel.rotation.y = -t * 9;
    spark.material.opacity = 0.42 + Math.sin(t * 3.1) * 0.1;
    for (const l of lights) {
      const x = ((l.sprite.position.x - l.speed * dtPose + BOKEH.spanX * 1.5) % BOKEH.spanX) - BOKEH.spanX / 2;
      l.sprite.position.x = x;
      l.sprite.position.y = l.y + Math.sin(t * 0.4 + l.phase) * 0.06;
    }
    root.position.z = (1 - k) * -3;
  }

  let frameId = 0;
  let last = performance.now();
  let t = 0;
  function draw(now: number) {
    // Долгую паузу (вкладка была скрыта) не превращаем в рывок.
    const dt = Math.min(0.25, (now - last) / 1000);
    last = now;
    t += dt;
    look.x += (target.x - look.x) * Math.min(1, dt * 3);
    look.y += (target.y - look.y) * Math.min(1, dt * 3);
    pose(t, Math.min(1, t / 1.6), dt);
    renderer.render(scene, camera);
    frameId = requestAnimationFrame(draw);
  }

  function start() {
    if (frameId || still) return;
    last = performance.now();
    frameId = requestAnimationFrame(draw);
  }
  function stop() {
    cancelAnimationFrame(frameId);
    frameId = 0;
  }
  const onVisibility = () => (document.hidden ? stop() : start());

  const resize = new ResizeObserver(() => {
    layout();
    if (still) {
      pose(0, 1);
      renderer.render(scene, camera);
    }
  });
  resize.observe(host);
  layout();
  pose(0, still ? 1 : 0);
  renderer.render(scene, camera);
  if (!still) {
    window.addEventListener('pointermove', onPointer, { passive: true });
    document.addEventListener('visibilitychange', onVisibility);
    start();
  }

  return () => {
    stop();
    resize.disconnect();
    window.removeEventListener('pointermove', onPointer);
    document.removeEventListener('visibilitychange', onVisibility);
    scene.traverse((o) => {
      if (o instanceof Mesh) {
        o.geometry.dispose();
        (Array.isArray(o.material) ? o.material : [o.material]).forEach((m) => m.dispose());
      }
    });
    scene.traverse((o) => {
      if (o instanceof Sprite) o.material.dispose();
    });
    [brushed, ropeMap, ropeFade, glow].forEach((x) => x.dispose());
    key.shadow.dispose();
    env.dispose();
    pmrem.dispose();
    renderer.dispose();
    canvas.remove();
  };
}
