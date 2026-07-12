test_that("contract loads steps and pipeline-level arguments", {
  ct <- gdalviz_contract()
  expect_s3_class(ct, "gdalviz_contract")
  expect_true(all(c("read", "filter", "reproject", "tee", "write") %in% names(ct$steps)))

  # pipeline-level args include the algorithm's own inputs plus common cli args
  expect_true(all(c("input", "output-format", "quiet", "config", "progress") %in% names(ct$pipeline_args)))
  expect_identical(ct$pipeline_args$config$type, "string_list")
  expect_identical(ct$pipeline_args$progress$type, "boolean")
})

test_that("contract args carry mutual exclusion groups", {
  ct <- gdalviz_contract()
  write <- contract_step("write", ct)
  expect_identical(write$args$append$mutex_group, write$args$upsert$mutex_group)
  expect_false(is.na(write$args$append$mutex_group))
  expect_true(is.na(write$args$output$mutex_group))
})

test_that("lint flags mutually exclusive argument combinations", {
  issues <- lint_pipeline(
    "read --input in.gpkg ! write --output out.gpkg --append --upsert"
  )
  mutex <- issues[issues$code == "mutually_exclusive_args", ]
  expect_identical(nrow(mutex), 1L)
  expect_identical(mutex$command, "write")
  expect_match(mutex$message, "--append, --upsert", fixed = TRUE)
})

test_that("valid pipelines produce no mutex issues", {
  issues <- lint_pipeline(
    "read --input in.gpkg ! write --output out.gpkg --append"
  )
  expect_identical(nrow(issues[issues$code == "mutually_exclusive_args", ]), 0L)
})
