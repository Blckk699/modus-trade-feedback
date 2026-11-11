import { useState, type FormEvent } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { api, unwrap } from '../api/client';
import { errorMessage } from '../api/errors';
import { uploadMeeting } from '../api/files';
import { formatDateTime, formatSize } from '../lib/format';
import { useAsync } from '../lib/useAsync';
import { MeetingStatusBadge } from './MeetingStatusBadge';

const ACCEPT = '.mp3,.m4a,.wav,.ogg,.webm,audio/*';

/** Режим «совещание»: загрузка записи и список своих совещаний (истории 48, 62). */
export function MeetingsPage() {
  const navigate = useNavigate();
  const list = useAsync(() => unwrap(api.GET('/api/v1/meetings')), []);
  const [file, setFile] = useState<File | null>(null);
  const [title, setTitle] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function submit(e: FormEvent) {
    e.preventDefault();
    if (!file) return;
    setBusy(true);
    setError('');
    try {
      const m = await uploadMeeting(file, title.trim());
      navigate(`/meetings/${m.id}`);
    } catch (err) {
      setError(errorMessage(err));
      setBusy(false);
    }
  }

  return (
    <section className="page">
      <h1 className="page__title">Совещания</h1>
      <p className="muted">
        Загрузите запись встречи: система расшифрует её и предложит черновики обращений с цитатами. Без вашего
        подтверждения обращения не создаются.
      </p>

      <form className="form" onSubmit={submit}>
        <label className="field">
          <span className="field__label">
            Название <span className="muted">— необязательно</span>
          </span>
          <input className="input" value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Планёрка закупок" />
        </label>
        <div className="field">
          <span className="field__label">
            Аудиозапись <span className="muted">— mp3, m4a, wav, ogg, webm, до 200 МБ</span>
          </span>
          <label className="file-pick">
            <input
              type="file"
              accept={ACCEPT}
              onChange={(e) => {
                setFile(e.target.files?.[0] ?? null);
                e.target.value = '';
              }}
            />
            <span className="btn btn--ghost">{file ? 'Выбрать другой файл' : 'Выбрать файл'}</span>
          </label>
          {file && (
            <span>
              {file.name} <span className="muted">{formatSize(file.size)}</span>
            </span>
          )}
        </div>
        <div className="form__actions">
          <button type="submit" className="btn btn--accent" disabled={busy || !file}>
            {busy ? 'Загружаем…' : 'Загрузить и расшифровать'}
          </button>
          {error && (
            <span className="error-text" role="alert">
              {error}
            </span>
          )}
        </div>
      </form>

      <h2 className="block__title">Загруженные записи</h2>
      {list.state.status === 'loading' && <p className="muted">Загружаем…</p>}
      {list.state.status === 'error' && <p className="error-text">{list.state.message}</p>}
      {list.state.status === 'ready' && list.state.data.length === 0 && <p className="muted">Вы ещё не загружали записи.</p>}
      {list.state.status === 'ready' && list.state.data.length > 0 && (
        <ul className="appeal-list">
          {list.state.data.map((m) => (
            <li key={m.id}>
              <Link to={`/meetings/${m.id}`} className="appeal-row">
                <div className="appeal-row__top">
                  <span className="appeal-row__number">{m.title}</span>
                  <span className="muted appeal-row__date">{formatDateTime(m.created_at)}</span>
                </div>
                <div className="appeal-row__meta">
                  <MeetingStatusBadge status={m.status} />
                  {m.status === 'ready' && (
                    <span className="muted">
                      Черновиков: {m.drafts_total}
                      {m.drafts_pending > 0 ? `, ждут решения: ${m.drafts_pending}` : ', все разобраны'}
                    </span>
                  )}
                </div>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
