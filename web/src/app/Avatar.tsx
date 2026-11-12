const TONES = ['new', 'in_progress', 'implemented', 'awaiting_info', 'in_review', 'closed'] as const;

export function initials(name: string): string {
  const parts = name.trim().split(/\s+/);
  return ((parts[0]?.[0] ?? '') + (parts[1]?.[0] ?? '')).toUpperCase() || '?';
}

/** Кружок с инициалами. Цвет — из палитры статусов, выбирается по имени, чтобы у человека он был всегда один. */
export function Avatar({ name, size = 'md' }: { name: string; size?: 'sm' | 'md' | 'lg' }) {
  let hash = 0;
  for (const ch of name) hash = (hash * 31 + ch.charCodeAt(0)) >>> 0;
  const tone = TONES[hash % TONES.length];
  return (
    <span
      className={`avatar avatar--${size}`}
      style={{ background: `var(--status-${tone}-bg)`, color: `var(--status-${tone})` }}
      aria-hidden="true"
    >
      {initials(name)}
    </span>
  );
}
