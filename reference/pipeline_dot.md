# Generate the DOT specification for a pipeline graph

Generate the DOT specification for a pipeline graph

## Usage

``` r
pipeline_dot(graph, direction = c("TB", "LR"), theme = c("light", "dark"))
```

## Arguments

- graph:

  A `gdalviz_graph` from
  [`pipeline_graph()`](http://docs.jimbrig.com/gdalviz/reference/pipeline_graph.md).

- direction:

  Layout direction: `"TB"` (vertical, default) or `"LR"`.

- theme:

  `"light"` or `"dark"`.

## Value

A length-one character string of DOT.
