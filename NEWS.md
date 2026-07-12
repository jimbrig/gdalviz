# gdalviz 0.1.0

Initial release.

## Parsing and validation

- `parse_pipeline()` parses any valid `gdal vector pipeline` command line:
  step splitting (`!`), nested pipelines (`[ ... ]`, `--tee-pipeline`),
  flag/value/positional/short argument forms, quoting, and `@file` arguments.
- `read_gdalg()` accepts raw pipeline strings, GDALG (`.gdalg.json`) files,
  pipeline text files, and pasted multiline bash / PowerShell scripts
  (continuations, heredocs/here-strings, and PowerShell `\"` quoting are
  normalized automatically). `parse_script()` / `read_script()` handle
  explicit script input.
- Pipeline-level options (`--config`, `--progress`) parse into
  `pipeline_options`, including when the first step follows them without a
  `!` separator.
- `lint_pipeline()` / `validate_pipeline()` check pipelines against GDAL's
  own `--json-usage` contract: unknown steps/arguments, missing required
  arguments, boolean/value mismatches, invalid enum choices, and mutually
  exclusive argument groups (`mutual_exclusion_group`).
- `gdalviz_contract()` loads the bundled contract snapshot (steps, argument
  metadata, and pipeline-level arguments); `gdalviz_refresh_contract()`
  regenerates the snapshot from the installed GDAL CLI.

## Graph model

- `pipeline_graph()` builds a renderer-agnostic dataflow graph: semantic
  categories, plain-language descriptions, structured arguments, docs URLs,
  and feature-stream state propagation (CRS, geometry type, fields, validity,
  ordering) with "what changed" edge badges.
- Runtime configuration renders as a dedicated node feeding the source;
  GDALG pipelines with an omitted `write` gain an implicit streamed sink;
  runs of 3+ consecutive identical steps merge into one stacked node
  (`merge_repeated = TRUE`).

## Rendering

- `render_reactflow()`: interactive React Flow htmlwidget (bundled, no node
  toolchain needed) with card-style nodes, dagre layout, minimap, controls,
  category legend, light/dark themes, and a click-to-open inspector showing
  step code, arguments, stream state, and GDAL docs links. Shiny bindings via
  `pipelineFlowOutput()` / `renderPipelineFlow()`.
- `render_diagrammer()` / `pipeline_dot()`: static-capable Graphviz path.
- `render_g6()`: AntV G6 alternative renderer.

## Serialization

- `render_command_line()` round-trips pipelines to canonical GDALG command
  lines; `render_script()` formats bash / PowerShell scripts (optionally
  reflowing SQL into heredocs); `as_gdalg()` / `write_gdalg()` emit GDALG
  JSON specifications.
