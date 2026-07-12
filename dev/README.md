# dev

Development-only tooling and scratch space (`.Rbuildignore`d, never shipped).

| Path | Purpose |
| --- | --- |
| `scripts/build_js.R` | build/watch the srcjs React Flow bundle via bun + vite |
| `scripts/build_site.R` | local pkgdown build (windows cross-drive temp workaround) |
| `scripts/pkg_logo.R` | deterministic hex logo (ggplot2 subplot + hexSticker) + favicons |
| `scripts/pkg_readme_figures.R` | regenerate README figures headlessly via webshot2 |
| `scripts/pkg_init.R` | one-time package scaffolding history |
| `scripts/pkg_srcjs.R` | one-time srcjs scaffolding (bun init) |
| `scripts/tiger_pipelines.R` | generates the TIGER example GDALG files in `inst/extdata/pipelines/` |
| `scripts/gdal_cli_run.R` | helper for shelling out to the gdal CLI during development |
| `scratch/` | gitignored experiments, rendered widget output, spike code |
