import { plural } from '../lib/plural';

export interface BriefInput {
  /** Открытые обращения, назначенные мне. null — пользователь обращения не обрабатывает. */
  assignedOpen: number | null;
  assignedOverdue: number;
  /** Мои обращения, где ответственный задал вопрос и ждёт ответа. */
  awaitingMe: number;
  /** Обращения без ответственного. null — пользователь их не видит. */
  unassigned: number | null;
  /** Заявки на доступ, ждущие решения. null — пользователь ими не управляет. */
  accessRequests: number | null;
  /** Из сводки: новые за сутки и просроченные в охвате (компания или подразделение). null — сводки нет. */
  newToday: number | null;
  overdueTotal: number | null;
  scope: 'company' | 'department' | null;
  openDiscussions: number;
}

const appeals = (n: number) => plural(n, ['обращение', 'обращения', 'обращений']);

/**
 * Главное на сейчас — две-три фразы из настоящих чисел, от срочного к спокойному.
 * Считает только клиент: сроки и права уже посчитал бэкенд, здесь лишь слова.
 */
export function buildBrief(i: BriefInput): string[] {
  const out: string[] = [];

  if (i.assignedOpen !== null && i.assignedOpen > 0) {
    const overdue =
      i.assignedOverdue > 0 ? `, ${i.assignedOverdue} ${plural(i.assignedOverdue, ['просрочено', 'просрочены', 'просрочено'])}` : '';
    out.push(`У вас ${i.assignedOpen} ${appeals(i.assignedOpen)} в работе${overdue}.`);
  }
  if (i.awaitingMe > 0) {
    out.push(i.awaitingMe === 1 ? 'Вас ждёт вопрос по обращению.' : `Вас ждут вопросы по ${i.awaitingMe} обращениям.`);
  }
  if (i.unassigned !== null && i.unassigned > 0) {
    out.push(`${i.unassigned} ${plural(i.unassigned, ['обращение ждёт', 'обращения ждут', 'обращений ждут'])} ответственного.`);
  }
  if (i.accessRequests !== null && i.accessRequests > 0) {
    out.push(
      `${i.accessRequests} ${plural(i.accessRequests, ['заявка на доступ ждёт', 'заявки на доступ ждут', 'заявок на доступ ждут'])} решения.`,
    );
  }
  if (i.scope && i.newToday !== null && i.overdueTotal !== null && (i.newToday > 0 || i.overdueTotal > 0)) {
    const where = i.scope === 'company' ? 'В компании' : 'В подразделении';
    const parts: string[] = [];
    if (i.newToday > 0) parts.push(`${i.newToday} ${plural(i.newToday, ['новое', 'новых', 'новых'])} за сутки`);
    if (i.overdueTotal > 0) parts.push(`${i.overdueTotal} ${plural(i.overdueTotal, ['просрочено', 'просрочены', 'просрочено'])}`);
    out.push(`${where}: ${parts.join(', ')}.`);
  }
  if (out.length < 3 && i.openDiscussions > 0) {
    out.push(
      `${plural(i.openDiscussions, ['Идёт', 'Идут', 'Идёт'])} ${i.openDiscussions} ${plural(i.openDiscussions, ['обсуждение', 'обсуждения', 'обсуждений'])}, можно проголосовать.`,
    );
  }
  if (out.length === 0) out.push('Срочного нет.', 'Что-то мешает работать или есть идея? Напишите, ответственный ответит в срок.');
  return out.slice(0, 3);
}

/** Приветствие по местному времени. Имя — первое слово из «Имя и фамилия». */
export function greeting(fullName: string, now: Date = new Date()): string {
  const h = now.getHours();
  const hello = h < 5 ? 'Доброй ночи' : h < 12 ? 'Доброе утро' : h < 18 ? 'Добрый день' : 'Добрый вечер';
  const name = fullName.trim().split(/\s+/)[0];
  return name ? `${hello}, ${name}` : hello;
}
