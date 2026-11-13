import {
  ACESFilmicToneMapping,
  BackSide,
  CanvasTexture,
  Color,
  CylinderGeometry,
  DirectionalLight,
  Group,
  LatheGeometry,
  Mesh,
  MeshBasicMaterial,
  MeshPhysicalMaterial,
  PerspectiveCamera,
  PlaneGeometry,
  PMREMGenerator,
  PointLight,
  Quaternion,
  RepeatWrapping,
  Scene,
  ShaderMaterial,
  SphereGeometry,
  Texture,
  Vector2,
  Vector3,
  WebGLRenderer,
} from 'three';

/**
 * Где стоит общий центр колец (доли ширины панели и свободной высоты над текстом) и радиус большого кольца
 * в долях ширины. Центр у правого края: в кадре остаётся часть колец, остальное обрезает панель.
 */
const ANCHOR = { x: 0.8, y: 0.52, radius: 0.62 };
const FOV = 30;
const DISTANCE = 8;
/** Радиус большого кольца в единицах сцены; остальные размеры — от него. */
const R = 2;

/**
 * Луч: направление (слева из глубины — вправо на зрителя), половина длины, радиус свечения.
 * Проходит через общий центр колец. glint — сила красного отсвета на кольцах.
 */
const BEAM = { dir: new Vector3(0.74, 0.2, 0.64).normalize(), half: 7, radius: 0.12, glint: 4.5 };
/** Импульс бежит по лучу: где он сейчас, в долях половины длины (0 — центр колец). */
const pulseAt = (t: number) => ((t * 0.085) % 1) * 2.8 - 1.5;

/**
 * Кольца качаются вокруг луча: ось каждого описывает конус вокруг него. Угол конуса меньше прямого,
 * поэтому луч всегда проходит в отверстие и не задевает металл.
 * radius — средний радиус, width и depth — половины ширины полки и толщины, cone — угол конуса,
 * speed — скорость обхода конуса (рад/с, знак — направление), phase — начальный угол.
 */
const RINGS = [
  { radius: R, width: 0.2, depth: 0.075, cone: 0.3, speed: 0.11, phase: 0.4, polished: false },
  { radius: R * 0.69, width: 0.115, depth: 0.1, cone: 0.62, speed: -0.17, phase: 2.2, polished: true },
  { radius: R * 0.46, width: 0.15, depth: 0.055, cone: 0.9, speed: 0.23, phase: 4.4, polished: false },
];

/**
 * Шлифованный металл: карта шероховатости из тонких волосяных линий вдоль окружности кольца, как после
 * токарного станка. Каждая строка текстуры — одна линия, её яркость медленно меняется по длине. Короткие
 * штрихи с резкими концами на большой детали складываются в «кирпичики», поэтому линии непрерывные.
 */
function brushedTexture(sharpness: number): Texture {
  const c = document.createElement('canvas');
  c.width = 256;
  c.height = 512;
  const g = c.getContext('2d')!;
  const tone = () => {
    const v = 135 + Math.floor(Math.random() * 120);
    return `rgb(${v},${v},${v})`;
  };
  for (let y = 0; y < c.height; y++) {
    // Края строки одного тона: текстура стыкуется по кругу без шва.
    const edge = tone();
    const line = g.createLinearGradient(0, 0, c.width, 0);
    line.addColorStop(0, edge);
    line.addColorStop(0.33, tone());
    line.addColorStop(0.66, tone());
    line.addColorStop(1, edge);
    g.fillStyle = line;
    g.fillRect(0, y, c.width, 1);
  }
  const t = new CanvasTexture(c);
  t.wrapS = t.wrapT = RepeatWrapping;
  t.repeat.set(4, 1);
  t.anisotropy = sharpness;
  return t;
}

/**
 * Луч света: цилиндр, который к краям силуэта растворяется, а по оси горит почти белым.
 * Рисуется обычной прозрачностью: сложение цветов на прозрачном холсте Safari показывает серым.
 * По лучу бежит лёгкая рябь и раз в несколько секунд проходит яркий импульс.
 */
function beamMaterial(): ShaderMaterial {
  return new ShaderMaterial({
    transparent: true,
    depthWrite: false,
    uniforms: { uTime: { value: 0 }, uPulse: { value: -2 }, uHalf: { value: BEAM.half } },
    vertexShader: /* glsl */ `
      uniform float uHalf;
      varying vec3 vNormal;
      varying vec3 vView;
      varying vec3 vAxis;
      varying float vAlong;
      void main() {
        vec4 mv = modelViewMatrix * vec4(position, 1.0);
        vNormal = normalMatrix * normal;
        vAxis = normalMatrix * vec3(0.0, 1.0, 0.0);
        vView = -mv.xyz;
        vAlong = position.y / uHalf;
        gl_Position = projectionMatrix * mv;
      }
    `,
    fragmentShader: /* glsl */ `
      uniform float uTime;
      uniform float uPulse;
      varying vec3 vNormal;
      varying vec3 vView;
      varying vec3 vAxis;
      varying float vAlong;
      void main() {
        // Смотрим на луч «сбоку»: из направления взгляда убираем составляющую вдоль оси.
        vec3 axis = normalize(vAxis);
        vec3 view = normalize(vView);
        vec3 across = normalize(view - dot(view, axis) * axis);
        float facing = clamp(dot(normalize(vNormal), across), 0.0, 1.0);
        float glow = pow(facing, 5.0);
        float core = smoothstep(0.99, 0.9995, facing);
        float ripple = 0.84 + 0.16 * sin(vAlong * 38.0 - uTime * 2.6) * sin(vAlong * 11.0 - uTime * 1.1);
        float pulse = exp(-pow((vAlong - uPulse) * 6.0, 2.0));
        // Дальний конец растворяется в глубине.
        float fade = smoothstep(-1.0, -0.45, vAlong);
        float alpha = (glow * (0.3 * ripple + 0.45 * pulse) + core) * fade;
        vec3 color = mix(vec3(1.0, 0.17, 0.09), vec3(1.0, 0.94, 0.9), clamp(core + pulse * glow * 0.5, 0.0, 1.0));
        gl_FragColor = vec4(color, clamp(alpha, 0.0, 1.0));
      }
    `,
  });
}

/**
 * Студия для отражений: тёмный серый зал и несколько светящихся панелей. Металл выглядит металлом,
 * когда в нём отражается контраст — яркие софтбоксы на тёмном, а не ровно светлая комната.
 * Полки колец смотрят вдоль луча и отражают то, что справа от зрителя, поэтому главный софтбокс там.
 */
function studio(): Scene {
  const room = new Scene();
  room.add(new Mesh(new SphereGeometry(20, 32, 16), new MeshBasicMaterial({ color: new Color('#2b2d31'), side: BackSide })));
  const panel = (w: number, h: number, power: number, tint: string, pos: [number, number, number]) => {
    const m = new Mesh(new PlaneGeometry(w, h), new MeshBasicMaterial({ color: new Color(tint).multiplyScalar(power) }));
    m.position.set(...pos);
    m.lookAt(0, 0, 0);
    room.add(m);
  };
  panel(9, 13, 4.2, '#fff4e6', [12, 4.5, -1.5]); // главный софтбокс справа: его отражают полки колец
  panel(14, 8, 8, '#fff3e2', [-4, 10, 6]); // большой верхний, тёплый
  panel(3, 14, 7, '#ffffff', [-11, 1, 4]); // узкая вертикальная полоса слева
  panel(5, 5, 4, '#b9d0f5', [7, -5, -8]); // холодный акцент справа снизу сзади
  panel(16, 6, 1.6, '#9aa3ad', [0, -9, 5]); // слабый отсвет снизу
  panel(6, 3, 6, '#ffffff', [3, 6, 10]); // небольшой блик спереди
  return room;
}

/**
 * Кольцо как точёная деталь: плоские полки, фаски по кромкам и тонкая проточка на каждой полке.
 * Контур сечения обходит кольцо по кругу: радиус от оси, высота вдоль оси.
 */
function ringGeometry(radius: number, width: number, depth: number): LatheGeometry {
  const bevel = Math.min(width, depth) * 0.32;
  const groove = { at: width * 0.42, half: width * 0.05, deep: depth * 0.22 };
  const half: [number, number][] = [
    [-width, depth - bevel],
    [-width + bevel, depth],
    [-groove.at - groove.half, depth],
    [-groove.at - groove.half * 0.4, depth - groove.deep],
    [-groove.at + groove.half * 0.4, depth - groove.deep],
    [-groove.at + groove.half, depth],
    [width - bevel, depth],
    [width, depth - bevel],
  ];
  // Верхняя полка, затем она же зеркально снизу — контур замыкается. Обходим его против часовой стрелки
  // (наружная стенка снизу вверх): иначе нормали смотрят внутрь и кольцо рисуется вывернутым, «полым».
  const outline = [...half, ...half.map(([x, y]) => [x, -y] as [number, number]).reverse(), half[0]].reverse();
  const points = outline.map(([x, y]) => new Vector2(radius + x, y));
  const g = new LatheGeometry(points, 300);
  // Тело вращения делит текстуру поровну между отрезками контура: на широкой полке штрихи шлифовки
  // растягиваются в квадраты. Раскладываем её по длине контура.
  const along = [0];
  for (let i = 1; i < points.length; i++) along.push(along[i - 1] + points[i].distanceTo(points[i - 1]));
  const uv = g.getAttribute('uv');
  for (let i = 0; i < uv.count; i++) uv.setY(i, along[i % points.length] / along[along.length - 1]);
  // Ось тела вращения — Y; кладём кольцо так, чтобы его ось смотрела вдоль Z.
  g.rotateX(Math.PI / 2);
  return g;
}

/**
 * Три массивных стальных кольца медленно проворачиваются друг в друге, сквозь них проходит красный луч.
 * Центр стоит у правого края панели: в кадре только часть колец, остальное обрезано — так они читаются
 * крупной формой, а не предметом на полке. Ниже границы текста сцена уходит в тень (маска в CSS).
 * Чисто декоративно, для диктора скрыто. `clearHeight` — сколько пикселей сверху свободно от текста.
 * Возвращает функцию, которая останавливает отрисовку и освобождает память видеокарты.
 */
export function mountRings(host: HTMLElement, still: boolean, clearHeight: () => number): () => void {
  const renderer = new WebGLRenderer({ antialias: true, alpha: true, powerPreference: 'low-power' });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.toneMapping = ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.0;
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
  // Тени не считаем: у чистого металла нет рассеянного света, и на вид они ничего не меняют.
  const key = new DirectionalLight(0xfff1de, 1.3);
  const rim = new DirectionalLight(0xc4d6f2, 0.4);
  rim.position.set(4, 1.5, -3);
  scene.add(key, key.target, rim);

  const camera = new PerspectiveCamera(FOV, 1, 0.1, 60);
  camera.position.z = DISTANCE;

  const root = new Group();
  scene.add(root);

  const brushed = brushedTexture(renderer.capabilities.getMaxAnisotropy());
  const steel = new MeshPhysicalMaterial({
    color: new Color('#a29d95'),
    metalness: 1,
    roughness: 0.48,
    roughnessMap: brushed,
    anisotropy: 0.8,
  });
  // Среднее кольцо полированное и темнее: рядом со шлифованными оно даёт резкие отражения.
  const polished = new MeshPhysicalMaterial({ color: new Color('#6b6d72'), metalness: 1, roughness: 0.2 });

  const rings = RINGS.map((spec) => {
    const mesh = new Mesh(ringGeometry(spec.radius, spec.width, spec.depth), spec.polished ? polished : steel);
    root.add(mesh);
    return { spec, mesh };
  });

  // Луч: цилиндр построен вдоль Y — поворачиваем его по направлению луча.
  const beam = new Mesh(new CylinderGeometry(BEAM.radius, BEAM.radius, BEAM.half * 2, 24, 1, true), beamMaterial());
  beam.quaternion.setFromUnitVectors(new Vector3(0, 1, 0), BEAM.dir);
  root.add(beam);
  // Красный отсвет луча на кромках колец: два источника на оси по обе стороны от центра.
  const glints = [-0.7, 0.7].map((at) => {
    const l = new PointLight(0xff3a22, BEAM.glint, 0, 2);
    l.position.copy(BEAM.dir).multiplyScalar(at);
    root.add(l);
    return l;
  });

  // Опорные оси для конуса: две перпендикулярные лучу.
  const side = new Vector3(0, 1, 0).cross(BEAM.dir).normalize();
  const up = BEAM.dir.clone().cross(side).normalize();
  const forward = new Vector3(0, 0, 1);
  const axis = new Vector3();
  const spin = new Quaternion();

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
    // Граница текста — для маски в CSS: ниже неё сцена гаснет.
    host.style.setProperty('--scene-clear', `${Math.round(clear)}px`);
    root.position.set((ANCHOR.x - 0.5) * visW, (0.5 - (clear * ANCHOR.y) / h) * visH, 0);
    root.scale.setScalar((w * ANCHOR.radius * unitsPerPx) / R);
    key.position.set(root.position.x - 4, root.position.y + 7, 6);
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
  function pose(t: number, appear: number) {
    const k = 1 - Math.pow(1 - appear, 3);
    root.rotation.set(look.y * 0.06, look.x * 0.14, 0);
    for (const { spec, mesh } of rings) {
      // Ось кольца обходит конус вокруг луча; при появлении конус раскрывается из нуля.
      const a = spec.phase + t * spec.speed;
      const cone = spec.cone * k;
      axis
        .copy(BEAM.dir)
        .multiplyScalar(Math.cos(cone))
        .addScaledVector(side, Math.sin(cone) * Math.cos(a))
        .addScaledVector(up, Math.sin(cone) * Math.sin(a));
      mesh.quaternion.setFromUnitVectors(forward, axis);
      // И само кольцо медленно крутится в своей плоскости: штрихи шлифовки ползут по кругу.
      spin.setFromAxisAngle(forward, t * spec.speed * 0.6);
      mesh.quaternion.multiply(spin);
    }
    const pulse = pulseAt(t);
    beam.material.uniforms.uTime.value = t;
    beam.material.uniforms.uPulse.value = pulse;
    // Когда импульс проходит сквозь кольца, отсвет на них коротко разгорается.
    const flare = Math.exp(-Math.pow(pulse * 3.2, 2));
    for (const l of glints) l.intensity = BEAM.glint * k * (0.8 + 1.5 * flare);
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
    pose(t, Math.min(1, t / 2.2));
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
    brushed.dispose();
    env.dispose();
    pmrem.dispose();
    renderer.dispose();
    canvas.remove();
  };
}
