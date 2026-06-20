import { useState } from "react";
import { BrandMark } from "./components/BrandMark";
import { CardStack } from "./components/CardStack";
import { Stats } from "./components/Stats";
import { useDeck } from "./useDeck";
import { Category } from "./types";
import { Theme } from "./theme";

type Tab = "study" | "progress";

export default function App() {
  const deck = useDeck();
  const [tab, setTab] = useState<Tab>("study");

  return (
    <div className="app">
      <header className="app-header">
        <BrandMark size={28} />
        <div className="app-title">
          <h1>AlgoRhythm</h1>
          <span className="app-sub">
            {deck.sessionMastered} mastered · {deck.sessionReviewed} to review
          </span>
        </div>
      </header>

      {tab === "study" ? (
        <main className="study">
          <SegmentedFilter value={deck.categoryFilter} onChange={deck.setCategoryFilter} />
          <CardStack deck={deck} />
          <div className="action-bar" style={{ opacity: deck.currentCard ? 1 : 0 }}>
            <button
              className="action-circle"
              style={{ color: Theme.review, borderColor: `${Theme.review}80` }}
              onClick={() => deck.handleSwipe("review")}
              aria-label="Mark for review"
            >
              <UndoIcon />
            </button>
            <button
              className="action-circle"
              style={{ color: Theme.mastered, borderColor: `${Theme.mastered}80` }}
              onClick={() => deck.handleSwipe("mastered")}
              aria-label="Mark mastered"
            >
              <CheckIcon />
            </button>
          </div>
        </main>
      ) : (
        <main className="progress-main">
          <Stats performance={deck.performance} onReset={deck.resetProgress} />
        </main>
      )}

      <nav className="tab-bar">
        <button className={tab === "study" ? "tab active" : "tab"} onClick={() => setTab("study")}>
          Study
        </button>
        <button
          className={tab === "progress" ? "tab active" : "tab"}
          onClick={() => setTab("progress")}
        >
          Progress
        </button>
      </nav>

      <footer className="app-footer">
        Swipe right to master, left to review. Progress is saved on this device.
      </footer>
    </div>
  );
}

function SegmentedFilter({
  value,
  onChange,
}: {
  value: Category | null;
  onChange: (c: Category | null) => void;
}) {
  const options: { label: string; value: Category | null }[] = [
    { label: "All", value: null },
    { label: "Algorithms", value: "algorithms" },
    { label: "System Design", value: "systemDesign" },
  ];
  return (
    <div className="segmented">
      {options.map((o) => (
        <button
          key={o.label}
          className={value === o.value ? "segment active" : "segment"}
          onClick={() => onChange(o.value)}
        >
          {o.label}
        </button>
      ))}
    </div>
  );
}

function CheckIcon() {
  return (
    <svg width="26" height="26" viewBox="0 0 24 24" fill="none">
      <path
        d="M5 13l4 4L19 7"
        stroke="currentColor"
        strokeWidth={2.6}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function UndoIcon() {
  return (
    <svg width="26" height="26" viewBox="0 0 24 24" fill="none">
      <path
        d="M9 14l-4-4 4-4M5 10h9a5 5 0 0 1 0 10h-3"
        stroke="currentColor"
        strokeWidth={2.4}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}
