# Render a pipeline graph as an interactive g6 (AntV G6) widget

Produces a modern, interactive node-link diagram using a dagre
(hierarchical) layout. Nodes are card-style, colored by category,
labelled with the step verb and a plain-language description; edges
carry state-change badges.

## Usage

``` r
render_g6(
  graph,
  direction = c("TB", "LR", "BT", "RL"),
  theme = c("light", "dark"),
  height = NULL,
  width = "100%"
)
```

## Arguments

- graph:

  A `gdalviz_graph` from
  [`pipeline_graph()`](http://docs.jimbrig.com/gdalviz/reference/pipeline_graph.md).

- direction:

  Layout direction: `"TB"` (default), `"LR"`, `"BT"`, `"RL"`.

- theme:

  `"light"` or `"dark"`.

- height, width:

  Widget dimensions.

## Value

A `g6` htmlwidget.
