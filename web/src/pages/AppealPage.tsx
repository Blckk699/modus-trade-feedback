import { CardSkeleton } from '../app/CardSkeleton';
import { useEffect } from 'react';
import { Link, useParams } from 'react-router-dom';
import { ArrowLeft, MessagesSquare, Users } from 'lucide-react';
import { api, unwrap } from '../api/client';
import { ApiError } from '../api/errors';
import type { Schemas } from '../api/types';
import { useBackground } from '../app/background';
import { useDictionaries } from '../app/dictionaries';
import { PageHead } from '../app/PageHead';
import { useUnread } from '../app/unread';
import { ActionsPanel } from '../appeals/ActionsPanel';
import { AssignSection } from '../appeals/AssignSection';
import { AttachmentsSection } from '../appeals/AttachmentsSection';
import { DueBadge, StatusBadge } from '../appeals/Badges';
import { BitrixSection } from '../appeals/BitrixSection';
import { cardSections, needsAssignee } from '../appeals/cardSections';
import { DuplicatesSection } from '../appeals/DuplicatesSection';
import { HistorySection } from '../appeals/HistorySection';
import { closedReasonLabel } from '../appeals/labels';
import { MessagesSection } from '../appeals/MessagesSection';
import { TypeChip } from '../appeals/TypeIcon';
import { formatDateTime } from '../lib/format';
import { plural } from '../lib/plural';
import { useAsync } from '../lib/useAsync';
import { useInCard } from './CardModal';

type Appeal = Schemas['Appeal'];

/**
 * Карточка обращения. Из списка открывается панелью справа поверх экрана; по прямой ссылке
 * (уведомление бота, адресная строка) — отдельной страницей с тем же содержимым.
 */
export function AppealPage() {
  const id = Number(useParams().id);
  const inCard = useInCard();
  const appeal = useAsync(() => unwrap(api.GET('/api/v1/appeals/{appeal_id}', { params: { path: { appeal_id: id } } })), [id]);
  const { markAppealRead } = useUnread();

  useEffect(() => {
    if (appeal.state.status === 'ready') markAppealRead(id);
  }, [appeal.state.status, id, markAppealRead]);

  const s = appeal.state;
  let body;
  if (s.status === 'loading') {
    body = (
      <CardSkeleton label="Открываем обращение…" />
    );
  } else if (s.status === 'error') {
    const notFound = s.error instanceof ApiError && (s.error.status === 404 || s.error.status === 403);
    body = (
      <div className="sheet sheet--state">
        <p className="error-text">{notFound ? 'Обращение не найдено или у вас нет к нему доступа.' : s.message}</p>
        {!notFound && (
          <button type="button" className="btn btn--soft" onClick={appeal.reload}>
            Повторить
          </button>
        )}
      </div>
    );
  } else {
    body = <AppealCard appeal={s.data} onChanged={appeal.reload} onUpdated={appeal.set} />;
  }

  if (inCard) return body;
  return (
    <section className="solo">
      <PageHead over="Обращение" title={s.status === 'ready' ? s.data.number : 'Обращение'} />
      <Link to="/" className="back-link">
        <ArrowLeft size={16} aria-hidden="true" /> На главный экран
      </Link>
      <div className="card solo__card">{body}</div>
    </section>
  );
}

interface CardProps {
  appeal: Appeal;
  onChanged: () => void;
  onUpdated: (a: Appeal) => void;
}

function AppealCard({ appeal: a, onChanged, onUpdated }: CardProps) {
  const dict = useDictionaries();
  const background = useBackground();
  const show = cardSections(a);
  const isAuthor = a.viewer_relations.includes('author');

  return (
    <article className="sheet">
      <header className="sheet__head">
        <div className="sheet__state" role="group" aria-label="Состояние обращения">
          <TypeChip type={a.type} label={dict.typeLabel(a.type)} />
          <StatusBadge status={a.status} />
          {a.status !== 'closed' && <DueBadge state={a.due_state} dueAt={a.first_response_due_at} />}
          {show.participantsCounter && (
            <span className="badge badge--people">
              <Users size={13} aria-hidden="true" />
              {a.participants_count} {plural(a.participants_count, ['человек', 'человека', 'человек'])} об этом
            </span>
          )}
        </div>
      </header>

      <div className="sheet__scroll">
        <div className="sheet__lead">
          <div>
            <h1 className="sheet__title">{a.summary ?? `Обращение ${a.number}`}</h1>
            <p className="sheet__sub">
              {a.number} · {a.category?.name ?? 'без категории'} · приоритет {dict.priorityLabel(a.priority).toLowerCase()}
            </p>
          </div>
        </div>

        {show.participantNotice && (
          <div className="notice">
            Вы видите это обращение, потому что ваше присоединили к нему как повтор. Статусы и итог придут вам. Текст и
            автор основного обращения скрыты.
          </div>
        )}

        {needsAssignee(a) && <AssignSection appeal={a} onUpdated={onUpdated} />}

        <Outcome appeal={a} />

        {(a.text || a.proposed_solution) && (
          <section className="sheet__text" aria-label="Описание">
            {a.text && <p className="prose">{a.text}</p>}
            {a.forwarded_from && <p className="muted">Переслано из: {a.forwarded_from}</p>}
            {a.proposed_solution && (
              <div className="solution">
                <p className="solution__label">Что предлагает автор</p>
                <p className="prose">{a.proposed_solution}</p>
              </div>
            )}
          </section>
        )}

        <dl className="facts">
          {a.author && !isAuthor && (
            <div>
              <dt>Автор</dt>
              <dd>
                {a.author.full_name}
                {a.author.department && <span className="muted"> · {a.author.department.name}</span>}
              </dd>
            </div>
          )}
          <div>
            <dt>Ответственный</dt>
            <dd>{a.assignee?.full_name ?? (needsAssignee(a) ? 'Не назначен' : 'Назначит администратор')}</dd>
          </div>
          <div>
            <dt>Срок первого ответа</dt>
            <dd>{a.first_response_due_at ? formatDateTime(a.first_response_due_at) : 'Без срока'}</dd>
          </div>
          {a.first_response_at && (
            <div>
              <dt>Первый ответ</dt>
              <dd>{formatDateTime(a.first_response_at)}</dd>
            </div>
          )}
          <div>
            <dt>Подано</dt>
            <dd>{formatDateTime(a.created_at)}</dd>
          </div>
        </dl>

        {a.discussion && (
          <Link to={`/discussions/${a.discussion.id}`} state={{ background }} className="jump">
            <span className="jump__icon" aria-hidden="true">
              <MessagesSquare size={18} />
            </span>
            <span className="jump__text">
              <strong>{a.discussion.status === 'open' ? 'Идёт общее обсуждение' : 'Общее обсуждение завершено'}</strong>
              <span>Голоса и комментарии сотрудников</span>
            </span>
            <span className="pill-action">Открыть</span>
          </Link>
        )}

        {show.duplicates && <DuplicatesSection appeal={a} onMerged={() => onChanged()} />}
        {show.bitrix && <BitrixSection appeal={a} onUpdated={onUpdated} />}
        {show.messages && <MessagesSection appeal={a} onAppealChanged={onChanged} />}
        {show.attachments && <AttachmentsSection appeal={a} />}
        {show.history && <HistorySection appealId={a.id} version={a.updated_at} />}
      </div>

      <ActionsPanel appeal={a} onUpdated={onUpdated} />
    </article>
  );
}

/** Итог по обращению: решение, причина отказа, результат, причина закрытия. */
function Outcome({ appeal: a }: { appeal: Appeal }) {
  const background = useBackground();
  if (a.status === 'rejected' && a.rejection_reason) {
    return (
      <div className="notice notice--danger" role="region" aria-label="Причина отказа">
        <h2 className="notice__title">Причина отказа</h2>
        <p className="prose">{a.rejection_reason}</p>
      </div>
    );
  }
  if (a.status === 'implemented' && a.result) {
    return (
      <div className="notice notice--success" role="region" aria-label="Результат">
        <h2 className="notice__title">Что сделано</h2>
        <p className="prose">{a.result}</p>
      </div>
    );
  }
  if (a.status === 'in_progress' && a.decision) {
    return (
      <div className="notice" role="region" aria-label="Принятое решение">
        <h2 className="notice__title">Что решили</h2>
        <p className="prose">{a.decision}</p>
      </div>
    );
  }
  if (a.status === 'closed' && a.closed_reason) {
    return (
      <div className="notice">
        <h2 className="notice__title">{closedReasonLabel[a.closed_reason]}</h2>
        {a.merged_into && (
          <>
            <p>
              <Link to={`/appeals/${a.merged_into.id}`} state={{ background }}>
                {a.merged_into.number}
              </Link>
              {a.merged_into.summary ? ` · ${a.merged_into.summary}` : ''}
            </p>
            <p className="notice__row">
              <span className="muted">Основное обращение:</span>
              <StatusBadge status={a.merged_into.status} />
            </p>
            <p className="muted">Его статусы будут приходить вам.</p>
          </>
        )}
      </div>
    );
  }
  return null;
}
