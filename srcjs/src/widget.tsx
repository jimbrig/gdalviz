import { createRoot, type Root } from "react-dom/client";
import "@xyflow/react/dist/style.css";
import "./styles.css";
import { App } from "./App";
import type { Payload } from "./types";

declare global {
  interface Window {
    HTMLWidgets: {
      widget: (def: {
        name: string;
        type: string;
        factory: (
          el: HTMLElement,
          width: number,
          height: number
        ) => { renderValue: (x: Payload) => void; resize: (w: number, h: number) => void };
      }) => void;
    };
  }
}

window.HTMLWidgets.widget({
  name: "pipeline_flow",
  type: "output",
  factory(el: HTMLElement) {
    let root: Root | null = null;
    return {
      renderValue(x: Payload) {
        if (!root) {
          root = createRoot(el);
        }
        root.render(<App payload={x} />);
      },
      resize() {
        // react flow tracks its container size; nothing to do
      },
    };
  },
});
