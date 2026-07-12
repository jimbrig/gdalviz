# Convert a pipeline to a GDALG specification list

Convert a pipeline to a GDALG specification list

## Usage

``` r
as_gdalg(x, relative_paths = TRUE, gdal_version = NULL)
```

## Arguments

- x:

  A `gdalviz_pipeline`, or a string/path accepted by
  [`read_gdalg()`](http://docs.jimbrig.com/gdalviz/reference/read_gdalg.md).

- relative_paths:

  Logical for the `relative_paths_relative_to_this_file` member.
  Defaults to `TRUE`.

- gdal_version:

  Optional GDAL version string to record.

## Value

A named list with `type`, `command_line`, and optional members, suitable
for serialization to a `*.gdalg.json` file.
