# Read a GDAL pipeline from a GDALG file or raw string

Accepts a path to a GDALG JSON file
(`{"type":"gdal_streamed_alg", "command_line": "..."}`), a path to a raw
pipeline text file, or a raw pipeline string, and returns a parsed
`gdalviz_pipeline`.

## Usage

``` r
read_gdalg(x, contract = gdalviz_contract())
```

## Arguments

- x:

  A path to a GDALG/JSON/text file, or a raw pipeline string.

- contract:

  A `gdalviz_contract`.

## Value

A `gdalviz_pipeline`.
