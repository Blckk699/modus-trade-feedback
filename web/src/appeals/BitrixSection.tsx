import { useState } from 'react';
import { ArrowUpRight } from 'lucide-react';
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
    <section className="section section--inline">
      <h2 className="section__title">Битрикс24</h2>
      {task ? (
        <a href={task.url} target="_blank" rel="noopener noreferrer" className="more-link">
          Задача №{task.task_id} <ArrowUpRight size={16} aria-hidden="true" />
        </a>
      ) : (
        <button type="button" className="btn btn--soft btn--sm" onClick={create} disabled={busy}>
          {busy ? 'Создаём…' : 'Создать задачу'}
        </button>
      )}
      {error && (
        <p className="error-text section__error" role="alert">
          {error}
        </p>
      )}
    </section>
  );
}
