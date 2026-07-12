# srcjs

TypeScript/React source for the `pipeline_flow` htmlwidget, rendered from R
via `gdalviz::render_reactflow()`.

## Stack

- [React Flow (@xyflow/react)](https://reactflow.dev) for the interactive
  node-link canvas (pan/zoom, minimap, controls, selection)
- [@dagrejs/dagre](https://github.com/dagrejs/dagre) for deterministic layered
  DAG layout (tee branches fan out, merges fan in)
- [Vite](https://vite.dev) building a single self-contained IIFE bundle
  (react + react flow + css inlined) into `inst/htmlwidgets/pipeline_flow.js`
- [Bun](https://bun.com) as the package manager / script runner

## Layout

| File                   | Purpose                                                        |
| ---------------------- | -------------------------------------------------------------- |
| `src/widget.tsx`       | htmlwidgets binding entry (registers `pipeline_flow`)          |
| `src/App.tsx`          | React Flow canvas, legend, config chips, inspector wiring      |
| `src/PipelineNode.tsx` | card-style custom node (header, args, flag chips)              |
| `src/Inspector.tsx`    | side panel: step code, arguments, stream state, docs link      |
| `src/layout.ts`        | dagre layout + graph payload -> React Flow nodes/edges         |
| `src/format.ts`        | value shortening (`/vsi.../` paths) and wrap estimation        |
| `src/types.ts`         | payload types mirroring the R `gdalviz_graph` model            |
| `src/styles.css`       | widget styles (light/dark via css variables on `.gv-root`)     |

## Commands

```bash
bun install        # install dependencies
bun run build      # typecheck-free production build -> inst/htmlwidgets/
bun run watch      # rebuild on change
bun run typecheck  # tsc --noEmit
```

The built bundle is committed so package users never need node/bun. After
changing anything here, run `bun run build` and commit the regenerated
`inst/htmlwidgets/pipeline_flow.js`.

## Payload contract

`render_reactflow()` sends `{ nodes, edges, globals, meta, options }` where
nodes/edges are row-wise serializations of the `gdalviz_graph` tibbles (plus
the structured `args` list per node) and `options` carries
direction/theme/minimap/controls/legend/draggable. Keep `src/types.ts` in sync
with `R/render-reactflow.R` and `R/graph.R`.
