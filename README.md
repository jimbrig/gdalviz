
# gdalviz <img src="man/figures/logo.png" align="right" height="139" alt="gdalviz hex logo" />

<!-- badges: start -->
[![R CMD CHECK](https://github.com/jimbrig/gdalviz/actions/workflows/check.yml/badge.svg)](https://github.com/jimbrig/gdalviz/actions/workflows/check.yml)
[![pkgdown](https://github.com/jimbrig/gdalviz/actions/workflows/pkgdown.yml/badge.svg)](https://github.com/jimbrig/gdalviz/actions/workflows/pkgdown.yml)
[![Automate Changelog](https://github.com/jimbrig/gdalviz/actions/workflows/changelog.yml/badge.svg)](https://github.com/jimbrig/gdalviz/actions/workflows/changelog.yml)
[![r-universe](https://jimbrig.r-universe.dev/badges/gdalviz)](https://jimbrig.r-universe.dev/gdalviz)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

`gdalviz` parses, validates, and visualizes modern GDAL CLI pipelines
(`gdal vector pipeline ! ...` command lines and GDALG `.gdalg.json` files),
turning them into diagrams that read like *what happens to the data* rather
than shell syntax.

- **Contract-driven** - steps and arguments are validated against GDAL's own
  `--json-usage` metadata (bundled snapshot, refreshable from your installed
  GDAL via `gdalviz_refresh_contract()`), including required arguments, enum
  choices, and mutually exclusive groups.
- **Flexible input** - raw pipeline strings, `.gdalg.json` files, and pasted
  bash / PowerShell scripts (line continuations, heredocs, and `\"` quoting
  are normalized automatically).
- **Semantic graphs** - `pipeline_graph()` builds a renderer-agnostic
  dataflow model: category classification, feature-stream state propagation
  (CRS, geometry type, field schema), runtime `--config` grouping, the
  GDALG-omitted write step as an explicit streamed sink, and merging of long
  repeated-step runs (e.g. one-field-at-a-time `set-field-type` chains).
- **Renderers** - interactive React Flow (`render_reactflow()`, bundled - no
  node toolchain needed), static Graphviz (`render_diagrammer()`), and AntV
  G6 (`render_g6()`).
- **Round-trip** - serialize back to canonical command lines
  (`render_command_line()`), formatted bash / PowerShell scripts
  (`render_script()`), or GDALG JSON (`as_gdalg()` / `write_gdalg()`).

## Installation

```r
# from r-universe (binaries)
install.packages("gdalviz", repos = c("https://jimbrig.r-universe.dev", "https://cloud.r-project.org"))

# or from github
pak::pak("jimbrig/gdalviz")
```

## Usage

Parse, lint, and render a pipeline:

```r
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
lint_pipeline(p)       # one row per contract violation (none here)

g <- pipeline_graph(p) # renderer-agnostic dataflow model
render_diagrammer(g)   # static graphviz rendering
```

![static graphviz rendering of the parcels pipeline](man/figures/readme-example-1.png)

The interactive React Flow renderer adds pan/zoom, a minimap, and a
click-to-open inspector with each step's arguments, propagated stream state,
and GDAL docs link. GDALG files work directly - note the implicit *streamed
output* sink attached where GDALG omits the final write:

```r
system.file("extdata", "pipelines", "tiger_states.gdalg.json", package = "gdalviz") |>
  pipeline_graph() |>
  render_reactflow(theme = "dark", minimap = FALSE, direction = "TB")
```

![interactive react flow rendering of the TIGER states GDALG pipeline](man/figures/readme-example-2.png)

Pasted shell scripts (bash or PowerShell) parse as-is, and everything
round-trips back out:

```r
render_command_line(p)             # canonical single-line command
cat(render_script(p, shell = "bash"))  # formatted multi-line script
write_gdalg(p, "parcels.gdalg.json")   # GDALG specification
```

## Learn more

- [Getting started vignette](https://docs.jimbrig.com/gdalviz/articles/gdalviz.html) -
  parse, validate, graph, render, round-trip
- [Pipeline gallery](https://docs.jimbrig.com/gdalviz/articles/pipeline-gallery.html) -
  live interactive diagrams of real-world pipelines (tee branching,
  config-heavy runs, merged schema chains)
- [Function reference](https://docs.jimbrig.com/gdalviz/reference/index.html)
- [Changelog](https://docs.jimbrig.com/gdalviz/news/index.html)

## Development

The interactive widget's TypeScript/React source lives in
[`srcjs/`](srcjs/README.md) (React Flow + dagre, built with Vite/Bun); the
compiled bundle is committed to `inst/htmlwidgets/` so package users never
need a node toolchain. Common tasks are wrapped in the `Makefile`
(`make docs`, `make js`, `make test`, `make check`, `make site`), and
`AGENTS.md` documents the architecture and conventions.

## Related work

- [GDAL CLI & pipelines](https://gdal.org/en/stable/programs/gdal_vector_pipeline.html) -
  the `gdal vector pipeline` algorithm and GDALG format this package visualizes
- [gdalraster](https://usdaforestservice.github.io/gdalraster/) - R bindings
  to the GDAL API, including the `GDALAlg` algorithm interface
- [dplyneage](https://github.com/tgerke/dplyneage) - React Flow lineage
  diagrams for dplyr/dbplyr pipelines (kindred spirit for tabular pipelines)
