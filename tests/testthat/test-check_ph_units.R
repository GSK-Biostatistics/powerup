test_that("check_ph_units()", {
  check <- function(x) check_ph_units(x)

  expect_snapshot(error = TRUE, check(NULL))
  expect_snapshot(error = TRUE, check("-5"))
  expect_snapshot(error = TRUE, check("-5%"))
  expect_snapshot(error = TRUE, check("110%"))
  expect_snapshot(error = TRUE, check("-5cm"))
  expect_snapshot(error = TRUE, check("-5in"))

  expect_snapshot(error = TRUE, check("4inch"))
  expect_snapshot(error = TRUE, check("4c"))

  expect_equal(check_ph_units("50%"), "50%")
  expect_equal(check_ph_units("3cm"), as.character(to_inch(3)))
  expect_equal(check_ph_units("3in"), "3")

  expect_equal(check_ph_units("50", ref_units = "%"), "50%")
  expect_equal(check_ph_units("3", ref_units = "cm"), as.character(to_inch(3)))
  expect_equal(check_ph_units("3", ref_units = "in"), "3")
  
})
