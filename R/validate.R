#' Lint a GDAL pipeline against the GDAL contract
#'
#' Produces a structured issue table for unknown steps, unknown arguments,
#' missing required arguments, and value/type mismatches.
#'
#' @param x A `gdalviz_pipeline`, or a string/path accepted by [read_gdalg()].
#' @param contract A `gdalviz_contract`.
#'
#' @return A tibble with one row per lint issue.
#' @export
lint_pipeline <- function(x, contract = gdalviz_contract()) {
  pipeline <- as_pipeline(x, contract = contract)
  issues <- list()

  for (i in seq_along(pipeline$steps)) {
    step <- pipeline$steps[[i]]
    command <- step$command %||% NA_character_
    defn <- contract_step(command, contract)

    if (is.null(defn)) {
      issues[[length(issues) + 1L]] <- new_issue(
        step_index = i,
        command = command,
        level = "error",
        code = "unknown_step",
        message = paste0("Unknown GDAL pipeline step: ", squote(command))
      )
      next
    }

    provided <- collect_provided_flags(step)

    required <- names(defn$args)[vapply(defn$args, function(arg) isTRUE(arg$required), logical(1))]
    missing_required <- setdiff(required, provided)
    if (length(missing_required) > 0) {
      issues[[length(issues) + 1L]] <- new_issue(
        step_index = i,
        command = command,
        level = "error",
        code = "missing_required_args",
        message = paste0("Missing required argument(s): ", paste(sort(missing_required), collapse = ", "))
      )
    }

    # mutually exclusive argument groups (from the contract's
    # mutual_exclusion_group metadata)
    groups <- list()
    for (canonical in provided) {
      spec <- defn$args[[canonical]]
      if (is.null(spec) || is.na(spec$mutex_group %||% NA_character_)) {
        next
      }
      groups[[spec$mutex_group]] <- c(groups[[spec$mutex_group]], canonical)
    }
    for (group in names(groups)) {
      members <- unique(groups[[group]])
      if (length(members) > 1) {
        issues[[length(issues) + 1L]] <- new_issue(
          step_index = i,
          command = command,
          level = "error",
          code = "mutually_exclusive_args",
          message = paste0(
            "Arguments --", paste(sort(members), collapse = ", --"),
            " are mutually exclusive (group '", group, "')."
          )
        )
      }
    }

    for (arg in step$args) {
      if (!identical(arg$kind, "flag") || is.null(arg$flag)) {
        next
      }

      flag <- arg$flag
      canonical <- resolve_arg_name(flag)
      spec <- defn$args[[canonical]] %||% defn$args[[flag]]

      if (is.null(spec)) {
        issues[[length(issues) + 1L]] <- new_issue(
          step_index = i,
          command = command,
          level = "warning",
          code = "unknown_argument",
          message = paste0("Unknown argument --", flag, " for step ", squote(command))
        )
        next
      }

      if (identical(spec$type, "boolean") && !is.null(arg$value)) {
        issues[[length(issues) + 1L]] <- new_issue(
          step_index = i,
          command = command,
          level = "error",
          code = "boolean_argument_with_value",
          message = paste0("Boolean argument --", flag, " should not take a value.")
        )
      }

      if (!identical(spec$type, "boolean") && is.null(arg$value) && is.null(arg$nested)) {
        issues[[length(issues) + 1L]] <- new_issue(
          step_index = i,
          command = command,
          level = "error",
          code = "missing_argument_value",
          message = paste0("Argument --", flag, " is missing a value.")
        )
      }

      if (!is.null(arg$value) && length(spec$choices) > 0 && !arg$value %in% spec$choices) {
        issues[[length(issues) + 1L]] <- new_issue(
          step_index = i,
          command = command,
          level = "warning",
          code = "invalid_choice",
          message = paste0(
            "Argument --", flag, " has invalid value ", squote(arg$value),
            ". Allowed: ", paste(spec$choices, collapse = ", ")
          )
        )
      }
    }
  }

  if (length(issues) == 0) {
    return(tibble::tibble(
      step_index = integer(0),
      command = character(0),
      level = character(0),
      code = character(0),
      message = character(0)
    ))
  }

  tibble::tibble(
    step_index = vapply(issues, `[[`, integer(1), "step_index"),
    command = vapply(issues, `[[`, character(1), "command"),
    level = vapply(issues, `[[`, character(1), "level"),
    code = vapply(issues, `[[`, character(1), "code"),
    message = vapply(issues, `[[`, character(1), "message")
  )
}

#' Validate a GDAL pipeline against the GDAL contract
#'
#' Validates a parsed pipeline and returns a structured validation object. By
#' default it errors when validation fails.
#'
#' @param x A `gdalviz_pipeline`, or a string/path accepted by [read_gdalg()].
#' @param contract A `gdalviz_contract`.
#' @param strict If `TRUE` (default), abort when validation contains errors.
#'
#' @return A `gdalviz_validation` object with `valid` and `issues`.
#' @export
validate_pipeline <- function(x, contract = gdalviz_contract(), strict = TRUE) {
  pipeline <- as_pipeline(x, contract = contract)
  issues <- lint_pipeline(pipeline, contract = contract)

  errors <- issues[issues$level == "error", , drop = FALSE]
  out <- structure(
    list(
      valid = nrow(errors) == 0L,
      issues = issues
    ),
    class = "gdalviz_validation"
  )

  if (isTRUE(strict) && !out$valid) {
    cli::cli_abort(c(
      "Pipeline validation failed.",
      "x" = "{nrow(errors)} error{?s} found.",
      "i" = "Inspect {.code lint_pipeline(...)} for full issue details."
    ))
  }

  out
}

#' @export
print.gdalviz_validation <- function(x, ...) {
  status <- if (isTRUE(x$valid)) "valid" else "invalid"
  cli::cli_rule(left = "{.cls gdalviz_validation}", right = status)
  if (nrow(x$issues) == 0) {
    cli::cli_alert_success("No lint issues found.")
    return(invisible(x))
  }

  cli::cli_text("{nrow(x$issues)} issue{?s}:")
  cli::cli_ol()
  for (i in seq_len(nrow(x$issues))) {
    row <- x$issues[i, , drop = FALSE]
    cli::cli_li(
      "[{toupper(row$level)}] step {row$step_index} ({row$command}) - {row$message}"
    )
  }
  cli::cli_end()
  invisible(x)
}

collect_provided_flags <- function(step) {
  flags <- character(0)
  for (arg in step$args) {
    if (identical(arg$kind, "flag") && !is.null(arg$flag)) {
      flags <- c(flags, resolve_arg_name(arg$flag))
    }
  }
  unique(flags)
}

new_issue <- function(step_index, command, level, code, message) {
  list(
    step_index = as.integer(step_index),
    command = command %||% NA_character_,
    level = level,
    code = code,
    message = message
  )
}
