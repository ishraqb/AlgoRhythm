import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import {
  Card,
  DIFFICULTY_TITLES,
  TOPIC_TITLES,
  categoryOf,
  hasCode,
} from "../types";
import { DIFFICULTY_TINT, Theme, chipColor } from "../theme";

// A single card that flips between prompt (front) and solution (back) on tap.
// The flip is a y-axis rotation; the back face is pre-rotated so its text reads
// correctly once revealed.
export function FlashCard({ card }: { card: Card }) {
  const [flipped, setFlipped] = useState(false);

  // A fresh card always starts on its prompt side.
  useEffect(() => {
    setFlipped(false);
  }, [card.id]);

  return (
    <div
      className="card-flip"
      onClick={() => setFlipped((f) => !f)}
      style={{ perspective: 1600 }}
    >
      <motion.div
        className="card-inner"
        animate={{ rotateY: flipped ? 180 : 0 }}
        transition={{ type: "spring", stiffness: 260, damping: 26 }}
      >
        <div className="card-face card-front">
          <CardHeader card={card} />
          <p className="card-prompt">{card.prompt}</p>
          <div className="card-hint">
            <TapIcon />
            <span>Tap to reveal</span>
          </div>
        </div>
        <div className="card-face card-back">
          <Solution card={card} />
        </div>
      </motion.div>
    </div>
  );
}

function CardHeader({ card }: { card: Card }) {
  const cat = categoryOf(card.topic);
  const chip = chipColor(cat);
  const tint = DIFFICULTY_TINT[card.difficulty];
  return (
    <div className="card-header">
      <span className="pill" style={{ color: chip, background: `${chip}33` }}>
        {TOPIC_TITLES[card.topic]}
      </span>
      <span className="pill" style={{ color: tint, background: `${tint}38` }}>
        {DIFFICULTY_TITLES[card.difficulty]}
      </span>
    </div>
  );
}

function Solution({ card }: { card: Card }) {
  return (
    <div className="solution" onClick={(e) => e.stopPropagation()}>
      <h3 className="solution-title" style={{ color: Theme.accent }}>
        Solution
      </h3>
      <p className="solution-body">{card.solution}</p>
      {hasCode(card) && (
        <div className="code-wrap">
          {card.language && <div className="code-lang">{card.language.toUpperCase()}</div>}
          <pre className="code-block">
            <code>{card.code}</code>
          </pre>
        </div>
      )}
      <div className="complexity-row">
        <ComplexityPill label="Time" value={card.timeComplexity} />
        <ComplexityPill label="Space" value={card.spaceComplexity} />
      </div>
    </div>
  );
}

function ComplexityPill({ label, value }: { label: string; value: string }) {
  return (
    <div className="complexity-pill">
      <span className="complexity-label">{label}</span>
      <span className="complexity-value">{value}</span>
    </div>
  );
}

function TapIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
      <path d="M9 11.5V5a1.5 1.5 0 0 1 3 0v6h.5l1.2-3a1.4 1.4 0 0 1 2.6 1l-.4 1.3 2.1.7A2 2 0 0 1 20.4 15l-1 4.2A3 3 0 0 1 16.5 21H12a4 4 0 0 1-3.4-1.9l-3-5a1.5 1.5 0 0 1 2.5-1.6L9 11.5z" />
    </svg>
  );
}
