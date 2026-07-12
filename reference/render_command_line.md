# Render a pipeline as a canonical GDALG command line

Serializes a parsed
[`parse_pipeline()`](http://docs.jimbrig.com/gdalviz/reference/parse_pipeline.md)
result back into a single-line `command_line` string, using the same
minimal quoting that GDAL itself uses when it writes `*.gdalg.json`
files. The result round-trips: parsing the output again yields an
equivalent pipeline.

## Usage

``` r
render_command_line(x, prog = TRUE, type = NULL)
```

## Arguments

- x:

  A `gdalviz_pipeline`, or a string/path accepted by
  [`read_gdalg()`](http://docs.jimbrig.com/gdalviz/reference/read_gdalg.md).

- prog:

  Logical or `NULL`. Whether to emit the leading `gdal <type> pipeline`
  program prefix. Defaults to `TRUE`.

- type:

  Pipeline type (`"vector"` or `"raster"`). Defaults to the type
  detected during parsing, falling back to `"vector"`.

## Value

A length-one character vector.
