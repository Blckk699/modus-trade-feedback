import { Fragment, useEffect, useId, useRef, useState, type FormEvent, type KeyboardEvent } from 'react';
import { createPortal } from 'react-dom';
import { ArrowUp, ChevronDown, MessageCircle } from 'lucide-react';
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
  /** Куда карточка просит поставить окно чата: якорь над нижней панелью действий. */
  host: HTMLElement | null;
}

/**
 * Закрытая переписка автора и тех, кто ведёт обращение. В карточке она занимает одну строку
 * с последним сообщением; по нажатию открывается окно чата поверх карточки и так же скрывается.
 * Автору, которому задали уточняющий вопрос, окно открыто сразу: ответ — то, зачем он пришёл.
 * Писать можно, если в allowed_actions есть send_message или reply_clarification.
 */
export function MessagesSection({ appeal, onAppealChanged, host }: Props) {
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
  const entry = useRef<HTMLButtonElement>(null);
  const input = useRef<HTMLTextAreaElement>(null);
  const scroller = useRef<HTMLDivElement>(null);
  const panel = useRef<HTMLDivElement>(null);
  /** Открыли кнопкой — ставим курсор в поле; открытое само (вопрос автору) фокус не забирает. */
  const byUser = useRef(false);

  const messages = list.state.status === 'ready' ? list.state.data : [];
  const count = messages.length;

  // Новое сообщение и открытие окна прокручивают переписку к последнему сообщению.
  useEffect(() => {
    if (open && scroller.current) scroller.current.scrollTop = scroller.current.scrollHeight;
  }, [open, count, host]);

  useEffect(() => {
    if (!open || !byUser.current) return;
    byUser.current = false;
    (input.current ?? panel.current)?.focus();
  }, [open, host]);

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
    if (!text.trim()) return;
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

  const rowBody = (
    <>
      <span className="chat-entry__icon" aria-hidden="true">
        <MessageCircle size={18} />
      </span>
      <span className="chat-entry__text">
        <strong>{asked ? `${asked.author.full_name} спрашивает` : 'Переписка'}</strong>
        <span className="chat-entry__sub">{sub}</span>
      </span>
      {count > 0 && (
        <span className="chat-entry__count">
          {count}
          <span className="sr-only"> {plural(count, ['сообщение', 'сообщения', 'сообщений'])}</span>
        </span>
      )}
    </>
  );

  return (
    <section className="section" aria-label="Переписка">
      {idle ? (
        <div className="chat-entry chat-entry--static">{rowBody}</div>
      ) : (
        <button
          ref={entry}
          type="button"
          className={asked ? 'chat-entry chat-entry--ask' : 'chat-entry'}
          aria-expanded={open}
          aria-controls={panelId}
          onClick={open ? hide : show}
        >
          {rowBody}
          <span className={asked && !open ? 'pill-action pill-action--primary' : 'pill-action'}>
            {open ? 'Скрыть' : asked ? 'Ответить' : count > 0 ? 'Открыть' : 'Написать'}
          </span>
        </button>
      )}

      {open &&
        host &&
        createPortal(
          <div
            ref={panel}
            id={panelId}
            className="chat"
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
                <ChevronDown size={18} aria-hidden="true" />
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
          host,
        )}
    </section>
  );
}
