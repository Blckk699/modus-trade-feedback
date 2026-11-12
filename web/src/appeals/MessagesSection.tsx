import { Fragment, useEffect, useId, useRef, useState, type FormEvent, type KeyboardEvent } from 'react';
import { createPortal } from 'react-dom';
import { ArrowUp, MessageCircle, X } from 'lucide-react';
import { api, unwrap } from '../api/client';
import { ApiError, errorMessage } from '../api/errors';
import type { Schemas } from '../api/types';
import { Avatar } from '../app/Avatar';
import { claimEscape } from '../app/escape';
import { useMe } from '../auth';
import { formatChatDay, formatTime } from '../lib/format';
import { plural } from '../lib/plural';
import { useAsync } from '../lib/useAsync';
import { chatDays, endsRun, startsRun } from './chat';

type Appeal = Schemas['Appeal'];

interface Props {
  appeal: Appeal;
  onAppealChanged: () => void;
  /** Место в подвале карточки для кнопки переписки (его даёт ActionsPanel). */
  entryHost: HTMLElement | null;
}

/** Где стоит чат: рядом с карточкой-панелью (внутри её окна) или сбоку страницы, когда обращение открыто по прямой ссылке. */
interface Place {
  host: HTMLElement;
  side: boolean;
}

/**
 * Закрытая переписка автора и тех, кто ведёт обращение. В карточке места не занимает: кнопка
 * «Переписка» со счётчиком стоит в подвале слева и работает как выключатель: по нажатию чат встаёт отдельной панелью
 * слева от карточки на всю её высоту и так же скрывается. На узком экране чат занимает место карточки.
 * Автору, которому задали уточняющий вопрос, окно открыто сразу: ответ — то, зачем он пришёл.
 * Писать можно, если в allowed_actions есть send_message или reply_clarification.
 */
export function MessagesSection({ appeal, onAppealChanged, entryHost }: Props) {
  const me = useMe();
  const list = useAsync(
    () => unwrap(api.GET('/api/v1/appeals/{appeal_id}/messages', { params: { path: { appeal_id: appeal.id } } })),
    [appeal.id],
  );
  const replying = appeal.allowed_actions.includes('reply_clarification');
  const canWrite = replying || appeal.allowed_actions.includes('send_message');

  const [open, setOpen] = useState(replying);
  const [text, setText] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const panelId = useId();
  const section = useRef<HTMLElement>(null);
  const [place, setPlace] = useState<Place | null>(null);
  const entry = useRef<HTMLButtonElement>(null);
  const input = useRef<HTMLTextAreaElement>(null);
  const scroller = useRef<HTMLDivElement>(null);
  const panel = useRef<HTMLDivElement>(null);
  /** Открыли кнопкой — ставим курсор в поле; открытое само (вопрос автору) фокус не забирает. */
  const byUser = useRef(false);
  /** Отправка идёт. Ref, а не только state: Ctrl+Enter зовёт requestSubmit() в обход выключенной кнопки, и второе нажатие приходит раньше перерисовки. */
  const sending = useRef(false);

  const messages = list.state.status === 'ready' ? list.state.data : [];
  const count = messages.length;

  // Карточка-панель живёт в <dialog>: чат кладём в то же окно, иначе он окажется под подложкой и вне фокуса.
  useEffect(() => {
    const dialog = section.current?.closest('dialog');
    setPlace({ host: dialog ?? document.body, side: Boolean(dialog) });
  }, []);

  // Новое сообщение и открытие чата прокручивают переписку к последнему сообщению.
  useEffect(() => {
    if (open && scroller.current) scroller.current.scrollTop = scroller.current.scrollHeight;
  }, [open, count, place]);

  useEffect(() => {
    if (!open || !place || !byUser.current) return;
    byUser.current = false;
    (input.current ?? panel.current)?.focus();
  }, [open, place]);

  // Кому переписка не положена, раздел не рисуют вовсе (cardSections.canReadMessages).
  // Это запасной случай: права изменились, пока карточка была открыта.
  if (list.state.status === 'error' && list.state.error instanceof ApiError && list.state.error.status === 403) {
    return null;
  }

  function show() {
    byUser.current = true;
    setOpen(true);
  }

  function hide() {
    setOpen(false);
    entry.current?.focus();
  }

  function onKeyDown(e: KeyboardEvent) {
    // Esc скрывает чат, а не карточку под ним.
    if (e.key !== 'Escape') return;
    e.preventDefault();
    e.stopPropagation();
    claimEscape();
    hide();
  }

  async function send(e: FormEvent) {
    e.preventDefault();
    if (!text.trim() || sending.current) return;
    sending.current = true;
    setBusy(true);
    setError('');
    try {
      const msg = await unwrap(
        api.POST('/api/v1/appeals/{appeal_id}/messages', {
          params: { path: { appeal_id: appeal.id } },
          body: { text: text.trim() },
        }),
      );
      setText('');
      if (list.state.status === 'ready') list.set([...list.state.data, msg]);
      else list.reload();
      // Ответ на уточнение возвращает обращение в «На рассмотрении» — перечитываем карточку.
      if (replying) onAppealChanged();
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      sending.current = false;
      setBusy(false);
    }
  }

  const last = messages[count - 1];
  const lastQuestion = [...messages].reverse().find((m) => m.is_clarification_question);
  const asked = replying && lastQuestion ? lastQuestion : null;
  const label = replying ? 'Ответ на вопрос' : 'Сообщение';

  let sub: string;
  if (list.state.status === 'loading') sub = 'Загружаем…';
  else if (list.state.status === 'error') sub = list.state.message;
  else if (asked) sub = asked.text;
  else if (last) sub = `${last.author.id === me.id ? 'Вы' : last.author.full_name}: ${last.text}`;
  else sub = canWrite ? 'Сообщений пока нет' : 'Сообщений нет';

  // Читать нечего и писать нельзя — открывать нечего, остаётся строка-справка.
  const idle = list.state.status === 'ready' && count === 0 && !canWrite;

  const entryLabel = open ? 'Скрыть переписку' : count > 0 ? `Переписка, ${count} ${plural(count, ['сообщение', 'сообщения', 'сообщений'])}` : 'Переписка';

  return (
    <>
      {/* Якорь в карточке: по нему находится окно, куда кладётся чат. Автору с вопросом здесь же стоит сам вопрос. */}
      {asked ? (
        <section ref={section} className="section" aria-label="Вопрос автору">
          <button type="button" className="chat-entry chat-entry--ask" aria-expanded={open} aria-controls={panelId} onClick={open ? hide : show}>
            <span className="chat-entry__icon" aria-hidden="true">
              <MessageCircle size={18} />
            </span>
            <span className="chat-entry__text">
              <strong>{asked.author.full_name} спрашивает</strong>
              <span className="chat-entry__sub">{asked.text}</span>
            </span>
            <span className={open ? 'pill-action' : 'pill-action pill-action--primary'}>{open ? 'Скрыть' : 'Ответить'}</span>
          </button>
        </section>
      ) : (
        <span ref={section} hidden />
      )}

      {/* Кнопка переписки стоит в подвале карточки слева: видна всегда, место в карточке не занимает. */}
      {!idle &&
        entryHost &&
        createPortal(
          <button
            ref={entry}
            type="button"
            className="btn btn--soft sheet__chat"
            aria-expanded={open}
            aria-controls={panelId}
            aria-label={entryLabel}
            title={list.state.status === 'error' ? sub : undefined}
            onClick={open ? hide : show}
          >
            <MessageCircle size={17} aria-hidden="true" />
            <span className="sheet__chat-text">Переписка</span>
            {count > 0 && <span className="sheet__chat-count">{count}</span>}
          </button>,
          entryHost,
        )}

      {open &&
        place &&
        createPortal(
          <div
            ref={panel}
            id={panelId}
            className={place.side ? 'chat chat--side' : 'chat chat--page'}
            role="dialog"
            aria-label={`Переписка по обращению ${appeal.number}`}
            tabIndex={-1}
            onKeyDown={onKeyDown}
          >
            <header className="chat__head">
              <span className="chat__icon" aria-hidden="true">
                <MessageCircle size={18} />
              </span>
              <div className="chat__who">
                <h2 className="chat__title">Переписка</h2>
                <p className="chat__sub">{appeal.number} · в общую ленту не попадает</p>
              </div>
              <button type="button" className="tool-btn chat__hide" aria-label="Скрыть переписку" onClick={hide}>
                <X size={18} aria-hidden="true" />
              </button>
            </header>

            <div ref={scroller} className="chat__scroll" role="log" aria-label="Сообщения" tabIndex={0}>
              {list.state.status === 'loading' && <p className="chat__state">Загружаем…</p>}
              {list.state.status === 'error' && (
                <div className="chat__state">
                  <p className="error-text">{list.state.message}</p>
                  <button type="button" className="btn btn--soft btn--sm" onClick={list.reload}>
                    Повторить
                  </button>
                </div>
              )}
              {list.state.status === 'ready' && count === 0 && (
                <p className="chat__state">Сообщений пока нет. Напишите первым: ответ придёт сюда и в Telegram.</p>
              )}
              {count > 0 && (
                <ol className="chat__list">
                  {chatDays(messages).map((day) => (
                    <Fragment key={day.key}>
                      <li className="chat__day">{formatChatDay(day.messages[0].created_at)}</li>
                      {day.messages.map((m, i) => {
                        const mine = m.author.id === me.id;
                        const first = startsRun(day.messages, i);
                        const cls = ['chat__msg', mine && 'chat__msg--mine', first && 'chat__msg--first'].filter(Boolean).join(' ');
                        return (
                          <li key={m.id} className={cls}>
                            {!mine &&
                              (endsRun(day.messages, i) ? (
                                <Avatar name={m.author.full_name} size="sm" />
                              ) : (
                                <span className="chat__gap" aria-hidden="true" />
                              ))}
                            <div className="chat__body">
                              {mine ? (
                                first && <span className="sr-only">Вы</span>
                              ) : (
                                first && <span className="chat__author">{m.author.full_name}</span>
                              )}
                              <div className={m.is_clarification_question ? 'chat__bubble chat__bubble--question' : 'chat__bubble'}>
                                {m.is_clarification_question && <span className="chat__tag">Уточняющий вопрос</span>}
                                <p className="prose">{m.text}</p>
                                <time className="chat__time" dateTime={m.created_at}>
                                  {formatTime(m.created_at)}
                                </time>
                              </div>
                            </div>
                          </li>
                        );
                      })}
                    </Fragment>
                  ))}
                </ol>
              )}
            </div>

            {canWrite ? (
              <form className="composer chat__composer" onSubmit={send}>
                <textarea
                  ref={input}
                  className="composer__input"
                  rows={1}
                  value={text}
                  onChange={(e) => setText(e.target.value)}
                  onKeyDown={(e) => {
                    // Ctrl/⌘ + Enter отправляет сообщение.
                    if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) e.currentTarget.form?.requestSubmit();
                  }}
                  placeholder={replying ? 'Ответьте на вопрос' : 'Напишите сообщение'}
                  aria-label={label}
                />
                <div className="composer__foot">
                  {error ? <span className="error-text">{error}</span> : <span className="composer__hint">Ctrl + Enter, чтобы отправить</span>}
                  <button type="submit" className="btn btn--sm composer__send" disabled={busy || !text.trim()}>
                    {busy ? 'Отправляем…' : replying ? 'Ответить' : 'Отправить'}
                    <ArrowUp size={15} aria-hidden="true" />
                  </button>
                </div>
              </form>
            ) : (
              count > 0 && <p className="chat__readonly">Вы можете только читать эту переписку.</p>
            )}
          </div>,
          place.host,
        )}
    </>
  );
}
