import { useMemo, useState, type FormEvent, type ReactNode } from 'react';
import { ChevronUp } from 'lucide-react';
import { api, unwrap } from '../api/client';
import { errorMessage } from '../api/errors';
import type { Schemas } from '../api/types';
import { useDictionaries } from '../app/dictionaries';
import { PublishDiscussionForm } from '../discussions/PublishDiscussionForm';
import { useAsync } from '../lib/useAsync';
import { Modal } from '../app/Modal';
import { Select } from '../app/Select';
import { useToast } from '../app/Toast';
import { usePopover } from '../app/usePopover';
import { ActionModal, useActionModal } from './actionModal';
import { needsAssignee } from './cardSections';

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

/** Короткие подписи кнопок. Чего здесь нет, берётся из словаря (/dictionaries, actions). */
const SHORT: Partial<Record<Action, string>> = {
  take: 'Взять',
  request_info: 'Задать вопрос',
  publish_discussion: 'На обсуждение',
};

/** Действия, которые нужны реже остальных. */
const RARE: Action[] = ['reassign', 'publish_discussion'];

/** Что сказать после действия: «A-021: вопрос отправлен автору». */
const DONE: Partial<Record<Action, string>> = {
  take: 'взято на рассмотрение',
  request_info: 'вопрос отправлен автору',
  start_work: 'переведено в работу',
  reject: 'отклонено',
  implement: 'отмечено реализованным',
  accept_feedback: 'отзыв принят',
  reassign: 'ответственный изменён',
  publish_discussion: 'вынесено на обсуждение',
};

/** Какое действие сделать главной кнопкой: то, что двигает обращение дальше. */
const PRIMARY: Action[] = ['take', 'start_work', 'implement', 'accept_feedback', 'request_info'];

export function ActionsPanel({ appeal, onUpdated }: Props) {
  const dict = useDictionaries();
  const toast = useToast();
  const [open, setOpen] = useState<Action | null>(null);
  const [busy, setBusy] = useState(false);
  const modal = useMemo(() => ({ setBusy, cancel: () => setOpen(null) }), []);
  const menu = usePopover<HTMLDivElement>();
  // Уже вынесенное обращение второй раз не выносим: ссылка на обсуждение — в карточке.
  // Пока ответственного нет, его назначают в блоке внутри карточки (AssignSection), а не кнопкой «Переназначить».
  const assignInCard = needsAssignee(appeal);
  const actions = PROCESSING.filter(
    (a) =>
      appeal.allowed_actions.includes(a) &&
      !(a === 'publish_discussion' && appeal.discussion) &&
      !(a === 'reassign' && assignInCard),
  );
  if (actions.length === 0) return null;

  const label = (a: Action) => SHORT[a] ?? dict.data?.actions.find((x) => x.code === a)?.label ?? a;
  const primary = PRIMARY.find((a) => actions.includes(a));
  // Редкие действия прячем под «Ещё», только когда кнопок больше трёх: иначе всё помещается в ряд.
  const rare = actions.length > 3 ? actions.filter((a) => RARE.includes(a)) : [];
  const shown = actions.filter((a) => !rare.includes(a));
  const done = (a: Appeal) => {
    if (open) toast(`${a.number}: ${DONE[open] ?? 'сохранено'}`);
    setOpen(null);
    onUpdated(a);
  };
  const id = { params: { path: { appeal_id: appeal.id } } };

  return (
    <>
      {/* Действия закреплены внизу карточки: отказ красным текстом слева, главное — тёмной кнопкой справа.
          Когда действий много, редкие (переназначить, вынести на обсуждение) уходят под «Ещё». */}
      <footer className="sheet__foot" role="group" aria-label="Действия">
        {actions.includes('reject') && (
          <button type="button" className="btn btn--text btn--danger sheet__reject" aria-haspopup="dialog" onClick={() => setOpen('reject')}>
            {label('reject')}
          </button>
        )}
        {rare.length > 0 && (
          <div className="sheet__more" ref={menu.ref}>
            <button
              type="button"
              className="btn btn--soft"
              aria-haspopup="menu"
              aria-expanded={menu.open}
              data-popover-trigger
              onClick={() => menu.setOpen(!menu.open)}
            >
              Ещё <ChevronUp size={16} aria-hidden="true" />
            </button>
            {menu.open && (
              <div className="pop pop--above" role="menu">
                {rare.map((a) => (
                  <button
                    key={a}
                    type="button"
                    className="pop__item"
                    role="menuitem"
                    onClick={() => {
                      menu.setOpen(false);
                      setOpen(a);
                    }}
                  >
                    {dict.data?.actions.find((x) => x.code === a)?.label ?? label(a)}
                  </button>
                ))}
              </div>
            )}
          </div>
        )}
        {shown
          .filter((a) => a !== 'reject' && a !== primary)
          .map((a) => (
            <button key={a} type="button" className="btn btn--soft" aria-haspopup="dialog" onClick={() => setOpen(a)}>
              {label(a)}
            </button>
          ))}
        {primary && (
          <button type="button" className="btn sheet__primary" aria-haspopup="dialog" onClick={() => setOpen(primary)}>
            {label(primary)}
          </button>
        )}
      </footer>

      <Modal open={open !== null} onClose={() => setOpen(null)} labelledBy="action-title" locked={busy} closeOnBackdrop={false}>
        <ActionModal.Provider value={modal}>

      {open === 'take' && (
        <TextAction
          title="Взять на рассмотрение"
          fieldLabel="Первый ответ автору"
          hint="Необязательно. Автор увидит, что обращение взяли."
          optional
          submitLabel="Взять"
          onSubmit={(text) => unwrap(api.POST('/api/v1/appeals/{appeal_id}/take', { ...id, body: { comment: text || null } }))}
          onDone={done}
        />
      )}
      {open === 'request_info' && (
        <TextAction
          title="Вопрос автору"
          fieldLabel="Вопрос"
          hint="Автор получит вопрос в Telegram и сможет ответить там или здесь."
          submitLabel="Задать вопрос"
          onSubmit={(question) => unwrap(api.POST('/api/v1/appeals/{appeal_id}/request-info', { ...id, body: { question } }))}
          onDone={done}
        />
      )}
      {open === 'start_work' && (
        <TextAction
          title="В работу"
          fieldLabel="Что решили сделать"
          hint="Автор увидит решение в карточке."
          submitLabel="В работу"
          onSubmit={(decision) => unwrap(api.POST('/api/v1/appeals/{appeal_id}/start-work', { ...id, body: { decision } }))}
          onDone={done}
        />
      )}
      {open === 'reject' && (
        <TextAction
          title="Отклонить обращение"
          fieldLabel="Причина отказа"
          hint="Её увидит автор."
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
          fieldLabel="Ответ автору"
          hint="Необязательно."
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
  hint?: string;
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
        <textarea
          className="input"
          rows={4}
          value={text}
          onChange={(e) => setText(e.target.value)}
          required={!props.optional}
          data-autofocus
        />
        {props.hint && <span className="field__hint muted">{props.hint}</span>}
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
        <span className="field__label">Что сделано</span>
        <textarea className="input" rows={3} value={result} onChange={(e) => setResult(e.target.value)} required data-autofocus />
      </label>
      <p className="muted field__hint">
        Обращение попадёт в общую ленту, её видят все сотрудники. Если не заполнить поля ниже, в ленте будут краткая суть
        и результат.
      </p>
      <label className="field">
        <span className="field__label">
          Для ленты: что предложили <span className="muted">· необязательно</span>
        </span>
        <input className="input" value={publicSummary} onChange={(e) => setPublicSummary(e.target.value)} />
      </label>
      <label className="field">
        <span className="field__label">
          Для ленты: что сделали <span className="muted">· необязательно</span>
        </span>
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
        <span className="field__label">Причина</span>
        <textarea className="input" rows={2} value={reason} onChange={(e) => setReason(e.target.value)} required />
        <span className="field__hint muted">Попадёт в историю. Срок первого ответа начнётся заново.</span>
      </label>
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
    <form className="dialog-form" onSubmit={submit}>
      <h2 id="action-title" className="dialog-form__title">
        {props.title}
      </h2>
      {props.children}
      {error && (
        <p className="error-text" role="alert">
          {error}
        </p>
      )}
      <div className="dialog-form__actions">
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
