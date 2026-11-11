import { useEffect } from 'react';
import { Link, useLocation, useParams } from 'react-router-dom';
import { api, unwrap } from '../api/client';
import { ApiError } from '../api/errors';
import type { Schemas } from '../api/types';
import { useDictionaries } from '../app/dictionaries';
import { useUnread } from '../app/unread';
import { ActionsPanel } from '../appeals/ActionsPanel';
import { AttachmentsSection } from '../appeals/AttachmentsSection';
import { BitrixSection } from '../appeals/BitrixSection';
import { cardSections } from '../appeals/cardSections';
import { DuplicatesSection } from '../appeals/DuplicatesSection';
import { DueBadge, StatusBadge } from '../appeals/Badges';
import { HistorySection } from '../appeals/HistorySection';
import { closedReasonLabel } from '../appeals/labels';
import { MessagesSection } from '../appeals/MessagesSection';
import { formatDateTime } from '../lib/format';
import { plural } from '../lib/plural';
import { useAsync } from '../lib/useAsync';

type Appeal = Schemas['Appeal'];

export function AppealPage() {
  const id = Number(useParams().id);
  const appeal = useAsync(() => unwrap(api.GET('/api/v1/appeals/{appeal_id}', { params: { path: { appeal_id: id } } })), [id]);
  const { markAppealRead } = useUnread();

  useEffect(() => {
    if (appeal.state.status === 'ready') markAppealRead(id);
  }, [appeal.state.status, id, markAppealRead]);

  const s = appeal.state;
  if (s.status === 'loading') return <p className="muted">Загружаем…</p>;
  if (s.status === 'error') {
    const notFound = s.error instanceof ApiError && (s.error.status === 404 || s.error.status === 403);
    return (
      <section className="page">
        <BackLink />
        <div className="notice">
          <p className="error-text">{notFound ? 'Обращение не найдено или у вас нет к нему доступа.' : s.message}</p>
          {!notFound && (
            <button type="button" className="btn btn--ghost" onClick={appeal.reload}>
              Повторить
            </button>
          )}
        </div>
      </section>
    );
  }

  return <AppealCard appeal={s.data} onChanged={appeal.reload} onUpdated={appeal.set} />;
}

const BACK: Record<string, { path: string; label: string }> = {
  '/my': { path: '/my', label: 'Мои обращения' },
  '/queue': { path: '/queue', label: 'Обработка' },
  '/digest': { path: '/digest', label: 'Сводка' },
};

/** Назад туда, откуда пришли: в очередь, сводку или свои обращения. */
function BackLink() {
  const from = (useLocation().state as { from?: string } | null)?.from;
  const back = BACK[from ?? ''] ?? BACK['/my'];
  return (
    <Link to={back.path} className="back-link">
      ← {back.label}
    </Link>
  );
}

interface CardProps {
  appeal: Appeal;
  onChanged: () => void;
  onUpdated: (a: Appeal) => void;
}

function AppealCard({ appeal: a, onChanged, onUpdated }: CardProps) {
  const dict = useDictionaries();
  const show = cardSections(a);

  return (
    <section className="page appeal">
      <BackLink />
      <header className="appeal__head">
        <h1 className="page__title">
          {a.number}
          {a.summary ? ` · ${a.summary}` : ''}
        </h1>
        <div className="appeal-row__meta">
          <StatusBadge status={a.status} />
          {a.status !== 'closed' && <DueBadge state={a.due_state} dueAt={a.first_response_due_at} />}
          {show.participantsCounter && (
            <span className="badge badge--people">
              Об этом сказали {a.participants_count} {plural(a.participants_count, ['человек', 'человека', 'человек'])}
            </span>
          )}
        </div>
      </header>

      {show.participantNotice && (
        <div className="notice">
          Вы видите это обращение, потому что ваше присоединили к нему как повтор. Статусы и итог приходят вам, текст
          и автор основного обращения скрыты.
        </div>
      )}

      <Outcome appeal={a} />


      <ActionsPanel appeal={a} onUpdated={onUpdated} />

      {a.discussion && (
        <div className="notice">
          {a.discussion.status === 'open' ? 'Вынесено на общее обсуждение. ' : 'Общее обсуждение завершено. '}
          <Link to={`/discussions/${a.discussion.id}`}>Открыть обсуждение</Link>
        </div>
      )}

      {show.duplicates && <DuplicatesSection appeal={a} onMerged={() => onChanged()} />}
      {show.bitrix && <BitrixSection appeal={a} onUpdated={onUpdated} />}

      <dl className="facts">
        <dt>Тип</dt>
        <dd>{dict.typeLabel(a.type)}</dd>
        <dt>Категория</dt>
        <dd>{a.category?.name ?? 'Не указана'}</dd>
        <dt>Приоритет</dt>
        <dd>{dict.priorityLabel(a.priority)}</dd>
        {a.author && !a.viewer_relations.includes('author') && (
          <>
            <dt>Автор</dt>
            <dd>
              {a.author.full_name}
              {a.author.department ? ` · ${a.author.department.name}` : ''}
            </dd>
          </>
        )}
        <dt>Ответственный</dt>
        <dd>{a.assignee?.full_name ?? 'Назначит администратор'}</dd>
        <dt>Срок первого ответа</dt>
        <dd>{a.first_response_due_at ? formatDateTime(a.first_response_due_at) : 'Без срока'}</dd>
        {a.first_response_at && (
          <>
            <dt>Первый ответ</dt>
            <dd>{formatDateTime(a.first_response_at)}</dd>
          </>
        )}
        <dt>Подано</dt>
        <dd>{formatDateTime(a.created_at)}</dd>
      </dl>

      {a.text && (
        <div className="block">
          <h2 className="block__title">Описание</h2>
          <p className="prose">{a.text}</p>
          {a.forwarded_from && <p className="muted">Переслано из: {a.forwarded_from}</p>}
        </div>
      )}
      {a.proposed_solution && (
        <div className="block">
          <h2 className="block__title">Предлагаемое решение</h2>
          <p className="prose">{a.proposed_solution}</p>
        </div>
      )}

      {show.messages && <MessagesSection appeal={a} onAppealChanged={onChanged} />}
      {show.attachments && <AttachmentsSection appeal={a} />}
      {show.history && <HistorySection appealId={a.id} version={a.updated_at} />}
    </section>
  );
}

/** Итог по обращению: решение, причина отказа, результат, причина закрытия. */
function Outcome({ appeal: a }: { appeal: Appeal }) {
  if (a.status === 'rejected' && a.rejection_reason) {
    return (
      <div className="notice notice--danger">
        <h2 className="block__title">Причина отказа</h2>
        <p className="prose">{a.rejection_reason}</p>
      </div>
    );
  }
  if (a.status === 'implemented' && a.result) {
    return (
      <div className="notice notice--success">
        <h2 className="block__title">Результат</h2>
        <p className="prose">{a.result}</p>
      </div>
    );
  }
  if (a.status === 'in_progress' && a.decision) {
    return (
      <div className="notice">
        <h2 className="block__title">Принятое решение</h2>
        <p className="prose">{a.decision}</p>
      </div>
    );
  }
  if (a.status === 'closed' && a.closed_reason) {
    return (
      <div className="notice">
        {closedReasonLabel[a.closed_reason]}
        {a.merged_into && (
          <>
            {': '}
            <Link to={`/appeals/${a.merged_into.id}`}>{a.merged_into.number}</Link>
            {a.merged_into.summary ? ` · ${a.merged_into.summary}` : ''}
            <div className="appeal-row__meta">
              <span className="muted">Статус основного:</span>
              <StatusBadge status={a.merged_into.status} />
            </div>
            <p className="muted">Статусы основного обращения будут приходить вам.</p>
          </>
        )}
      </div>
    );
  }
  return null;
}
