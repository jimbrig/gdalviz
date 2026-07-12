# Render a pipeline graph as a Graphviz diagram (static-capable)

Builds a DOT specification with card-style HTML nodes (verb header, code
body, plain-language description), category colors, and state-annotated
edges, rendered via DiagrammeR. Suitable for static export to SVG/PNG.

## Usage

``` r
render_diagrammer(graph, direction = c("TB", "LR"), theme = c("light", "dark"))
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

A DiagrammeR `grViz` htmlwidget.
