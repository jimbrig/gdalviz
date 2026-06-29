
# gdalviz

<!-- badges: start -->
<!-- badges: end -->

`gdalviz` provides a modern framework for parsing, validating, and visualizing
GDAL pipeline algorithms (for example `gdal vector pipeline ! ...` and GDALG
`command_line` definitions).

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
