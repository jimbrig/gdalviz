// shared between the node card renderer and the dagre size estimator so the
// estimated card height matches what actually renders

export const VALUE_CHARS_PER_LINE = 22;
export const VALUE_MAX_LINES = 3;

// long argument lists (merged step runs, repeated --input/--open-option args)
// are clamped on the card; the inspector always shows the full list
export const CARD_MAX_ROWS = 6;

// shorten noisy /vsi.../ chains to a readable tail
export function prettyValue(v: string): string {
  if (v.includes("/vsi")) {
    const tail = v.split("/").filter(Boolean).pop() ?? v;
    const prefixes: string[] = [];
    if (v.includes("/vsizip/")) prefixes.push("zip");
    if (v.includes("/vsicurl/")) prefixes.push("curl");
    return prefixes.length ? `${prefixes.join("+")}: \u2026/${tail}` : `\u2026/${tail}`;
  }
  return v;
}

export function valueLines(v: string): number {
  const shown = prettyValue(v);
  return Math.min(VALUE_MAX_LINES, Math.max(1, Math.ceil(shown.length / VALUE_CHARS_PER_LINE)));
}
