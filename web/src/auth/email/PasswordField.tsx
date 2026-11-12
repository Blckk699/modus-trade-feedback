import { useId, useState } from 'react';
import { Eye, EyeOff } from 'lucide-react';

interface Props {
  label: string;
  value: string;
  onChange: (value: string) => void;
  /** current-password — вход и «текущий пароль», new-password — регистрация и смена. */
  autoComplete: 'current-password' | 'new-password';
  error?: string;
  hint?: string;
  disabled?: boolean;
  autoFocus?: boolean;
}

/** Поле пароля с кнопкой «показать»: на телефоне пароль набирают вслепую, ошибку проще увидеть, чем искать. */
export function PasswordField({ label, value, onChange, autoComplete, error, hint, disabled, autoFocus }: Props) {
  const [shown, setShown] = useState(false);
  const id = useId();
  const note = error ?? hint;
  // Подпись связана с полем через htmlFor, а не оборачивает его: иначе текст ошибки и кнопка «показать»
  // попали бы в название поля для экранного диктора.
  return (
    <div className="field">
      <label className="field__label" htmlFor={id}>
        {label}
      </label>
      <span className="pwd">
        <input
          id={id}
          className="input pwd__input"
          type={shown ? 'text' : 'password'}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          autoComplete={autoComplete}
          aria-invalid={Boolean(error)}
          aria-describedby={note ? `${id}-note` : undefined}
          disabled={disabled}
          data-autofocus={autoFocus || undefined}
          required
        />
        <button
          type="button"
          className="pwd__toggle"
          aria-label={shown ? 'Скрыть пароль' : 'Показать пароль'}
          aria-pressed={shown}
          onClick={() => setShown(!shown)}
        >
          {shown ? <EyeOff size={18} aria-hidden="true" /> : <Eye size={18} aria-hidden="true" />}
        </button>
      </span>
      {note && (
        <span id={`${id}-note`} className={error ? 'error-text field__hint' : 'field__hint muted'}>
          {note}
        </span>
      )}
    </div>
  );
}
