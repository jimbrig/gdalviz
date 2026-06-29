#' Render a pipeline graph as a Graphviz diagram (static-capable)
#'
#' Builds a DOT specification with card-style HTML nodes (verb header, code
#' body, plain-language description), category colors, and state-annotated
#' edges, rendered via DiagrammeR. Suitable for static export to SVG/PNG.
#'
#' @param graph A `gdalviz_graph` from [pipeline_graph()].
#' @param direction Layout direction: `"TB"` (vertical, default) or `"LR"`.
#' @param theme `"light"` or `"dark"`.
#'
#' @return A DiagrammeR `grViz` htmlwidget.
#' @export
render_diagrammer <- function(graph, direction = c("TB", "LR"), theme = c("light", "dark")) {
  direction <- match.arg(direction)
  theme <- match.arg(theme)
  dot <- pipeline_dot(graph, direction = direction, theme = theme)
  DiagrammeR::grViz(dot)
}

#' Generate the DOT specification for a pipeline graph
#' @inheritParams render_diagrammer
#' @return A length-one character string of DOT.
#' @export
pipeline_dot <- function(graph, direction = c("TB", "LR"), theme = c("light", "dark")) {
  direction <- match.arg(direction)
  theme <- match.arg(theme)

  bg <- if (theme == "dark") "#0f172a" else "#ffffff"
  node_lines <- vapply(
    seq_len(nrow(graph$nodes)),
    function(i) {
      dot_node(graph$nodes[i, ], theme = theme)
    },
    character(1)
  )

  edge_lines <- vapply(
    seq_len(nrow(graph$edges)),
    function(i) {
      dot_edge(graph$edges[i, ], graph$nodes, theme = theme)
    },
    character(1)
  )

  paste0(
    "digraph gdalviz {\n",
    sprintf("  bgcolor=\"%s\"\n", bg),
    sprintf("  rankdir=%s\n", direction),
    "  nodesep=0.45\n  ranksep=0.55\n",
    "  node [shape=plain fontname=\"Helvetica\"]\n",
    sprintf(
      "  edge [fontname=\"Helvetica\" fontsize=9 color=\"%s\" penwidth=1.4]\n",
      if (theme == "dark") "#64748b" else "#94a3b8"
    ),
    paste(node_lines, collapse = "\n"),
    "\n",
    paste(edge_lines, collapse = "\n"),
    "\n",
    "}\n"
  )
}

dot_node <- function(node, theme) {
  text_color <- if (theme == "dark") "#e2e8f0" else "#0f172a"
  body_bg <- if (theme == "dark") "#1e293b" else "#f8fafc"
  desc_color <- if (theme == "dark") "#94a3b8" else "#64748b"

  code <- truncate_code(node$code, 48)
  rows <- paste0(
    "<TR><TD ALIGN=\"LEFT\" BGCOLOR=\"",
    node$color,
    "\" CELLPADDING=\"6\">",
    "<FONT COLOR=\"#ffffff\" POINT-SIZE=\"12\"><B>",
    html_escape(node$verb),
    "</B></FONT>",
    "</TD></TR>",
    if (nzchar(code)) {
      paste0(
        "<TR><TD ALIGN=\"LEFT\" BGCOLOR=\"",
        body_bg,
        "\" CELLPADDING=\"6\">",
        "<FONT FACE=\"Courier\" POINT-SIZE=\"9\" COLOR=\"",
        text_color,
        "\">",
        html_escape(code),
        "</FONT></TD></TR>"
      )
    } else {
      ""
    },
    "<TR><TD ALIGN=\"LEFT\" BGCOLOR=\"",
    body_bg,
    "\" CELLPADDING=\"6\">",
    "<FONT POINT-SIZE=\"9\" COLOR=\"",
    desc_color,
    "\">",
    html_escape(node$description),
    "</FONT></TD></TR>"
  )

  label <- paste0(
    "<<TABLE BORDER=\"0\" CELLBORDER=\"0\" CELLSPACING=\"0\" STYLE=\"ROUNDED\">",
    rows,
    "</TABLE>>"
  )
  url <- if (!is.na(node$docs_url)) sprintf(" URL=\"%s\"", node$docs_url) else ""
  sprintf("  %s [label=%s%s]", node$id, label, url)
}

dot_edge <- function(edge, nodes, theme) {
  target <- nodes[nodes$id == edge$to, ]
  is_branch <- nrow(target) == 1 && target$branch_role[1] == "tee"
  style <- if (is_branch) " style=dashed" else ""
  label <- if (!is.na(edge$badge)) sprintf(" label=\" %s \"", edge$badge) else ""
  color <- if (is_branch) {
    if (theme == "dark") " color=\"#475569\"" else " color=\"#cbd5e1\""
  } else {
    ""
  }
  sprintf("  %s -> %s [%s%s%s]", edge$from, edge$to, trimws(paste0(style, color, label)), "", "")
}

truncate_code <- function(x, n) {
  if (is.na(x) || !nzchar(x)) {
    return("")
  }
  if (nchar(x) <= n) {
    return(x)
  }
  paste0(substr(x, 1, n - 1), "\u2026")
}

html_escape <- function(x) {
  if (is.na(x)) {
    return("")
  }
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub("\"", "&quot;", x, fixed = TRUE)
  x
}
