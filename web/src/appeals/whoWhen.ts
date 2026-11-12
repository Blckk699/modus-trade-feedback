import type { Schemas } from '../api/types';
import { formatDateTime } from '../lib/format';

type Appeal = Pick<
  Schemas['Appeal'],
  'type' | 'status' | 'assignee' | 'category' | 'first_response_due_at' | 'first_response_at' | 'due_state' | 'escalation_level'
>;

export interface WhoWhen {
  /** Кто рассмотрит. */
  who: string;
  /** Ориентир по сроку. */
  when: string;
  /** Что будет дальше, по шагам. Пусто — у отзыва шагов нет. */
  steps: string[];
  /** Куда придёт ответ. */
  where: string;
}

/**
 * «Кто и когда» для автора — человеческими словами вместо «Назначит администратор / Без срока».
 * Правила из SPEC: ответственного назначает правило категории, без него — администратор; срок только
 * у первого ответа и ставится вместе с ответственным; у положительного отзыва срока нет.
 */
export function whoWhen(a: Appeal, telegramLinked: boolean): WhoWhen {
  const praise = a.type === 'praise';
  const who = a.assignee
    ? `${a.assignee.full_name}${a.category ? `, ответственный за «${a.category.name}»` : ''}`
    : a.category
      ? `Администратор выберет ответственного: у категории «${a.category.name}» сейчас его нет.`
      : 'Администратор выберет ответственного: категорию не удалось определить.';

  const when = praise
    ? 'Без срока: отзыв передадут, ответ не обязателен.'
    : a.first_response_at
      ? `Первый ответ дан ${formatDateTime(a.first_response_at)}.`
      : a.first_response_due_at && a.due_state === 'overdue'
        ? `Срок первого ответа прошёл ${formatDateTime(a.first_response_due_at)}. ${dueExplanation(a.escalation_level).now ?? 'Ответственному уйдёт напоминание.'}`
        : a.first_response_due_at
          ? `Первый ответ — до ${formatDateTime(a.first_response_due_at)}.`
        : 'Срок первого ответа появится вместе с ответственным. Он считается в рабочих днях и зависит от приоритета.';

  const steps = praise
    ? []
    : [
        'Ответственный берёт обращение в работу.',
        'Отвечает вам. Если чего-то не хватает, задаст вопрос — ответить можно здесь же.',
        a.type === 'suggestion'
          ? 'Сообщает решение: реализуем, отклоняем с причиной или выносим на общее обсуждение.'
          : 'Сообщает решение: что сделано или почему нет.',
      ];

  const where = telegramLinked
    ? 'Ответы и смена статуса придут в Telegram и появятся здесь, в «Мои обращения».'
    : 'Ответы и смена статуса появятся здесь, в «Мои обращения». Привяжите Telegram в профиле, чтобы узнавать сразу.';

  return { who, when, steps, where };
}

/** Что происходит при просрочке первого ответа (SPEC «Сроки и эскалация»), и на каком шаге обращение сейчас. */
export function dueExplanation(escalationLevel: number): { rule: string; now: string | null } {
  const rule =
    'Срок ставится только на первый ответ, не на решение. Если ответа нет: в первый рабочий день просрочки — напоминание ' +
    'ответственному, на второй — уведомление руководителю подразделения, на третий — обращение попадает в «Зависло» ' +
    'в сводке собственника.';
  const now =
    escalationLevel >= 3
      ? 'Сейчас: обращение в «Зависло» у собственника.'
      : escalationLevel === 2
        ? 'Сейчас: руководитель подразделения уведомлён.'
        : escalationLevel === 1
          ? 'Сейчас: ответственному отправлено напоминание.'
          : null;
  return { rule, now };
}
