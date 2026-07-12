# Build a renderer-agnostic graph model from a parsed pipeline

Converts a
[`parse_pipeline()`](http://docs.jimbrig.com/gdalviz/reference/parse_pipeline.md)
result into a graph of nodes and edges, classifying each step, rendering
its arguments as code, generating a plain-language description, and
propagating the feature-stream state (CRS, geometry type, field schema,
validity, ordering) along the pipeline.

## Usage

``` r
pipeline_graph(x, contract = gdalviz_contract())
```

## Arguments

- x:

  A `gdalviz_pipeline` (from
  [`parse_pipeline()`](http://docs.jimbrig.com/gdalviz/reference/parse_pipeline.md))
  or a string/path accepted by
  [`read_gdalg()`](http://docs.jimbrig.com/gdalviz/reference/read_gdalg.md).

- contract:

  A `gdalviz_contract`.

## Value

A `gdalviz_graph`: a list with `nodes` and `edges` tibbles.
