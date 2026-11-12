import { useState, type FormEvent } from 'react';
import { ArrowUp } from 'lucide-react';
import { api, unwrap } from '../api/client';
import { ApiError, errorMessage } from '../api/errors';
import type { Schemas } from '../api/types';
import { Avatar } from '../app/Avatar';
import { useMe } from '../auth';
import { formatDateTime } from '../lib/format';
import { useAsync } from '../lib/useAsync';

type Appeal = Schemas['Appeal'];

/** Закрытая переписка автора и ответственного. Писать можно, если в allowed_actions есть send_message или reply_clarification. */
export function MessagesSection({ appeal, onAppealChanged }: { appeal: Appeal; onAppealChanged: () => void }) {
  const me = useMe();
  const list = useAsync(
    () => unwrap(api.GET('/api/v1/appeals/{appeal_id}/messages', { params: { path: { appeal_id: appeal.id } } })),
    [appeal.id],
  );
  const [text, setText] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  const replying = appeal.allowed_actions.includes('reply_clarification');
  const canWrite = replying || appeal.allowed_actions.includes('send_message');

  // Нет доступа к переписке (например, администратор) — раздела нет.
  if (list.state.status === 'error' && list.state.error instanceof ApiError && list.state.error.status === 403) {
    return null;
  }

  async function send(e: FormEvent) {
    e.preventDefault();
    if (!text.trim()) return;
    setBusy(true);
    setError('');
    try {
      const msg = await unwrap(
        api.POST('/api/v1/appeals/{appeal_id}/messages', {
          params: { path: { appeal_id: appeal.id } },
          body: { text: text.trim() },
        }),
      );
      setText('');
      if (list.state.status === 'ready') list.set([...list.state.data, msg]);
      else list.reload();
      // Ответ на уточнение возвращает обращение в «На рассмотрении» — перечитываем карточку.
      if (replying) onAppealChanged();
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  }

  const messages = list.state.status === 'ready' ? list.state.data : [];
  const lastQuestion = [...messages].reverse().find((m) => m.is_clarification_question);
  const label = replying ? 'Ответ на вопрос' : 'Сообщение';

  return (
    <section className="section">
      <h2 className="section__title">
        Переписка
        {messages.length > 0 && <span className="section__count">{messages.length}</span>}
      </h2>
      {replying && lastQuestion && (
        <div className="notice notice--warn">
          <p className="notice__title">{lastQuestion.author.full_name} спрашивает</p>
          <p>{lastQuestion.text}</p>
        </div>
      )}
      {list.state.status === 'loading' && <p className="muted section__empty">Загружаем…</p>}
      {list.state.status === 'error' && <p className="error-text">{list.state.message}</p>}
      {list.state.status === 'ready' && messages.length === 0 && (
        <p className="muted section__empty">
          {canWrite ? 'Сообщений пока нет. Переписку видят только автор и ответственный.' : 'Сообщений нет.'}
        </p>
      )}
      {messages.length > 0 && (
        <ul className="thread">
          {messages.map((m) => {
            const mine = m.author.id === me.id;
            return (
              <li key={m.id} className={mine ? 'msg msg--mine' : 'msg'}>
                {!mine && <Avatar name={m.author.full_name} size="sm" />}
                <div className={m.is_clarification_question ? 'msg__bubble msg__bubble--question' : 'msg__bubble'}>
                  <div className="msg__meta">
                    <span className="msg__author">{mine ? 'Вы' : m.author.full_name}</span>
                    {m.is_clarification_question && <span className="msg__tag">уточняющий вопрос</span>}
                    <span className="msg__time">{formatDateTime(m.created_at)}</span>
                  </div>
                  <p className="prose">{m.text}</p>
                </div>
              </li>
            );
          })}
        </ul>
      )}
      {canWrite && (
        <form className="composer" onSubmit={send}>
          <textarea
            className="composer__input"
            rows={2}
            value={text}
            onChange={(e) => setText(e.target.value)}
            onKeyDown={(e) => {
              // Ctrl/⌘ + Enter отправляет сообщение.
              if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) e.currentTarget.form?.requestSubmit();
            }}
            placeholder={replying ? 'Ответьте на вопрос' : 'Напишите сообщение'}
            aria-label={label}
          />
          <div className="composer__foot">
            {error ? <span className="error-text">{error}</span> : <span className="composer__hint">Ctrl + Enter — отправить</span>}
            <button type="submit" className="btn btn--sm composer__send" disabled={busy || !text.trim()}>
              {busy ? 'Отправляем…' : replying ? 'Ответить' : 'Отправить'}
              <ArrowUp size={15} aria-hidden="true" />
            </button>
          </div>
        </form>
      )}
    </section>
  );
}
