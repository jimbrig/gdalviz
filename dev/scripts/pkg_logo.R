
#  ------------------------------------------------------------------------
#
# Title : Package Logo
#    By : Jimmy Briggs
#  Date : 2026-07-11
#
#  ------------------------------------------------------------------------

# deterministic hex logo: the subplot is a mini pipeline dataflow drawn with
# ggplot2 from the package's own category palette (no downloaded artwork),
# composed into a hex sticker and installed via usethis::use_logo().

proj <- this.path::this.proj()
setwd(proj)
pkgload::load_all(proj, quiet = TRUE)

man_figures_path <- file.path(proj, "man/figures")
if (!dir.exists(man_figures_path)) dir.create(man_figures_path, recursive = TRUE)

# subplot: mini dataflow ------------------------------------------------------

pal <- gdalviz:::gdalviz_palette()

node_w <- 1.15
node_h <- 0.42

nodes <- data.frame(
  x = c(0, 0, 0, 0, 1.35),
  y = c(3, 2, 1, 0, 1.5),
  fill = c(pal$source, pal$filter, pal$attribute, pal$sink, pal$geometry)
)

edges <- data.frame(
  x = c(0, 0, 0),
  y = c(3, 2, 1) - node_h / 2,
  xend = c(0, 0, 0),
  yend = c(2, 1, 0) + node_h / 2 + 0.04
)

subplot <- ggplot2::ggplot() +
  # main chain edges
  ggplot2::geom_segment(
    data = edges,
    ggplot2::aes(x = x, y = y, xend = xend, yend = yend),
    color = "#94a3b8",
    linewidth = 0.35,
    arrow = ggplot2::arrow(length = ggplot2::unit(0.045, "in"), type = "closed")
  ) +
  # dashed tee branch
  ggplot2::geom_segment(
    ggplot2::aes(x = node_w / 2, y = 2, xend = 1.35, yend = 1.5 + node_h / 2 + 0.04),
    color = "#64748b",
    linewidth = 0.3,
    linetype = "22",
    arrow = ggplot2::arrow(length = ggplot2::unit(0.04, "in"), type = "closed")
  ) +
  # node cards
  ggplot2::geom_tile(
    data = nodes,
    ggplot2::aes(x = x, y = y, fill = fill),
    width = node_w,
    height = node_h,
    color = "#0b0e12",
    linewidth = 0.25
  ) +
  # "code" lines inside each card
  ggplot2::geom_segment(
    data = nodes,
    ggplot2::aes(x = x - node_w / 2 + 0.14, y = y, xend = x + node_w / 2 - 0.14, yend = y),
    color = "#ffffff",
    alpha = 0.85,
    linewidth = 0.28
  ) +
  ggplot2::scale_fill_identity() +
  ggplot2::coord_equal(clip = "off") +
  ggplot2::theme_void() +
  hexSticker::theme_transparent()

# sticker ----------------------------------------------------------------

sysfonts::font_add_google("JetBrains Mono", "jbmono")
showtext::showtext_auto()

sticker_args <- function(filename, p_size) {
  list(
    filename = filename,
    # package name
    package = pkgload::pkg_name(),
    p_x = 1,
    p_y = 1.52,
    p_color = "#e2e8f0",
    p_family = "jbmono",
    p_fontface = "bold",
    p_size = p_size,
    # subplot
    subplot = subplot,
    s_x = 1,
    s_y = 0.85,
    s_width = 1.05,
    s_height = 1.05,
    asp = 0.9,
    dpi = 600,
    # hexagon
    h_size = 1.2,
    h_fill = "#0b0e12",
    h_color = "#0d9488",
    # url
    url = "github.com/jimbrig/gdalviz",
    u_x = 1,
    u_y = 0.08,
    u_color = "#0d9488",
    u_family = "jbmono",
    u_size = 1.4,
    u_angle = 30,
    white_around_sticker = FALSE
  )
}

do.call(hexSticker::sticker, sticker_args("man/figures/hex.logo.svg", p_size = 7))
do.call(hexSticker::sticker, sticker_args("man/figures/hex.logo.png", p_size = 14))

# install as package logo + favicons ------------------------------------------

# use_logo() prompts before overwriting, so resize/install explicitly
logo <- magick::image_read("man/figures/hex.logo.png")
logo <- magick::image_resize(logo, "480x556")
magick::image_write(logo, "man/figures/logo.png")
cli::cli_alert_success("Wrote {.path man/figures/logo.png}")

pkgdown::build_favicons(overwrite = TRUE)
