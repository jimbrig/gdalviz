# GDAL vector pipeline contract registry

Loads the bundled `gdal vector pipeline --json-usage` snapshot and turns
it into a lookup of pipeline steps and their arguments. This is the
single source of truth for which steps and arguments are valid, their
types, choices, and documentation URLs.

## Usage

``` r
gdalviz_contract(path = NULL, refresh = FALSE)
```

## Arguments

- path:

  Optional path to a `--json-usage` JSON snapshot. Defaults to the
  snapshot bundled with the package.

- refresh:

  If `TRUE`, bypass the cache and reload.

## Value

A `gdalviz_contract` object: a named list of step definitions.
