import { describe, expect, it } from 'vitest';
import { ApiError } from '../api/errors';
import { assignable, changes, fieldErrors, idOrNull, type User } from './shared';

const user = (over: Partial<User>): User => ({
  id: 1,
  telegram_id: 1,
  full_name: 'А',
  position: null,
  role: 'employee',
  department: null,
  is_absent: false,
  is_disabled: false,
  ...over,
});

describe('настройки: помощники', () => {
  it('PATCH получает только изменённые поля', () => {
    expect(changes({ role: 'employee', department_id: 1, is_absent: false }, { role: 'head', department_id: 1, is_absent: true })).toEqual({
      role: 'head',
      is_absent: true,
    });
  });

  it('пустой выбор — null', () => {
    expect(idOrNull('')).toBeNull();
    expect(idOrNull('7')).toBe(7);
  });

  it('ошибки полей из 422', () => {
    const e = new ApiError(422, 'validation_error', 'Проверьте поля', {
      fields: [{ field: 'body.telegram_id', message: 'Уже есть' }],
    });
    expect(fieldErrors(e)).toEqual({ telegram_id: 'Уже есть' });
    expect(fieldErrors(new Error('x'))).toEqual({});
  });

  it('ответственным нельзя назначить администратора и отключённого', () => {
    const list = [user({ id: 1 }), user({ id: 2, role: 'admin' }), user({ id: 3, is_disabled: true }), user({ id: 4, role: 'head' })];
    expect(assignable(list).map((u) => u.id)).toEqual([1, 4]);
  });
});
