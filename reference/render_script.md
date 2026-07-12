# Render a pipeline as a formatted shell script

Produces an indented, line-continued `gdal <type> pipeline` invocation
for either `bash`/`sh` or `powershell`, with one `! step` per line and
shell-appropriate quoting. Optionally reflows large SQL into a heredoc
(bash) or here-string (powershell) for readability.

## Usage

``` r
render_script(
  x,
  shell = c("bash", "powershell"),
  indent = "  ",
  type = NULL,
  globals_per_line = 3L,
  sql = c("inline", "block")
)
```

## Arguments

- x:

  A `gdalviz_pipeline`, or a string/path accepted by
  [`read_gdalg()`](http://docs.jimbrig.com/gdalviz/reference/read_gdalg.md).

- shell:

  Target shell: `"bash"` (default) or `"powershell"`.

- indent:

  Indentation unit for steps. Defaults to two spaces.

- type:

  Pipeline type (`"vector"` or `"raster"`).

- globals_per_line:

  Number of global options to place per continuation line. Defaults to
  `3`.

- sql:

  Either `"inline"` (default, single quoted token) or `"block"`
  (multiline heredoc / here-string for `--sql` values).

## Value

A length-one character vector containing the full script.
