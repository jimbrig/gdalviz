#  ------------------------------------------------------------------------
#
# Title : Package Utilities
#    By : Jimmy Briggs
#  Date : 2026-05-31
#
#  ------------------------------------------------------------------------

# meta ------------------------------------------------------------------------------------------------------------

#' @keywords internal
#' @noRd
pkg_name <- function() {
  "gdalviz"
}

#' @keywords internal
#' @noRd
#' @importFrom utils packageVersion
pkg_version <- function() {
  # TODO: consider incorporating a local({}) for this to avoid repeated calls that may be unecessary
  as.character(utils::packageVersion(pkg_name()))
}

# user agent ------------------------------------------------------------------------------------------------------

#' @keywords internal
#' @noRd
pkg_user_agent <- function() {
  paste0(pkg_name(), "/", pkg_version())
}

# system file -----------------------------------------------------------------------------------------------------

#' @keywords internal
#' @noRd
pkg_sys <- function(...) {
  system.file(..., package = pkg_name())
}

#' @keywords internal
#' @noRd
pkg_sys_extdata <- function(...) {
  pkg_sys("extdata", ...)
}

#' @keywords internal
#' @noRd
pkg_sys_schemas <- function(...) {
  pkg_sys("schemas", ...)
}

# startup message -------------------------------------------------------------------------------------------------

#' @keywords internal
#' @noRd
#' @importFrom crayon green cyan yellow bold italic
pkg_startup_msg <- function() {
  msg_title <- paste0(crayon::bold(crayon::cyan(pkg_name(), paste0("v", pkg_version()))))
  msg_desc <- crayon::italic(crayon::cyan("Modern Package for GDAL Pipeline Visualization"))
  paste0(msg_title, " - ", msg_desc)
}
