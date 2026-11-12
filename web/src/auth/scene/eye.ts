import {
  ACESFilmicToneMapping,
  Color,
  DirectionalLight,
  ExtrudeGeometry,
  Group,
  InstancedMesh,
  Mesh,
  MeshPhysicalMaterial,
  MeshStandardMaterial,
  Object3D,
  PerspectiveCamera,
  PMREMGenerator,
  Scene,
  Shape,
  SphereGeometry,
  Vector3,
  WebGLRenderer,
} from 'three';
import { RoomEnvironment } from 'three/examples/jsm/environments/RoomEnvironment.js';

/** Фигура стоит в свободном месте над текстом: центр по ширине панели и доля этого места под диаметр. */
const ANCHOR = { x: 0.54, width: 0.8, height: 0.84, shiftDown: 26 };
/** На низком экране места над текстом мало, фигура встаёт вровень с логотипом — сдвигаем её вправо от него. */
const TIGHT = { below: 360, x: 0.68 };
const FOV = 32;
const DISTANCE = 7;
/** Внешний радиус фигуры в единицах сцены вместе с орбитой точек. */
const EXTENT = 1.5;

/** Пропорции знака из логотипа, внешний радиус дуг принят за единицу. */
const MARK = { outer: 1, inner: 0.63, gap: 0.185, depth: 0.3, pupil: 0.37, glint: 0.125 };

const DOTS = 44;
const ORBIT = 1.42;

/** Половина знака: дуга кольца над горизонтальной прорезью. Нижняя половина — она же, перевёрнутая. */
function lidGeometry() {
  const a0 = Math.asin(MARK.gap / MARK.outer);
  const a1 = Math.asin(MARK.gap / MARK.inner);
  const shape = new Shape();
  shape.absarc(0, 0, MARK.outer, a0, Math.PI - a0, false);
  shape.absarc(0, 0, MARK.inner, Math.PI - a1, a1, true);
  shape.closePath();
  const geometry = new ExtrudeGeometry(shape, {
    depth: MARK.depth,
    curveSegments: 96,
    bevelEnabled: true,
    bevelSize: 0.05,
    bevelThickness: 0.05,
    bevelSegments: 8,
  });
  geometry.translate(0, 0, -MARK.depth / 2);
  return geometry;
}

const easeOut = (x: number) => 1 - Math.pow(1 - x, 3);

/**
 * Знак «Модус Трейд» в объёме: две дуги и красный зрачок с бликом. Глаз поворачивается за указателем,
 * блик смотрит туда же, время от времени дуги сходятся — глаз щурится. Вокруг орбита точек, как на табло.
 * Чисто декоративно, для диктора скрыто. `clearHeight` — сколько пикселей сверху свободно от текста.
 * Возвращает функцию, которая останавливает отрисовку и освобождает память видеокарты.
 */
export function mountEye(host: HTMLElement, still: boolean, clearHeight: () => number): () => void {
  const renderer = new WebGLRenderer({ antialias: true, alpha: true, powerPreference: 'low-power' });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.toneMapping = ACESFilmicToneMapping;
  renderer.toneMappingExposure = 0.92;
  const canvas = renderer.domElement;
  canvas.setAttribute('aria-hidden', 'true');
  host.appendChild(canvas);

  const scene = new Scene();
  const pmrem = new PMREMGenerator(renderer);
  const env = pmrem.fromScene(new RoomEnvironment(), 0.04);
  scene.environment = env.texture;
  const key = new DirectionalLight(0xffffff, 0.7);
  key.position.set(-2.5, 3, 4);
  scene.add(key);

  const camera = new PerspectiveCamera(FOV, 1, 0.1, 50);
  camera.position.z = DISTANCE;

  const root = new Group();
  scene.add(root);
  const eye = new Group();
  root.add(eye);

  const ceramic = new MeshPhysicalMaterial({ color: new Color('#dbe4f0'), metalness: 0, roughness: 0.34, clearcoat: 1, clearcoatRoughness: 0.12 });
  const lid = lidGeometry();
  const upper = new Mesh(lid, ceramic);
  const lower = new Mesh(lid, ceramic);
  lower.rotation.z = Math.PI;
  eye.add(upper, lower);

  const pupil = new Mesh(
    new SphereGeometry(MARK.pupil, 64, 64),
    new MeshPhysicalMaterial({ color: new Color('#e40000'), metalness: 0.05, roughness: 0.2, clearcoat: 1, clearcoatRoughness: 0.06 }),
  );
  const glint = new Mesh(new SphereGeometry(MARK.glint, 32, 32), new MeshStandardMaterial({ color: new Color('#ffffff'), roughness: 0.25 }));
  eye.add(pupil, glint);

  const orbit = new Group();
  orbit.rotation.set(1.2, 0.1, 0.3);
  const dots = new InstancedMesh(new SphereGeometry(0.024, 12, 12), new MeshStandardMaterial({ color: new Color('#ffffff'), roughness: 0.4 }), DOTS);
  const dummy = new Object3D();
  for (let i = 0; i < DOTS; i++) {
    const a = (i / DOTS) * Math.PI * 2;
    dummy.position.set(Math.cos(a) * ORBIT, Math.sin(a) * ORBIT, 0);
    dummy.updateMatrix();
    dots.setMatrixAt(i, dummy.matrix);
  }
  orbit.add(dots);
  root.add(orbit);

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
    const diameter = Math.min(w * ANCHOR.width, clear * ANCHOR.height);
    const centerY = clear / 2 + ANCHOR.shiftDown;
    anchorX = clear < TIGHT.below ? TIGHT.x : ANCHOR.x;
    root.position.set((anchorX - 0.5) * visW, (0.5 - centerY / h) * visH, 0);
    baseScale = (diameter * unitsPerPx) / (EXTENT * 2);
  }
  let baseScale = 1;
  let anchorX = ANCHOR.x;

  // Куда смотрит глаз: цель задаёт указатель относительно центра фигуры, кадр догоняет её плавно.
  const target = { x: 0, y: 0 };
  const look = { x: 0, y: 0 };
  function onPointer(e: PointerEvent) {
    const box = host.getBoundingClientRect();
    const cx = box.left + box.width * anchorX;
    const cy = box.top + Math.min(box.height, clearHeight()) / 2;
    const reach = Math.max(window.innerWidth, window.innerHeight) * 0.5;
    target.x = Math.max(-1, Math.min(1, (e.clientX - cx) / reach));
    target.y = Math.max(-1, Math.min(1, (e.clientY - cy) / reach));
  }

  const gaze = new Vector3();
  /** Поза кадра: t — секунды от начала, squint — насколько прищурен (0…1), appear — появление (0…1). */
  function pose(t: number, squint: number, appear: number) {
    const k = easeOut(appear);
    root.scale.setScalar(baseScale * (0.72 + 0.28 * k));
    root.rotation.set(0.1 + Math.sin(t * 0.5) * 0.03, -0.3 + Math.sin(t * 0.37) * 0.05 + (1 - k) * -1.6, 0);
    root.position.z = Math.sin(t * 0.8) * 0.04;
    eye.rotation.set(look.y * 0.5, look.x * 0.75, 0);
    const shut = squint * (MARK.gap - 0.03);
    upper.position.y = -shut;
    lower.position.y = shut;
    // Блик в покое стоит справа сверху, как в логотипе, и смещается туда же, куда смотрит глаз.
    gaze.set(0.42 + look.x * 0.38, 0.42 - look.y * 0.38, 1).normalize().multiplyScalar(MARK.pupil * 0.86);
    glint.position.copy(gaze);
    orbit.rotation.z = t * 0.14;
  }

  let frame = 0;
  let last = performance.now();
  let t = 0;
  let nextSquint = 3.5;
  function draw(now: number) {
    const dt = Math.min(0.05, (now - last) / 1000);
    last = now;
    t += dt;
    look.x += (target.x - look.x) * Math.min(1, dt * 4);
    look.y += (target.y - look.y) * Math.min(1, dt * 4);
    // Прищур длится 0.45 с: дуги сходятся и расходятся по синусу.
    const since = t - nextSquint;
    let squint = 0;
    if (since >= 0) {
      if (since < 0.45) squint = Math.sin((since / 0.45) * Math.PI);
      else nextSquint = t + 4 + Math.random() * 4;
    }
    pose(t, squint, Math.min(1, t / 1.4));
    renderer.render(scene, camera);
    frame = requestAnimationFrame(draw);
  }

  function start() {
    if (frame || still) return;
    last = performance.now();
    frame = requestAnimationFrame(draw);
  }
  function stop() {
    cancelAnimationFrame(frame);
    frame = 0;
  }
  const onVisibility = () => (document.hidden ? stop() : start());

  const resize = new ResizeObserver(() => {
    layout();
    if (still) {
      pose(0, 0, 1);
      renderer.render(scene, camera);
    }
  });
  resize.observe(host);
  layout();
  pose(0, 0, still ? 1 : 0);
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
    env.dispose();
    pmrem.dispose();
    renderer.dispose();
    canvas.remove();
  };
}
