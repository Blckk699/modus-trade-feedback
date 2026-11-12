import type { Schemas } from '../api/types';

type Attachment = Schemas['Attachment'];

/** Что это за файл для галереи: от этого зависит превью в плитке и показ в просмотре. */
export type FileKind = 'image' | 'video' | 'audio' | 'pdf' | 'other';

const BY_EXT: Record<string, FileKind> = {
  jpg: 'image',
  jpeg: 'image',
  png: 'image',
  gif: 'image',
  webp: 'image',
  heic: 'other', // браузеры HEIC не показывают — остаётся скачивание
  mp4: 'video',
  mov: 'video',
  webm: 'video',
  m4v: 'video',
  mp3: 'audio',
  m4a: 'audio',
  wav: 'audio',
  ogg: 'audio',
  pdf: 'pdf',
};

export function extension(filename: string): string {
  const dot = filename.lastIndexOf('.');
  return dot > 0 ? filename.slice(dot + 1).toLowerCase() : '';
}

/** Сначала расширение (оно надёжнее: телефоны шлют HEIC и MOV с общим типом), затем content_type. */
export function fileKind(att: Pick<Attachment, 'filename' | 'content_type'>): FileKind {
  const byExt = BY_EXT[extension(att.filename)];
  if (byExt) return byExt;
  const type = att.content_type.toLowerCase();
  if (type.startsWith('image/') && !type.includes('heic') && !type.includes('heif')) return 'image';
  if (type.startsWith('video/')) return 'video';
  if (type.startsWith('audio/')) return 'audio';
  if (type === 'application/pdf') return 'pdf';
  return 'other';
}

/** Подпись на плитке без превью: «PDF», «MOV», «ФАЙЛ». */
export function fileBadge(filename: string): string {
  const ext = extension(filename);
  return ext && ext.length <= 5 ? ext.toUpperCase() : 'ФАЙЛ';
}

/** Соседний файл в карусели: по кругу. */
export function stepIndex(index: number, delta: number, total: number): number {
  if (total <= 0) return 0;
  return (((index + delta) % total) + total) % total;
}

export const MAX_FILE_BYTES = 20 * 1024 * 1024;

/** Файлы больше 20 МБ сервер не примет (413): отсекаем до отправки и называем их. */
export function splitBySize<T extends { name: string; size: number }>(files: T[]): { ok: T[]; tooLarge: string[] } {
  const ok: T[] = [];
  const tooLarge: string[] = [];
  for (const f of files) {
    if (f.size > MAX_FILE_BYTES) tooLarge.push(f.name);
    else ok.push(f);
  }
  return { ok, tooLarge };
}
