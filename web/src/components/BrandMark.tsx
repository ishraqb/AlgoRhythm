import { Theme } from "../theme";

// A small linked list of nodes whose pointer chain resolves into a music note:
// the "algorithm" (nodes + pointers) meeting the "rhythm" (the note at the tail).
export function BrandMark({ size = 28, color = Theme.accent }: { size?: number; color?: string }) {
  const node = size * 0.44;
  const stroke = Math.max(1.5, size * 0.05);
  const gap = size * 0.1;

  return (
    <div style={{ display: "flex", alignItems: "center", gap, height: size }}>
      <span
        style={{
          width: node,
          height: node,
          borderRadius: "50%",
          border: `${stroke}px solid ${color}`,
          boxSizing: "border-box",
        }}
      />
      <Arrow color={color} size={size * 0.24} />
      <span
        style={{
          width: node,
          height: node,
          borderRadius: "50%",
          border: `${stroke}px solid ${color}`,
          boxSizing: "border-box",
        }}
      />
      <Arrow color={color} size={size * 0.24} />
      <span
        style={{
          position: "relative",
          width: node * 1.16,
          height: node * 1.16,
          borderRadius: "50%",
          background: color,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <NoteGlyph color={Theme.background} size={node * 0.72} />
      </span>
    </div>
  );
}

function Arrow({ color, size }: { color: string; size: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" style={{ opacity: 0.65 }}>
      <path
        d="M4 12h14M13 6l6 6-6 6"
        stroke={color}
        strokeWidth={3}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function NoteGlyph({ color, size }: { color: string; size: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={color}>
      <path d="M12 3v10.55A4 4 0 1 0 14 17V7h4V3h-6z" />
    </svg>
  );
}
