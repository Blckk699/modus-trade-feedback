import { useState, type FormEvent } from 'react';
import { api, unwrap } from '../api/client';
import { errorMessage } from '../api/errors';
import type { Schemas } from '../api/types';
import { useActionModal } from '../appeals/actionModal';
import { deadlineFromDate, defaultDeadlineDate, todayDate } from './deadline';

type Appeal = Schemas['Appeal'];
type Discussion = Schemas['Discussion'];

/** Вынос на общее обсуждение: публичная формулировка и срок (история 38). */
export function PublishDiscussionForm({ appeal, onDone }: { appeal: Appeal; onDone: (d: Discussion) => void }) {
  const [text, setText] = useState(appeal.public_summary ?? appeal.summary ?? '');
  const [date, setDate] = useState(defaultDeadlineDate());
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const canSubmit = Boolean(text.trim() && date);
  const cancel = useActionModal(busy);

  async function submit(e: FormEvent) {
    e.preventDefault();
    if (!canSubmit) return;
    setBusy(true);
    setError('');
    try {
      const d = await unwrap(
        api.POST('/api/v1/appeals/{appeal_id}/discussion', {
          params: { path: { appeal_id: appeal.id } },
          body: { public_text: text.trim(), deadline: deadlineFromDate(date) },
        }),
      );
      onDone(d);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <form className="dialog-form" onSubmit={submit}>
      <h2 id="action-title" className="dialog-form__title">
        Вынести на общее обсуждение
      </h2>
      <p className="muted field__hint">
        Обсуждение увидят все сотрудники. Переписка по обращению остаётся закрытой. Автора спросят, показывать ли его
        имя. Без согласия будет указано только подразделение.
      </p>
      <label className="field">
        <span className="field__label">Что обсуждаем</span>
        <textarea className="input" rows={3} value={text} onChange={(e) => setText(e.target.value)} required data-autofocus />
      </label>
      <label className="field field--narrow">
        <span className="field__label">Голосование до</span>
        <input className="input" type="date" value={date} min={todayDate()} onChange={(e) => setDate(e.target.value)} required />
      </label>
      {error && (
        <p className="error-text" role="alert">
          {error}
        </p>
      )}
      <div className="dialog-form__actions">
        <button type="button" className="btn btn--soft" onClick={cancel} disabled={busy}>
          Отмена
        </button>
        <button type="submit" className="btn" disabled={busy || !canSubmit}>
          {busy ? 'Публикуем…' : 'Вынести на обсуждение'}
        </button>
      </div>
    </form>
  );
}
