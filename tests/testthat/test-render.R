cmd <- paste0(
  "gdal vector pipeline ",
  "read --open-option LIST_ALL_TABLES=NO ",
  "--open-option \"PRELUDE_STATEMENTS=PRAGMA cache_size=-4000000;PRAGMA temp_store=MEMORY;\" ",
  "--input C:/GEODATA/parcels.gpkg --input-layer lr_parcel_us ",
  "! filter --where \"statefp = '13'\" ",
  "! sql --sql \"SELECT geoid, statefp AS state_fips FROM \\\"lr_parcel_us\\\"\" --dialect SQLITE ",
  "! make-valid ",
  "! set-geom-type --multi --skip ",
  "! reproject --output-crs EPSG:4326"
)

test_that("render_command_line round-trips through the parser", {
  p1 <- parse_pipeline(cmd)
  cl <- render_command_line(p1)
  p2 <- parse_pipeline(cl)
  expect_identical(render_command_line(p2), cl)
})

test_that("canonical quoting matches GDAL style", {
  cl <- render_command_line(parse_pipeline(cmd))
  # bare tokens stay unquoted
  expect_match(cl, "--input-layer lr_parcel_us", fixed = TRUE)
  expect_match(cl, "--output-crs EPSG:4326", fixed = TRUE)
  # values with spaces get double quotes, inner identifier quotes escaped
  expect_match(cl, "--where \"statefp = '13'\"", fixed = TRUE)
  expect_match(cl, "FROM \\\"lr_parcel_us\\\"", fixed = TRUE)
})

test_that("bash script reverse round-trips", {
  p <- parse_pipeline(cmd)
  cl <- render_command_line(p)
  script <- render_script(p, shell = "bash")
  expect_match(script, "\\\\\n", perl = TRUE) # has line continuations
  back <- parse_script(script, shell = "bash")
  expect_identical(render_command_line(back), cl)
})

test_that("powershell script reverse round-trips (inline + block sql)", {
  p <- parse_pipeline(cmd)
  cl <- render_command_line(p)

  inline <- render_script(p, shell = "powershell")
  expect_match(inline, "`\n", perl = TRUE)
  expect_identical(render_command_line(parse_script(inline, "powershell")), cl)

  block <- render_script(p, shell = "powershell", sql = "block")
  expect_match(block, "@\"", fixed = TRUE)
  expect_identical(render_command_line(parse_script(block, "powershell")), cl)
})

test_that("bash quoting is shell-safe", {
  p <- parse_pipeline(cmd)
  script <- render_script(p, shell = "bash")
  # value containing single quotes uses double quotes
  expect_match(script, "--where \"statefp = '13'\"", fixed = TRUE)
  # value containing double quotes uses single quotes
  expect_match(script, "'SELECT geoid, statefp AS state_fips FROM \"lr_parcel_us\"'", fixed = TRUE)
})

test_that("nested tee branches survive a round-trip", {
  tee <- paste0(
    "gdal vector pipeline read --input in.gpkg ",
    "! tee --tee-pipeline [ sql --sql \"SELECT 1\" ! write --output /vsimem/a.arrow --output-format Arrow ] ",
    "! write --output out.fgb"
  )
  p <- parse_pipeline(tee)
  cl <- render_command_line(p)
  expect_match(cl, "! tee --tee-pipeline [ sql --sql \"SELECT 1\" ! write", fixed = TRUE)
  expect_identical(render_command_line(parse_pipeline(cl)), cl)
})

test_that("globals with an implicit first step round-trip", {
  cmd2 <- paste(
    "gdal vector pipeline --progress --config GDAL_NUM_THREADS=ALL_CPUS",
    "read --input in.gpkg ! write --output out.fgb"
  )
  p <- parse_pipeline(cmd2)
  cl <- render_command_line(p)
  # the canonical form re-adds the `!` between globals and the first step
  expect_match(cl, "--config GDAL_NUM_THREADS=ALL_CPUS ! read", fixed = TRUE)
  expect_identical(render_command_line(parse_pipeline(cl)), cl)
})

test_that("as_gdalg builds a schema-shaped spec", {
  spec <- as_gdalg(parse_pipeline(cmd))
  expect_identical(spec$type, "gdal_streamed_alg")
  expect_true(is.character(spec$command_line))
  expect_true(spec$relative_paths_relative_to_this_file)
})
