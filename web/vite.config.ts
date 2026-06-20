import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Served from https://<user>.github.io/AlgoRhythm/, so assets need that base.
// Falls back to "/" for local dev and preview.
export default defineConfig(({ command }) => ({
  base: command === "build" ? "/AlgoRhythm/" : "/",
  plugins: [react()],
}));
