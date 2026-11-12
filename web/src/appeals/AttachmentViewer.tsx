import { useEffect } from 'react';
import { ChevronLeft, ChevronRight, Download, FileText, Trash2 } from 'lucide-react';
import type { Schemas } from '../api/types';
import { Modal } from '../app/Modal';
import { formatDateTime, formatSize } from '../lib/format';
import { fileBadge, fileKind, stepIndex } from './attachments';
import { useAttachmentUrl } from './useAttachmentUrl';

type Attachment = Schemas['Attachment'];

interface Props {
  items: Attachment[];
  index: number;
  onIndex: (index: number) => void;
  onClose: () => void;
  onDownload: (att: Attachment) => void;
  /** Попросить удалить файл: подтверждение показывает раздел. */
  onDelete: (att: Attachment) => void;
}

/** Просмотр вложений каруселью: стрелки на экране и на клавиатуре, лента миниатюр внизу. */
export function AttachmentViewer({ items, index, onIndex, onClose, onDownload, onDelete }: Props) {
  const att = items[index];
  const many = items.length > 1;

  useEffect(() => {
    if (!many) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'ArrowLeft') onIndex(stepIndex(index, -1, items.length));
      if (e.key === 'ArrowRight') onIndex(stepIndex(index, 1, items.length));
    };
    document.addEventListener('keydown', onKey);
    return () => document.removeEventListener('keydown', onKey);
  }, [index, items.length, many, onIndex]);

  if (!att) return null;

  return (
    <Modal open onClose={onClose} label={`Файл ${index + 1} из ${items.length}: ${att.filename}`} size="viewer">
      <div className="viewer">
        <header className="viewer__head">
          <div className="viewer__name">
            <strong>{att.filename}</strong>
            <span>
              {formatSize(att.size_bytes)} · {att.uploaded_by.full_name} · {formatDateTime(att.created_at)}
            </span>
          </div>
          {many && (
            <span className="viewer__count" aria-hidden="true">
              {index + 1} / {items.length}
            </span>
          )}
          {att.can_delete && (
            <button type="button" className="btn btn--ghost btn--sm btn--danger" onClick={() => onDelete(att)}>
              <Trash2 size={15} aria-hidden="true" /> Удалить
            </button>
          )}
          <button type="button" className="btn btn--soft btn--sm" onClick={() => onDownload(att)}>
            <Download size={15} aria-hidden="true" /> Скачать
          </button>
        </header>

        <div className="viewer__stage">
          {many && (
            <button type="button" className="tool-btn viewer__nav viewer__nav--prev" aria-label="Предыдущий файл" onClick={() => onIndex(stepIndex(index, -1, items.length))}>
              <ChevronLeft size={20} aria-hidden="true" />
            </button>
          )}
          <Slide key={att.id} att={att} onDownload={onDownload} />
          {many && (
            <button type="button" className="tool-btn viewer__nav viewer__nav--next" aria-label="Следующий файл" onClick={() => onIndex(stepIndex(index, 1, items.length))}>
              <ChevronRight size={20} aria-hidden="true" />
            </button>
          )}
        </div>

        {many && (
          <div className="viewer__strip" role="tablist" aria-label="Файлы обращения">
            {items.map((a, i) => (
              <button
                key={a.id}
                type="button"
                role="tab"
                aria-selected={i === index}
                aria-label={a.filename}
                className="viewer__thumb"
                onClick={() => onIndex(i)}
              >
                <Thumb att={a} />
              </button>
            ))}
          </div>
        )}
      </div>
    </Modal>
  );
}

function Slide({ att, onDownload }: { att: Attachment; onDownload: (att: Attachment) => void }) {
  const kind = fileKind(att);
  const playable = kind === 'image' || kind === 'video' || kind === 'audio';
  const src = useAttachmentUrl(att, playable);

  if (!playable) {
    return (
      <div className="viewer__file">
        <span className="viewer__badge">
          <FileText size={22} aria-hidden="true" />
          {fileBadge(att.filename)}
        </span>
        <p>Этот файл в браузере не показать. Скачайте его, чтобы открыть.</p>
        <button type="button" className="btn" onClick={() => onDownload(att)}>
          <Download size={16} aria-hidden="true" /> Скачать
        </button>
      </div>
    );
  }
  if (src.status === 'error') return <p className="viewer__file error-text">Не удалось загрузить файл. Попробуйте скачать его.</p>;
  if (src.status !== 'ready') {
    return (
      <div className="viewer__file" role="status">
        <span className="spinner" aria-hidden="true" /> Загружаем файл…
      </div>
    );
  }
  if (kind === 'image') return <img className="viewer__media" src={src.url} alt={att.filename} />;
  if (kind === 'video') return <video className="viewer__media" src={src.url} controls autoPlay playsInline aria-label={att.filename} />;
  return <audio className="viewer__audio" src={src.url} controls autoPlay aria-label={att.filename} />;
}

/** Миниатюра: у картинки — её уменьшенная копия, у остальных — подпись с типом файла. */
export function Thumb({ att, eager = true }: { att: Attachment; eager?: boolean }) {
  const kind = fileKind(att);
  const src = useAttachmentUrl(att, kind === 'image' && eager, 'preview');
  if (kind === 'image' && src.status === 'ready') return <img className="thumb__img" src={src.url} alt="" />;
  if (kind === 'image' && src.status !== 'error') return <span className="thumb__ph bone" aria-hidden="true" />;
  return (
    <span className={`thumb__ph thumb__ph--${kind}`} aria-hidden="true">
      {fileBadge(att.filename)}
    </span>
  );
}
