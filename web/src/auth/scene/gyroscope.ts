import {
  ACESFilmicToneMapping,
  CanvasTexture,
  Color,
  BoxGeometry,
  DirectionalLight,
  Group,
  LatheGeometry,
  Mesh,
  MeshPhysicalMaterial,
  MeshStandardMaterial,
  PerspectiveCamera,
  PMREMGenerator,
  QuadraticBezierCurve3,
  RepeatWrapping,
  Scene,
  SRGBColorSpace,
  Texture,
  TorusGeometry,
  TubeGeometry,
  Vector2,
  Vector3,
  WebGLRenderer,
} from 'three';
import { RoomEnvironment } from 'three/examples/jsm/environments/RoomEnvironment.js';

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

/** Тело вращения по контуру «радиус, высота». */
const lathe = (profile: [number, number][], segments = 96) => new LatheGeometry(profile.map(([r, y]) => new Vector2(r, y)), segments);

/**
 * Игрушечный гироскоп из шлифованной стали едет по красной нити. Сам он стоит на месте кадра — камера как будто
 * едет рядом с той же скоростью, — а движение видно по нити: бегут витки, меняется её наклон под остриём.
 * Маховик крутится, рамка медленно прецессирует, указатель чуть поворачивает сцену.
 * Чисто декоративно, для диктора скрыто. `clearHeight` — сколько пикселей сверху свободно от текста.
 * Возвращает функцию, которая останавливает отрисовку и освобождает память видеокарты.
 */
export function mountGyroscope(host: HTMLElement, still: boolean, clearHeight: () => number): () => void {
  const renderer = new WebGLRenderer({ antialias: true, alpha: true, powerPreference: 'low-power' });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.toneMapping = ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.0;
  const canvas = renderer.domElement;
  canvas.setAttribute('aria-hidden', 'true');
  host.appendChild(canvas);

  const scene = new Scene();
  const pmrem = new PMREMGenerator(renderer);
  const env = pmrem.fromScene(new RoomEnvironment(), 0.06);
  scene.environment = env.texture;
  scene.environmentIntensity = 0.75;
  const key = new DirectionalLight(0xfff4e6, 1.4);
  key.position.set(-3, 4, 5);
  const rim = new DirectionalLight(0x9fc4ff, 0.9);
  rim.position.set(4, 1.5, -3);
  scene.add(key, rim);

  const camera = new PerspectiveCamera(FOV, 1, 0.1, 60);
  camera.position.z = DISTANCE;

  const root = new Group();
  scene.add(root);

  const brushed = brushedTexture();
  const steel = new MeshPhysicalMaterial({
    color: new Color('#8f8a83'),
    metalness: 1,
    roughness: 0.46,
    roughnessMap: brushed,
    bumpMap: brushed,
    bumpScale: 0.35,
    anisotropy: 0.55,
    clearcoat: 0.25,
    clearcoatRoughness: 0.5,
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

  // Маховик: ступица, тонкий диск со спицами и тяжёлый обод.
  const wheel = new Group();
  frame.add(wheel);
  wheel.add(
    new Mesh(
      lathe([
        [0.075, 0.075],
        [0.14, 0.075],
        [0.17, 0.03],
        [0.5, 0.02],
        [0.53, 0.05],
        [WHEEL - 0.02, 0.05],
        [WHEEL, 0.03],
        [WHEEL, -0.03],
        [WHEEL - 0.02, -0.05],
        [0.53, -0.05],
        [0.5, -0.02],
        [0.17, -0.03],
        [0.14, -0.075],
        [0.075, -0.075],
      ]),
      steel,
    ),
  );
  const spoke = new BoxGeometry(0.34, 0.016, 0.022);
  for (let i = 0; i < 8; i++) {
    const s = new Mesh(spoke, steel);
    const a = (i / 8) * Math.PI * 2;
    s.position.set(Math.cos(a) * 0.335, 0.026, Math.sin(a) * 0.335);
    s.rotation.y = -a;
    wheel.add(s);
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
    new MeshStandardMaterial({ map: ropeMap, alphaMap: ropeFade, transparent: true, roughness: 0.62, metalness: 0 }),
  );
  const ropePivot = new Group();
  ropePivot.position.y = -AXLE - ROPE.radius;
  ropePivot.add(rope);
  root.add(ropePivot);

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
  }

  // Указатель чуть поворачивает сцену, как будто зритель заглядывает сбоку.
  const target = { x: 0, y: 0 };
  const look = { x: 0, y: 0 };
  function onPointer(e: PointerEvent) {
    target.x = (e.clientX / window.innerWidth - 0.5) * 2;
    target.y = (e.clientY / window.innerHeight - 0.5) * 2;
  }

  /** Поза кадра: t — секунды от начала, appear — появление (0…1). */
  function pose(t: number, appear: number) {
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
    pose(t, Math.min(1, t / 1.6));
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
    [brushed, ropeMap, ropeFade].forEach((x) => x.dispose());
    env.dispose();
    pmrem.dispose();
    renderer.dispose();
    canvas.remove();
  };
}
