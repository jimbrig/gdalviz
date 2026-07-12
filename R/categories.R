# classification of pipeline steps into semantic categories, with a modern
# palette and iconography. categories drive node color/icon and grouping.

gdalviz_category_map <- function() {
  c(
    read = "source",
    concat = "source",
    write = "sink",
    partition = "sink",
    materialize = "sink",
    update = "sink",
    create = "sink",
    external = "sink",
    sql = "attribute",
    select = "attribute",
    "set-field-type" = "attribute",
    edit = "attribute",
    "rename-layer" = "attribute",
    "export-schema" = "attribute",
    reproject = "crs",
    filter = "filter",
    clip = "filter",
    limit = "filter",
    sort = "order",
    tee = "branch",
    info = "inspect",
    "check-geometry" = "inspect",
    "check-coverage" = "inspect",
    "make-valid" = "geometry",
    "set-geom-type" = "geometry",
    buffer = "geometry",
    simplify = "geometry",
    segmentize = "geometry",
    "swap-xy" = "geometry",
    "explode-collections" = "geometry",
    dissolve = "geometry",
    combine = "geometry",
    "concave-hull" = "geometry",
    "convex-hull" = "geometry",
    "make-point" = "geometry",
    "simplify-coverage" = "geometry",
    "clean-coverage" = "geometry"
  )
}

gdalviz_category <- function(command) {
  if (is.null(command) || is.na(command)) {
    return("other")
  }
  m <- gdalviz_category_map()
  cat <- unname(m[command])
  if (is.na(cat)) "other" else cat
}

# modern, accessible palette (tailwind-ish), keyed by category.
gdalviz_palette <- function(theme = c("light", "dark")) {
  theme <- match.arg(theme)
  list(
    source = "#2563eb",
    sink = "#16a34a",
    attribute = "#7c3aed",
    crs = "#0d9488",
    filter = "#e11d48",
    order = "#4f46e5",
    branch = "#64748b",
    inspect = "#ea580c",
    geometry = "#d97706",
    runtime = "#334155",
    other = "#475569"
  )
}

# icon keyword per category (renderer maps to its own glyph set).
gdalviz_category_icon <- function(category) {
  icons <- c(
    source = "database-in",
    sink = "database-out",
    attribute = "table",
    crs = "globe",
    filter = "funnel",
    order = "sort",
    branch = "split",
    inspect = "search",
    geometry = "shapes",
    runtime = "gear",
    other = "dots"
  )
  icons[[category]] %||% "dots"
}

gdalviz_category_label <- function(category) {
  labels <- c(
    source = "Input",
    sink = "Output",
    attribute = "Attributes",
    crs = "Projection",
    filter = "Selection",
    order = "Ordering",
    branch = "Branch",
    inspect = "Inspect",
    geometry = "Geometry",
    runtime = "Config",
    other = "Step"
  )
  labels[[category]] %||% "Step"
}
