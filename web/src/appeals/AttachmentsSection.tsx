import { useEffect, useRef, useState, type DragEvent } from 'react';
import { Paperclip, Play, UploadCloud } from 'lucide-react';
import { errorMessage } from '../api/errors';
import { downloadAttachment, uploadAttachment } from '../api/files';
import type { Schemas } from '../api/types';
import { formatSize } from '../lib/format';
import { fileKind, splitBySize } from './attachments';
import { AttachmentViewer, Thumb } from './AttachmentViewer';
import { rememberLocal } from './useAttachmentUrl';

type Appeal = Schemas['Appeal'];
type Attachment = Schemas['Attachment'];

/**
 * Вложения в карточке — галерея: плитки с превью, просмотр каруселью, загрузка кнопкой
 * или перетаскиванием файлов на раздел. Приложить можно, если в allowed_actions есть upload_attachment.
 */
export function AttachmentsSection({ appeal }: { appeal: Appeal }) {
  const [items, setItems] = useState<Attachment[]>(appeal.attachments);
  const [pending, setPending] = useState<string[]>([]);
  const [error, setError] = useState('');
  const [over, setOver] = useState(false);
  const [viewing, setViewing] = useState<number | null>(null);
  const depth = useRef(0);
  const canUpload = appeal.allowed_actions.includes('upload_attachment');
  const busy = pending.length > 0;

  if (items.length === 0 && !canUpload) return null;

  async function upload(list: FileList | File[] | null) {
    const { ok, tooLarge } = splitBySize(Array.from(list ?? []));
    const errors = tooLarge.map((name) => `${name}: больше 20 МБ.`);
    setError(errors.join(' '));
    if (ok.length === 0) return;
    setPending(ok.map((f) => f.name));
    for (const f of ok) {
      try {
        const att = await uploadAttachment(appeal.id, f);
        rememberLocal(att.id, f);
        setItems((prev) => [...prev, att]);
      } catch (e) {
        errors.push(`${f.name}: ${errorMessage(e)}`);
      }
      setPending((names) => names.slice(1));
    }
    setError(errors.join(' '));
  }

  async function download(att: Attachment) {
    setError('');
    try {
      await downloadAttachment(att);
    } catch (e) {
      setError(errorMessage(e));
    }
  }

  // Перетаскивание: считаем входы и выходы, иначе подсветка мигает над вложенными элементами.
  const hasFiles = (e: DragEvent) => Array.from(e.dataTransfer.types).includes('Files');
  const drag = canUpload
    ? {
        onDragEnter: (e: DragEvent) => {
          if (!hasFiles(e)) return;
          e.preventDefault();
          depth.current += 1;
          setOver(true);
        },
        onDragOver: (e: DragEvent) => {
          if (hasFiles(e)) e.preventDefault();
        },
        onDragLeave: (e: DragEvent) => {
          if (!hasFiles(e)) return;
          depth.current = Math.max(0, depth.current - 1);
          if (depth.current === 0) setOver(false);
        },
        onDrop: (e: DragEvent) => {
          if (!hasFiles(e)) return;
          e.preventDefault();
          depth.current = 0;
          setOver(false);
          if (!busy) void upload(e.dataTransfer.files);
        },
      }
    : {};

  return (
    <section className={over ? 'section files files--over' : 'section files'} {...drag}>
      <div className="section__head">
        <h2 className="section__title">Файлы{items.length > 0 && <span className="section__count">{items.length}</span>}</h2>
        {canUpload && (
          <label className="file-pick">
            <input
              type="file"
              multiple
              disabled={busy}
              onChange={(e) => {
                void upload(e.target.files);
                e.target.value = '';
              }}
            />
            <span className="btn btn--soft btn--sm">
              <Paperclip size={15} aria-hidden="true" />
              {busy ? 'Загружаем…' : 'Приложить'}
            </span>
          </label>
        )}
      </div>

      {items.length === 0 && pending.length === 0 && (
        <p className="muted section__empty">{canUpload ? 'Файлов пока нет. Перетащите их сюда или нажмите «Приложить».' : 'Файлов пока нет.'}</p>
      )}

      {(items.length > 0 || pending.length > 0) && (
        <ul className="files__grid">
          {items.map((att, i) => (
            <li key={att.id}>
              <Tile att={att} onOpen={() => setViewing(i)} />
            </li>
          ))}
          {pending.map((name, i) => (
            <li key={`pending-${i}-${name}`} className="files__tile files__tile--pending" role="status">
              <span className="files__thumb">
                <span className="thumb__ph bone" aria-hidden="true" />
              </span>
              <span className="files__name">{name}</span>
              <span className="files__meta">{i === 0 ? 'Загружаем…' : 'В очереди'}</span>
            </li>
          ))}
        </ul>
      )}

      {canUpload && items.length > 0 && <p className="files__hint">Файлы можно перетащить сюда. До 20 МБ каждый.</p>}
      {over && (
        <div className="files__drop" aria-hidden="true">
          <UploadCloud size={22} /> Отпустите, чтобы приложить
        </div>
      )}
      {error && (
        <p className="error-text" role="alert">
          {error}
        </p>
      )}

      {viewing !== null && (
        <AttachmentViewer items={items} index={Math.min(viewing, items.length - 1)} onIndex={setViewing} onClose={() => setViewing(null)} onDownload={download} />
      )}
    </section>
  );
}

/** Плитка файла. Картинка подгружается, когда плитка показалась на экране: файлы бывают по 10 МБ. */
function Tile({ att, onOpen }: { att: Attachment; onOpen: () => void }) {
  const ref = useRef<HTMLButtonElement>(null);
  const [seen, setSeen] = useState(false);
  const kind = fileKind(att);

  useEffect(() => {
    const el = ref.current;
    if (!el || seen) return;
    if (typeof IntersectionObserver === 'undefined') return setSeen(true);
    const io = new IntersectionObserver(
      (entries) => {
        if (entries.some((e) => e.isIntersecting)) {
          setSeen(true);
          io.disconnect();
        }
      },
      { rootMargin: '200px' },
    );
    io.observe(el);
    return () => io.disconnect();
  }, [seen]);

  return (
    <button ref={ref} type="button" className="files__tile" onClick={onOpen} aria-label={`Открыть ${att.filename}, ${formatSize(att.size_bytes)}`}>
      <span className="files__thumb">
        <Thumb att={att} eager={seen} />
        {kind === 'video' && (
          <span className="files__play" aria-hidden="true">
            <Play size={16} />
          </span>
        )}
      </span>
      <span className="files__name">{att.filename}</span>
      <span className="files__meta">{formatSize(att.size_bytes)}</span>
    </button>
  );
}
