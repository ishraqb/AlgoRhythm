import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import rawCards from "./data/questions.json";
import { adjustedTier, nextCard } from "./engine";
import {
  Card,
  Category,
  SwipeOutcome,
  UserPerformance,
  categoryOf,
  defaultPerformance,
} from "./types";

const ALL_CARDS = rawCards as Card[];
const STORAGE_KEY = "algorhythm.performance.v1";

function loadPerformance(): UserPerformance {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? (JSON.parse(raw) as UserPerformance) : {};
  } catch {
    // Corrupt or unavailable storage shouldn't break the session.
    return {};
  }
}

function savePerformance(p: UserPerformance) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(p));
  } catch {
    // Private mode / quota — progress just stays in memory this session.
  }
}

export interface Deck {
  currentCard: Card | null;
  performance: UserPerformance;
  categoryFilter: Category | null;
  sessionMastered: number;
  sessionReviewed: number;
  setCategoryFilter: (c: Category | null) => void;
  handleSwipe: (outcome: SwipeOutcome) => void;
  restart: () => void;
  resetProgress: () => void;
}

export function useDeck(): Deck {
  const [performance, setPerformance] = useState<UserPerformance>(loadPerformance);
  const [categoryFilter, setCategoryFilterState] = useState<Category | null>(null);
  const [sessionMastered, setSessionMastered] = useState(0);
  const [sessionReviewed, setSessionReviewed] = useState(0);
  const seenIds = useRef<Set<string>>(new Set());
  const [currentCard, setCurrentCard] = useState<Card | null>(null);

  const pool = useMemo(() => {
    if (!categoryFilter) return ALL_CARDS;
    return ALL_CARDS.filter((c) => categoryOf(c.topic) === categoryFilter);
  }, [categoryFilter]);

  // `performance` is read inside advance via a ref to avoid stale closures
  // while keeping the public API stable.
  const perfRef = useRef(performance);
  perfRef.current = performance;

  const advance = useCallback(() => {
    setCurrentCard(nextCard(pool, perfRef.current, seenIds.current));
  }, [pool]);

  useEffect(() => {
    advance();
  }, [advance]);

  const handleSwipe = useCallback(
    (outcome: SwipeOutcome) => {
      setCurrentCard((card) => {
        if (!card) return card;
        const topic = card.topic;

        setPerformance((prev) => {
          const perf = { ...(prev[topic] ?? defaultPerformance()) };
          if (outcome === "mastered") {
            perf.masteredCount += 1;
            perf.streak = Math.max(perf.streak, 0) + 1;
          } else {
            perf.reviewedCount += 1;
            perf.streak = Math.min(perf.streak, 0) - 1;
          }

          // Let the engine decide whether this topic graduates to a new tier.
          const newTier = adjustedTier(perf.tier, perf.streak);
          if (newTier !== perf.tier) {
            perf.tier = newTier;
            perf.streak = 0; // reset momentum after a tier change
          }

          const next = { ...prev, [topic]: perf };
          savePerformance(next);
          return next;
        });

        if (outcome === "mastered") setSessionMastered((n) => n + 1);
        else setSessionReviewed((n) => n + 1);

        seenIds.current.add(card.id);
        return card;
      });

      // Pick the next card after state has been queued.
      setTimeout(advance, 0);
    },
    [advance],
  );

  const setCategoryFilter = useCallback(
    (c: Category | null) => {
      seenIds.current = new Set();
      setSessionMastered(0);
      setSessionReviewed(0);
      setCategoryFilterState(c);
    },
    [],
  );

  const restart = useCallback(() => {
    seenIds.current = new Set();
    setSessionMastered(0);
    setSessionReviewed(0);
    advance();
  }, [advance]);

  const resetProgress = useCallback(() => {
    setPerformance({});
    savePerformance({});
    seenIds.current = new Set();
    setSessionMastered(0);
    setSessionReviewed(0);
    setTimeout(advance, 0);
  }, [advance]);

  return {
    currentCard,
    performance,
    categoryFilter,
    sessionMastered,
    sessionReviewed,
    setCategoryFilter,
    handleSwipe,
    restart,
    resetProgress,
  };
}

export { ALL_CARDS };
