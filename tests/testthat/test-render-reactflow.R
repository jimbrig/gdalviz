cmd <- paste0(
  "gdal vector pipeline --config GDAL_NUM_THREADS=ALL_CPUS ",
  "! read --input in.gpkg --input-layer parcels ",
  "! filter --where \"statefp = '13'\" ",
  "! tee --tee-pipeline [ sql --sql \"SELECT 1\" ! write --output side.fgb ] ",
  "! reproject --output-crs EPSG:4326 ",
  "! write --output out.parquet --output-format Parquet --overwrite"
)

test_that("render_reactflow builds a pipeline_flow htmlwidget", {
  skip_if_not_installed("htmlwidgets")

  w <- render_reactflow(pipeline_graph(cmd))
  expect_s3_class(w, "pipeline_flow")
  expect_s3_class(w, "htmlwidget")
})

test_that("widget payload carries nodes, edges, globals, and options", {
  skip_if_not_installed("htmlwidgets")

  w <- render_reactflow(
    pipeline_graph(cmd),
    direction = "LR",
    theme = "dark",
    minimap = FALSE
  )
  x <- w$x

  commands <- vapply(x$nodes, `[[`, character(1), "command")
  expect_setequal(
    commands,
    c("read", "filter", "tee", "sql", "write", "reproject", "write")
  )

  read_node <- x$nodes[[which(commands == "read")[1]]]
  expect_identical(read_node$category, "source")
  expect_identical(read_node$category_label, "Input")
  arg_names <- vapply(read_node$args, function(a) a$name %||% "", character(1))
  expect_true(all(c("input", "input-layer") %in% arg_names))

  expect_true(any(vapply(x$edges, function(e) identical(e$kind, "main"), logical(1))))
  expect_identical(x$globals[[1]], "GDAL_NUM_THREADS=ALL_CPUS")

  expect_identical(x$options$direction, "LR")
  expect_identical(x$options$theme, "dark")
  expect_false(x$options$minimap)
})

test_that("render_reactflow accepts strings and pipelines directly", {
  skip_if_not_installed("htmlwidgets")

  expect_s3_class(render_reactflow(cmd), "pipeline_flow")
  expect_s3_class(render_reactflow(parse_pipeline(cmd)), "pipeline_flow")
})
