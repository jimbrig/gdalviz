test_that("the pipeline_flow widget bundle is present and registered", {
  js <- system.file("htmlwidgets", "pipeline_flow.js", package = "gdalviz")
  if (!nzchar(js)) {
    # development fallback (package loaded via load_all)
    js <- file.path("..", "..", "inst", "htmlwidgets", "pipeline_flow.js")
  }
  expect_true(file.exists(js))
  expect_gt(file.size(js), 100000)

  content <- readChar(js, file.size(js), useBytes = TRUE)
  expect_match(content, "pipeline_flow", fixed = TRUE)
})
