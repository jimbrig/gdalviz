# Build a renderer-agnostic graph model from a parsed pipeline

Converts a
[`parse_pipeline()`](http://docs.jimbrig.com/gdalviz/reference/parse_pipeline.md)
result into a graph of nodes and edges, classifying each step, rendering
its arguments as code, generating a plain-language description, and
propagating the feature-stream state (CRS, geometry type, field schema,
validity, ordering) along the pipeline.

## Usage

``` r
pipeline_graph(x, contract = gdalviz_contract(), merge_repeated = TRUE)
```

## Arguments

- x:

  A `gdalviz_pipeline` (from
  [`parse_pipeline()`](http://docs.jimbrig.com/gdalviz/reference/parse_pipeline.md))
  or a string/path accepted by
  [`read_gdalg()`](http://docs.jimbrig.com/gdalviz/reference/read_gdalg.md).

- contract:

  A `gdalviz_contract`.

- merge_repeated:

  Merge runs of 3+ consecutive identical commands (e.g. the
  one-field-at-a-time `set-field-type` chains needed for schema
  overrides) into a single stacked node. Defaults to `TRUE`.

## Value

A `gdalviz_graph`: a list with `nodes` and `edges` tibbles.
