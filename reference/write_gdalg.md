# Write a pipeline to a GDALG JSON file

Write a pipeline to a GDALG JSON file

## Usage

``` r
write_gdalg(x, path, relative_paths = TRUE, gdal_version = NULL, pretty = TRUE)
```

## Arguments

- x:

  A `gdalviz_pipeline`, or a string/path accepted by
  [`read_gdalg()`](http://docs.jimbrig.com/gdalviz/reference/read_gdalg.md).

- path:

  Output path (conventionally ending in `.gdalg.json`).

- relative_paths:

  Logical for the `relative_paths_relative_to_this_file` member.
  Defaults to `TRUE`.

- gdal_version:

  Optional GDAL version string to record.

- pretty:

  Whether to pretty-print the JSON. Defaults to `TRUE`.

## Value

The `path`, invisibly.
