import { useState, type FormEvent } from 'react';
import { api, unwrap } from '../api/client';
import { ApiError, errorMessage } from '../api/errors';
import type { Schemas } from '../api/types';
import { useMe } from '../auth';
import { formatDateTime } from '../lib/format';
import { useAsync } from '../lib/useAsync';

type Appeal = Schemas['Appeal'];

/** Приватная переписка. Писать можно, если в allowed_actions есть send_message или reply_clarification. */
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

  return (
    <div className="block">
      <h2 className="block__title">Переписка</h2>
      {replying && lastQuestion && (
        <div className="notice notice--warn">
          <strong>Вопрос от {lastQuestion.author.full_name}:</strong> {lastQuestion.text}
        </div>
      )}
      {list.state.status === 'loading' && <p className="muted">Загружаем…</p>}
      {list.state.status === 'error' && <p className="error-text">{list.state.message}</p>}
      {list.state.status === 'ready' && messages.length === 0 && <p className="muted">Сообщений пока нет.</p>}
      {messages.length > 0 && (
        <ul className="thread">
          {messages.map((m) => (
            <li
              key={m.id}
              className={`thread__msg${m.author.id === me.id ? ' thread__msg--mine' : ''}${
                m.is_clarification_question ? ' thread__msg--question' : ''
              }`}
            >
              <div className="thread__meta">
                <span>{m.author.full_name}</span>
                {m.is_clarification_question && <span className="badge badge--due-due_soon">Уточняющий вопрос</span>}
                <span className="muted">{formatDateTime(m.created_at)}</span>
              </div>
              <p className="prose">{m.text}</p>
            </li>
          ))}
        </ul>
      )}
      {canWrite && (
        <form className="composer" onSubmit={send}>
          <textarea
            className="input"
            rows={3}
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder={replying ? 'Ответ на вопрос' : 'Сообщение ответственному'}
            aria-label={replying ? 'Ответ на вопрос' : 'Сообщение'}
          />
          <div className="form__actions">
            <button type="submit" className="btn" disabled={busy || !text.trim()}>
              {busy ? 'Отправляем…' : replying ? 'Ответить' : 'Отправить'}
            </button>
            {error && <span className="error-text">{error}</span>}
          </div>
        </form>
      )}
    </div>
  );
}
