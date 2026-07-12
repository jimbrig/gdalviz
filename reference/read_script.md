# Read a shell or powershell script file into a pipeline

Read a shell or powershell script file into a pipeline

## Usage

``` r
read_script(path, shell = NULL, contract = gdalviz_contract())
```

## Arguments

- path:

  Path to a `.sh` / `.ps1` script.

- shell:

  Source shell: `"bash"` (default) or `"powershell"`.

- contract:

  A `gdalviz_contract`.

## Value

A `gdalviz_pipeline`.
