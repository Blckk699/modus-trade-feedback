import type { Schemas } from '../api/types';

const LABEL: Record<Schemas['MeetingStatus'], string> = {
  processing: 'Обрабатывается',
  ready: 'Готово',
  failed: 'Ошибка обработки',
};

const CLASS: Record<Schemas['MeetingStatus'], string> = {
  processing: 'badge--status-awaiting_info',
  ready: 'badge--status-implemented',
  failed: 'badge--status-rejected',
};

export function MeetingStatusBadge({ status }: { status: Schemas['MeetingStatus'] }) {
  return <span className={`badge ${CLASS[status]}`}>{LABEL[status]}</span>;
}
