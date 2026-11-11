import { useMemo, useState, type FormEvent, type ReactNode } from 'react';
import { api, unwrap } from '../api/client';
import { errorMessage } from '../api/errors';
import type { Schemas } from '../api/types';
import { useDictionaries } from '../app/dictionaries';
import { PublishDiscussionForm } from '../discussions/PublishDiscussionForm';
import { useAsync } from '../lib/useAsync';
import { Modal } from '../app/Modal';
import { Select } from '../app/Select';
import { ActionModal, useActionModal } from './actionModal';

type Appeal = Schemas['Appeal'];
type Action = Schemas['AppealAction'];

/** Действия обработки в карточке. Набор кнопок — ровно allowed_actions от бэкенда. */
const PROCESSING: Action[] = [
  'take',
  'request_info',
  'start_work',
  'reject',
  'implement',
  'accept_feedback',
  'reassign',
  'publish_discussion',
];

interface Props {
  appeal: Appeal;
  onUpdated: (appeal: Appeal) => void;
}

export function ActionsPanel({ appeal, onUpdated }: Props) {
  const dict = useDictionaries();
  const [open, setOpen] = useState<Action | null>(null);
  const [busy, setBusy] = useState(false);
  const modal = useMemo(() => ({ setBusy, cancel: () => setOpen(null) }), []);
  // Уже вынесенное обращение второй раз не выносим: ссылка на обсуждение — в карточке.
  const actions = PROCESSING.filter(
    (a) => appeal.allowed_actions.includes(a) && !(a === 'publish_discussion' && appeal.discussion),
  );
  if (actions.length === 0) return null;

  const label = (a: Action) => dict.data?.actions.find((x) => x.code === a)?.label ?? a;
  const done = (a: Appeal) => {
    setOpen(null);
    onUpdated(a);
  };
  const id = { params: { path: { appeal_id: appeal.id } } };

  return (
    <>
      {/* Кнопки действий строкой, без карточки; форма выбранного действия — в окне. */}
      <div className="actions__buttons" role="group" aria-label="Действия">
        {actions.map((a, i) => (
          <button
            key={a}
            type="button"
            // «Отклонить» — красная обводка; первое действие — основное; остальные — тихие.
            className={`btn${a === 'reject' ? ' btn--ghost btn--danger' : i === 0 ? '' : ' btn--soft'}`}
            aria-haspopup="dialog"
            onClick={() => setOpen(a)}
          >
            {label(a)}
          </button>
        ))}
      </div>

      <Modal open={open !== null} onClose={() => setOpen(null)} labelledBy="action-title" locked={busy} closeOnBackdrop={false}>
        <ActionModal.Provider value={modal}>

      {open === 'take' && (
        <TextAction
          title="Взять на рассмотрение"
          fieldLabel="Первый ответ автору — необязательно"
          optional
          submitLabel="Взять"
          onSubmit={(text) => unwrap(api.POST('/api/v1/appeals/{appeal_id}/take', { ...id, body: { comment: text || null } }))}
          onDone={done}
        />
      )}
      {open === 'request_info' && (
        <TextAction
          title="Уточняющий вопрос автору"
          fieldLabel="Вопрос"
          submitLabel="Задать вопрос"
          onSubmit={(question) => unwrap(api.POST('/api/v1/appeals/{appeal_id}/request-info', { ...id, body: { question } }))}
          onDone={done}
        />
      )}
      {open === 'start_work' && (
        <TextAction
          title="Перевести в работу"
          fieldLabel="Принятое решение — что будет сделано"
          submitLabel="В работу"
          onSubmit={(decision) => unwrap(api.POST('/api/v1/appeals/{appeal_id}/start-work', { ...id, body: { decision } }))}
          onDone={done}
        />
      )}
      {open === 'reject' && (
        <TextAction
          title="Отклонить"
          fieldLabel="Причина отказа — её увидит автор"
          submitLabel="Отклонить"
          danger
          onSubmit={(reason) => unwrap(api.POST('/api/v1/appeals/{appeal_id}/reject', { ...id, body: { reason } }))}
          onDone={done}
        />
      )}
      {open === 'implement' && <ImplementForm appeal={appeal} onDone={done} />}
      {open === 'accept_feedback' && (
        <TextAction
          title="Принять отзыв"
          fieldLabel="Ответ автору — необязательно"
          optional
          submitLabel="Принять"
          onSubmit={(comment) =>
            unwrap(api.POST('/api/v1/appeals/{appeal_id}/accept-feedback', { ...id, body: { comment: comment || null } }))
          }
          onDone={done}
        />
      )}
      {open === 'reassign' && <ReassignForm appeal={appeal} onDone={done} />}
      {open === 'publish_discussion' && (
        <PublishDiscussionForm
          appeal={appeal}
          onDone={(d) => done({ ...appeal, discussion: { id: d.id, status: d.status } })}
        />
      )}
        </ActionModal.Provider>
      </Modal>
    </>
  );
}

/** Общая форма «одно текстовое поле + кнопка». Обязательное поле нельзя отправить пустым. */
function TextAction(props: {
  title: string;
  fieldLabel: string;
  submitLabel: string;
  optional?: boolean;
  danger?: boolean;
  onSubmit: (text: string) => Promise<Appeal>;
  onDone: (a: Appeal) => void;
}) {
  const [text, setText] = useState('');
  return (
    <ActionForm
      title={props.title}
      submitLabel={props.submitLabel}
      danger={props.danger}
      canSubmit={props.optional || Boolean(text.trim())}
      run={() => props.onSubmit(text.trim())}
      onDone={props.onDone}
    >
      <label className="field">
        <span className="field__label">{props.fieldLabel}</span>
        <textarea className="input" rows={3} value={text} onChange={(e) => setText(e.target.value)} required={!props.optional} />
      </label>
    </ActionForm>
  );
}

function ImplementForm({ appeal, onDone }: { appeal: Appeal; onDone: (a: Appeal) => void }) {
  const [result, setResult] = useState('');
  const [publicSummary, setPublicSummary] = useState(appeal.public_summary ?? '');
  const [publicResult, setPublicResult] = useState('');
  return (
    <ActionForm
      title="Отметить реализованным"
      submitLabel="Реализовано"
      canSubmit={Boolean(result.trim())}
      run={() =>
        unwrap(
          api.POST('/api/v1/appeals/{appeal_id}/implement', {
            params: { path: { appeal_id: appeal.id } },
            body: {
              result: result.trim(),
              public_summary: publicSummary.trim() || null,
              public_result: publicResult.trim() || null,
            },
          }),
        )
      }
      onDone={onDone}
    >
      <label className="field">
        <span className="field__label">Результат — что сделано</span>
        <textarea className="input" rows={3} value={result} onChange={(e) => setResult(e.target.value)} required />
      </label>
      <p className="muted field__hint">
        Обращение попадёт в ленту реализованного, которую видят все. Без публичных формулировок в ленте покажутся краткая
        суть и результат.
      </p>
      <label className="field">
        <span className="field__label">Для ленты: что предложили — необязательно</span>
        <input className="input" value={publicSummary} onChange={(e) => setPublicSummary(e.target.value)} />
      </label>
      <label className="field">
        <span className="field__label">Для ленты: что сделали — необязательно</span>
        <input className="input" value={publicResult} onChange={(e) => setPublicResult(e.target.value)} />
      </label>
    </ActionForm>
  );
}

function ReassignForm({ appeal, onDone }: { appeal: Appeal; onDone: (a: Appeal) => void }) {
  const users = useAsync(() => unwrap(api.GET('/api/v1/users')), []);
  const [assigneeId, setAssigneeId] = useState('');
  const [reason, setReason] = useState('');
  const candidates =
    users.state.status === 'ready'
      ? users.state.data.filter((u) => !u.is_disabled && u.role !== 'admin' && u.id !== appeal.assignee?.id)
      : [];
  return (
    <ActionForm
      title="Переназначить ответственного"
      submitLabel="Переназначить"
      canSubmit={Boolean(assigneeId && reason.trim())}
      run={() =>
        unwrap(
          api.POST('/api/v1/appeals/{appeal_id}/reassign', {
            params: { path: { appeal_id: appeal.id } },
            body: { assignee_id: Number(assigneeId), reason: reason.trim() },
          }),
        )
      }
      onDone={onDone}
    >
      <label className="field">
        <span className="field__label">Новый ответственный</span>
        <Select value={assigneeId} onChange={(e) => setAssigneeId(e.target.value)} required>
          <option value="">Выберите сотрудника</option>
          {candidates.map((u) => (
            <option key={u.id} value={u.id}>
              {u.full_name}
              {u.department ? ` — ${u.department.name}` : ''}
              {u.is_absent ? ' (отсутствует)' : ''}
            </option>
          ))}
        </Select>
        {users.state.status === 'error' && <span className="error-text field__hint">{users.state.message}</span>}
      </label>
      <label className="field">
        <span className="field__label">Причина — попадёт в историю</span>
        <textarea className="input" rows={2} value={reason} onChange={(e) => setReason(e.target.value)} required />
      </label>
      <p className="muted field__hint">Срок первого ответа отсчитается заново.</p>
    </ActionForm>
  );
}

function ActionForm(props: {
  title: string;
  submitLabel: string;
  canSubmit: boolean;
  danger?: boolean;
  run: () => Promise<Appeal>;
  onDone: (a: Appeal) => void;
  children: ReactNode;
}) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const cancel = useActionModal(busy);

  async function submit(e: FormEvent) {
    e.preventDefault();
    if (!props.canSubmit) return;
    setBusy(true);
    setError('');
    try {
      props.onDone(await props.run());
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <form className="actions__form" onSubmit={submit}>
      <h2 id="action-title" className="actions__title">
        {props.title}
      </h2>
      {props.children}
      {error && (
        <p className="error-text" role="alert">
          {error}
        </p>
      )}
      <div className="actions__submit">
        <button type="button" className="btn btn--soft" onClick={cancel} disabled={busy}>
          Отмена
        </button>
        <button type="submit" className={`btn${props.danger ? ' btn--danger' : ''}`} disabled={busy || !props.canSubmit}>
          {busy ? 'Сохраняем…' : props.submitLabel}
        </button>
      </div>
    </form>
  );
}
