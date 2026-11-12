import { describe, expect, it } from 'vitest';
import { mergeBlockReason } from './mergeReason';

const labels: Record<string, string> = { new: 'Новое', in_review: 'На рассмотрении', awaiting_info: 'Ожидает уточнения', in_progress: 'В работе', implemented: 'Реализовано' };
const base = { status: 'new' as const, canMergeHere: true, main: { number: 'A-001', status: 'in_review' as const }, canMergeSuggestion: true, statusLabel: (s: string) => labels[s] ?? s };

describe('почему нельзя склеить', () => {
  it('всё разрешено — причины нет', () => {
    expect(mergeBlockReason(base)).toBeNull();
  });

  it('основное завершено — называем его статус', () => {
    expect(mergeBlockReason({ ...base, canMergeSuggestion: false, main: { number: 'A-001', status: 'implemented' } })).toBe(
      'A-001 уже завершено («Реализовано»): к нему повтор не присоединить.',
    );
  });

  it('основное в работе — статус не мешает, причина в другом', () => {
    expect(mergeBlockReason({ ...base, canMergeSuggestion: false, main: { number: 'A-001', status: 'in_progress' } })).toMatch(/^A-001 у другого ответственного/);
  });

  it('это обращение уже в работе — называем его статус', () => {
    expect(mergeBlockReason({ ...base, status: 'in_progress', canMergeHere: false, canMergeSuggestion: false })).toMatch(/Это сейчас «В работе»/);
  });

  it('статусы подходят, но основное у другого ответственного', () => {
    expect(mergeBlockReason({ ...base, canMergeSuggestion: false })).toMatch(/^A-001 у другого ответственного/);
  });

  it('статусы подходят, но у пользователя нет права склеивать это обращение', () => {
    expect(mergeBlockReason({ ...base, canMergeHere: false })).toMatch(/^Склеивает ответственный/);
  });
});
