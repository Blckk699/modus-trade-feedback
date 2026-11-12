import { RowsSkeleton } from '../app/ListStates';
import { useEffect, useState, type FormEvent } from 'react';
import { api, unwrap } from '../api/client';
import { errorMessage } from '../api/errors';
import { useDictionaries } from '../app/dictionaries';
import { useAsync } from '../lib/useAsync';
import type { Priority } from './shared';

const PRIORITIES: Priority[] = ['high', 'medium', 'low'];

function loadAll() {
  return Promise.all([unwrap(api.GET('/api/v1/admin/deadline-rules')), unwrap(api.GET('/api/v1/admin/settings'))]);
}

/** Сроки первого ответа по приоритетам (история 69) и время утренней сводки. */
export function DeadlinesTab() {
  const dict = useDictionaries();
  const data = useAsync(loadAll, []);
  const [days, setDays] = useState<Record<string, string>>({});
  const [digestTime, setDigestTime] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    if (data.state.status !== 'ready') return;
    const [rules, settings] = data.state.data;
    setDays(Object.fromEntries(rules.map((r) => [r.priority, String(r.business_days)])));
    setDigestTime(settings.digest_time);
  }, [data.state]);

  const s = data.state;
  if (s.status === 'loading') return <RowsSkeleton />;
  if (s.status === 'error')
    return (
      <div className="notice">
        <p className="error-text">{s.message}</p>
        <button type="button" className="btn btn--ghost" onClick={data.reload}>
          Повторить
        </button>
      </div>
    );
  const [rules, settings] = s.data;
  const known = PRIORITIES.filter((p) => rules.some((r) => r.priority === p) || p in days);

  const invalid = known.filter((p) => !/^\d+$/.test(days[p] ?? '') || Number(days[p]) < 1 || Number(days[p]) > 30);

  async function submit(e: FormEvent) {
    e.preventDefault();
    setError('');
    setSaved(false);
    if (invalid.length) return setError('Срок: целое число рабочих дней от 1 до 30.');
    setBusy(true);
    try {
      const nextRules = await unwrap(
        api.PUT('/api/v1/admin/deadline-rules', {
          body: known.map((p) => ({ priority: p, business_days: Number(days[p]) })),
        }),
      );
      const nextSettings =
        digestTime !== settings.digest_time
          ? await unwrap(api.PATCH('/api/v1/admin/settings', { body: { digest_time: digestTime } }))
          : settings;
      data.set([nextRules, nextSettings]);
      setSaved(true);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <form className="form settings-form" onSubmit={submit} noValidate>
      <p className="muted">
        Срок первого ответа считается в рабочих днях. Новые значения действуют для обращений, которые подали или
        переназначили после сохранения.
      </p>
      <div className="settings-grid">
        {known.map((p) => (
          <label key={p} className="field">
            <span className="field__label">Приоритет «{dict.priorityLabel(p)}»</span>
            <input
              className="input"
              type="number"
              min={1}
              max={30}
              inputMode="numeric"
              value={days[p] ?? ''}
              onChange={(e) => setDays({ ...days, [p]: e.target.value })}
              aria-invalid={invalid.includes(p)}
            />
            <span className="field__hint muted">рабочих дней</span>
          </label>
        ))}
        <label className="field">
          <span className="field__label">Утренняя сводка</span>
          <input className="input" type="time" value={digestTime} onChange={(e) => setDigestTime(e.target.value)} />
          <span className="field__hint muted">время отправки в Telegram, UTC{settings.timezone}</span>
        </label>
      </div>
      <div className="form__actions">
        <button type="submit" className="btn" disabled={busy}>
          {busy ? 'Сохраняем…' : 'Сохранить'}
        </button>
        {saved && <span className="muted">Сохранено.</span>}
        {error && <span className="error-text">{error}</span>}
      </div>
    </form>
  );
}
