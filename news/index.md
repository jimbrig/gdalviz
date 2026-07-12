# Changelog

## gdalviz 0.1.0

Initial release.

### Parsing and validation

- [`parse_pipeline()`](http://docs.jimbrig.com/gdalviz/reference/parse_pipeline.md)
  parses any valid `gdal vector pipeline` command line: step splitting
  (`!`), nested pipelines (`[ ... ]`, `--tee-pipeline`),
  flag/value/positional/short argument forms, quoting, and `@file`
  arguments.
- [`read_gdalg()`](http://docs.jimbrig.com/gdalviz/reference/read_gdalg.md)
  accepts raw pipeline strings, GDALG (`.gdalg.json`) files, pipeline
  text files, and pasted multiline bash / PowerShell scripts
  (continuations, heredocs/here-strings, and PowerShell `\"` quoting are
  normalized automatically).
  [`parse_script()`](http://docs.jimbrig.com/gdalviz/reference/parse_script.md)
  /
  [`read_script()`](http://docs.jimbrig.com/gdalviz/reference/read_script.md)
  handle explicit script input.
- Pipeline-level options (`--config`, `--progress`) parse into
  `pipeline_options`, including when the first step follows them without
  a `!` separator.
- [`lint_pipeline()`](http://docs.jimbrig.com/gdalviz/reference/lint_pipeline.md)
  /
  [`validate_pipeline()`](http://docs.jimbrig.com/gdalviz/reference/validate_pipeline.md)
  check pipelines against GDAL’s own `--json-usage` contract: unknown
  steps/arguments, missing required arguments, boolean/value mismatches,
  invalid enum choices, and mutually exclusive argument groups
  (`mutual_exclusion_group`).
- [`gdalviz_contract()`](http://docs.jimbrig.com/gdalviz/reference/gdalviz_contract.md)
  loads the bundled contract snapshot (steps, argument metadata, and
  pipeline-level arguments);
  [`gdalviz_refresh_contract()`](http://docs.jimbrig.com/gdalviz/reference/gdalviz_refresh_contract.md)
  regenerates the snapshot from the installed GDAL CLI.

### Graph model

- [`pipeline_graph()`](http://docs.jimbrig.com/gdalviz/reference/pipeline_graph.md)
  builds a renderer-agnostic dataflow graph: semantic categories,
  plain-language descriptions, structured arguments, docs URLs, and
  feature-stream state propagation (CRS, geometry type, fields,
  validity, ordering) with “what changed” edge badges.
- Runtime configuration renders as a dedicated node feeding the source;
  GDALG pipelines with an omitted `write` gain an implicit streamed
  sink; runs of 3+ consecutive identical steps merge into one stacked
  node (`merge_repeated = TRUE`).

### Rendering

- [`render_reactflow()`](http://docs.jimbrig.com/gdalviz/reference/render_reactflow.md):
  interactive React Flow htmlwidget (bundled, no node toolchain needed)
  with card-style nodes, dagre layout, minimap, controls, category
  legend, light/dark themes, and a click-to-open inspector showing step
  code, arguments, stream state, and GDAL docs links. Shiny bindings via
  [`pipelineFlowOutput()`](http://docs.jimbrig.com/gdalviz/reference/pipelineFlowOutput.md)
  /
  [`renderPipelineFlow()`](http://docs.jimbrig.com/gdalviz/reference/pipelineFlowOutput.md).
- [`render_diagrammer()`](http://docs.jimbrig.com/gdalviz/reference/render_diagrammer.md)
  /
  [`pipeline_dot()`](http://docs.jimbrig.com/gdalviz/reference/pipeline_dot.md):
  static-capable Graphviz path.
- [`render_g6()`](http://docs.jimbrig.com/gdalviz/reference/render_g6.md):
  AntV G6 alternative renderer.

### Serialization

- [`render_command_line()`](http://docs.jimbrig.com/gdalviz/reference/render_command_line.md)
  round-trips pipelines to canonical GDALG command lines;
  [`render_script()`](http://docs.jimbrig.com/gdalviz/reference/render_script.md)
  formats bash / PowerShell scripts (optionally reflowing SQL into
  heredocs);
  [`as_gdalg()`](http://docs.jimbrig.com/gdalviz/reference/as_gdalg.md)
  /
  [`write_gdalg()`](http://docs.jimbrig.com/gdalviz/reference/write_gdalg.md)
  emit GDALG JSON specifications.
