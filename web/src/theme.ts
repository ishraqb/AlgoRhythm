import type { Category, DifficultyName } from "./types";

// Warm, editorial "study desk" palette, ported from the iOS Theme so the two
// clients share one visual language.
export const Theme = {
  background: "#16140f",
  accent: "#e1a849",
  secondary: "#73a494",
  mastered: "#83b167",
  review: "#d96f51",
  cardTop: "#2d2821",
  cardBottom: "#1c1915",
};

export const DIFFICULTY_TINT: Record<DifficultyName, string> = {
  intro: "#73a494",
  easy: "#83b167",
  medium: "#e1a849",
  hard: "#e28d49",
  expert: "#d96f51",
};

export function chipColor(category: Category): string {
  return category === "algorithms" ? Theme.accent : Theme.secondary;
}
