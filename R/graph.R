#' Build a renderer-agnostic graph model from a parsed pipeline
#'
#' Converts a [parse_pipeline()] result into a graph of nodes and edges,
#' classifying each step, rendering its arguments as code, generating a
#' plain-language description, and propagating the feature-stream state
#' (CRS, geometry type, field schema, validity, ordering) along the pipeline.
#'
#' @param x A `gdalviz_pipeline` (from [parse_pipeline()]) or a string/path
#'   accepted by [read_gdalg()].
#' @param contract A `gdalviz_contract`.
#'
#' @return A `gdalviz_graph`: a list with `nodes` and `edges` tibbles.
#' @export
pipeline_graph <- function(x, contract = gdalviz_contract()) {
  if (is.character(x)) {
    x <- read_gdalg(x, contract = contract)
  }
  if (!inherits(x, "gdalviz_pipeline")) {
    cli::cli_abort("{.arg x} must be a {.cls gdalviz_pipeline}, string, or path.")
  }

  ctx <- new.env(parent = emptyenv())
  ctx$id <- 0L
  ctx$nodes <- list()
  ctx$edges <- list()
  ctx$contract <- contract

  state <- empty_state()
  walk_chain(ctx, x$steps, prev_id = NULL, state = state, depth = 0L, branch_role = "main")

  structure(
    list(
      nodes = nodes_to_tibble(ctx$nodes),
      edges = edges_to_tibble(ctx$edges),
      globals = format_globals(x$pipeline_options),
      pipeline_type = x$pipeline_type,
      command_line = x$command_line
    ),
    class = "gdalviz_graph"
  )
}

empty_state <- function() {
  list(
    crs = NA_character_,
    geom = NA_character_,
    fields = NA_character_,
    validity = NA_character_,
    ordering = NA_character_,
    source = NA_character_,
    layer = NA_character_
  )
}

# walk a linear chain of steps, returning the id of the last main node
walk_chain <- function(ctx, steps, prev_id, state, depth, branch_role) {
  last_id <- prev_id
  for (step in steps) {
    res <- add_step_node(ctx, step, prev_id = last_id, state = state, depth = depth, branch_role = branch_role)
    state <- res$state
    last_id <- res$id
  }
  last_id
}

add_step_node <- function(ctx, step, prev_id, state, depth, branch_role) {
  command <- step$command
  category <- gdalviz_category(command)
  before <- state
  state <- apply_transition(command, step, state)

  ctx$id <- ctx$id + 1L
  id <- paste0("n", ctx$id)
  defn <- contract_step(command, ctx$contract)

  node <- list(
    id = id,
    command = command,
    category = category,
    category_label = gdalviz_category_label(category),
    verb = paste0("! ", command),
    code = render_step_code(step),
    args = step_args_payload(step),
    description = describe_step(command, step, state),
    icon = gdalviz_category_icon(category),
    color = gdalviz_palette()[[category]],
    docs_url = defn$url %||% NA_character_,
    crs = state$crs,
    geom = state$geom,
    fields = state$fields,
    validity = state$validity,
    ordering = state$ordering,
    branch_role = branch_role,
    depth = depth
  )
  ctx$nodes[[length(ctx$nodes) + 1L]] <- node

  if (!is.null(prev_id)) {
    add_edge(ctx, prev_id, id, kind = "main", badge = state_badge(before, state))
  }

  # nested branches
  for (a in step$args) {
    if (is.null(a$nested)) {
      next
    }
    if (identical(command, "tee")) {
      # output-nested: side branch fed from this node, dead-ends
      walk_chain(ctx, a$nested$steps, prev_id = id, state = state, depth = depth + 1L, branch_role = "tee")
    } else {
      # input-nested: branch result feeds INTO this node
      branch_last <- walk_chain(
        ctx,
        a$nested$steps,
        prev_id = NULL,
        state = empty_state(),
        depth = depth + 1L,
        branch_role = "input"
      )
      if (!is.null(branch_last)) {
        add_edge(ctx, branch_last, id, kind = "merge", badge = NA_character_)
      }
    }
  }

  list(id = id, state = state)
}

add_edge <- function(ctx, from, to, kind, badge) {
  ctx$edges[[length(ctx$edges) + 1L]] <- list(
    from = from,
    to = to,
    kind = kind,
    badge = badge %||% NA_character_
  )
}

# --- state transitions -------------------------------------------------------

apply_transition <- function(command, step, state) {
  switch(
    command,
    read = {
      state$source <- arg_value(step, "input")
      state$layer <- arg_value(step, "input-layer")
      state
    },
    concat = {
      state$source <- "multiple inputs"
      state
    },
    reproject = {
      crs <- arg_value(step, "output-crs")
      if (!is.na(crs)) {
        state$crs <- crs
      }
      state
    },
    `set-geom-type` = {
      state$geom <- geom_type_label(step)
      state
    },
    sql = {
      f <- parse_select_fields(arg_value(step, "sql"))
      if (!is.na(f)) {
        state$fields <- f
      }
      state
    },
    select = {
      if (!has_flag(step, "exclude")) {
        fields <- arg_value(step, "fields")
        if (!is.na(fields)) state$fields <- fields
      }
      state
    },
    `make-valid` = {
      state$validity <- "valid"
      state
    },
    sort = {
      state$ordering <- arg_value(step, "method")
      if (is.na(state$ordering)) {
        state$ordering <- "hilbert"
      }
      state
    },
    state
  )
}

state_badge <- function(before, after) {
  parts <- character(0)
  if (!identical(before$crs, after$crs) && !is.na(after$crs)) {
    parts <- c(parts, after$crs)
  }
  if (!identical(before$geom, after$geom) && !is.na(after$geom)) {
    parts <- c(parts, after$geom)
  }
  if (!identical(before$fields, after$fields) && !is.na(after$fields)) {
    n <- length(strsplit(after$fields, ",")[[1]])
    parts <- c(parts, paste0(n, " fields"))
  }
  if (length(parts) == 0) NA_character_ else paste(parts, collapse = " | ")
}

# --- descriptions ------------------------------------------------------------

describe_step <- function(command, step, state) {
  defn <- contract_step(command, gdalviz_contract())
  fallback <- defn$description %||% command

  switch(
    command,
    read = {
      layer <- arg_value(step, "input-layer")
      if (!is.na(layer)) paste0("Read layer ", squote(layer)) else "Read input dataset"
    },
    concat = "Concatenate input datasets",
    filter = {
      where <- arg_value(step, "where")
      bbox <- arg_value(step, "bbox")
      if (!is.na(where)) {
        paste0("Keep features where ", where)
      } else if (!is.na(bbox)) {
        paste0("Filter to bounding box ", bbox)
      } else {
        "Filter features"
      }
    },
    sql = "Transform attributes with SQL",
    select = {
      fields <- arg_value(step, "fields")
      verb <- if (has_flag(step, "exclude")) "Drop fields: " else "Keep fields: "
      if (!is.na(fields)) paste0(verb, fields) else "Select fields"
    },
    `make-valid` = "Repair invalid geometries",
    `set-geom-type` = paste0("Set geometry type to ", geom_type_label(step)),
    reproject = {
      crs <- arg_value(step, "output-crs")
      if (!is.na(crs)) paste0("Reproject to ", crs) else "Reproject"
    },
    sort = {
      m <- arg_value(step, "method")
      paste0("Spatially sort features (", m %||% "hilbert", ")")
    },
    tee = {
      n <- sum(vapply(step$args, function(a) !is.null(a$nested), logical(1)))
      paste0("Split stream into ", n, " side output", if (n == 1) "" else "s")
    },
    write = {
      out <- arg_value(step, "output")
      fmt <- arg_value(step, "output-format")
      msg <- "Write output"
      if (!is.na(out)) {
        msg <- paste0("Write to ", basename_safe(out))
      }
      if (!is.na(fmt)) {
        msg <- paste0(msg, " as ", fmt)
      }
      msg
    },
    `check-geometry` = "Flag invalid or non-simple geometries",
    buffer = {
      d <- step_positional(step)
      if (!is.na(d)) paste0("Buffer geometries by ", d) else "Buffer geometries"
    },
    clip = "Clip geometries",
    fallback
  )
}

# --- helpers -----------------------------------------------------------------

# structured argument list for renderers (name/value/kind per argument)
step_args_payload <- function(step) {
  lapply(step$args, function(a) {
    if (!is.null(a$nested)) {
      list(name = a$flag, value = NULL, kind = "nested")
    } else if (identical(a$kind, "flag")) {
      list(name = a$flag, value = a$value, kind = "flag")
    } else {
      list(name = NULL, value = a$value, kind = "positional")
    }
  })
}

# render pipeline-level options (--config etc.) as display chips
format_globals <- function(pipeline_options) {
  if (length(pipeline_options) == 0) {
    return(character(0))
  }
  vapply(
    pipeline_options,
    function(a) {
      if (identical(a$kind, "flag") && !is.null(a$flag)) {
        if (is.null(a$value)) paste0("--", a$flag) else a$value
      } else {
        a$value %||% ""
      }
    },
    character(1)
  )
}

geom_type_label <- function(step) {
  gt <- arg_value(step, "geometry-type")
  if (!is.na(gt)) {
    return(gt)
  }
  parts <- character(0)
  if (has_flag(step, "multi")) {
    parts <- c(parts, "multi-part")
  }
  if (has_flag(step, "single")) {
    parts <- c(parts, "single-part")
  }
  if (has_flag(step, "curve")) {
    parts <- c(parts, "curved")
  }
  if (has_flag(step, "linear")) {
    parts <- c(parts, "linear")
  }
  dim <- arg_value(step, "dim")
  if (!is.na(dim)) {
    parts <- c(parts, dim)
  }
  if (length(parts) == 0) "unchanged" else paste(parts, collapse = ", ")
}

parse_select_fields <- function(sql) {
  if (is.na(sql)) {
    return(NA_character_)
  }
  m <- regmatches(sql, regexec("(?is)\\bSELECT\\b(.*?)\\bFROM\\b", sql, perl = TRUE))[[1]]
  if (length(m) < 2) {
    return(NA_character_)
  }
  cols <- split_top_commas(m[2])
  aliases <- vapply(cols, field_alias, character(1))
  aliases <- aliases[nzchar(aliases)]
  if (length(aliases) == 0) NA_character_ else paste(aliases, collapse = ",")
}

field_alias <- function(col) {
  col <- trimws(col)
  m <- regmatches(col, regexec("(?i)\\bAS\\s+\"?([A-Za-z0-9_]+)\"?\\s*$", col, perl = TRUE))[[1]]
  if (length(m) >= 2) {
    return(m[2])
  }
  # last identifier token
  m2 <- regmatches(col, regexec("([A-Za-z0-9_]+)\\s*$", col))[[1]]
  if (length(m2) >= 2) m2[2] else ""
}

split_top_commas <- function(x) {
  chars <- strsplit(x, "", fixed = TRUE)[[1]]
  depth <- 0L
  out <- character(0)
  buf <- character(0)
  for (ch in chars) {
    if (ch == "(") {
      depth <- depth + 1L
    }
    if (ch == ")") {
      depth <- depth - 1L
    }
    if (ch == "," && depth == 0L) {
      out <- c(out, paste0(buf, collapse = ""))
      buf <- character(0)
    } else {
      buf <- c(buf, ch)
    }
  }
  out <- c(out, paste0(buf, collapse = ""))
  out
}

render_step_code <- function(step) {
  parts <- vapply(
    step$args,
    function(a) {
      if (!is.null(a$nested)) {
        if (!is.null(a$flag)) paste0("--", a$flag, " [...]") else "[...]"
      } else if (identical(a$kind, "flag")) {
        if (is.null(a$value)) paste0("--", a$flag) else paste0("--", a$flag, " ", quote_if_needed(a$value))
      } else {
        quote_if_needed(a$value)
      }
    },
    character(1)
  )
  paste(parts, collapse = " ")
}

arg_value <- function(step, name) {
  canonical <- resolve_arg_name(name)
  for (a in step$args) {
    if (identical(a$kind, "flag") && !is.null(a$flag)) {
      if (identical(resolve_arg_name(a$flag), canonical) || identical(a$flag, name)) {
        return(a$value %||% NA_character_)
      }
    }
  }
  NA_character_
}

has_flag <- function(step, name) {
  canonical <- resolve_arg_name(name)
  for (a in step$args) {
    if (identical(a$kind, "flag") && !is.null(a$flag)) {
      if (identical(resolve_arg_name(a$flag), canonical) || identical(a$flag, name)) {
        return(TRUE)
      }
    }
  }
  FALSE
}

step_positional <- function(step) {
  for (a in step$args) {
    if (identical(a$kind, "positional") && !is.null(a$value)) return(a$value)
  }
  NA_character_
}

quote_if_needed <- function(x) {
  if (is.null(x) || is.na(x)) {
    return("")
  }
  if (grepl("[[:space:]]", x)) paste0("'", x, "'") else x
}

squote <- function(x) paste0("'", x, "'")

basename_safe <- function(x) {
  if (is.na(x)) {
    return(x)
  }
  sub(".*[/\\\\]", "", x)
}

nodes_to_tibble <- function(nodes) {
  if (length(nodes) == 0) {
    return(tibble::tibble(
      id = character(0),
      command = character(0),
      category = character(0),
      category_label = character(0),
      args = list(),
      verb = character(0),
      code = character(0),
      description = character(0),
      icon = character(0),
      color = character(0),
      docs_url = character(0),
      crs = character(0),
      geom = character(0),
      fields = character(0),
      validity = character(0),
      ordering = character(0),
      branch_role = character(0),
      depth = integer(0)
    ))
  }
  tibble::tibble(
    id = vapply(nodes, `[[`, character(1), "id"),
    command = vapply(nodes, `[[`, character(1), "command"),
    category = vapply(nodes, `[[`, character(1), "category"),
    category_label = vapply(nodes, `[[`, character(1), "category_label"),
    args = lapply(nodes, function(n) n$args %||% list()),
    verb = vapply(nodes, `[[`, character(1), "verb"),
    code = vapply(nodes, `[[`, character(1), "code"),
    description = vapply(nodes, `[[`, character(1), "description"),
    icon = vapply(nodes, `[[`, character(1), "icon"),
    color = vapply(nodes, `[[`, character(1), "color"),
    docs_url = vapply(nodes, function(n) n$docs_url %||% NA_character_, character(1)),
    crs = vapply(nodes, function(n) n$crs %||% NA_character_, character(1)),
    geom = vapply(nodes, function(n) n$geom %||% NA_character_, character(1)),
    fields = vapply(nodes, function(n) n$fields %||% NA_character_, character(1)),
    validity = vapply(nodes, function(n) n$validity %||% NA_character_, character(1)),
    ordering = vapply(nodes, function(n) n$ordering %||% NA_character_, character(1)),
    branch_role = vapply(nodes, `[[`, character(1), "branch_role"),
    depth = vapply(nodes, `[[`, integer(1), "depth")
  )
}

edges_to_tibble <- function(edges) {
  if (length(edges) == 0) {
    return(tibble::tibble(
      from = character(0),
      to = character(0),
      kind = character(0),
      badge = character(0)
    ))
  }
  tibble::tibble(
    from = vapply(edges, `[[`, character(1), "from"),
    to = vapply(edges, `[[`, character(1), "to"),
    kind = vapply(edges, `[[`, character(1), "kind"),
    badge = vapply(edges, function(e) e$badge %||% NA_character_, character(1))
  )
}
