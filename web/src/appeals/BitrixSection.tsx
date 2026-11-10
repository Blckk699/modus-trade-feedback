import { useState } from 'react';
import { api, unwrap } from '../api/client';
import { errorMessage } from '../api/errors';
import type { Schemas } from '../api/types';

type Appeal = Schemas['Appeal'];

/** Задача в Битрикс24 (история 39): кнопка по allowed_actions, после создания — ссылка на задачу. */
export function BitrixSection({ appeal, onUpdated }: { appeal: Appeal; onUpdated: (a: Appeal) => void }) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const task = appeal.bitrix_task;
  const canCreate = appeal.allowed_actions.includes('create_bitrix_task');

  if (!task && !canCreate) return null;

  async function create() {
    setBusy(true);
    setError('');
    try {
      const t = await unwrap(
        api.POST('/api/v1/appeals/{appeal_id}/bitrix-task', { params: { path: { appeal_id: appeal.id } } }),
      );
      onUpdated({ ...appeal, bitrix_task: t });
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="block bitrix">
      <h2 className="block__title">Битрикс24</h2>
      {task ? (
        <p>
          <a href={task.url} target="_blank" rel="noopener noreferrer">
            Задача №{task.task_id} в Битрикс24 ↗
          </a>
        </p>
      ) : (
        <div className="form__actions">
          <button type="button" className="btn btn--ghost" onClick={create} disabled={busy}>
            {busy ? 'Создаём…' : 'Создать задачу в Битрикс24'}
          </button>
          {error && (
            <span className="error-text" role="alert">
              {error}
            </span>
          )}
        </div>
      )}
    </div>
  );
}
