
#  ------------------------------------------------------------------------
#
# Title : Build the srcjs widget bundle
#    By : Jimmy Briggs
#  Date : 2026-07-11
#
#  ------------------------------------------------------------------------

# builds srcjs/ -> inst/htmlwidgets/pipeline_flow.js via bun + vite.
# run from the package root. use `watch = TRUE` while iterating on the
# typescript; each save rebuilds in ~300ms and re-printing the widget in R
# picks up the fresh bundle (no load_all needed).

build_js <- function(watch = FALSE, typecheck = TRUE) {
  bun <- Sys.which("bun")
  if (!nzchar(bun)) {
    cli::cli_abort("Could not find {.code bun} on the PATH (see {.path srcjs/README.md}).")
  }
  if (isTRUE(typecheck)) {
    processx::run(bun, c("run", "typecheck"), wd = "srcjs", echo = TRUE)
  }
  if (isTRUE(watch)) {
    cli::cli_alert_info("Watching srcjs/ (ctrl+c to stop) ...")
    processx::run(bun, c("run", "watch"), wd = "srcjs", echo = TRUE)
  } else {
    processx::run(bun, c("run", "build"), wd = "srcjs", echo = TRUE)
    cli::cli_alert_success("Bundle written to {.path inst/htmlwidgets/pipeline_flow.js}")
  }
  invisible(TRUE)
}

if (identical(environment(), globalenv()) && !interactive()) {
  build_js()
}
