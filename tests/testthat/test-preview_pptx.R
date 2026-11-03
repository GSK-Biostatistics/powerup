test_that("preview_pptx returns a pptx_preview htmlwidget from a pptx_container", {
  result <- preview_pptx(example_pptx(), view = FALSE)

  expect_s3_class(result, "htmlwidget")
  expect_s3_class(result, "pptx_preview")
  expect_match(result$x$data, "^[A-Za-z0-9+/=]+$")
  expect_equal(result$x$slide, 0L)
})

test_that("preview_pptx accepts a file path", {
  tmp <- tempfile(fileext = ".pptx")
  on.exit(unlink(tmp))
  save_pptx(example_pptx(), tmp)

  result <- preview_pptx(tmp, slide = 2, view = FALSE)

  expect_s3_class(result, "pptx_preview")
  expect_equal(result$x$slide, 1L)
})

test_that("preview_pptx bundles the viewer JS dependencies", {
  result <- preview_pptx(example_pptx(), view = FALSE)
  dep_names <- vapply(result$dependencies, function(d) d$name, character(1))

  expect_true(all(c("jszip", "chartjs", "pptxviewjs") %in% dep_names))
})

test_that("preview_pptx dispatches on launch.browser", {
  seen <- NULL
  res <- preview_pptx(example_pptx(), view = TRUE,
                      launch.browser = function(url) seen <<- url)

  expect_s3_class(res, "pptx_preview")
  expect_true(file.exists(seen))
  expect_match(paste(readLines(seen, warn = FALSE), collapse = "\n"), "pptx_preview")
})

test_that("preview_pptx errors informatively on bad input", {
  expect_error(preview_pptx("nonexistent.pptx"), class = "rlang_error")
  expect_error(preview_pptx(42),                 class = "rlang_error")
  expect_error(preview_pptx(example_pptx(), launch.browser = "x"), class = "rlang_error")
})
