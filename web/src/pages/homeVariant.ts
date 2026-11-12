import type { Schemas } from '../api/types';

type Summary = Schemas['AnalyticsSummary'];
type Stuck = Schemas['StuckAppeal'];

/**
 * Версия экрана «Сегодня». У каждой роли свой вопрос на входе:
 * author — сотрудник: что с моими обращениями и что обсуждают;
 * assignee — сотрудник-ответственный: что мне ответить и к какому сроку;
 * head — руководитель: что в подразделении и кто не успевает;
 * owner — собственник: картина по компании и что требует внимания;
 * admin — администратор: что распределить и где в настройках пробелы.
 */
export type HomeVariant = 'author' | 'assignee' | 'head' | 'owner' | 'admin';

export function homeVariant(role: Schemas['Role'], assignedOpen: number): HomeVariant {
  if (role === 'owner' || role === 'admin' || role === 'head') return role;
  return assignedOpen > 0 ? 'assignee' : 'author';
}

/** О чём этот экран — подпись под заголовком главной карточки. */
export function variantScope(variant: HomeVariant, department: string | null): string {
  switch (variant) {
    case 'owner':
      return 'Вся компания';
    case 'head':
      return department ? `Подразделение «${department}»` : 'Ваше подразделение';
    case 'admin':
      return 'Распределение и доступ';
    case 'assignee':
      return 'Назначенные вам обращения';
    case 'author':
      return 'Ваши обращения';
  }
}

/**
 * «Требуют внимания»: зависшие и просроченные одним списком без повторов.
 * Сначала с более высоким шагом эскалации, затем с большей просрочкой.
 */
export function attention(summary: Pick<Summary, 'stuck' | 'overdue'>): Stuck[] {
  const byId = new Map<number, Stuck>();
  for (const s of [...summary.stuck, ...summary.overdue]) {
    const prev = byId.get(s.appeal.id);
    if (!prev || s.escalation_level > prev.escalation_level || s.days_overdue > prev.days_overdue) byId.set(s.appeal.id, s);
  }
  return [...byId.values()].sort((a, b) => b.escalation_level - a.escalation_level || b.days_overdue - a.days_overdue);
}

export interface SetupGaps {
  /** Действующие категории без ответственного: их обращения уходят администратору. */
  noResponsible: number;
  /** Действующие категории без заместителя: при отсутствии ответственного подменить некому. */
  noDeputy: number;
  /** Подразделения без руководителя: эскалацию и сводку получать некому. */
  noHead: number;
}

/** Пробелы в настройках, из-за которых обращения теряют адресата. */
export function setupGaps(
  categories: Pick<Schemas['Category'], 'responsible' | 'deputy' | 'is_active'>[],
  departments: Pick<Schemas['Department'], 'head'>[],
): SetupGaps {
  const active = categories.filter((c) => c.is_active);
  return {
    noResponsible: active.filter((c) => !c.responsible).length,
    noDeputy: active.filter((c) => c.responsible && !c.deputy).length,
    noHead: departments.filter((d) => !d.head).length,
  };
}
