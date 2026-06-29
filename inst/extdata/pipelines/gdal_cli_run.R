require(gdalraster)
require(processx)


# setup GDAL ------------------------------------------------------------------------------------------------------

gdal_cmd <- normalizePath(Sys.which("gdal"), winslash = "/")
processx::run(gdal_cmd, c("--version"))

gdal_cli_run <- function(args, label = NULL, log_file = "gdal.log", verbose = TRUE, cmd = gdal_cmd) {
  cmd_str <- paste0("gdal ", paste(args, collapse = " "))
  label <- label %||% paste0(substr(cmd_str, start = 1L, stop = 10L), " ... ", substr(cmd_str, start = nchar(cmd_str) - 10L, stop = nchar(cmd_str)))
  if (verbose) {
    cli::cli_alert_info("Running {.field {label}}")
  }
  started_at <- Sys.time()
  res <- processx::run(
    command = cmd,
    args = args,
    echo_cmd = verbose,
    error_on_status = FALSE,
    spinner = TRUE
  )
  elapsed <- as.numeric(difftime(Sys.time(), started_at, units = "secs"))
  if (res$status != 0L) {
    cli::cli_abort(
      c(
        "GDAL Failed: {label}",
        "x" = "Exit Status: {.field {res$status}}",
        "i" = "stdout: {.field {res$stdout}}",
        "i" = "stderr: {.field {res$stderr}}",
        "i" = "Log File: {.path {log_file}}"
      )
    )
  }
  cli::cli_alert_success("Finished {.field {label}} in {round(elapsed, 2)} seconds")
  res
}
