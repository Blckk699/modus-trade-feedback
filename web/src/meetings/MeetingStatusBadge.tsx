import type { Schemas } from '../api/types';

const LABEL: Record<Schemas['MeetingStatus'], string> = {
  processing: 'Расшифровываем',
  ready: 'Готово',
  failed: 'Не удалось обработать',
};

const CLASS: Record<Schemas['MeetingStatus'], string> = {
  processing: 'badge--status-awaiting_info',
  ready: 'badge--status-implemented',
  failed: 'badge--status-rejected',
};

export function MeetingStatusBadge({ status }: { status: Schemas['MeetingStatus'] }) {
  return <span className={`badge badge--dot ${CLASS[status]}`}>{LABEL[status]}</span>;
}
