import { useEffect, useState, type DragEvent, type FormEvent } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { api, unwrap } from '../api/client';
import { errorMessage } from '../api/errors';
import { uploadMeeting } from '../api/files';
import { formatDateTime, formatSize } from '../lib/format';
import { useAsync } from '../lib/useAsync';
import { Modal } from '../app/Modal';
import { MeetingStatusBadge } from './MeetingStatusBadge';
import { useReloadOnCardClose } from '../app/cardClosed';

const ACCEPT = '.mp3,.m4a,.wav,.ogg,.webm,audio/*';
const EXTENSIONS = ['mp3', 'm4a', 'wav', 'ogg', 'webm'];
const MAX_SIZE = 200 * 1024 * 1024;

/** Перетащенный файл мимо accept, поэтому формат и размер проверяем сами. */
function checkFile(f: File): string {
  const ext = f.name.split('.').pop()?.toLowerCase() ?? '';
  if (!EXTENSIONS.includes(ext) && !f.type.startsWith('audio/')) return 'Нужна аудиозапись: mp3, m4a, wav, ogg или webm.';
  if (f.size > MAX_SIZE) return 'Файл больше 200 МБ.';
  return '';
}

function formatDuration(sec: number): string {
  const total = Math.round(sec);
  const h = Math.floor(total / 3600);
  const m = Math.floor((total % 3600) / 60);
  const ss = String(total % 60).padStart(2, '0');
  return h > 0 ? `${h}:${String(m).padStart(2, '0')}:${ss}` : `${m}:${ss}`;
}

/** Длительность записи из метаданных; если браузер не прочитал файл — null. */
function useDuration(file: File | null): number | null {
  const [duration, setDuration] = useState<number | null>(null);
  useEffect(() => {
    setDuration(null);
    if (!file) return;
    const url = URL.createObjectURL(file);
    const audio = new Audio();
    audio.preload = 'metadata';
    audio.onloadedmetadata = () => {
      if (Number.isFinite(audio.duration)) setDuration(audio.duration);
    };
    audio.src = url;
    return () => {
      audio.onloadedmetadata = null;
      audio.src = '';
      URL.revokeObjectURL(url);
    };
  }, [file]);
  return duration;
}

function titleFromName(name: string): string {
  return name.replace(/\.[^.]+$/, '').replace(/[_-]+/g, ' ').trim();
}

/** Режим «совещание»: загрузка записи и список своих совещаний (истории 48, 62). */
export function MeetingsPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const list = useAsync(() => unwrap(api.GET('/api/v1/meetings')), []);
  useReloadOnCardClose(list.reload);
  const [file, setFile] = useState<File | null>(null);
  const [title, setTitle] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [dragging, setDragging] = useState(false);
  const duration = useDuration(file);

  function pick(f: File | undefined) {
    if (!f) return;
    const problem = checkFile(f);
    setError(problem);
    if (problem) return;
    setFile(f);
    setTitle(titleFromName(f.name));
  }

  function reset() {
    setFile(null);
    setTitle('');
    setError('');
  }

  function onDrop(e: DragEvent) {
    e.preventDefault();
    setDragging(false);
    pick(e.dataTransfer.files[0]);
  }

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

      <div className="upload">
          <label
            className={dragging ? 'dropzone dropzone--over' : 'dropzone'}
            onDragOver={(e) => {
              e.preventDefault();
              setDragging(true);
            }}
            onDragLeave={() => setDragging(false)}
            onDrop={onDrop}
          >
            <input
              type="file"
              accept={ACCEPT}
              onChange={(e) => {
                pick(e.target.files?.[0]);
                e.target.value = '';
              }}
            />
            <span className="btn btn--ghost dropzone__btn">
              <span aria-hidden="true" className="dropzone__icon">↑</span>
              Выбрать запись
            </span>
            <span className="muted">или перетащите файл сюда</span>
            <span className="dropzone__hint">mp3, m4a, wav, ogg, webm · до 200 МБ</span>
          </label>
          {error && !file && (
            <span className="error-text" role="alert">
              {error}
            </span>
          )}
      </div>

      <Modal open={file !== null} onClose={reset} labelledBy="upload-title" locked={busy}>
        {file && (
          <form className="upload-modal" onSubmit={submit}>
            <div className="upload-modal__top">
              <span className="upload-modal__done" aria-hidden="true">
                <svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M5 12.5l4.5 4.5L19 7.5" />
                </svg>
              </span>
              <div className="upload-modal__head">
                <h2 id="upload-title" className="upload-modal__title">
                  Запись добавлена
                </h2>
              </div>
            </div>

            <div className="upload-card__file">
              <span className="upload-card__icon" aria-hidden="true">
                <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
                  <path d="M4 10v4M8 6v12M12 9v6M16 4v16M20 10v4" />
                </svg>
              </span>
              <span className="upload-card__meta">
                <span className="upload-card__name" title={file.name}>
                  {file.name}
                </span>
                <span className="upload-card__sub">
                  {formatSize(file.size)}
                  {duration !== null && ` · ${formatDuration(duration)}`}
                </span>
              </span>
            </div>

            <label className="upload-card__field">
              <span className="upload-card__label">Название совещания</span>
              <input
                className="input input--soft"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="Например, планёрка закупок"
                data-autofocus
              />
            </label>

            {error && (
              <span className="error-text" role="alert">
                {error}
              </span>
            )}

            <div className="upload-modal__actions">
              <button type="button" className="btn btn--soft" onClick={reset} disabled={busy}>
                Отмена
              </button>
              <button type="submit" className="btn btn--accent" disabled={busy}>
                {busy ? 'Загружаем…' : 'Загрузить и расшифровать'}
              </button>
            </div>
          </form>
        )}
      </Modal>

      <h2 className="block__title">Загруженные записи</h2>
      {list.state.status === 'loading' && <p className="muted">Загружаем…</p>}
      {list.state.status === 'error' && <p className="error-text">{list.state.message}</p>}
      {list.state.status === 'ready' && list.state.data.length === 0 && <p className="muted">Вы ещё не загружали записи.</p>}
      {list.state.status === 'ready' && list.state.data.length > 0 && (
        <ul className="appeal-list">
          {list.state.data.map((m) => (
            <li key={m.id}>
              <Link to={`/meetings/${m.id}`} state={{ background: location }} className="appeal-row">
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
