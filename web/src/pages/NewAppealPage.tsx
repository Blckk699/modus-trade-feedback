import { useEffect, useRef, useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import { ArrowLeft, Check, Paperclip, X } from 'lucide-react';
import { api, unwrap } from '../api/client';
import { errorMessage } from '../api/errors';
import { fieldErrors } from '../api/fieldErrors';
import { uploadAttachment } from '../api/files';
import type { Schemas } from '../api/types';
import { useBackground } from '../app/background';
import { useDictionaries } from '../app/dictionaries';
import { PageHead } from '../app/PageHead';
import { Select } from '../app/Select';
import { TypeIcon } from '../appeals/TypeIcon';
import { WhoWhenBlock } from '../appeals/WhoWhenBlock';
import { formatSize } from '../lib/format';
import { useAsync } from '../lib/useAsync';
import { useCardLock, useInCard } from './CardModal';

type AppealType = Schemas['AppealType'];
type Priority = Schemas['Priority'];
type Appeal = Schemas['Appeal'];

interface Created {
  appeal: Appeal;
  failedFiles: { name: string; message: string }[];
}

/** Подсказка под названием типа: помогает выбрать, не читая инструкцию. */
const TYPE_HINT: Record<AppealType, string> = {
  problem: 'Что-то мешает работать',
  suggestion: 'Есть идея, как сделать лучше',
  praise: 'Отметить хорошую работу',
};

const TEXT_PLACEHOLDER: Record<AppealType, string> = {
  problem: 'Что происходит, где и как часто',
  suggestion: 'Что предлагаете изменить и что это даст',
  praise: 'Что получилось хорошо и кого отметить',
};

/** Подача обращения. Из приложения открывается окном поверх экрана, по прямой ссылке — отдельной страницей. */
export function NewAppealPage() {
  const dict = useDictionaries();
  const inCard = useInCard();
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
      setErrors({ text: 'Напишите хотя бы пару слов.' });
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

  const activeCategories = categories.state.status === 'ready' ? categories.state.data.filter((c) => c.is_active) : [];

  const body = created ? (
    <CreatedPanel {...created} />
  ) : (
    <form className="compose" onSubmit={submit} noValidate>
      <header className="compose__head">
        {/* На отдельной странице заголовок уже стоит в шапке. */}
        {inCard && <h1 className="compose__title">Новое обращение</h1>}
        <p className="muted">Его получит ответственный за тему и ответит в срок.</p>
      </header>

      <fieldset className="field">
        <legend className="field__label">О чём</legend>
        <div className="choice">
          {(dict.data?.appeal_types ?? []).map((t) => (
            <label key={t.code} className="choice__item">
              <input type="radio" name="type" value={t.code} checked={type === t.code} onChange={() => setType(t.code as AppealType)} />
              <span className="choice__box">
                <TypeIcon type={t.code as AppealType} />
                <span className="choice__check" aria-hidden="true">
                  <Check size={12} strokeWidth={3} />
                </span>
                <span className="choice__text">
                  <span className="choice__label">{t.label}</span>
                  <span className="choice__hint">{TYPE_HINT[t.code as AppealType]}</span>
                </span>
              </span>
            </label>
          ))}
        </div>
      </fieldset>

      <label className="field">
        <span className="field__label">Описание</span>
        {/* У отзыва нет поля «Как это можно решить»: описание занимает его место, и форма не меняет высоту при смене типа. */}
        <textarea
          className={type === 'praise' ? 'input compose__text compose__text--tall' : 'input compose__text'}
          rows={5}
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder={TEXT_PLACEHOLDER[type]}
          aria-invalid={Boolean(errors.text)}
          data-autofocus
        />
        {errors.text && <span className="error-text field__hint">{errors.text}</span>}
      </label>

      {type !== 'praise' && (
        <label className="field">
          <span className="field__label">
            Как это можно решить <span className="muted">· необязательно</span>
          </span>
          <textarea className="input" rows={2} value={solution} onChange={(e) => setSolution(e.target.value)} />
        </label>
      )}

      <div className="form__row">
        <label className="field">
          <span className="field__label">Категория</span>
          <Select value={categoryId} onChange={(e) => setCategoryId(e.target.value)}>
            <option value="">Пусть решит администратор</option>
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

      {files.length > 0 && (
        <ul className="file-list" aria-label="Выбранные файлы">
          {files.map((f, i) => (
            <li key={`${f.name}-${i}`}>
              <span>{f.name}</span>
              <span className="muted">{formatSize(f.size)}</span>
              <button
                type="button"
                className="file-list__remove"
                aria-label={`Убрать файл ${f.name}`}
                onClick={() => setFiles((prev) => prev.filter((_, j) => j !== i))}
              >
                <X size={16} aria-hidden="true" />
              </button>
            </li>
          ))}
        </ul>
      )}

      {error && (
        <p className="error-text" role="alert">
          {error}
        </p>
      )}

      <div className="compose__foot">
        <label className="file-pick">
          <input
            type="file"
            multiple
            aria-label="Приложить файлы, до 20 МБ каждый"
            onChange={(e) => {
              // Копируем список до сброса поля: updater setFiles выполнится позже.
              const picked = Array.from(e.target.files ?? []);
              setFiles((prev) => [...prev, ...picked]);
              e.target.value = '';
            }}
          />
          <span className="btn btn--soft">
            <Paperclip size={16} aria-hidden="true" /> Приложить файл
          </span>
        </label>
        <span className="muted compose__limit">до 20 МБ</span>
        <button type="submit" className="btn btn--accent compose__send" disabled={busy}>
          {busy ? 'Отправляем…' : 'Отправить'}
        </button>
      </div>
    </form>
  );

  if (inCard) return body;
  return (
    <section className="solo">
      <PageHead over="Мои обращения" title="Новое обращение" />
      <Link to="/my" className="back-link">
        <ArrowLeft size={16} aria-hidden="true" /> Мои обращения
      </Link>
      <div className="card solo__card solo__card--pad">{body}</div>
    </section>
  );
}

function CreatedPanel({ appeal, failedFiles }: Created) {
  const background = useBackground();
  const inCard = useInCard();
  // После подачи фокус на заголовке: диктор объявит результат, а не «тело страницы».
  const title = useRef<HTMLHeadingElement>(null);
  useEffect(() => title.current?.focus(), []);
  return (
    <div className="created">
      <span className="created__mark" aria-hidden="true">
        <Check size={26} strokeWidth={2.5} />
      </span>
      <h1 ref={title} tabIndex={-1} className="compose__title" role="status">
        Обращение {appeal.number} подано
      </h1>
      <WhoWhenBlock appeal={appeal} />

      {failedFiles.length > 0 && (
        <div className="notice notice--danger" role="alert">
          <p className="notice__title">Не все файлы загрузились</p>
          <p>Приложите их ещё раз из карточки обращения.</p>
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
        <Link to="/my" replace className="btn btn--soft">
          К моим обращениям
        </Link>
        <Link to={`/appeals/${appeal.id}`} replace state={inCard ? { background } : undefined} className="btn">
          Открыть обращение
        </Link>
      </div>
    </div>
  );
}
