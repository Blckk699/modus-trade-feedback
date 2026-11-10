import { describe, expect, it } from 'vitest';
import { ApiError } from './errors';
import { fieldErrors } from './fieldErrors';

describe('ошибки полей из 422 validation_error (истории 5, 6)', () => {
  it('раскладывает details.fields по полям формы', () => {
    const e = new ApiError(422, 'validation_error', 'Проверьте поля.', {
      fields: [
        { field: 'text', message: 'Опишите проблему.' },
        { field: 'category_id', message: 'Категория отключена.' },
      ],
    });
    expect(fieldErrors(e)).toEqual({ text: 'Опишите проблему.', category_id: 'Категория отключена.' });
  });

  it('отбрасывает префикс body.', () => {
    const e = new ApiError(422, 'validation_error', 'Проверьте поля.', {
      fields: [{ field: 'body.text', message: 'Обязательное поле.' }],
    });
    expect(fieldErrors(e)).toEqual({ text: 'Обязательное поле.' });
  });

  it('другие ошибки не дают ошибок полей', () => {
    expect(fieldErrors(new ApiError(409, 'invalid_transition', 'Нельзя.'))).toEqual({});
    expect(fieldErrors(new ApiError(0, 'network_error', 'Нет связи.'))).toEqual({});
    expect(fieldErrors(new Error('boom'))).toEqual({});
  });

  it('не падает на кривых details', () => {
    expect(fieldErrors(new ApiError(422, 'validation_error', 'x', null))).toEqual({});
    expect(fieldErrors(new ApiError(422, 'validation_error', 'x', { fields: 'oops' }))).toEqual({});
    expect(fieldErrors(new ApiError(422, 'validation_error', 'x', { fields: [{ field: 1 }, null] }))).toEqual({});
  });
});
