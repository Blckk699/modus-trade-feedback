import { Check, ChevronDown } from 'lucide-react';
import { Avatar } from '../../app/Avatar';
import { useDictionaries } from '../../app/dictionaries';
import { usePopover } from '../../app/usePopover';
import { targetCaption, type SwitchTarget } from './destination';
import { useRoleSwitch } from './useRoleSwitch';

type Switch = ReturnType<typeof useRoleSwitch>;

/** Строки списка: текущий пользователь с галочкой и те, под кого можно переключиться. */
function Targets({ sw, onPick }: { sw: Switch; onPick?: () => void }) {
  const dict = useDictionaries();
  const row = (t: SwitchTarget, current: boolean) => (
    <button
      key={t.id}
      type="button"
      className="pop__item roleswitch__item"
      role="menuitemradio"
      aria-checked={current}
      disabled={sw.busyId !== null}
      onClick={() => {
        if (current) return onPick?.();
        void sw.switchTo(t).then(() => onPick?.());
      }}
    >
      <Avatar name={t.full_name} size="sm" />
      <span className="roleswitch__who">
        <strong>{t.full_name}</strong>
        <span>{sw.busyId === t.id ? 'Переключаем…' : targetCaption(t, dict.roleLabel(t.role))}</span>
      </span>
      {current && <Check size={16} aria-hidden="true" />}
    </button>
  );
  return (
    <>
      {row(sw.me, true)}
      {sw.targets.map((t) => row(t, false))}
    </>
  );
}

/**
 * Переключатель роли в шапке рядом с уведомлениями (W-14): кто сейчас вошёл и список связанных
 * демо-пользователей. Без связанных пользователей не показывается. Стоит только в шапке сайта:
 * чтобы сменить роль при открытой карточке-панели, её сначала закрывают.
 */
export function RoleSwitch() {
  const sw = useRoleSwitch();
  const dict = useDictionaries();
  const menu = usePopover<HTMLDivElement>();
  if (sw.targets.length === 0) return null;
  const role = dict.roleLabel(sw.me.role);

  return (
    <div className="roleswitch" ref={menu.ref}>
      <button
        type="button"
        className="roleswitch__btn"
        aria-haspopup="menu"
        aria-expanded={menu.open}
        aria-label={`Сменить роль. Сейчас: ${sw.me.full_name}, ${role}`}
        data-popover-trigger
        onClick={() => menu.setOpen(!menu.open)}
      >
        <Avatar name={sw.me.full_name} size="sm" />
        <span className="roleswitch__who roleswitch__who--btn">
          <strong>{sw.me.full_name}</strong>
          <span>{role}</span>
        </span>
        <ChevronDown size={16} aria-hidden="true" />
      </button>
      {menu.open && (
        <div className="pop pop--right roleswitch__pop" role="menu" aria-label="Сменить роль">
          <p className="roleswitch__note">Демо: одна заявка под разными ролями</p>
          <Targets sw={sw} onPick={() => menu.setOpen(false)} />
        </div>
      )}
    </div>
  );
}

/** То же для меню профиля на телефоне: список ролей отдельной группой. */
export function RoleSwitchItems({ onPick }: { onPick: () => void }) {
  const sw = useRoleSwitch();
  if (sw.targets.length === 0) return null;
  return (
    <div className="roleswitch__group" role="group" aria-label="Сменить роль">
      <p className="roleswitch__note">Сменить роль</p>
      <Targets sw={sw} onPick={onPick} />
    </div>
  );
}
