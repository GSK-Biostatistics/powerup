test_that("ref_placeholder", {
  ph <- ref_placeholder(
    label = "[Tt]itle",
    type = "title",
    tie_breaker = "top",
    label_match = "match",
    label_from = c("slide","layout"),
    replace = TRUE
  )

  expect_equal(ph$label, "[Tt]itle")
  expect_equal(ph$type, "title")
  expect_equal(ph$tie_breaker, "top")
  expect_equal(ph$label_from, c("slide", "layout"))
  expect_equal(ph$label_match, "match")
  expect_equal(ph$replace, TRUE)
})


test_that("ref_placeholder() checks arguments", {
  expect_snapshot(error = TRUE, ref_placeholder(label = "label", type = "foo"))
  expect_snapshot(error = TRUE, ref_placeholder(label = "label", label_match = "foo"))
  expect_snapshot(error = TRUE, ref_placeholder(label = "label", label_from = "foo"))
  expect_snapshot(error = TRUE, ref_placeholder(label = "label", tie_breaker = "foo"))
})

test_that("new_placeholder() checks arguments", {
  expect_snapshot(error = FALSE, new_placeholder(label = "label", type = "foo"))
  expect_snapshot(error = TRUE, new_placeholder(label = "label", units = "foo"))
})

test_that("new_placeholder() checks units", {
  expect_snapshot(error = TRUE, new_placeholder(label = "label", x_offset = "foo"))
  expect_snapshot(error = TRUE, new_placeholder(label = "label", x_offset = "120%"))
  expect_snapshot(error = TRUE, new_placeholder(label = "label", y_offset = "foo"))
  expect_snapshot(error = TRUE, new_placeholder(label = "label", width = "foo"))
  expect_snapshot(error = TRUE, new_placeholder(label = "label", height = "foo"))
  expect_snapshot(error = TRUE, new_placeholder(label = "label", height = "10", units = "foo"))
  expect_snapshot(error = TRUE, new_placeholder(label = "label", height = 10, units = "foo"))
})

test_that("new_placeholder can have units specified in line or units argument", {
  ph <- new_placeholder(label = "label", x_offset = "50%", y_offset = "3cm", width = "3in", height = "10", units = "cm")
  expect_equal(ph$offx, "50%")
  expect_equal(ph$offy, as.character(to_inch(3)))
  expect_equal(ph$cx, as.character(3))
  expect_equal(ph$cy, as.character(to_inch(10)))
})
