# Getting started with gdalviz

``` r

library(gdalviz)
```

Modern GDAL (\>= 3.11) ships a composable CLI where vector operations
chain into *pipelines*:

``` sh
gdal vector pipeline ! read ... ! filter ... ! reproject ... ! write ...
```

Pipelines can be saved as `.gdalg.json` files (the command line without
the final `write` step) and reused as streamed datasets. gdalviz parses
these pipelines, validates them against GDAL’s own algorithm contract,
and renders them as static or interactive dataflow diagrams for people
who think in maps, not command lines.

## Parsing pipelines

[`parse_pipeline()`](http://docs.jimbrig.com/gdalviz/reference/parse_pipeline.md)
accepts a raw command line, with or without the `gdal vector pipeline`
prefix:

``` r

cmd <- paste(
  "gdal vector pipeline",
  "--config GDAL_NUM_THREADS=ALL_CPUS",
  "! read --input parcels.gpkg --input-layer parcels",
  "! filter --where \"statefp = '13'\"",
  "! make-valid",
  "! reproject --output-crs EPSG:4326",
  "! write --output parcels.fgb --output-format FlatGeobuf"
)

p <- parse_pipeline(cmd)
p
#> ── <gdalviz_pipeline> ────────────────────────────────── gdal vector pipeline ──
#> global: `--config GDAL_NUM_THREADS=ALL_CPUS`
#> 5 steps:
#> 1. read `--input parcels.gpkg --input-layer parcels`
#> 2. filter `--where "statefp = '13'"`
#> 3. make-valid
#> 4. reproject `--output-crs EPSG:4326`
#> 5. write `--output parcels.fgb --output-format FlatGeobuf`
```

[`read_gdalg()`](http://docs.jimbrig.com/gdalviz/reference/read_gdalg.md)
additionally accepts paths to `.gdalg.json` files, raw pipeline text
files, and pasted multiline bash / PowerShell scripts – line
continuations, heredocs, and PowerShell `\"` quoting are normalized
automatically:

``` r

script <- "gdal vector pipeline `
  read --input parcels.gpkg `
! reproject --output-crs 'EPSG:4326' `
! write --output out.fgb"

read_gdalg(script)
#> ── <gdalviz_pipeline> ────────────────────────────────── gdal vector pipeline ──
#> 3 steps:
#> 1. read `--input parcels.gpkg`
#> 2. reproject `--output-crs EPSG:4326`
#> 3. write `--output out.fgb`
```

## Validating against the GDAL contract

The single source of truth for valid steps and arguments is GDAL’s own
`--json-usage` output. A snapshot is bundled with the package, and
[`gdalviz_refresh_contract()`](http://docs.jimbrig.com/gdalviz/reference/gdalviz_refresh_contract.md)
regenerates it from your locally installed GDAL.

[`lint_pipeline()`](http://docs.jimbrig.com/gdalviz/reference/lint_pipeline.md)
returns one row per issue;
[`validate_pipeline()`](http://docs.jimbrig.com/gdalviz/reference/validate_pipeline.md)
wraps the result into a pass/fail object:

``` r

bad <- "read --input in.gpkg ! reproject ! write --output out.fgb --append --upsert"
lint_pipeline(bad)
#> # A tibble: 2 × 5
#>   step_index command   level code                    message                    
#>        <int> <chr>     <chr> <chr>                   <chr>                      
#> 1          2 reproject error missing_required_args   Missing required argument(…
#> 2          3 write     error mutually_exclusive_args Arguments --append, --upse…
```

Unknown steps and arguments, missing required arguments, invalid enum
choices, and mutually exclusive combinations (like `--append` +
`--upsert` above) are all reported.

## The pipeline graph

[`pipeline_graph()`](http://docs.jimbrig.com/gdalviz/reference/pipeline_graph.md)
turns a pipeline into a renderer-agnostic dataflow model: nodes carry a
semantic category (source, filter, geometry, …), a plain-language
description, and the propagated feature-stream state (CRS, geometry
type, field schema); edges carry “what changed” badges.

``` r

g <- pipeline_graph(cmd)
g$nodes[, c("command", "category", "description")]
#> # A tibble: 6 × 3
#>   command    category description                            
#>   <chr>      <chr>    <chr>                                  
#> 1 config     runtime  Runtime configuration (1 config option)
#> 2 read       source   Read layer 'parcels'                   
#> 3 filter     filter   Keep features where statefp = '13'     
#> 4 make-valid geometry Repair invalid geometries              
#> 5 reproject  crs      Reproject to EPSG:4326                 
#> 6 write      sink     Write to parcels.fgb as FlatGeobuf
```

A few GDAL nuances get dedicated treatment:

- pipeline-level options (`--config`, `--progress`) group into a single
  *runtime configuration* node feeding the source,
- GDALG pipelines omit their terminal `write`; the graph adds an
  implicit *streamed output* sink so the flow reads complete,
- runs of 3+ consecutive identical steps (for example the
  one-field-at-a-time `set-field-type` chains needed for schema
  overrides) merge into one stacked node. Opt out with
  `merge_repeated = FALSE`.

## Interactive rendering

[`render_reactflow()`](http://docs.jimbrig.com/gdalviz/reference/render_reactflow.md)
produces the interactive [React Flow](https://reactflow.dev) widget
bundled with the package (no node toolchain required). Drag to pan,
scroll to zoom, and **click any node** to open an inspector with the
step’s arguments, the propagated stream state, and a link to its GDAL
documentation.

``` r

render_reactflow(g, theme = "light", height = 460)
```

Layout direction (`"TB"`, `"LR"`, …), light/dark themes, and the
minimap/controls/legend overlays are all arguments. For static output
use
[`render_diagrammer()`](http://docs.jimbrig.com/gdalviz/reference/render_diagrammer.md)
(Graphviz), or
[`render_g6()`](http://docs.jimbrig.com/gdalviz/reference/render_g6.md)
for an AntV G6 alternative. See the [pipeline
gallery](https://docs.jimbrig.com/gdalviz/articles/pipeline-gallery.html)
article for larger real-world examples (tee branching, config-heavy
runs, merged schema chains).

## Round-tripping and scripts

Parsed pipelines serialize back out losslessly:

``` r

render_command_line(p)
#> [1] "gdal vector pipeline --config GDAL_NUM_THREADS=ALL_CPUS ! read --input parcels.gpkg --input-layer parcels ! filter --where \"statefp = '13'\" ! make-valid ! reproject --output-crs EPSG:4326 ! write --output parcels.fgb --output-format FlatGeobuf"
```

and can be formatted as ready-to-run shell scripts for either bash or
PowerShell, optionally reflowing SQL into heredocs:

``` r

cat(render_script(p, shell = "bash"))
#> gdal vector pipeline \
#>   --config GDAL_NUM_THREADS=ALL_CPUS \
#>   ! read --input parcels.gpkg --input-layer parcels \
#>   ! filter --where "statefp = '13'" \
#>   ! make-valid \
#>   ! reproject --output-crs EPSG:4326 \
#>   ! write --output parcels.fgb --output-format FlatGeobuf
```

[`as_gdalg()`](http://docs.jimbrig.com/gdalviz/reference/as_gdalg.md) /
[`write_gdalg()`](http://docs.jimbrig.com/gdalviz/reference/write_gdalg.md)
produce GDALG JSON specifications directly.
