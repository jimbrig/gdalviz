
#  ------------------------------------------------------------------------
#
# Title : Package srcjs
#    By : Jimmy Briggs
#  Date : 2026-07-11
#
#  ------------------------------------------------------------------------

usethis::use_directory("srcjs", TRUE)

bun_cmd <- Sys.which("bun") |> normalizePath(winslash = "/")

processx::run(
  command = bun_cmd,
  args = c(
    "init", "-y", "srcjs"
  ),
  echo_cmd = TRUE,
  spinner = TRUE
)

fs::dir_create("srcjs/src")
