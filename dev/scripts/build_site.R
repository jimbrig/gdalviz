
#  ------------------------------------------------------------------------
#
# Title : Build the pkgdown site locally
#    By : Jimmy Briggs
#  Date : 2026-07-11
#
#  ------------------------------------------------------------------------

# workaround for a quarto-on-windows bug: pkgdown renders quarto articles
# with `--output-dir <TEMP>`, and quarto mangles cross-drive absolute paths
# (package on D:, temp on C: -> "D:\...\vignettes\C:\Users\..." os error 123).
# pointing TEMP at a same-drive directory for the build avoids it. linux ci
# runners are unaffected.

build_site <- function(...) {
  tmp <- file.path(normalizePath("."), ".tmp")
  dir.create(tmp, showWarnings = FALSE)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  withr::with_envvar(
    c(TEMP = tmp, TMP = tmp, TMPDIR = tmp),
    pkgdown::build_site(preview = FALSE, ...)
  )
}

if (identical(environment(), globalenv()) && !interactive()) {
  build_site()
}
