import {
  ALGORITHM_TOPICS,
  DIFFICULTY_TITLES,
  TOPIC_TITLES,
  TopicId,
  UserPerformance,
  defaultPerformance,
  masteryRate,
} from "../types";
import { DIFFICULTY_TINT, Theme } from "../theme";

const SYSTEM_DESIGN_TOPICS: TopicId[] = [
  "scalability",
  "loadBalancing",
  "caching",
  "sharding",
  "capTheorem",
  "microservices",
  "rateLimiting",
  "messageQueues",
];

const ALL_TOPICS = [...ALGORITHM_TOPICS, ...SYSTEM_DESIGN_TOPICS];

export function Stats({
  performance,
  onReset,
}: {
  performance: UserPerformance;
  onReset: () => void;
}) {
  const seen = ALL_TOPICS.filter((t) => {
    const p = performance[t];
    return p && p.masteredCount + p.reviewedCount > 0;
  });

  if (seen.length === 0) {
    return (
      <div className="stats-empty">
        <svg width="44" height="44" viewBox="0 0 24 24" fill={Theme.accent}>
          <path d="M3 21V3h2v16h16v2H3zm4-3V9h3v9H7zm5 0V5h3v13h-3zm5 0v-6h3v6h-3z" />
        </svg>
        <h2>No progress yet</h2>
        <p>Swipe through some cards and your per-topic mastery shows up here.</p>
      </div>
    );
  }

  return (
    <div className="stats">
      <div className="stats-head">
        <h2>Progress</h2>
        <button className="btn-ghost" onClick={onReset}>
          Reset
        </button>
      </div>
      <div className="stats-list">
        {seen.map((topic) => {
          const p = performance[topic] ?? defaultPerformance();
          const rate = masteryRate(p);
          return (
            <div key={topic} className="stat-row">
              <div className="stat-row-top">
                <span className="stat-topic">{TOPIC_TITLES[topic]}</span>
                <span className="stat-tier" style={{ color: DIFFICULTY_TINT[p.tier] }}>
                  {DIFFICULTY_TITLES[p.tier]}
                </span>
              </div>
              <div className="progress-track">
                <div
                  className="progress-fill"
                  style={{ width: `${Math.round(rate * 100)}%` }}
                />
              </div>
              <span className="stat-counts">
                {p.masteredCount} mastered · {p.reviewedCount} to review
              </span>
            </div>
          );
        })}
      </div>
    </div>
  );
}
