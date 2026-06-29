test_that("lint_pipeline reports unknown step and unknown argument", {
  p <- parse_pipeline("gdal vector pipeline frobnicate --mystery 42")
  issues <- lint_pipeline(p)

  expect_true(any(issues$code == "unknown_step"))
  expect_false(any(issues$code == "unknown_argument"))
})

test_that("lint_pipeline catches missing required args on known steps", {
  p <- parse_pipeline("gdal vector pipeline read --input-layer parcels")
  issues <- lint_pipeline(p)

  expect_true(any(issues$code == "missing_required_args"))
  expect_true(any(grepl("input", issues$message, fixed = TRUE)))
})

test_that("validate_pipeline returns structured result and strict mode aborts", {
  p <- parse_pipeline("gdal vector pipeline read --input-layer parcels")

  non_strict <- validate_pipeline(p, strict = FALSE)
  expect_s3_class(non_strict, "gdalviz_validation")
  expect_false(non_strict$valid)
  expect_true(nrow(non_strict$issues) > 0)

  expect_error(validate_pipeline(p, strict = TRUE), "Pipeline validation failed", fixed = TRUE)
})

test_that("validate_pipeline accepts valid basic pipelines", {
  p <- parse_pipeline(
    "gdal vector pipeline read --input in.gpkg --input-layer parcels ! reproject --output-crs EPSG:4326"
  )

  v <- validate_pipeline(p, strict = FALSE)
  expect_true(v$valid)
  expect_equal(nrow(v$issues), 0)
})
