#' Render a pipeline graph as an interactive React Flow widget
#'
#' Produces a modern, interactive dataflow diagram of a GDAL pipeline using
#' [React Flow](https://reactflow.dev) (xyflow). Steps render as card-style
#' nodes colored by category with their arguments inline; edges carry
#' state-change badges (CRS, geometry type, field count); tee branches render
#' as dashed side flows. Clicking a node opens an inspector panel with the
#' full argument list, the propagated stream state, and a link to the GDAL
#' documentation for that step.
#'
#' The JavaScript bundle is built from `srcjs/` (see
#' `srcjs/README.md`) and shipped with the package, so no node toolchain is
#' needed at run time.
#'
#' @param graph A `gdalviz_graph` from [pipeline_graph()], or a
#'   pipeline/string/path accepted by it.
#' @param direction Layout direction: `"TB"` (default), `"LR"`, `"BT"`, `"RL"`.
#' @param theme `"light"` (default) or `"dark"`.
#' @param minimap Show a minimap overview. Defaults to `TRUE`.
#' @param controls Show zoom/fit controls. Defaults to `TRUE`.
#' @param legend Show the category legend. Defaults to `TRUE`.
#' @param draggable Allow nodes to be repositioned by dragging. Defaults to
#'   `TRUE`.
#' @param width,height Widget dimensions passed to
#'   [htmlwidgets::createWidget()].
#' @param elementId Optional explicit element id for the widget container.
#'
#' @return A `pipeline_flow` htmlwidget.
#'
#' @examples
#' \dontrun{
#' gdalg <- system.file(
#'   "extdata", "pipelines", "tiger_states_gdalg.json",
#'   package = "gdalviz"
#' )
#' pipeline_graph(gdalg) |> render_reactflow(theme = "dark")
#' }
#'
#' @export
render_reactflow <- function(
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
) {
  rlang::check_installed("htmlwidgets")
  direction <- rlang::arg_match(direction)
  theme <- rlang::arg_match(theme)

  if (!inherits(graph, "gdalviz_graph")) {
    graph <- pipeline_graph(graph)
  }

  payload <- list(
    nodes = reactflow_nodes(graph$nodes),
    edges = reactflow_edges(graph$edges),
    globals = as.list(graph$globals %||% character(0)),
    meta = list(
      command_line = graph$command_line %||% NA_character_,
      pipeline_type = graph$pipeline_type %||% NA_character_
    ),
    options = list(
      direction = direction,
      theme = theme,
      minimap = isTRUE(minimap),
      controls = isTRUE(controls),
      legend = isTRUE(legend),
      draggable = isTRUE(draggable)
    )
  )

  htmlwidgets::createWidget(
    name = "pipeline_flow",
    x = payload,
    width = width,
    height = height,
    package = "gdalviz",
    elementId = elementId,
    sizingPolicy = htmlwidgets::sizingPolicy(
      defaultWidth = "100%",
      defaultHeight = 560,
      viewer.fill = TRUE,
      browser.fill = TRUE,
      knitr.defaultWidth = "100%",
      knitr.defaultHeight = "560px"
    )
  )
}

#' Shiny bindings for pipeline_flow widgets
#'
#' Output and render functions for using [render_reactflow()] widgets within
#' Shiny applications.
#'
#' @param outputId Output variable to read from.
#' @param width,height CSS dimensions for the widget container.
#' @param expr An expression that returns a `pipeline_flow` widget.
#' @param env The environment in which to evaluate `expr`.
#' @param quoted Whether `expr` is a quoted expression.
#'
#' @return `pipelineFlowOutput()` returns a Shiny output element;
#'   `renderPipelineFlow()` returns a Shiny render function.
#'
#' @export
pipelineFlowOutput <- function(outputId, width = "100%", height = "560px") {
  rlang::check_installed("htmlwidgets")
  htmlwidgets::shinyWidgetOutput(outputId, "pipeline_flow", width, height, package = "gdalviz")
}

#' @rdname pipelineFlowOutput
#' @export
renderPipelineFlow <- function(expr, env = parent.frame(), quoted = FALSE) {
  rlang::check_installed("htmlwidgets")
  if (!quoted) {
    expr <- substitute(expr)
  }
  htmlwidgets::shinyRenderWidget(expr, pipelineFlowOutput, env, quoted = TRUE)
}

# row-wise payloads so jsonlite serializes objects, not column vectors --------

reactflow_nodes <- function(nodes) {
  lapply(seq_len(nrow(nodes)), function(i) {
    n <- nodes[i, ]
    list(
      id = n$id,
      command = n$command,
      category = n$category,
      category_label = n$category_label,
      verb = n$verb,
      code = na_null(n$code),
      description = na_null(n$description),
      icon = n$icon,
      color = n$color,
      docs_url = na_null(n$docs_url),
      crs = na_null(n$crs),
      geom = na_null(n$geom),
      fields = na_null(n$fields),
      validity = na_null(n$validity),
      ordering = na_null(n$ordering),
      branch_role = n$branch_role,
      depth = n$depth,
      args = n$args[[1]]
    )
  })
}

reactflow_edges <- function(edges) {
  lapply(seq_len(nrow(edges)), function(i) {
    e <- edges[i, ]
    list(
      from = e$from,
      to = e$to,
      kind = e$kind,
      badge = na_null(e$badge)
    )
  })
}

na_null <- function(x) {
  if (is.null(x) || length(x) == 0 || is.na(x)) NULL else x
}
