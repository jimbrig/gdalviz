
#  ------------------------------------------------------------------------
#
# Title : Pacakge Initialization Script
#    By : Jimmy Briggs
#  Date : 2026-05-31
#
#  ------------------------------------------------------------------------

# libraries ---------------------------------------------------------------

require(devtools)
require(usethis)
require(roxygen2)
require(testthat)
require(rmarkdown)
require(knitr)
require(attachment)
require(pak)
require(purrr)
require(lifecycle)
require(rlang)
require(cli)
require(pkgload)
require(pkgbuild)
require(rcmdcheck)
require(fs)
require(targets)
require(tarchetypes)
require(withr)
require(this.path)

# create ----------------------------------------------------------------------------------------------------------

if (FALSE) {
  usethis::create_package("gdalviz")
  usethis::use_namespace()
  usethis::use_roxygen_md()
  usethis::use_readme_md()
  usethis::use_package_doc()
}

# dev -------------------------------------------------------------------------------------------------------------

if (FALSE) {
  usethis::use_directory("dev", ignore = TRUE)
  fs::file_create("dev/README.md")
  c("R", "scripts", "check", "docs", "scratch") |>
    purrr::walk(~ fs::dir_create(file.path("dev", .x), recurse = TRUE))
  attachment::att_amend_desc()
  fs::file_create("AGENTS.md")
  fs::file_create("CHANGELOG.md")
  usethis::use_directory(".cursor", ignore = TRUE)
  fs::file_create(".cursor/mcp.json")
  fs::file_create(".cursor/mcp.env")
  usethis::use_git_ignore(c("mcp.env"), ".cursor")
  usethis::use_air()
  fs::dir_create("man/figures")
  fs::dir_create("man/fragments")
}

# buildignore -----------------------------------------------------------------------------------------------------

if (FALSE) {
  usethis::use_directory(".cursor", ignore = TRUE)
  c(
    "dev",
    "data-raw",
    ".cursor",
    ".github",
    ".vscode",
    ".positai",
    ".claude",
    ".gitattributes",
    ".editorconfig",
    ".cursorignore",
    ".dockerignore",
    ".repomixignore",
    "repomix.config.json",
    "Makefile",
    ".Renviron",
    ".Rprofile",
    ".build",
    "renv",
    "renv.lock",
    "config.yml",
    ".env",
    ".env.example",
    "codemeta.json",
    ".lintr",
    "README.Rmd",
    "Dockerfile",
    "compose.yml",
    "gdalviz.code-workspace",
    "AGENTS.md",
    "CHANGELOG.md",
    "LICENSE.md",
    "cran-comments.md"
  ) |>
    purrr::walk(usethis::use_build_ignore)
}

# git/github ------------------------------------------------------------------------------------------------------

if (FALSE) {
  usethis::use_git()
  usethis::use_github()
}

# inst ------------------------------------------------------------------------------------------------------------

if (FALSE) {
  c("inst/extdata", "inst/config", "inst/schemas") |>
    purrr::walk(fs::dir_create)
}


# R ---------------------------------------------------------------------------------------------------------------

if (FALSE) {

  usethis::use_import_from("rlang", ".data")
  usethis::use_import_from("rlang", ".env")
  usethis::use_import_from("rlang", "%||%")

  usethis::use_r("aaa.R", open = FALSE)
  usethis::use_r("zzz.R", open = FALSE)
  usethis::use_r("utils_pkg.R", open = FALSE)
  usethis::use_r("utils_checks.R", open = FALSE)
  usethis::use_r("utils_predicates.R", open = FALSE)
}


# tests -----------------------------------------------------------------------------------------------------------

if (FALSE) {
  usethis::use_testthat()
  usethis::use_spell_check()
  cat(
    "if (requireNamespace(\"spelling\", quietly = TRUE)) {",
    "  spelling::spell_check_test(",
    "    vignettes = TRUE,",
    "    error = FALSE,",
    "    skip_on_cran = TRUE",
    "  )",
    "}",
    "",
    file = "tests/spelling.R",
    sep = "\n",
    append = FALSE
  )
  spelling::update_wordlist()

  usethis::use_test("gdal_viz")
  usethis::use_test_helper("mocks")
}

# data ------------------------------------------------------------------------------------------------------------

# usethis::use_data_raw("internal")
# usethis::use_data_raw("exported")
#
# fs::dir_create("data-raw/cache")
# usethis::use_git_ignore(c("*", "!.gitignore", "!*.md"), "data-raw/cache")
