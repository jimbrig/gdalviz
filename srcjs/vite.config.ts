import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import cssInjectedByJsPlugin from "vite-plugin-css-injected-by-js";

// builds a single self-contained iife bundle (react + react flow + css)
// into inst/htmlwidgets/, where the htmlwidgets binding loads it by name.
export default defineConfig({
  plugins: [react(), cssInjectedByJsPlugin()],
  define: {
    "process.env.NODE_ENV": JSON.stringify("production"),
  },
  build: {
    lib: {
      entry: "src/widget.tsx",
      name: "pipeline_flow",
      formats: ["iife"],
      fileName: () => "pipeline_flow.js",
    },
    outDir: "../inst/htmlwidgets",
    emptyOutDir: false,
    minify: true,
    sourcemap: false,
  },
});
