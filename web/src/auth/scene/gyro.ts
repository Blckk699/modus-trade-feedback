import {
  ACESFilmicToneMapping,
  Color,
  Group,
  InstancedMesh,
  Mesh,
  MeshPhysicalMaterial,
  MeshStandardMaterial,
  Object3D,
  PerspectiveCamera,
  PMREMGenerator,
  Scene,
  SphereGeometry,
  TorusGeometry,
  WebGLRenderer,
} from 'three';
import { RoomEnvironment } from 'three/examples/jsm/environments/RoomEnvironment.js';

/** Где на панели стоит объект (доли ширины и высоты) и какую часть меньшей стороны занимает. */
const ANCHOR = { x: 0.56, y: 0.41, size: 0.8 };
const FOV = 32;
const DISTANCE = 7;
/** Внешний радиус фигуры в единицах сцены вместе с орбитой точек. */
const EXTENT = 1.42;

/** Кольца: радиус, толщина, ось и скорость вращения (рад/с). */
const RINGS = [
  { r: 1.18, tube: 0.05, axis: 'x', speed: 0.21, tilt: 0.5 },
  { r: 0.93, tube: 0.056, axis: 'y', speed: -0.29, tilt: 1.1 },
  { r: 0.68, tube: 0.062, axis: 'x', speed: 0.38, tilt: 2.0 },
] as const;

const DOTS = 36;

/**
 * Декоративный гироскоп на экране входа: три кольца вокруг красного ядра и орбита точек —
 * тот же точечный мотив, что в цифрах-табло. Смысла не несёт, поэтому для диктора скрыт.
 * Возвращает функцию, которая останавливает отрисовку и освобождает память видеокарты.
 */
export function mountGyro(host: HTMLElement, still: boolean): () => void {
  const renderer = new WebGLRenderer({ antialias: true, alpha: true, powerPreference: 'low-power' });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.toneMapping = ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.1;
  const canvas = renderer.domElement;
  canvas.setAttribute('aria-hidden', 'true');
  host.appendChild(canvas);

  const scene = new Scene();
  const pmrem = new PMREMGenerator(renderer);
  const env = pmrem.fromScene(new RoomEnvironment(), 0.04);
  scene.environment = env.texture;

  const camera = new PerspectiveCamera(FOV, 1, 0.1, 50);
  camera.position.z = DISTANCE;

  const root = new Group();
  scene.add(root);

  const steel = new MeshPhysicalMaterial({ color: new Color('#dfe9f7'), metalness: 1, roughness: 0.16, clearcoat: 1, clearcoatRoughness: 0.2 });
  const rings = RINGS.map((cfg) => {
    const pivot = new Group();
    pivot.rotation.set(cfg.tilt, cfg.tilt * 0.6, 0);
    pivot.add(new Mesh(new TorusGeometry(cfg.r, cfg.tube, 24, 160), steel));
    root.add(pivot);
    return { pivot, cfg };
  });

  const core = new Mesh(
    new SphereGeometry(0.3, 48, 48),
    new MeshPhysicalMaterial({ color: new Color('#e40000'), metalness: 0.1, roughness: 0.22, clearcoat: 1, clearcoatRoughness: 0.08 }),
  );
  root.add(core);

  const orbit = new Group();
  orbit.rotation.set(1.25, 0, 0.35);
  const dots = new InstancedMesh(new SphereGeometry(0.026, 12, 12), new MeshStandardMaterial({ color: new Color('#ffffff'), metalness: 0.2, roughness: 0.35 }), DOTS);
  const dummy = new Object3D();
  for (let i = 0; i < DOTS; i++) {
    const a = (i / DOTS) * Math.PI * 2;
    dummy.position.set(Math.cos(a) * 1.4, Math.sin(a) * 1.4, 0);
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
    root.position.set((ANCHOR.x - 0.5) * visW, (0.5 - ANCHOR.y) * visH, 0);
    root.scale.setScalar((Math.min(w, h) * ANCHOR.size * unitsPerPx) / (EXTENT * 2));
  }

  // Указатель чуть наклоняет фигуру: цель задаёт событие, кадр догоняет её плавно.
  const target = { x: 0, y: 0 };
  const lean = { x: 0, y: 0 };
  function onPointer(e: PointerEvent) {
    target.x = (e.clientX / window.innerWidth - 0.5) * 2;
    target.y = (e.clientY / window.innerHeight - 0.5) * 2;
  }

  let frame = 0;
  let last = performance.now();
  let t = 0;
  function draw(now: number) {
    const dt = Math.min(0.05, (now - last) / 1000);
    last = now;
    t += dt;
    for (const { pivot, cfg } of rings) {
      if (cfg.axis === 'x') pivot.rotation.x += cfg.speed * dt;
      else pivot.rotation.y += cfg.speed * dt;
    }
    orbit.rotation.z += 0.12 * dt;
    lean.x += (target.x - lean.x) * Math.min(1, dt * 3);
    lean.y += (target.y - lean.y) * Math.min(1, dt * 3);
    root.rotation.set(0.28 + lean.y * 0.22, -0.42 + lean.x * 0.34 + t * 0.05, 0);
    core.position.y = Math.sin(t * 0.9) * 0.03;
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
    if (still) renderer.render(scene, camera);
  });
  resize.observe(host);
  layout();
  root.rotation.set(0.28, -0.42, 0);
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
