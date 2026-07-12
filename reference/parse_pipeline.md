# Parse a GDAL vector pipeline into a structured object

Accepts a raw pipeline command line (with or without the
`gdal [vector|raster] pipeline` prefix) and parses it into an ordered
list of steps, resolving nested pipelines (`[ ... ]`) and associating
arguments with their values using the GDAL contract to disambiguate
boolean flags.

## Usage

``` r
parse_pipeline(x, contract = gdalviz_contract())
```

## Arguments

- x:

  A pipeline command-line string.

- contract:

  A `gdalviz_contract` used to disambiguate argument types.

## Value

A `gdalviz_pipeline` object.
