import { useLocation, type Location } from 'react-router-dom';

/**
 * Экран, поверх которого открыта карточка. Ссылка с `state={{ background }}` открывает обращение, обсуждение
 * или форму панелью поверх этого экрана; закрытие возвращает к нему. Из уже открытой карточки фон тот же.
 */
export function useBackground(): Location {
  const location = useLocation();
  return (location.state as { background?: Location } | null)?.background ?? location;
}
