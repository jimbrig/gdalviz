# Render a pipeline graph as an interactive React Flow widget

Produces a modern, interactive dataflow diagram of a GDAL pipeline using
[React Flow](https://reactflow.dev) (xyflow). Steps render as card-style
nodes colored by category with their arguments inline; edges carry
state-change badges (CRS, geometry type, field count); tee branches
render as dashed side flows. Clicking a node opens an inspector panel
with the full argument list, the propagated stream state, and a link to
the GDAL documentation for that step.

## Usage

``` r
render_reactflow(
  graph,
  direction = c("TB", "LR", "BT", "RL"),
  theme = c("light", "dark"),
  minimap = TRUE,
  controls = TRUE,
  legend = TRUE,
  draggable = TRUE,
  width = NULL,
  height = NULL,
  elementId = NULL
)
```

## Arguments

- graph:

  A `gdalviz_graph` from
  [`pipeline_graph()`](http://docs.jimbrig.com/gdalviz/reference/pipeline_graph.md),
  or a pipeline/string/path accepted by it.

- direction:

  Layout direction: `"TB"` (default), `"LR"`, `"BT"`, `"RL"`.

- theme:

  `"light"` (default) or `"dark"`.

- minimap:

  Show a minimap overview. Defaults to `TRUE`.

- controls:

  Show zoom/fit controls. Defaults to `TRUE`.

- legend:

  Show the category legend. Defaults to `TRUE`.

- draggable:

  Allow nodes to be repositioned by dragging. Defaults to `TRUE`.

- width, height:

  Widget dimensions passed to
  [`htmlwidgets::createWidget()`](https://rdrr.io/pkg/htmlwidgets/man/createWidget.html).

- elementId:

  Optional explicit element id for the widget container.

## Value

A `pipeline_flow` htmlwidget.

## Details

The JavaScript bundle is built from `srcjs/` (see `srcjs/README.md`) and
shipped with the package, so no node toolchain is needed at run time.

## Examples

``` r
if (FALSE) { # \dontrun{
gdalg <- system.file(
  "extdata", "pipelines", "tiger_states_gdalg.json",
  package = "gdalviz"
)
pipeline_graph(gdalg) |> render_reactflow(theme = "dark")
} # }
```
