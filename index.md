# gdalviz

`gdalviz` provides a modern framework for parsing, validating, and
visualizing GDAL pipeline algorithms (for example
`gdal vector pipeline ! ...` and GDALG `command_line` definitions).

- **Contract-driven**: steps and arguments are validated against GDAL’s
  own `--json-usage` metadata (bundled snapshot, refreshable from your
  installed GDAL via
  [`gdalviz_refresh_contract()`](http://docs.jimbrig.com/gdalviz/reference/gdalviz_refresh_contract.md)).
- **Flexible input**: raw pipeline strings, `.gdalg.json` files, and
  pasted bash/PowerShell scripts (line continuations and heredocs are
  normalized automatically).
- **Semantic graphs**:
  [`pipeline_graph()`](http://docs.jimbrig.com/gdalviz/reference/pipeline_graph.md)
  builds a renderer-agnostic dataflow model with category
  classification, feature-stream state propagation (CRS, geometry,
  fields), runtime `--config` grouping, the GDALG-omitted write step,
  and merging of long repeated-step runs (e.g. `set-field-type` chains).
- **Renderers**: interactive React Flow
  ([`render_reactflow()`](http://docs.jimbrig.com/gdalviz/reference/render_reactflow.md),
  bundled - no node toolchain needed), AntV G6
  ([`render_g6()`](http://docs.jimbrig.com/gdalviz/reference/render_g6.md)),
  and static Graphviz
  ([`render_diagrammer()`](http://docs.jimbrig.com/gdalviz/reference/render_diagrammer.md)).

## Installation

You can install the development version of gdalviz like so:

``` r

pak::pak("jimbrig/gdalviz")
```

## Example

Parse, validate, and render a modern GDAL vector pipeline:

``` r

library(gdalviz)

cmd <- paste(
  "gdal vector pipeline",
  "read --input /data/parcels.gpkg --input-layer parcels",
  "! filter --where \"statefp = '13'\"",
  "! make-valid",
  "! reproject --output-crs EPSG:4326",
  "! write --output /tmp/parcels.fgb --output-format FlatGeobuf"
)

p <- parse_pipeline(cmd)
v <- validate_pipeline(p, strict = FALSE)
issues <- lint_pipeline(p)

g <- pipeline_graph(p)
render_diagrammer(g)
```

![readme-example-1](reference/figures/readme-example-1.png)

readme-example-1

or use the *react-flow* based interactive renderer:

``` r

system.file("extdata", "pipelines", "tiger_states.gdalg.json", package = "gdalviz") |>
  pipeline_graph() |>
  render_reactflow(theme = "dark", minimap = FALSE, direction = "TB")
```

![readme-example-2](reference/figures/readme-example-2.png)

readme-example-2
