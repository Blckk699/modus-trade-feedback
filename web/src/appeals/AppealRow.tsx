import { Link } from 'react-router-dom';
import { ChevronRight } from 'lucide-react';
import type { Schemas } from '../api/types';
import { useBackground } from '../app/background';
import { useDictionaries } from '../app/dictionaries';
import { formatDay } from '../lib/format';
import { StatusBadge } from './Badges';
import { timeLeftLabel } from './timeLeft';
import { TypeIcon } from './TypeIcon';

type Item = Schemas['AppealListItem'];

/** Есть ли у обращения идущий срок первого ответа (ответа ещё нет и срок назначен). */
export function isWaitingAnswer(item: Pick<Item, 'first_response_due_at' | 'due_state'>): boolean {
  return Boolean(item.first_response_due_at) && item.due_state !== 'answered' && item.due_state !== 'no_deadline';
}

interface Props {
  item: Item;
  /** mine — список автора: дата подачи. queue — очередь обработки: сколько осталось до срока и кто отвечает. */
  view: 'mine' | 'queue';
  now?: Date;
}

/** Строка обращения в списке. Открывает карточку панелью поверх текущего экрана. */
export function AppealRow({ item, view, now }: Props) {
  const dict = useDictionaries();
  const background = useBackground();
  const overdue = item.due_state === 'overdue' && item.status !== 'closed';
  const waiting = isWaitingAnswer(item) && item.status !== 'closed';
  const meta = [item.number, dict.typeLabel(item.type)];
  if (view === 'queue') {
    if (item.category) meta.push(item.category.name);
    meta.push(item.assignee ? item.assignee.full_name : 'без ответственного');
  } else {
    meta.push(formatDay(item.created_at));
    if (item.merged_into) meta.push(`присоединено к ${item.merged_into.number}`);
  }

  return (
    <li>
      <Link to={`/appeals/${item.id}`} state={{ background }} className={overdue ? 'row row--overdue' : 'row'}>
        <TypeIcon type={item.type} />
        <span className="row__main">
          <span className="row__title">
            {item.has_unread && <span className="dot" role="img" aria-label="Есть новое" />}
            {item.summary ?? 'Без краткой сути'}
          </span>
          <span className="row__meta">{meta.join(' · ')}</span>
        </span>
        <span className="row__side">
          {view === 'queue' && item.participants_count > 1 && <span className="badge badge--people">{item.participants_count} сообщили</span>}
          {waiting && (
            <span className={`row__due row__due--${item.due_state}`}>{timeLeftLabel(item.first_response_due_at!, now)}</span>
          )}
          <StatusBadge status={item.status} />
        </span>
        <ChevronRight className="row__chev" size={18} aria-hidden="true" />
      </Link>
    </li>
  );
}
