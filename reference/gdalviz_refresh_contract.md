# Regenerate the GDAL pipeline contract snapshot from the installed GDAL

Runs `gdal <type> pipeline --json-usage` against the GDAL CLI on the
user's `PATH` (or an explicit binary) and writes the result as a new
contract snapshot, so the contract registry matches the locally
installed GDAL version instead of the snapshot bundled with the package.

## Usage

``` r
gdalviz_refresh_contract(
  path = NULL,
  type = c("vector", "raster"),
  gdal = NULL
)
```

## Arguments

- path:

  Destination for the snapshot JSON. Defaults to the bundled snapshot
  location, replacing it for the current installation.

- type:

  Pipeline type (`"vector"` or `"raster"`).

- gdal:

  Path to the `gdal` binary. Defaults to `gdal` on the `PATH`.

## Value

The refreshed `gdalviz_contract`, invisibly.
