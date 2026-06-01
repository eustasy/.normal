export type Nothing = Record<string, never>;

export const nothing: Nothing = {};

export function identity<T>(value: T): T {
  return value;
}
