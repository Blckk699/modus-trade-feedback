import { useState } from 'react';
import { KeyRound } from 'lucide-react';
import { emailAuth } from '../auth/email/emailAuth';
import { resetPasswordProblem } from '../auth/email/forms';

/**
 * Сброс пароля сотруднику (история 77). Временный пароль система показывает один раз:
 * администратор передаёт его сотруднику, при входе с ним тот задаёт свой.
 */
export function ResetPassword({ userId, name }: { userId: number; name: string }) {
  const [state, setState] = useState<'idle' | 'confirm' | 'busy'>('idle');
  const [temporary, setTemporary] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);
  const [error, setError] = useState('');

  async function reset() {
    setState('busy');
    setError('');
    try {
      setTemporary((await emailAuth.resetPassword(userId)).temporaryPassword);
      setState('idle');
    } catch (e) {
      setError(resetPasswordProblem(e));
      setState('confirm');
    }
  }

  if (temporary) {
    return (
      <div className="notice notice--warn reset" role="status">
        <p className="notice__title">Временный пароль — показываем один раз</p>
        <p>Передайте его {name}. При входе система попросит задать свой пароль. Прежний пароль больше не действует.</p>
        <div className="reset__row">
          <input className="input reset__value" value={temporary} readOnly onFocus={(e) => e.currentTarget.select()} aria-label="Временный пароль" />
          <button
            type="button"
            className="btn btn--soft"
            onClick={() => {
              navigator.clipboard
                ?.writeText(temporary)
                .then(() => {
                  setCopied(true);
                  setTimeout(() => setCopied(false), 2000);
                })
                .catch(() => {});
            }}
          >
            {copied ? 'Скопировано' : 'Копировать'}
          </button>
        </div>
      </div>
    );
  }

  if (state === 'idle') {
    return (
      <div className="reset">
        <button type="button" className="btn btn--soft" onClick={() => setState('confirm')}>
          <KeyRound size={16} aria-hidden="true" /> Сбросить пароль
        </button>
      </div>
    );
  }

  return (
    <div className="notice reset">
      <p className="notice__title">Сбросить пароль {name}?</p>
      <p>Текущий пароль перестанет работать. Вы получите временный и передадите его сотруднику.</p>
      <div className="reset__row">
        <button type="button" className="btn" onClick={reset} disabled={state === 'busy'}>
          {state === 'busy' ? 'Сбрасываем…' : 'Сбросить'}
        </button>
        <button type="button" className="btn btn--soft" onClick={() => setState('idle')} disabled={state === 'busy'}>
          Отмена
        </button>
        {error && (
          <span className="error-text" role="alert">
            {error}
          </span>
        )}
      </div>
    </div>
  );
}
