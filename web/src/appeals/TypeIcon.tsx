import { CircleAlert, Heart, Lightbulb } from 'lucide-react';
import type { Schemas } from '../api/types';

const ICON = { problem: CircleAlert, suggestion: Lightbulb, praise: Heart } as const;

/** Значок типа обращения в цветном кружке: проблема, предложение, отзыв. Подпись типа всегда стоит рядом текстом. */
export function TypeIcon({ type, size = 'md' }: { type: Schemas['AppealType']; size?: 'md' | 'lg' }) {
  const Icon = ICON[type] ?? CircleAlert;
  return (
    <span className={`type-icon type-icon--${type} type-icon--${size}`} aria-hidden="true">
      <Icon size={size === 'lg' ? 22 : 18} />
    </span>
  );
}

/** Тип обращения чипом в ряду статусов карточки: значок и подпись, без отдельного кружка у заголовка. */
export function TypeChip({ type, label }: { type: Schemas['AppealType']; label: string }) {
  const Icon = ICON[type] ?? CircleAlert;
  return (
    <span className={`badge badge--type badge--type-${type}`}>
      <Icon size={13} aria-hidden="true" />
      {label}
    </span>
  );
}
