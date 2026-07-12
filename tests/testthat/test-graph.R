test_that("unknown steps fall back to the 'other' category instead of erroring", {
  g <- pipeline_graph("read --input in.gpkg ! frobnicate --level 9 ! write --output out.fgb")
  frob <- g$nodes[g$nodes$command == "frobnicate", ]
  expect_identical(frob$category, "other")
})

test_that("powershell-style multiline scripts parse via read_gdalg", {
  script <- paste(
    "gdal vector pipeline `",
    "  read",
    "    --input \\\"/vsizip/vsicurl/https://example.com/tl.zip/tl.shp\\\" `",
    "    --input-layer tl_2025_us_state `",
    "! filter --where \\\"STATEFP NOT IN ('02','15')\\\" `",
    "! reproject --output-crs 'EPSG:4326' `",
    "! write --output out.fgb --output-format FlatGeobuf",
    sep = "\n"
  )
  p <- read_gdalg(script)
  commands <- vapply(p$steps, `[[`, character(1), "command")
  expect_identical(commands, c("read", "filter", "reproject", "write"))
  expect_identical(
    p$steps[[1]]$args[[1]]$value,
    "/vsizip/vsicurl/https://example.com/tl.zip/tl.shp"
  )
})

test_that("globals followed by an implicit first step (no !) split correctly", {
  cmd <- paste(
    "gdal vector pipeline --progress --config CPL_DEBUG=ON",
    "--config GDAL_NUM_THREADS=ALL_CPUS",
    "read --input in.gpkg --input-layer parcels",
    "! write --output out.parquet"
  )
  p <- parse_pipeline(cmd)

  flags <- vapply(p$pipeline_options, function(a) a$flag %||% "", character(1))
  expect_identical(flags, c("progress", "config", "config"))

  commands <- vapply(p$steps, `[[`, character(1), "command")
  expect_identical(commands, c("read", "write"))
  expect_identical(p$steps[[1]]$args[[1]]$value, "in.gpkg")
})

test_that("pipeline options become a runtime config node feeding the source", {
  g <- pipeline_graph(paste(
    "gdal vector pipeline --config GDAL_NUM_THREADS=ALL_CPUS",
    "! read --input in.gpkg ! write --output out.fgb"
  ))

  config <- g$nodes[g$nodes$category == "runtime", ]
  expect_identical(nrow(config), 1L)
  expect_identical(config$command, "config")

  read_id <- g$nodes$id[g$nodes$command == "read"]
  config_edge <- g$edges[g$edges$kind == "config", ]
  expect_identical(config_edge$from, config$id)
  expect_identical(config_edge$to, read_id)
})

test_that("runs of 3+ identical commands merge into one stacked node", {
  sft <- paste(
    sprintf("! set-field-type --field-name f%02d --field-type Integer", 1:12),
    collapse = " "
  )
  cmd <- paste("read --input in.gpkg", sft, "! write --output out.parquet")

  g <- pipeline_graph(cmd)
  merged <- g$nodes[g$nodes$command == "set-field-type", ]
  expect_identical(nrow(merged), 1L)
  expect_identical(merged$count, 12L)
  expect_identical(length(merged$args[[1]]), 12L)
  expect_identical(merged$args[[1]][[1]]$name, "f01")
  expect_identical(merged$args[[1]][[1]]$value, "Integer")

  # opt-out keeps one node per step
  g2 <- pipeline_graph(cmd, merge_repeated = FALSE)
  expect_identical(sum(g2$nodes$command == "set-field-type"), 12L)

  # short runs below the threshold are not merged
  g3 <- pipeline_graph(
    "read --input in.gpkg ! buffer 1 ! buffer 2 ! write --output out.fgb"
  )
  expect_identical(sum(g3$nodes$command == "buffer"), 2L)
})

test_that("GDALG pipelines without a write step get an implicit streamed sink", {
  g <- pipeline_graph("read --input in.gpkg ! reproject --output-crs EPSG:4326")
  sink <- g$nodes[g$nodes$implicit, ]
  expect_identical(nrow(sink), 1L)
  expect_identical(sink$command, "write")
  expect_identical(sink$category, "sink")

  # explicit sinks do not get a synthetic node
  g2 <- pipeline_graph("read --input in.gpkg ! write --output out.fgb")
  expect_false(any(g2$nodes$implicit))
})
