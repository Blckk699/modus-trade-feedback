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
