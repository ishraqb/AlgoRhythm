import { useState } from "react";
import {
  PanInfo,
  motion,
  useMotionValue,
  useTransform,
} from "framer-motion";
import { FlashCard } from "./FlashCard";
import { Deck } from "../useDeck";
import { Theme } from "../theme";

const THRESHOLD = 120;

export function CardStack({ deck }: { deck: Deck }) {
  const x = useMotionValue(0);
  const rotate = useTransform(x, [-300, 300], [-16, 16]);
  const masterOpacity = useTransform(x, [0, THRESHOLD], [0, 1]);
  const reviewOpacity = useTransform(x, [0, -THRESHOLD], [0, 1]);
  const [exitX, setExitX] = useState(0);

  if (!deck.currentCard) {
    return <CompletedState onRestart={deck.restart} />;
  }

  const onDragEnd = (_: unknown, info: PanInfo) => {
    const dx = info.offset.x;
    if (Math.abs(dx) < THRESHOLD) {
      return; // dragSnapToOrigin returns it home
    }
    const outcome = dx > 0 ? "mastered" : "review";
    setExitX(dx > 0 ? 1000 : -1000);
    // Let the fly-off animation play, then advance.
    window.setTimeout(() => {
      deck.handleSwipe(outcome);
      setExitX(0);
      x.set(0);
    }, 180);
  };

  return (
    <div className="stack">
      <div className="stack-backing" />
      <motion.div
        key={deck.currentCard.id}
        className="stack-top"
        style={{ x, rotate }}
        drag="x"
        dragSnapToOrigin
        dragElastic={0.6}
        onDragEnd={onDragEnd}
        animate={exitX !== 0 ? { x: exitX, opacity: 0 } : undefined}
        transition={{ type: "spring", stiffness: 300, damping: 30 }}
        whileTap={{ cursor: "grabbing" }}
      >
        <FlashCard card={deck.currentCard} />
        <motion.div className="stamp stamp-master" style={{ opacity: masterOpacity }}>
          MASTERED
        </motion.div>
        <motion.div className="stamp stamp-review" style={{ opacity: reviewOpacity }}>
          REVIEW
        </motion.div>
      </motion.div>
    </div>
  );
}

function CompletedState({ onRestart }: { onRestart: () => void }) {
  return (
    <div className="stack">
      <div className="completed">
        <svg width="54" height="54" viewBox="0 0 24 24" fill={Theme.accent}>
          <path d="M12 1l2.4 1.8 3 .1 1 2.8 2.4 1.7-.9 2.9.9 2.9-2.4 1.7-1 2.8-3 .1L12 23l-2.4-1.8-3-.1-1-2.8L3.2 16l.9-2.9-.9-2.9 2.4-1.7 1-2.8 3-.1L12 1zm-1 14l5-5-1.4-1.4L11 12.2 9.4 10.6 8 12l3 3z" />
        </svg>
        <h2>Deck complete</h2>
        <p>You worked through every card in this filter.</p>
        <button className="btn-primary" onClick={onRestart}>
          Start over
        </button>
      </div>
    </div>
  );
}
