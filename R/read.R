#' Read a GDAL pipeline from a GDALG file or raw string
#'
#' Accepts a path to a GDALG JSON file (`{"type":"gdal_streamed_alg",
#' "command_line": "..."}`), a path to a raw pipeline text file, or a raw
#' pipeline string, and returns a parsed `gdalviz_pipeline`.
#'
#' @param x A path to a GDALG/JSON/text file, or a raw pipeline string.
#' @param contract A `gdalviz_contract`.
#'
#' @return A `gdalviz_pipeline`.
#' @export
read_gdalg <- function(x, contract = gdalviz_contract()) {
  if (!rlang::is_string(x)) {
    cli::cli_abort("{.arg x} must be a single string (a path or a pipeline).")
  }

  command_line <- if (is_existing_file(x)) {
    read_gdalg_file(x)
  } else {
    x
  }

  # multiline shell scripts (trailing ` or \ continuations) are normalized
  # before parsing so pasted powershell/bash invocations just work
  shell <- detect_script_shell(command_line)
  if (!is.null(shell)) {
    command_line <- normalize_script(command_line, shell = shell, require_prefix = FALSE)
  }

  parse_pipeline(command_line, contract = contract)
}

detect_script_shell <- function(x) {
  if (!grepl("\n", x, fixed = TRUE)) {
    return(NULL)
  }
  if (grepl("`[ \t]*\r?\n", x)) {
    return("powershell")
  }
  if (grepl("\\\\[ \t]*\r?\n", x)) {
    return("bash")
  }
  NULL
}

is_existing_file <- function(x) {
  # avoid treating a long pipeline string as a path
  !grepl("[\n!]", x) && nchar(x) < 1000 && file.exists(x)
}

read_gdalg_file <- function(path) {
  txt <- paste(readLines(path, warn = FALSE), collapse = "\n")
  trimmed <- trimws(txt)
  if (startsWith(trimmed, "{")) {
    obj <- jsonlite::fromJSON(trimmed, simplifyVector = FALSE)
    cl <- obj[["command_line"]]
    if (is.null(cl)) {
      cli::cli_abort(c(
        "{.path {path}} is JSON but has no {.field command_line} member.",
        "i" = "Expected a GDALG file produced by {.code gdal vector pipeline ! ... ! write out.gdalg.json}."
      ))
    }
    return(cl)
  }
  trimmed
}
