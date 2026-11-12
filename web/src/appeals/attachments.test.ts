import { describe, expect, it } from 'vitest';
import { fileBadge, fileKind, MAX_FILE_BYTES, splitBySize, stepIndex } from './attachments';

const att = (filename: string, content_type = 'application/octet-stream') => ({ filename, content_type });

describe('вид файла в галерее', () => {
  it('по расширению, без учёта регистра', () => {
    expect(fileKind(att('DSC00464.jpg'))).toBe('image');
    expect(fileKind(att('IMG_4400.MOV'))).toBe('video');
    expect(fileKind(att('пример_заявки.pdf'))).toBe('pdf');
    expect(fileKind(att('запись.m4a'))).toBe('audio');
  });

  it('без знакомого расширения — по content_type', () => {
    expect(fileKind(att('снимок', 'image/png'))).toBe('image');
    expect(fileKind(att('ролик', 'video/mp4'))).toBe('video');
    expect(fileKind(att('таблица.xlsx', 'application/vnd.ms-excel'))).toBe('other');
  });

  it('HEIC браузер не покажет — это обычный файл для скачивания', () => {
    expect(fileKind(att('IMG_0001.HEIC', 'image/heic'))).toBe('other');
    expect(fileKind(att('фото', 'image/heif'))).toBe('other');
  });

  it('подпись на плитке без превью', () => {
    expect(fileBadge('IMG_4400.MOV')).toBe('MOV');
    expect(fileBadge('отчёт')).toBe('ФАЙЛ');
    expect(fileBadge('архив.verylongext')).toBe('ФАЙЛ');
  });
});

describe('карусель и загрузка', () => {
  it('листание идёт по кругу', () => {
    expect(stepIndex(0, -1, 3)).toBe(2);
    expect(stepIndex(2, 1, 3)).toBe(0);
    expect(stepIndex(1, 1, 3)).toBe(2);
    expect(stepIndex(0, 1, 0)).toBe(0);
  });

  it('файлы больше 20 МБ отсекаются до отправки и называются', () => {
    const files = [
      { name: 'мелкий.jpg', size: 1024 },
      { name: 'ровно.mov', size: MAX_FILE_BYTES },
      { name: 'большой.mov', size: MAX_FILE_BYTES + 1 },
    ];
    expect(splitBySize(files)).toEqual({ ok: [files[0], files[1]], tooLarge: ['большой.mov'] });
  });
});
