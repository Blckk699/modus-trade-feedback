import { useSearchParams } from 'react-router-dom';
import { AccessRequestsTab } from '../access/AccessRequestsTab';
import { InvitesTab } from '../access/InvitesTab';
import { PageHead } from '../app/PageHead';
import { useMe } from '../auth';
import { CategoriesTab } from './CategoriesTab';
import { DeadlinesTab } from './DeadlinesTab';
import { DepartmentsTab } from './DepartmentsTab';
import { UnassignedTab } from './UnassignedTab';
import { UsersTab } from './UsersTab';
import './settings.css';

/** settings — вкладки администратора (can_manage_settings), access — заявки и приглашения (can_manage_access, W-12). */
const TABS = {
  users: { label: 'Сотрудники', Component: UsersTab, need: 'settings' },
  departments: { label: 'Подразделения', Component: DepartmentsTab, need: 'settings' },
  categories: { label: 'Категории', Component: CategoriesTab, need: 'settings' },
  deadlines: { label: 'Сроки', Component: DeadlinesTab, need: 'settings' },
  unassigned: { label: 'Без ответственного', Component: UnassignedTab, need: 'settings' },
  requests: { label: 'Заявки', Component: AccessRequestsTab, need: 'access' },
  invites: { label: 'Приглашения', Component: InvitesTab, need: 'access' },
} as const;
type TabId = keyof typeof TABS;

/**
 * Настройки администратора (W-08, истории 64–70). Раздел в навигации виден только при
 * Me.permissions.can_manage_settings; права на сами операции проверяет бэкенд (403 остальным).
 */
export function SettingsPage() {
  const p = useMe().permissions;
  const [params, setParams] = useSearchParams();
  const visible = (Object.keys(TABS) as TabId[]).filter((id) =>
    TABS[id].need === 'settings' ? p.can_manage_settings : p.can_manage_access,
  );
  const raw = params.get('tab');
  const tab: TabId = raw && visible.includes(raw as TabId) ? (raw as TabId) : visible[0];
  const { Component } = TABS[tab];

  return (
    <section className="page">
      <PageHead over={p.can_manage_settings ? 'Люди, подразделения, категории и сроки' : 'Кто получает доступ'} title="Настройки" />
      <div className="segmented settings-tabs" role="radiogroup" aria-label="Разделы настроек">
        {visible.map((id) => (
          <label key={id} className="segmented__item">
            <input
              type="radio"
              name="settings-tab"
              checked={tab === id}
              onChange={() => setParams(id === visible[0] ? {} : { tab: id }, { replace: true })}
            />
            <span>{TABS[id].label}</span>
          </label>
        ))}
      </div>
      <Component key={tab} />
    </section>
  );
}
