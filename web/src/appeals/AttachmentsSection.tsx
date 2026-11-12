import { useState } from 'react';
import { Paperclip } from 'lucide-react';
import { errorMessage } from '../api/errors';
import { downloadAttachment, uploadAttachment } from '../api/files';
import type { Schemas } from '../api/types';
import { formatDateTime, formatSize } from '../lib/format';

type Appeal = Schemas['Appeal'];
type Attachment = Schemas['Attachment'];

/** Вложения из карточки. Приложить файл — если в allowed_actions есть upload_attachment. */
export function AttachmentsSection({ appeal }: { appeal: Appeal }) {
  const [items, setItems] = useState<Attachment[]>(appeal.attachments);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const canUpload = appeal.allowed_actions.includes('upload_attachment');

  if (items.length === 0 && !canUpload) return null;

  async function upload(files: FileList | null) {
    if (!files?.length) return;
    setBusy(true);
    setError('');
    const errors: string[] = [];
    for (const f of Array.from(files)) {
      try {
        const att = await uploadAttachment(appeal.id, f);
        setItems((list) => [...list, att]);
      } catch (e) {
        errors.push(`${f.name}: ${errorMessage(e)}`);
      }
    }
    setError(errors.join(' '));
    setBusy(false);
  }

  async function download(att: Attachment) {
    setError('');
    try {
      await downloadAttachment(att);
    } catch (e) {
      setError(errorMessage(e));
    }
  }

  return (
    <section className="section">
      <div className="section__head">
        <h2 className="section__title">Файлы{items.length > 0 && <span className="section__count">{items.length}</span>}</h2>
        {canUpload && (
          <label className="file-pick">
            <input
              type="file"
              multiple
              disabled={busy}
              onChange={(e) => {
                upload(e.target.files);
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
      {items.length === 0 && <p className="muted section__empty">Файлов пока нет.</p>}
      {items.length > 0 && (
        <ul className="file-list">
          {items.map((att) => (
            <li key={att.id}>
              <button type="button" className="link-btn" onClick={() => download(att)}>
                {att.filename}
              </button>
              <span className="muted">
                {formatSize(att.size_bytes)} · {att.uploaded_by.full_name} · {formatDateTime(att.created_at)}
              </span>
            </li>
          ))}
        </ul>
      )}
      {error && <p className="error-text">{error}</p>}
    </section>
  );
}
