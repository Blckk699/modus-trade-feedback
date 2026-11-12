import { useEffect, useState, type DragEvent, type FormEvent } from 'react';
import { AudioLines, ChevronRight, Upload } from 'lucide-react';
import { Link, useNavigate } from 'react-router-dom';
import { useBackground } from '../app/background';
import { LoadError, RowsSkeleton } from '../app/ListStates';
import { PageHead } from '../app/PageHead';
import { plural } from '../lib/plural';
import { api, unwrap } from '../api/client';
import { errorMessage } from '../api/errors';
import { uploadMeeting } from '../api/files';
import { formatDateTime, formatSize } from '../lib/format';
import { useAsync } from '../lib/useAsync';
import { Modal } from '../app/Modal';
import { MeetingStatusBadge } from './MeetingStatusBadge';
import { useReloadOnCardClose } from '../app/cardClosed';
import { EmptyState } from '../app/EmptyState';

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
  const background = useBackground();
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
      setFile(null);
      setBusy(false);
      list.reload();
      navigate(`/meetings/${m.id}`, { state: { background } });
    } catch (err) {
      setError(errorMessage(err));
      setBusy(false);
    }
  }

  return (
    <section className="page">
      <PageHead over="Запись встречи превращается в черновики обращений" title="Совещания" />

      <div className="card upload">
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
          <span className="dropzone__icon" aria-hidden="true">
            <AudioLines size={26} />
          </span>
          <span className="dropzone__title">Перетащите запись сюда</span>
          <span className="dropzone__hint">mp3, m4a, wav, ogg, webm · до 200 МБ</span>
          <span className="btn dropzone__btn">
            <Upload size={16} aria-hidden="true" /> Выбрать файл
          </span>
        </label>
        <ol className="steps">
          <li>
            <strong>Расшифруем</strong>
            <span>Запись станет текстом за пару минут.</span>
          </li>
          <li>
            <strong>Найдём вопросы</strong>
            <span>Каждую проблему и идею оформим черновиком с цитатой.</span>
          </li>
          <li>
            <strong>Вы решаете</strong>
            <span>Обращением станет только то, что вы подтвердите.</span>
          </li>
        </ol>
        {error && !file && (
          <p className="error-text upload__error" role="alert">
            {error}
          </p>
        )}
      </div>

      <Modal open={file !== null} onClose={reset} labelledBy="upload-title" locked={busy}>
        {file && (
          <form className="dialog-form" onSubmit={submit}>
            <h2 id="upload-title" className="dialog-form__title">
              Загрузить запись
            </h2>

            <div className="audio-file">
              <span className="audio-file__icon" aria-hidden="true">
                <AudioLines size={20} />
              </span>
              <span className="audio-file__meta">
                <span className="audio-file__name" title={file.name}>
                  {file.name}
                </span>
                <span className="audio-file__sub">
                  {formatSize(file.size)}
                  {duration !== null && ` · ${formatDuration(duration)}`}
                </span>
              </span>
            </div>

            <label className="field">
              <span className="field__label">Название совещания</span>
              <input
                className="input"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="Например, планёрка закупок"
                data-autofocus
              />
            </label>

            {error && (
              <p className="error-text" role="alert">
                {error}
              </p>
            )}

            <div className="dialog-form__actions">
              <button type="button" className="btn btn--soft" onClick={reset} disabled={busy}>
                Отмена
              </button>
              <button type="submit" className="btn" disabled={busy}>
                {busy ? 'Загружаем…' : 'Загрузить и расшифровать'}
              </button>
            </div>
          </form>
        )}
      </Modal>

      {list.state.status === 'loading' && <RowsSkeleton rows={2} />}
      {list.state.status === 'error' && <LoadError message={list.state.message} onRetry={list.reload} />}
      {list.state.status === 'ready' && list.state.data.length === 0 && (
        <EmptyState icon="audio" title="Записей пока нет">
          Загруженные совещания и черновики из них появятся здесь.
        </EmptyState>
      )}
      {list.state.status === 'ready' && list.state.data.length > 0 && (
        <article className="card">
          <header className="card__head">
            <h2 className="card__title">Загруженные записи</h2>
          </header>
          <ul className="rows">
            {list.state.data.map((m) => (
              <li key={m.id}>
                <Link to={`/meetings/${m.id}`} state={{ background }} className="row">
                  <span className="type-icon type-icon--audio" aria-hidden="true">
                    <AudioLines size={18} />
                  </span>
                  <span className="row__main">
                    <span className="row__title">{m.title}</span>
                    <span className="row__meta">
                      {formatDateTime(m.created_at)}
                      {m.status === 'ready' &&
                        ` · ${m.drafts_total} ${plural(m.drafts_total, ['черновик', 'черновика', 'черновиков'])}${
                          m.drafts_pending > 0 ? `, ${m.drafts_pending} ждут решения` : ', все разобраны'
                        }`}
                    </span>
                  </span>
                  <span className="row__side">
                    <MeetingStatusBadge status={m.status} />
                  </span>
                  <ChevronRight className="row__chev" size={18} aria-hidden="true" />
                </Link>
              </li>
            ))}
          </ul>
        </article>
      )}
    </section>
  );
}
