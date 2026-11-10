import { useSearchParams } from 'react-router-dom';
import { CategoriesTab } from './CategoriesTab';
import { DeadlinesTab } from './DeadlinesTab';
import { DepartmentsTab } from './DepartmentsTab';
import { UnassignedTab } from './UnassignedTab';
import { UsersTab } from './UsersTab';
import './settings.css';

const TABS = {
  users: { label: 'Сотрудники', Component: UsersTab },
  departments: { label: 'Подразделения', Component: DepartmentsTab },
  categories: { label: 'Категории', Component: CategoriesTab },
  deadlines: { label: 'Сроки', Component: DeadlinesTab },
  unassigned: { label: 'Нераспределённые', Component: UnassignedTab },
} as const;
type TabId = keyof typeof TABS;

/**
 * Настройки администратора (W-08, истории 64–70). Раздел в навигации виден только при
 * Me.permissions.can_manage_settings; права на сами операции проверяет бэкенд (403 остальным).
 */
export function SettingsPage() {
  const [params, setParams] = useSearchParams();
  const raw = params.get('tab');
  const tab: TabId = raw && raw in TABS ? (raw as TabId) : 'users';
  const { Component } = TABS[tab];

  return (
    <section className="page">
      <h1 className="page__title">Настройки</h1>
      <div className="segmented settings-tabs" role="tablist" aria-label="Разделы настроек">
        {(Object.keys(TABS) as TabId[]).map((id) => (
          <label key={id} className="segmented__item">
            <input
              type="radio"
              name="settings-tab"
              role="tab"
              aria-selected={tab === id}
              checked={tab === id}
              onChange={() => setParams(id === 'users' ? {} : { tab: id }, { replace: true })}
            />
            <span>{TABS[id].label}</span>
          </label>
        ))}
      </div>
      <Component key={tab} />
    </section>
  );
}
