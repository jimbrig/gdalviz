#  ------------------------------------------------------------------------
#
# Title : Pipeline Rendering
#    By : Jimmy Briggs
#  Date : 2026-06-27
#
#  ------------------------------------------------------------------------

# The functions in this file are the inverse of `parse.R`: they take a parsed
# `gdalviz_pipeline` and serialize it back into either a canonical GDALG
# `command_line` string or a nicely formatted bash / powershell script.

# canonical command line ------------------------------------------------------

#' Render a pipeline as a canonical GDALG command line
#'
#' Serializes a parsed [parse_pipeline()] result back into a single-line
#' `command_line` string, using the same minimal quoting that GDAL itself uses
#' when it writes `*.gdalg.json` files. The result round-trips: parsing the
#' output again yields an equivalent pipeline.
#'
#' @param x A `gdalviz_pipeline`, or a string/path accepted by [read_gdalg()].
#' @param prog Logical or `NULL`. Whether to emit the leading
#'   `gdal <type> pipeline` program prefix. Defaults to `TRUE`.
#' @param type Pipeline type (`"vector"` or `"raster"`). Defaults to the type
#'   detected during parsing, falling back to `"vector"`.
#'
#' @return A length-one character vector.
#' @export
render_command_line <- function(x, prog = TRUE, type = NULL) {
  x <- as_pipeline(x)
  type <- type %||% x$pipeline_type %||% "vector"

  steps <- vapply(
    x$steps,
    function(step) render_step(step, quoter = quote_cmdline, sep = " ! "),
    character(1)
  )

  globals <- render_args(x$pipeline_options, quoter = quote_cmdline)

  body <- if (length(globals) > 0) {
    # when global options are present GDAL requires the `!` before the first step
    paste(c(paste(globals, collapse = " "), steps), collapse = " ! ")
  } else {
    paste(steps, collapse = " ! ")
  }

  if (isTRUE(prog)) {
    paste(c("gdal", type, "pipeline", body), collapse = " ")
  } else {
    body
  }
}

# script rendering ------------------------------------------------------------

#' Render a pipeline as a formatted shell script
#'
#' Produces an indented, line-continued `gdal <type> pipeline` invocation for
#' either `bash`/`sh` or `powershell`, with one `! step` per line and
#' shell-appropriate quoting. Optionally reflows large SQL into a heredoc
#' (bash) or here-string (powershell) for readability.
#'
#' @param x A `gdalviz_pipeline`, or a string/path accepted by [read_gdalg()].
#' @param shell Target shell: `"bash"` (default) or `"powershell"`.
#' @param indent Indentation unit for steps. Defaults to two spaces.
#' @param type Pipeline type (`"vector"` or `"raster"`).
#' @param globals_per_line Number of global options to place per continuation
#'   line. Defaults to `3`.
#' @param sql Either `"inline"` (default, single quoted token) or `"block"`
#'   (multiline heredoc / here-string for `--sql` values).
#'
#' @return A length-one character vector containing the full script.
#' @export
render_script <- function(
  x,
  shell = c("bash", "powershell"),
  indent = "  ",
  type = NULL,
  globals_per_line = 3L,
  sql = c("inline", "block")
) {
  shell <- rlang::arg_match(shell)
  sql <- rlang::arg_match(sql)
  x <- as_pipeline(x)
  type <- type %||% x$pipeline_type %||% "vector"

  quoter <- if (shell == "powershell") quote_ps else quote_bash
  cont <- if (shell == "powershell") "`" else "\\"

  lines <- paste("gdal", type, "pipeline")

  globals <- render_args(x$pipeline_options, quoter = quoter)
  if (length(globals) > 0) {
    chunks <- chunk_vec(globals, globals_per_line)
    lines <- c(lines, vapply(chunks, function(ch) paste0(indent, paste(ch, collapse = " ")), character(1)))
  }

  for (step in x$steps) {
    rendered <- render_step(step, quoter = quoter, sep = " ! ", sql = sql, shell = shell)
    lines <- c(lines, paste0(indent, "! ", rendered))
  }

  # join with a trailing continuation on every line except the last
  n <- length(lines)
  if (n > 1) {
    lines[-n] <- paste0(lines[-n], " ", cont)
  }
  paste(lines, collapse = "\n")
}

# step / arg rendering --------------------------------------------------------

#' @keywords internal
#' @noRd
render_step <- function(step, quoter, sep = " ! ", sql = "inline", shell = "bash") {
  parts <- render_args(step$args, quoter = quoter, command = step$command, sql = sql, shell = shell, sep = sep)
  paste(c(step$command, parts), collapse = " ")
}

#' @keywords internal
#' @noRd
render_args <- function(args, quoter, command = NA_character_, sql = "inline", shell = "bash", sep = " ! ") {
  if (length(args) == 0) {
    return(character(0))
  }
  out <- character(0)
  for (a in args) {
    if (!is.null(a$nested)) {
      branch <- render_branch(a$nested, quoter = quoter, sql = sql, shell = shell, sep = sep)
      if (identical(a$kind, "flag") && !is.null(a$flag)) {
        out <- c(out, paste0("--", a$flag), branch)
      } else {
        out <- c(out, branch)
      }
      next
    }

    if (identical(a$kind, "flag") && !is.null(a$flag)) {
      if (is.null(a$value)) {
        out <- c(out, paste0("--", a$flag))
      } else {
        val <- render_value(a$flag, a$value, quoter = quoter, sql = sql, shell = shell)
        out <- c(out, paste0("--", a$flag), val)
      }
      next
    }

    # positional
    out <- c(out, quoter(a$value))
  }
  out
}

#' @keywords internal
#' @noRd
render_value <- function(flag, value, quoter, sql = "inline", shell = "bash") {
  if (identical(sql, "block") && resolve_arg_name(flag) == "sql" && !startsWith(value, "@")) {
    return(sql_block(value, shell = shell))
  }
  quoter(value)
}

#' @keywords internal
#' @noRd
render_branch <- function(branch, quoter, sql = "inline", shell = "bash", sep = " ! ") {
  steps <- vapply(
    branch$steps,
    function(step) render_step(step, quoter = quoter, sep = sep, sql = sql, shell = shell),
    character(1)
  )
  paste("[", paste(steps, collapse = " ! "), "]")
}

# quoting ---------------------------------------------------------------------

# A token is "bare safe" when it contains no characters that any shell (or the
# GDAL command-line parser) would treat specially.
.safe_bare <- function(x) {
  nzchar(x) && grepl("^[A-Za-z0-9_./:=,*@+-]+$", x)
}

#' @keywords internal
#' @noRd
quote_cmdline <- function(x) {
  if (is.null(x) || is.na(x)) {
    return("")
  }
  if (.safe_bare(x)) {
    return(x)
  }
  # GDAL's own command_line quoting: wrap in double quotes, escape inner `"`.
  paste0("\"", gsub("\"", "\\\\\"", x), "\"")
}

#' @keywords internal
#' @noRd
quote_bash <- function(x) {
  if (is.null(x) || is.na(x)) {
    return("''")
  }
  if (.safe_bare(x)) {
    return(x)
  }
  if (!grepl("'", x, fixed = TRUE)) {
    return(paste0("'", x, "'"))
  }
  # contains single quotes: double-quote and escape shell metacharacters
  escaped <- gsub("([\\\\\"$`])", "\\\\\\1", x, perl = TRUE)
  paste0("\"", escaped, "\"")
}

#' @keywords internal
#' @noRd
quote_ps <- function(x) {
  if (is.null(x) || is.na(x)) {
    return("''")
  }
  if (.safe_bare(x)) {
    return(x)
  }
  has_single <- grepl("'", x, fixed = TRUE)
  has_double <- grepl("\"", x, fixed = TRUE)
  has_expand <- grepl("[$`]", x)

  # single-quoted strings are fully literal in powershell (no expansion); use
  # them when the value has no single quote to escape.
  if (!has_single && (has_double || has_expand)) {
    return(paste0("'", x, "'"))
  }
  if (!has_single) {
    return(paste0("\"", x, "\""))
  }
  if (!has_double && !has_expand) {
    # single quotes only: double-quoted string keeps them literal
    return(paste0("\"", x, "\""))
  }
  # both kinds present: double-quote and backtick-escape powershell specials
  escaped <- gsub("([`\"$])", "`\\1", x, perl = TRUE)
  paste0("\"", escaped, "\"")
}

# sql block (heredoc / here-string) -------------------------------------------

#' @keywords internal
#' @noRd
sql_block <- function(sql, shell = "bash") {
  pretty <- reflow_sql(sql)
  if (shell == "powershell") {
    paste0("@\"\n", pretty, "\n\"@")
  } else {
    paste0("\"$(cat <<'SQL'\n", pretty, "\nSQL\n)\"")
  }
}

#' @keywords internal
#' @noRd
reflow_sql <- function(sql) {
  s <- trimws(sql)
  m <- regmatches(s, regexec("(?is)^\\s*SELECT\\b(.*?)\\bFROM\\b(.*)$", s, perl = TRUE))[[1]]
  if (length(m) < 3) {
    return(s)
  }
  cols <- split_top_commas(m[2])
  cols <- trimws(cols)
  cols <- cols[nzchar(cols)]
  select_block <- paste0("  ", cols, collapse = ",\n")
  rest <- trimws(m[3])
  rest <- gsub("(?i)\\s+(WHERE|GROUP BY|ORDER BY|HAVING|LIMIT)\\b", "\n\\1", rest, perl = TRUE)
  paste0("SELECT\n", select_block, "\nFROM ", rest)
}

# gdalg wrappers --------------------------------------------------------------

#' Convert a pipeline to a GDALG specification list
#'
#' @param x A `gdalviz_pipeline`, or a string/path accepted by [read_gdalg()].
#' @param relative_paths Logical for the
#'   `relative_paths_relative_to_this_file` member. Defaults to `TRUE`.
#' @param gdal_version Optional GDAL version string to record.
#'
#' @return A named list with `type`, `command_line`, and optional members,
#'   suitable for serialization to a `*.gdalg.json` file.
#' @export
as_gdalg <- function(x, relative_paths = TRUE, gdal_version = NULL) {
  out <- list(
    type = "gdal_streamed_alg",
    command_line = render_command_line(x),
    relative_paths_relative_to_this_file = relative_paths
  )
  if (!is.null(gdal_version)) {
    out$gdal_version <- as.character(gdal_version)
  }
  out
}

#' Write a pipeline to a GDALG JSON file
#'
#' @inheritParams as_gdalg
#' @param path Output path (conventionally ending in `.gdalg.json`).
#' @param pretty Whether to pretty-print the JSON. Defaults to `TRUE`.
#'
#' @return The `path`, invisibly.
#' @export
write_gdalg <- function(x, path, relative_paths = TRUE, gdal_version = NULL, pretty = TRUE) {
  spec <- as_gdalg(x, relative_paths = relative_paths, gdal_version = gdal_version)
  json <- jsonlite::toJSON(spec, auto_unbox = TRUE, pretty = pretty)
  writeLines(json, path)
  invisible(path)
}

# reverse: script -> pipeline -------------------------------------------------

#' Parse a shell or powershell script into a pipeline
#'
#' Normalizes a `gdal ... pipeline` invocation written as a shell or powershell
#' script -- joining line continuations, stripping comments, and collapsing
#' here-strings / heredocs into single tokens -- then parses it with
#' [parse_pipeline()].
#'
#' @param text The script text (a single string or a character vector of
#'   lines).
#' @param shell Source shell: `"bash"` (default) or `"powershell"`.
#' @param contract A `gdalviz_contract`.
#'
#' @return A `gdalviz_pipeline`.
#' @export
parse_script <- function(text, shell = c("bash", "powershell"), contract = gdalviz_contract()) {
  shell <- rlang::arg_match(shell)
  if (length(text) > 1) {
    text <- paste(text, collapse = "\n")
  }
  command_line <- normalize_script(text, shell = shell)
  parse_pipeline(command_line, contract = contract)
}

#' Read a shell or powershell script file into a pipeline
#'
#' @param path Path to a `.sh` / `.ps1` script.
#' @inheritParams parse_script
#'
#' @return A `gdalviz_pipeline`.
#' @export
read_script <- function(path, shell = NULL, contract = gdalviz_contract()) {
  shell <- shell %||% if (grepl("\\.ps1$", path, ignore.case = TRUE)) "powershell" else "bash"
  text <- readLines(path, warn = FALSE)
  parse_script(text, shell = shell, contract = contract)
}

#' @keywords internal
#' @noRd
normalize_script <- function(text, shell = "bash", require_prefix = TRUE) {
  # powershell native-command quoting: `\"` passes a literal quote through to
  # gdal, so it maps to a plain quote for the pipeline tokenizer. this runs
  # before heredoc collapse, which emits its own (intentional) \" escapes.
  if (shell == "powershell") {
    text <- gsub("\\\\\"", "\"", text)
  }

  # 1. collapse here-strings / heredocs into single double-quoted tokens
  text <- collapse_heredocs(text, shell = shell)

  lines <- strsplit(text, "\n", fixed = TRUE)[[1]]

  # 2. drop comment-only lines and blank lines
  lines <- lines[!grepl("^\\s*#", lines)]

  # 3. join continuation lines (trailing `\` for bash, trailing backtick for ps)
  cont <- if (shell == "powershell") "`" else "\\"
  joined <- character(0)
  acc <- ""
  for (ln in lines) {
    trimmed <- sub("[ \t]+$", "", ln)
    if (endsWith(trimmed, cont)) {
      acc <- paste0(acc, substr(trimmed, 1, nchar(trimmed) - 1), " ")
    } else {
      acc <- paste0(acc, trimmed)
      joined <- c(joined, acc)
      acc <- ""
    }
  }
  if (nzchar(acc)) {
    joined <- c(joined, acc)
  }

  # 4. keep the segment starting at the gdal pipeline invocation
  whole <- paste(joined, collapse = " ")
  m <- regexpr("gdal\\s+(raster|vector)?\\s*pipeline.*$", whole, perl = TRUE, ignore.case = TRUE)
  if (m == -1) {
    if (!isTRUE(require_prefix)) {
      return(trimws(gsub("\\s+", " ", whole)))
    }
    cli::cli_abort(c(
      "Could not find a {.code gdal ... pipeline} invocation in the script.",
      "i" = "Provide a script that contains a {.code gdal vector pipeline} or {.code gdal raster pipeline} command."
    ))
  }
  trimws(regmatches(whole, m))
}

#' @keywords internal
#' @noRd
collapse_heredocs <- function(text, shell = "bash") {
  if (shell == "powershell") {
    # @"\n...\n"@  -> single double-quoted, whitespace-collapsed token
    repl <- function(match) {
      inner <- sub("(?s)^@\"\\s*\\n", "", match, perl = TRUE)
      inner <- sub("(?s)\\n\"@$", "", inner, perl = TRUE)
      inner <- gsub("\\s+", " ", inner, perl = TRUE)
      paste0("\"", gsub("\"", "\\\\\"", trimws(inner)), "\"")
    }
    gsubfn_like(text, "(?s)@\"\\s*\\n.*?\\n\"@", repl)
  } else {
    # bash: "$(cat <<'TAG'\n...\nTAG\n)"  or  <<'TAG' ... TAG
    repl <- function(match) {
      inner <- sub("(?s)^.*?<<-?['\"]?[A-Za-z_][A-Za-z0-9_]*['\"]?\\s*\\n", "", match, perl = TRUE)
      inner <- sub("(?s)\\n[A-Za-z_][A-Za-z0-9_]*\\s*\\)?\"?$", "", inner, perl = TRUE)
      inner <- gsub("\\s+", " ", inner, perl = TRUE)
      paste0("\"", gsub("\"", "\\\\\"", trimws(inner)), "\"")
    }
    gsubfn_like(
      text,
      "(?s)\"\\$\\(cat\\s+<<-?['\"]?[A-Za-z_][A-Za-z0-9_]*['\"]?\\s*\\n.*?\\n[A-Za-z_][A-Za-z0-9_]*\\s*\\)\"",
      repl
    )
  }
}

# minimal gsub-with-function (avoids a hard gsubfn dependency)
#' @keywords internal
#' @noRd
gsubfn_like <- function(x, pattern, fn) {
  m <- gregexpr(pattern, x, perl = TRUE)[[1]]
  if (length(m) == 1 && m == -1) {
    return(x)
  }
  lens <- attr(m, "match.length")
  out <- ""
  last <- 1L
  for (i in seq_along(m)) {
    start <- m[i]
    stop <- start + lens[i] - 1L
    out <- paste0(out, substr(x, last, start - 1L), fn(substr(x, start, stop)))
    last <- stop + 1L
  }
  paste0(out, substr(x, last, nchar(x)))
}

# helpers ---------------------------------------------------------------------

#' @keywords internal
#' @noRd
as_pipeline <- function(x, contract = gdalviz_contract()) {
  if (inherits(x, "gdalviz_pipeline")) {
    return(x)
  }
  if (is.character(x) && length(x) == 1) {
    return(read_gdalg(x, contract = contract))
  }
  cli::cli_abort("{.arg x} must be a {.cls gdalviz_pipeline}, a string, or a path.")
}

#' @keywords internal
#' @noRd
chunk_vec <- function(x, size) {
  if (length(x) == 0) {
    return(list())
  }
  size <- max(1L, as.integer(size))
  split(x, ceiling(seq_along(x) / size))
}

# print method ----------------------------------------------------------------

#' @export
print.gdalviz_pipeline <- function(x, ...) {
  type <- x$pipeline_type %||% "vector"
  cli::cli_rule(left = "{.cls gdalviz_pipeline}", right = "gdal {type} pipeline")
  n <- length(x$steps)
  if (length(x$pipeline_options) > 0) {
    opts <- render_args(x$pipeline_options, quoter = quote_cmdline)
    cli::cli_text("{.field global}: {.code {paste(opts, collapse = ' ')}}")
  }
  cli::cli_text("{n} step{?s}:")
  cli::cli_ol()
  for (step in x$steps) {
    args <- render_args(step$args, quoter = quote_cmdline)
    if (length(args) == 0) {
      cli::cli_li("{.strong {step$command}}")
    } else {
      cli::cli_li("{.strong {step$command}} {.code {paste(args, collapse = ' ')}}")
    }
  }
  cli::cli_end()
  invisible(x)
}
