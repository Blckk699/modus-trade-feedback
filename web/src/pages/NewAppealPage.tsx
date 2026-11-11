import { useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import { api, unwrap } from '../api/client';
import { errorMessage } from '../api/errors';
import { fieldErrors } from '../api/fieldErrors';
import { uploadAttachment } from '../api/files';
import type { Schemas } from '../api/types';
import { useDictionaries } from '../app/dictionaries';
import { formatDateTime, formatSize } from '../lib/format';
import { useAsync } from '../lib/useAsync';
import { Select } from '../app/Select';
import { useCardLock } from './CardModal';

type AppealType = Schemas['AppealType'];
type Priority = Schemas['Priority'];
type Appeal = Schemas['Appeal'];

interface Created {
  appeal: Appeal;
  failedFiles: { name: string; message: string }[];
}

export function NewAppealPage() {
  const dict = useDictionaries();
  const categories = useAsync(() => unwrap(api.GET('/api/v1/categories')), []);

  const [type, setType] = useState<AppealType>('problem');
  const [categoryId, setCategoryId] = useState<string>('');
  const [priority, setPriority] = useState<Priority>('medium');
  const [text, setText] = useState('');
  const [solution, setSolution] = useState('');
  const [files, setFiles] = useState<File[]>([]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [created, setCreated] = useState<Created | null>(null);
  // В окне: пока идёт отправка и загрузка вложений, окно не закрыть — иначе ошибку сервера не увидеть.
  useCardLock(busy);

  async function submit(e: FormEvent) {
    e.preventDefault();
    setError('');
    setErrors({});
    if (!text.trim()) {
      setErrors({ text: 'Опишите проблему или предложение.' });
      return;
    }
    setBusy(true);
    try {
      const appeal = await unwrap(
        api.POST('/api/v1/appeals', {
          body: {
            type,
            category_id: categoryId ? Number(categoryId) : null,
            priority,
            text: text.trim(),
            proposed_solution: type === 'praise' ? null : solution.trim() || null,
            source: 'form',
          },
        }),
      );
      const failedFiles: Created['failedFiles'] = [];
      for (const f of files) {
        try {
          await uploadAttachment(appeal.id, f);
        } catch (err) {
          failedFiles.push({ name: f.name, message: errorMessage(err) });
        }
      }
      setCreated({ appeal, failedFiles });
      window.scrollTo(0, 0);
    } catch (err) {
      setErrors(fieldErrors(err));
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  }

  if (created) return <CreatedPanel {...created} />;

  const activeCategories = categories.state.status === 'ready' ? categories.state.data.filter((c) => c.is_active) : [];

  return (
    <section className="page">
      <Link to="/my" className="back-link">
        ← Мои обращения
      </Link>
      <h1 className="page__title">Новое обращение</h1>

      <form className="form" onSubmit={submit} noValidate>
        <fieldset className="field">
          <legend className="field__label">Тип</legend>
          <div className="segmented">
            {(dict.data?.appeal_types ?? []).map((t) => (
              <label key={t.code} className="segmented__item">
                <input
                  type="radio"
                  name="type"
                  value={t.code}
                  checked={type === t.code}
                  onChange={() => setType(t.code as AppealType)}
                />
                <span>{t.label}</span>
              </label>
            ))}
          </div>
        </fieldset>

        <div className="form__row">
          <label className="field">
            <span className="field__label">Категория</span>
            <Select value={categoryId} onChange={(e) => setCategoryId(e.target.value)}>
              <option value="">Не знаю — распределит администратор</option>
              {activeCategories.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </Select>
            {categories.state.status === 'error' && (
              <span className="error-text field__hint">Категории не загрузились: {categories.state.message}</span>
            )}
            {errors.category_id && <span className="error-text field__hint">{errors.category_id}</span>}
          </label>

          <label className="field">
            <span className="field__label">Приоритет</span>
            <Select value={priority} onChange={(e) => setPriority(e.target.value as Priority)}>
              {(dict.data?.priorities ?? []).map((p) => (
                <option key={p.code} value={p.code}>
                  {p.label}
                </option>
              ))}
            </Select>
          </label>
        </div>

        <label className="field">
          <span className="field__label">Описание</span>
          <textarea
            className="input"
            rows={6}
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder={type === 'praise' ? 'Что работает хорошо и кого отметить' : 'Что происходит, где и как часто'}
            aria-invalid={Boolean(errors.text)}
          />
          {errors.text && <span className="error-text field__hint">{errors.text}</span>}
        </label>

        {type !== 'praise' && (
          <label className="field">
            <span className="field__label">
              Предлагаемое решение <span className="muted">— необязательно</span>
            </span>
            <textarea className="input" rows={3} value={solution} onChange={(e) => setSolution(e.target.value)} />
          </label>
        )}

        <div className="field">
          <span className="field__label">
            Вложения <span className="muted">— до 20 МБ на файл</span>
          </span>
          <label className="file-pick">
            <input
              type="file"
              multiple
              onChange={(e) => {
                // Копируем список до сброса поля: updater setFiles выполнится позже.
                const picked = Array.from(e.target.files ?? []);
                setFiles((prev) => [...prev, ...picked]);
                e.target.value = '';
              }}
            />
            <span className="btn btn--soft">Выбрать файлы</span>
          </label>
          {files.length > 0 && (
            <ul className="file-list">
              {files.map((f, i) => (
                <li key={`${f.name}-${i}`}>
                  <span>{f.name}</span>
                  <span className="muted">{formatSize(f.size)}</span>
                  <button
                    type="button"
                    className="link-btn"
                    onClick={() => setFiles((prev) => prev.filter((_, j) => j !== i))}
                  >
                    Убрать
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>

        {error && (
          <p className="error-text" role="alert">
            {error}
          </p>
        )}
        <div className="form__actions">
          <button type="submit" className="btn btn--accent" disabled={busy}>
            {busy ? 'Отправляем…' : 'Отправить'}
          </button>
        </div>
      </form>
    </section>
  );
}

function CreatedPanel({ appeal, failedFiles }: Created) {
  const due = appeal.first_response_due_at;
  return (
    <section className="page created">
      <div className="upload-modal__top" role="status">
        <span className="upload-modal__done" aria-hidden="true">
          <svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M5 12.5l4.5 4.5L19 7.5" />
          </svg>
        </span>
        <div className="upload-modal__head">
          <h1 className="upload-modal__title">Обращение {appeal.number} подано</h1>
          <p className="muted">{due ? `Первый ответ придёт до ${formatDateTime(due)}.` : 'Статусы будут приходить в бот и сюда.'}</p>
        </div>
      </div>

      <dl className="created__facts">
        <div>
          <dt>Ответственный</dt>
          <dd>{appeal.assignee ? appeal.assignee.full_name : 'Назначит администратор'}</dd>
        </div>
        <div>
          <dt>Первый ответ</dt>
          <dd>{due ? `до ${formatDateTime(due)}` : 'Без срока'}</dd>
        </div>
      </dl>

      {failedFiles.length > 0 && (
        <div className="error-text" role="alert">
          Не все файлы загрузились — приложите их из карточки обращения:
          <ul>
            {failedFiles.map((f) => (
              <li key={f.name}>
                {f.name}: {f.message}
              </li>
            ))}
          </ul>
        </div>
      )}

      <div className="created__actions">
        <Link to="/my" className="btn btn--soft">
          К моим обращениям
        </Link>
        <Link to={`/appeals/${appeal.id}`} className="btn">
          Открыть обращение
        </Link>
      </div>
    </section>
  );
}
