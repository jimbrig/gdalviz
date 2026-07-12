#' GDAL vector pipeline contract registry
#'
#' Loads the bundled `gdal vector pipeline --json-usage` snapshot and turns it
#' into a lookup of pipeline steps and their arguments. This is the single
#' source of truth for which steps and arguments are valid, their types,
#' choices, and documentation URLs.
#'
#' @param path Optional path to a `--json-usage` JSON snapshot. Defaults to the
#'   snapshot bundled with the package.
#' @param refresh If `TRUE`, bypass the cache and reload.
#'
#' @return A `gdalviz_contract` object: a named list of step definitions.
#' @export
gdalviz_contract <- function(path = NULL, refresh = FALSE) {
  if (is.null(path) && !refresh && !is.null(the$contract)) {
    return(the$contract)
  }
  path <- path %||% contract_snapshot_path()
  if (!file.exists(path)) {
    cli::cli_abort(c(
      "Could not find the GDAL pipeline contract snapshot.",
      "x" = "No file at {.path {path}}.",
      "i" = "Regenerate it with {.code gdalviz_refresh_contract()}."
    ))
  }

  raw <- jsonlite::fromJSON(path, simplifyVector = FALSE)
  algos <- raw[["pipeline_algorithms"]] %||% list()

  steps <- lapply(algos, parse_contract_step)
  names(steps) <- vapply(steps, function(x) x$name, character(1))

  contract <- structure(
    list(
      steps = steps,
      pipeline_args = parse_pipeline_args(raw),
      gdal_version = raw[["gdal_version"]],
      description = raw[["description"]]
    ),
    class = "gdalviz_contract"
  )

  if (is.null(path) || identical(path, contract_snapshot_path())) {
    the$contract <- contract
  }
  contract
}

parse_contract_arg <- function(arg) {
  list(
    name = arg[["name"]],
    type = arg[["type"]] %||% "string",
    required = isTRUE(arg[["required"]]),
    choices = unlist(arg[["choices"]]) %||% character(0),
    description = arg[["description"]] %||% "",
    metavar = arg[["metavar"]] %||% NULL,
    default = arg[["default"]] %||% NULL
  )
}

# pipeline-level arguments: the algorithm's own input_arguments plus the
# common gdal cli arguments (--config/--progress/...) that json-usage omits
parse_pipeline_args <- function(raw) {
  args <- lapply(raw[["input_arguments"]] %||% list(), parse_contract_arg)
  names(args) <- vapply(args, function(x) x$name, character(1))

  common <- list(
    config = list(
      name = "config",
      type = "string_list",
      required = FALSE,
      choices = character(0),
      description = "Configuration option (<KEY>=<VALUE>)",
      metavar = "<KEY>=<VALUE>",
      default = NULL
    ),
    progress = list(
      name = "progress",
      type = "boolean",
      required = FALSE,
      choices = character(0),
      description = "Display progress bar",
      metavar = NULL,
      default = NULL
    )
  )
  for (nm in names(common)) {
    if (is.null(args[[nm]])) {
      args[[nm]] <- common[[nm]]
    }
  }
  args
}

parse_contract_step <- function(algo) {
  args <- lapply(algo[["input_arguments"]], parse_contract_arg)
  names(args) <- vapply(args, function(x) x$name, character(1))

  boolean_args <- names(args)[vapply(args, function(x) identical(x$type, "boolean"), logical(1))]

  list(
    name = algo[["name"]],
    description = algo[["description"]] %||% "",
    url = algo[["url"]] %||% NA_character_,
    short_url = algo[["short_url"]] %||% NA_character_,
    args = args,
    arg_names = names(args),
    boolean_args = boolean_args
  )
}

contract_snapshot_path <- function() {
  installed <- system.file("extdata", "gdal_vector_pipeline_usage.json", package = "gdalviz")
  if (nzchar(installed)) {
    return(installed)
  }
  # development fallback (package not installed)
  file.path("inst", "extdata", "gdal_vector_pipeline_usage.json")
}

#' Regenerate the GDAL pipeline contract snapshot from the installed GDAL
#'
#' Runs `gdal <type> pipeline --json-usage` against the GDAL CLI on the user's
#' `PATH` (or an explicit binary) and writes the result as a new contract
#' snapshot, so the contract registry matches the locally installed GDAL
#' version instead of the snapshot bundled with the package.
#'
#' @param path Destination for the snapshot JSON. Defaults to the bundled
#'   snapshot location, replacing it for the current installation.
#' @param type Pipeline type (`"vector"` or `"raster"`).
#' @param gdal Path to the `gdal` binary. Defaults to `gdal` on the `PATH`.
#'
#' @return The refreshed `gdalviz_contract`, invisibly.
#' @export
gdalviz_refresh_contract <- function(
  path = NULL,
  type = c("vector", "raster"),
  gdal = NULL
) {
  rlang::check_installed("processx")
  type <- rlang::arg_match(type)

  gdal <- gdal %||% Sys.which("gdal")
  if (!nzchar(gdal)) {
    cli::cli_abort(c(
      "Could not find the {.code gdal} CLI.",
      "i" = "Install GDAL >= 3.11 or pass {.arg gdal} explicitly."
    ))
  }

  res <- processx::run(gdal, c(type, "pipeline", "--json-usage"), error_on_status = TRUE)
  path <- path %||% contract_snapshot_path()
  writeLines(res$stdout, path)
  cli::cli_alert_success("Wrote contract snapshot to {.path {path}}.")

  the$contract <- NULL
  invisible(gdalviz_contract(refresh = TRUE))
}

#' Look up a single pipeline step in the contract
#'
#' @param command Step command name (e.g. `"reproject"`).
#' @param contract A `gdalviz_contract`. Defaults to the bundled contract.
#'
#' @return The step definition list, or `NULL` if the command is unknown.
#' @export
contract_step <- function(command, contract = gdalviz_contract()) {
  contract$steps[[command]]
}

#' Argument aliases not present in the json-usage contract
#'
#' The `--json-usage` output reports only canonical argument names. The CLI also
#' accepts short flags and historical synonyms. This maps an alias to its
#' canonical name so the parser can resolve argument metadata.
#' @noRd
arg_alias_map <- function() {
  list(
    i = "input",
    l = "input-layer",
    layer = "input-layer",
    o = "output",
    f = "output-format",
    of = "output-format",
    format = "output-format",
    s = "input-crs",
    d = "output-crs",
    "src-crs" = "input-crs",
    "dst-crs" = "output-crs",
    "if" = "input-format",
    oo = "open-option",
    co = "creation-option",
    lco = "layer-creation-option",
    "output-oo" = "output-open-option"
  )
}

#' Determine whether a step argument is a boolean (value-less) flag
#'
#' Uses the contract when the command is known, falling back to a heuristic for
#' unknown commands or arguments.
#' @noRd
arg_is_boolean <- function(command, flag, contract = gdalviz_contract()) {
  canonical <- resolve_arg_name(flag)
  step <- contract_step(command, contract)
  if (!is.null(step)) {
    arg <- step$args[[canonical]] %||% step$args[[flag]]
    if (!is.null(arg)) {
      return(identical(arg$type, "boolean"))
    }
  }
  NA
}

#' Determine whether a pipeline-level (global) argument is a boolean flag
#' @noRd
pipeline_arg_is_boolean <- function(flag, contract = gdalviz_contract()) {
  flag <- sub("^-+", "", flag)
  arg <- contract$pipeline_args[[flag]]
  if (!is.null(arg)) {
    return(identical(arg$type, "boolean"))
  }
  NA
}

resolve_arg_name <- function(flag) {
  flag <- sub("^-+", "", flag)
  aliases <- arg_alias_map()
  if (!is.null(aliases[[flag]])) {
    return(aliases[[flag]])
  }
  flag
}
