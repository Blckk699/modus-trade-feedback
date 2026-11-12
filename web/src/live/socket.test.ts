import { describe, expect, it } from 'vitest';
import { socketUrl } from './socket';

describe('адрес сокета', () => {
  it('абсолютная база API: http → ws, https → wss', () => {
    expect(socketUrl('http://localhost:5174', 'http://localhost:5174/queue')).toBe('ws://localhost:5174/api/v1/ws');
    expect(socketUrl('https://modus.systm.kz/', 'https://other.example/x')).toBe('wss://modus.systm.kz/api/v1/ws');
  });

  it('относительная или пустая база — от адреса страницы', () => {
    expect(socketUrl('', 'https://modus.systm.kz/appeals/28?x=1')).toBe('wss://modus.systm.kz/api/v1/ws');
    expect(socketUrl('/back', 'http://localhost:5174/queue')).toBe('ws://localhost:5174/back/api/v1/ws');
  });
});
