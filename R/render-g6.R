#' Render a pipeline graph as an interactive g6 (AntV G6) widget
#'
#' Produces a modern, interactive node-link diagram using a dagre (hierarchical)
#' layout. Nodes are card-style, colored by category, labelled with the step
#' verb and a plain-language description; edges carry state-change badges.
#'
#' @param graph A `gdalviz_graph` from [pipeline_graph()].
#' @param direction Layout direction: `"TB"` (default), `"LR"`, `"BT"`, `"RL"`.
#' @param theme `"light"` or `"dark"`.
#' @param height,width Widget dimensions.
#'
#' @return A `g6` htmlwidget.
#' @export
render_g6 <- function(
  graph,
  direction = c("TB", "LR", "BT", "RL"),
  theme = c("light", "dark"),
  height = NULL,
  width = "100%"
) {
  rlang::check_installed("g6R")
  direction <- match.arg(direction)
  theme <- match.arg(theme)

  text_color <- if (theme == "dark") "#e2e8f0" else "#0f172a"
  node_fill <- if (theme == "dark") "#1e293b" else "#ffffff"
  bg <- if (theme == "dark") "#0f172a" else "#ffffff"

  nodes <- lapply(seq_len(nrow(graph$nodes)), function(i) {
    n <- graph$nodes[i, ]
    label <- paste0(n$verb, "\n", n$description)
    g6R::g6_node(
      id = n$id,
      type = "rect",
      data = list(
        category = n$category,
        code = n$code %||% "",
        docs_url = n$docs_url %||% ""
      ),
      style = list(
        size = c(230, 56),
        radius = 8,
        fill = node_fill,
        stroke = n$color,
        lineWidth = 2,
        labelText = label,
        labelPlacement = "center",
        labelFill = text_color,
        labelFontSize = 11,
        labelFontWeight = 500,
        labelWordWrap = TRUE,
        labelMaxWidth = 210,
        labelMaxLines = 3,
        iconText = NULL
      )
    )
  })

  edges <- lapply(seq_len(nrow(graph$edges)), function(i) {
    e <- graph$edges[i, ]
    target <- graph$nodes[graph$nodes$id == e$to, ]
    is_branch <- nrow(target) == 1 && target$branch_role[1] == "tee"
    style <- list(
      endArrow = TRUE,
      stroke = if (is_branch) "#94a3b8" else (if (theme == "dark") "#475569" else "#cbd5e1"),
      lineWidth = 1.5,
      lineDash = if (is_branch) c(4, 4) else NULL
    )
    if (!is.na(e$badge)) {
      style$labelText <- e$badge
      style$labelFontSize <- 9
      style$labelFill <- if (theme == "dark") "#94a3b8" else "#64748b"
      style$labelBackground <- TRUE
      style$labelBackgroundFill <- bg
    }
    g6R::g6_edge(source = e$from, target = e$to, style = style)
  })

  widget <- g6R::g6(nodes = nodes, edges = edges, height = height, width = width)
  widget <- g6R::g6_layout(widget, g6R::antv_dagre_layout(rankdir = direction, nodesep = 30, ranksep = 45))
  widget <- g6R::g6_behaviors(widget, "zoom-canvas", "drag-canvas", "drag-element")
  widget <- g6R::g6_plugins(widget, "minimap", "tooltip")
  widget
}
