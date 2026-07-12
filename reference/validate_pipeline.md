# Validate a GDAL pipeline against the GDAL contract

Validates a parsed pipeline and returns a structured validation object.
By default it errors when validation fails.

## Usage

``` r
validate_pipeline(x, contract = gdalviz_contract(), strict = TRUE)
```

## Arguments

- x:

  A `gdalviz_pipeline`, or a string/path accepted by
  [`read_gdalg()`](http://docs.jimbrig.com/gdalviz/reference/read_gdalg.md).

- contract:

  A `gdalviz_contract`.

- strict:

  If `TRUE` (default), abort when validation contains errors.

## Value

A `gdalviz_validation` object with `valid` and `issues`.
