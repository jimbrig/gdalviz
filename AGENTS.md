# AGENTS.md

Guidance for AI agents (and humans) working in this repository.

## What this package is

gdalviz parses, validates, and visualizes modern GDAL CLI pipelines
(`gdal vector pipeline ! ...` command lines and GDALG `.gdalg.json`
files). The architecture is a strict one-way flow:

    parse_pipeline() / read_gdalg()   R/parse.R, R/read.R
            -> gdalviz_pipeline
    pipeline_graph()                  R/graph.R (+ R/categories.R)
            -> gdalviz_graph          renderer-agnostic nodes/edges tibbles
    render_reactflow() / render_g6() / render_diagrammer()
            -> htmlwidgets            R/render-*.R + srcjs/ (React Flow)

`R/contract.R` loads the bundled `gdal vector pipeline --json-usage`
snapshot (`inst/extdata/gdal_vector_pipeline_usage.json`) — the single
source of truth for valid steps/arguments, used by both the parser and
[`lint_pipeline()`](http://docs.jimbrig.com/gdalviz/reference/lint_pipeline.md).
`R/render.R` is the inverse of the parser (command lines, shell scripts,
GDALG output).

## Key invariants

- The graph model stays renderer-agnostic. Renderer-specific styling
  lives in the renderers, never in `R/graph.R`.
- The React Flow bundle `inst/htmlwidgets/pipeline_flow.js` is built
  from `srcjs/` and **committed**, so package users never need node/bun.
  After any `srcjs/` change run `bun run build` (in `srcjs/`) and commit
  the bundle.
- The widget payload contract must stay in sync across three places:
  `R/render-reactflow.R` (serialization), `R/graph.R` (node fields), and
  `srcjs/src/types.ts`.
- The contract snapshot is regenerated with
  [`gdalviz_refresh_contract()`](http://docs.jimbrig.com/gdalviz/reference/gdalviz_refresh_contract.md),
  not edited by hand.

## Commands

``` sh
# R (from the package root)
Rscript -e "pkgload::load_all('.'); testthat::test_dir('tests/testthat')"
Rscript -e "roxygen2::roxygenise()"
Rscript -e "rcmdcheck::rcmdcheck(args = '--no-manual')"
Rscript dev/scripts/build_site.R      # pkgdown (windows temp-drive workaround)

# JS/TS (from srcjs/)
bun install
bun run typecheck
bun run build                          # -> inst/htmlwidgets/pipeline_flow.js
bun run watch
```

## Conventions

- R: native pipe `|>` only (never `%>%`); namespace-prefix all non-base
  calls
  ([`cli::cli_abort()`](https://cli.r-lib.org/reference/cli_abort.html),
  [`rlang::arg_match()`](https://rlang.r-lib.org/reference/arg_match.html));
  rlang + cli for conditions/validation; httr2 over httr; testthat
  edition 3.
- Comments: sparse, lowercase, only for non-obvious logic.
- Docs: roxygen2 with markdown; vignettes/articles are **Quarto**
  (`.qmd`), built with `VignetteBuilder: quarto`. Heavy interactive
  examples belong in `vignettes/articles/` (pkgdown-only, not shipped in
  the package).
- Commits: conventional style with scope, e.g. `feat(pipeline): ...`,
  `docs(cicd): ...`, `fix(parse): ...`, `chore(meta): ...`.
- No emojis anywhere.

## Layout notes

- `dev/` is .Rbuildignore’d scratch/tooling space; `dev/scratch/` is
  gitignored entirely. Do not put anything load-bearing there.
- `inst/extdata/pipelines/` ships only example pipeline data (GDALG
  JSON); scripts that generate examples live in `dev/scripts/`.
- `inst/schemas/` holds upstream GDAL JSON schemas for
  reference/validation.
- Test corpus and expectations live in `tests/testthat/`; the widget
  bundle has a guard test (`test-widget-assets.R`).
