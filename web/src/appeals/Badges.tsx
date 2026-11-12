import type { Schemas } from '../api/types';
import { useDictionaries } from '../app/dictionaries';
import { formatDateTime } from '../lib/format';
import { dueStateLabel } from './labels';

/** Статус обращения: цветная точка и подпись из словаря. */
export function StatusBadge({ status }: { status: Schemas['AppealStatus'] }) {
  const dict = useDictionaries();
  return <span className={`badge badge--dot badge--status-${status}`}>{dict.statusLabel(status)}</span>;
}

interface DueProps {
  state: Schemas['DueState'];
  dueAt: string | null;
}

/** Срок первого ответа: состояние от бэкенда и дата. Клиент сроки не считает. */
export function DueBadge({ state, dueAt }: DueProps) {
  const showDate = dueAt && state !== 'answered' && state !== 'no_deadline';
  return (
    <span className={`badge badge--due-${state}`}>
      {dueStateLabel[state]}
      {showDate ? ` · до ${formatDateTime(dueAt)}` : ''}
    </span>
  );
}
