# Parse a shell or powershell script into a pipeline

Normalizes a `gdal ... pipeline` invocation written as a shell or
powershell script – joining line continuations, stripping comments, and
collapsing here-strings / heredocs into single tokens – then parses it
with
[`parse_pipeline()`](http://docs.jimbrig.com/gdalviz/reference/parse_pipeline.md).

## Usage

``` r
parse_script(
  text,
  shell = c("bash", "powershell"),
  contract = gdalviz_contract()
)
```

## Arguments

- text:

  The script text (a single string or a character vector of lines).

- shell:

  Source shell: `"bash"` (default) or `"powershell"`.

- contract:

  A `gdalviz_contract`.

## Value

A `gdalviz_pipeline`.
