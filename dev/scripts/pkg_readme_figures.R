
#  ------------------------------------------------------------------------
#
# Title : README Figures
#    By : Jimmy Briggs
#  Date : 2026-07-11
#
#  ------------------------------------------------------------------------

# regenerates man/figures/readme-example-*.png deterministically:
# widgets are saved with htmlwidgets::saveWidget() and screenshotted
# headlessly via webshot2 (chrome). run after visual changes to renderers.

proj <- this.path::this.proj()
setwd(proj)
pkgload::load_all(proj, quiet = TRUE)

# webshot2/chromote needs a chromium browser; fall back to edge on windows
if (!nzchar(Sys.getenv("CHROMOTE_CHROME")) && is.null(chromote::find_chrome())) {
  edge <- file.path(Sys.getenv("ProgramFiles(x86)"), "Microsoft", "Edge", "Application", "msedge.exe")
  if (file.exists(edge)) {
    Sys.setenv(CHROMOTE_CHROME = edge)
  }
}

figures <- file.path(proj, "man", "figures")

cmd <- paste(
  "gdal vector pipeline",
  "read --input /data/parcels.gpkg --input-layer parcels",
  "! filter --where \"statefp = '13'\"",
  "! make-valid",
  "! reproject --output-crs EPSG:4326",
  "! write --output /tmp/parcels.fgb --output-format FlatGeobuf"
)

shoot <- function(widget, file, width, height, delay = 1.5, trim = FALSE) {
  tmp <- tempfile(fileext = ".html")
  htmlwidgets::saveWidget(widget, tmp, selfcontained = FALSE)
  out <- file.path(figures, file)
  webshot2::webshot(tmp, file = out, vwidth = width, vheight = height, delay = delay)
  if (isTRUE(trim)) {
    img <- magick::image_trim(magick::image_read(out))
    img <- magick::image_border(img, "white", "24x24")
    magick::image_write(img, out)
  }
  cli::cli_alert_success("Wrote {.path man/figures/{file}}")
}

# example 1: static graphviz rendering
shoot(
  render_diagrammer(pipeline_graph(cmd), theme = "light"),
  "readme-example-1.png",
  width = 760,
  height = 860,
  trim = TRUE
)

# example 2: interactive react flow rendering (tiger gdalg, dark)
tiger <- system.file("extdata", "pipelines", "tiger_states.gdalg.json", package = "gdalviz")
if (!nzchar(tiger)) tiger <- file.path("inst", "extdata", "pipelines", "tiger_states.gdalg.json")
shoot(
  render_reactflow(pipeline_graph(tiger), theme = "dark", minimap = FALSE, direction = "TB"),
  "readme-example-2.png",
  width = 1000,
  height = 820
)
