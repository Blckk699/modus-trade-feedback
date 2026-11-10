import { describe, expect, it } from 'vitest';
import { plural } from './plural';

const people: [string, string, string] = ['человек', 'человека', 'человек'];

describe('склонение числа', () => {
  it.each([
    [1, 'человек'],
    [2, 'человека'],
    [4, 'человека'],
    [5, 'человек'],
    [11, 'человек'],
    [12, 'человек'],
    [21, 'человек'],
    [22, 'человека'],
  ])('%i → %s', (n, word) => {
    expect(plural(n, people)).toBe(word);
  });
});
