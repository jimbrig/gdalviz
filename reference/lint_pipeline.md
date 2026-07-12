# Lint a GDAL pipeline against the GDAL contract

Produces a structured issue table for unknown steps, unknown arguments,
missing required arguments, and value/type mismatches.

## Usage

``` r
lint_pipeline(x, contract = gdalviz_contract())
```

## Arguments

- x:

  A `gdalviz_pipeline`, or a string/path accepted by
  [`read_gdalg()`](http://docs.jimbrig.com/gdalviz/reference/read_gdalg.md).

- contract:

  A `gdalviz_contract`.

## Value

A tibble with one row per lint issue.
