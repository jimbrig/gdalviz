#' Parse a GDAL vector pipeline into a structured object
#'
#' Accepts a raw pipeline command line (with or without the
#' `gdal [vector|raster] pipeline` prefix) and parses it into an ordered list of
#' steps, resolving nested pipelines (`[ ... ]`) and associating arguments with
#' their values using the GDAL contract to disambiguate boolean flags.
#'
#' @param x A pipeline command-line string.
#' @param contract A `gdalviz_contract` used to disambiguate argument types.
#'
#' @return A `gdalviz_pipeline` object.
#' @export
parse_pipeline <- function(x, contract = gdalviz_contract()) {
  if (!rlang::is_string(x)) {
    cli::cli_abort("{.arg x} must be a single pipeline string, not {.obj_type_friendly {x}}.")
  }

  prefix <- detect_pipeline_prefix(x)
  body <- sub(prefix$pattern, "", x)

  tokens <- tokenize_pipeline(body)
  nested <- nest_tokens(tokens)

  chunks <- split_top_level(nested, "!")
  chunks <- Filter(function(ch) length(ch) > 0, chunks)

  pipeline_options <- list()
  if (length(chunks) > 0 && !is_step_command(chunk_command(chunks[[1]]), contract)) {
    pipeline_options <- parse_step_args("", chunks[[1]], contract)$args
    chunks <- chunks[-1]
  }

  steps <- lapply(chunks, parse_step, contract = contract)

  structure(
    list(
      steps = steps,
      pipeline_type = prefix$type,
      pipeline_options = pipeline_options,
      command_line = x
    ),
    class = "gdalviz_pipeline"
  )
}

detect_pipeline_prefix <- function(x) {
  m <- regmatches(x, regexec("^\\s*gdal\\s+(raster|vector)?\\s*pipeline", x, ignore.case = TRUE))[[1]]
  if (length(m) == 0) {
    return(list(pattern = "^", type = NA_character_))
  }
  list(
    pattern = "^\\s*gdal\\s+(raster|vector)?\\s*pipeline\\s*",
    type = if (nzchar(m[2])) tolower(m[2]) else NA_character_
  )
}

# --- tokenizer ---------------------------------------------------------------

tokenize_pipeline <- function(x) {
  chars <- strsplit(x, "", fixed = TRUE)[[1]]
  tokens <- character(0)
  buf <- character(0)
  i <- 1L
  n <- length(chars)
  in_quote <- NULL

  flush <- function() {
    if (length(buf) > 0) {
      tokens[[length(tokens) + 1L]] <<- paste0(buf, collapse = "")
      buf <<- character(0)
    }
  }

  while (i <= n) {
    ch <- chars[[i]]
    if (!is.null(in_quote)) {
      if (ch == "\\" && i < n) {
        nxt <- chars[[i + 1L]]
        if (nxt %in% c("\"", "'", "\\")) {
          buf[[length(buf) + 1L]] <- nxt
          i <- i + 2L
          next
        }
        buf[[length(buf) + 1L]] <- ch
        i <- i + 1L
        next
      }
      if (ch == in_quote) {
        in_quote <- NULL
        i <- i + 1L
        next
      }
      buf[[length(buf) + 1L]] <- ch
      i <- i + 1L
      next
    }

    if (ch %in% c("\"", "'")) {
      in_quote <- ch
      i <- i + 1L
      next
    }
    if (ch %in% c(" ", "\t", "\n", "\r")) {
      flush()
      i <- i + 1L
      next
    }
    if (ch %in% c("[", "]", "!")) {
      flush()
      tokens[[length(tokens) + 1L]] <- ch
      i <- i + 1L
      next
    }
    buf[[length(buf) + 1L]] <- ch
    i <- i + 1L
  }
  flush()
  tokens
}

# group bracketed tokens into nested lists
nest_tokens <- function(tokens) {
  pos <- 1L
  build <- function() {
    out <- list()
    while (pos <= length(tokens)) {
      tok <- tokens[[pos]]
      if (identical(tok, "[")) {
        pos <<- pos + 1L
        out[[length(out) + 1L]] <- structure(build(), class = "gdalviz_nested")
      } else if (identical(tok, "]")) {
        pos <<- pos + 1L
        return(out)
      } else {
        out[[length(out) + 1L]] <- tok
        pos <<- pos + 1L
      }
    }
    out
  }
  build()
}

# split a nested token list on a separator token, at this level only
split_top_level <- function(items, sep) {
  chunks <- list()
  current <- list()
  for (it in items) {
    if (is.character(it) && length(it) == 1L && identical(it, sep)) {
      chunks[[length(chunks) + 1L]] <- current
      current <- list()
    } else {
      current[[length(current) + 1L]] <- it
    }
  }
  chunks[[length(chunks) + 1L]] <- current
  chunks
}

# --- step parsing ------------------------------------------------------------

chunk_command <- function(chunk) {
  if (length(chunk) == 0) {
    return(NA_character_)
  }
  first <- chunk[[1]]
  if (is.character(first)) first else NA_character_
}

is_step_command <- function(command, contract) {
  !is.na(command) && !startsWith(command, "-") && !is.null(contract_step(command, contract))
}

parse_step <- function(chunk, contract) {
  command <- chunk_command(chunk)
  rest <- if (length(chunk) > 1) chunk[-1] else list()
  parsed <- parse_step_args(command, rest, contract)
  structure(
    list(command = command, args = parsed$args),
    class = "gdalviz_step"
  )
}

parse_step_args <- function(command, items, contract) {
  args <- list()
  i <- 1L
  n <- length(items)
  while (i <= n) {
    it <- items[[i]]

    if (inherits(it, "gdalviz_nested")) {
      branch <- parse_nested_branch(it, contract)
      args[[length(args) + 1L]] <- new_arg(kind = "positional", nested = branch)
      i <- i + 1L
      next
    }

    if (is_flag(it)) {
      flag <- it
      if (grepl("=", flag, fixed = TRUE)) {
        parts <- strsplit(sub("^(-+[^=]+)=", "\\1\t", flag), "\t", fixed = TRUE)[[1]]
        args[[length(args) + 1L]] <- new_arg(
          kind = "flag",
          flag = sub("^-+", "", parts[1]),
          value = parts[2]
        )
        i <- i + 1L
        next
      }

      flag_name <- sub("^-+", "", flag)
      nxt <- if (i < n) items[[i + 1L]] else NULL
      is_bool <- arg_is_boolean(command, flag_name, contract)

      # nested pipeline value (e.g. --tee-pipeline [ ... ])
      if (!is.null(nxt) && inherits(nxt, "gdalviz_nested")) {
        branch <- parse_nested_branch(nxt, contract)
        args[[length(args) + 1L]] <- new_arg(kind = "flag", flag = flag_name, nested = branch)
        i <- i + 2L
        next
      }

      takes_value <- if (is.na(is_bool)) {
        !is.null(nxt) && is.character(nxt) && !is_flag(nxt)
      } else {
        !is_bool
      }

      if (takes_value && !is.null(nxt) && is.character(nxt) && !is_flag(nxt)) {
        args[[length(args) + 1L]] <- new_arg(kind = "flag", flag = flag_name, value = nxt)
        i <- i + 2L
      } else {
        args[[length(args) + 1L]] <- new_arg(kind = "flag", flag = flag_name, value = NULL)
        i <- i + 1L
      }
      next
    }

    # bare positional value
    args[[length(args) + 1L]] <- new_arg(kind = "positional", value = it)
    i <- i + 1L
  }
  list(args = args)
}

parse_nested_branch <- function(nested, contract) {
  chunks <- split_top_level(unclass(nested), "!")
  chunks <- Filter(function(ch) length(ch) > 0, chunks)
  steps <- lapply(chunks, parse_step, contract = contract)
  structure(list(steps = steps), class = "gdalviz_pipeline")
}

is_flag <- function(x) {
  is.character(x) && length(x) == 1L && grepl("^-{1,2}[A-Za-z]", x)
}

new_arg <- function(kind, flag = NULL, value = NULL, nested = NULL) {
  list(kind = kind, flag = flag, value = value, nested = nested)
}
