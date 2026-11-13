test_that("add_slide()", {
  pptx <- load_pptx()
  expect_equal(length(pptx$rpptx), 0)

  expect_snapshot({
    pptx <- pptx |>
      add_slide(layout = "Title Slide",
        content("Title", ph = ph_title()),
        content("Subtitle", ph = ph_subtitle())
      ) |>
      add_slide(layout = "Comparison",
        content("left" , ph = ph_body_left()),
        content("right", ph = ph_body_right())
      )
  })

  expect_equal(length(pptx$rpptx), 2)

  expect_snapshot(error = TRUE, {
    pptx <- add_slide(pptx)
  })

  expect_snapshot(error = TRUE, {
    pptx <- add_slide(pptx, index = 2)
  })

})


test_that("add_slide() with polish_error_continue", {

  local_methods(
    polish_content_pptx.foo = function(x, ph = '<p:ph/>', ..., error_call = current_env()) {
      "not an xml_nodeset"
    },
    polish_content_pptx.bar = function(x, ph = '<p:ph/>', ..., error_call = current_env()) {
      NextMethod()
    }
  )

  foo <- structure(list(), class = "foo")
  bar <- structure(list(), class = c("bar", "foo"))

  pptx <- load_pptx()
  expect_equal(length(pptx), 0)

  expect_snapshot({
    pptx <- pptx |>
      add_slide(layout = "Title Slide",
                content("Title", ph = ph_title()),
                content("Subtitle", ph = ph_subtitle())
      )
  })
  expect_equal(length(pptx), 1)

  expect_snapshot({
    pptx <- pptx |>
      add_slide(
        layout = "Title Slide",
        content(foo, ph = ph_title())
      )
  })
  expect_equal(length(pptx), 2)

})

test_that("add_slide() with with actual error fails", {

  ## missing/nonexisting object
  pptx <- load_pptx()

  ## intiital state
  expect_equal(length(pptx), 0)

  expect_snapshot(error = TRUE,{
    pptx <- pptx |>
      add_slide(
        layout = "Title Slide",
        content(foo, ph = ph_body())
      )
  })

  ## expect the slide was not added
  expect_equal(length(pptx), 0)

  ## one erroring content and one valid content, expect the slide was not added
  expect_snapshot(error = TRUE,{
    pptx <- pptx |>
      add_slide(
        layout = "Title Slide",
        content(foo, ph = ph_body()),
        content(1, ph = ph_body())
      )
  })

  ## expect the slide was not added
  expect_equal(length(pptx), 0)

  ## one valid content and one invalid content, expect the slide was not added
  expect_snapshot(error = TRUE,{
    pptx <- pptx |>
      add_slide(
        layout = "Title Slide",
        content(1, ph = ph_body()),
        content(foo, ph = ph_body())
      )
  })

  ## expect the slide was not added
  expect_equal(length(pptx), 0)


})

test_that("update_slide() + new_placeholder() uses <p:ph/>", {
  local_options(powerup.verbose = FALSE)

  pptx <- example_pptx() |>
    update_slide(
      index = 1,
      content(
        "",
        ph = new_placeholder(
          type = "body",
          x_offset = "5%", y_offset = "5%",
          width = "80%", height = "50%",
          label = "new placeholder 42"
        )
      )
    )

  ph <- read_slide_placeholders(pptx, index = 1, only_slide = TRUE) |>
    dplyr::filter(slide_ph_name == "new placeholder 42")
  expect_equal(nrow(ph), 1)
  expect_true(is.na(ph$layout_name))
  expect_equal(ph$ph, "<p:ph type=\"body\"/>")
})

test_that("update_slide(), errors on unknown arguments", {
  plot <- ggplot(mtcars, aes(mpg, cyl)) + geom_point()

  ct <- content(plot, description = "plot", ph = new_placeholder(
    type = "body",
    x_offset = "5%",
    y_offset = "28%",
    width = "44%",
    height = "67%",
    label = "powerup_body_left_placeholder 1"
  ))

  pptx <- load_pptx() |>
    add_slide(index = 1, layout = "Title Slide")

  expect_snapshot(pptx <- update_slide(pptx, index = 1, ct))
})

test_that("update_slide() with ref_placeholder() removes old ph", {
  local_options(powerup.verbose = FALSE)

  pptx <- example_pptx()
  old_phs <- read_slide_placeholders(pptx, index = 1, only_slide = TRUE)
  old_id <- old_phs$slide_ph_id[old_phs$slide_ph_name == "Content Placeholder 2"]

  pptx <- pptx |>
    update_slide(index = 1, content(
        "",
        ph = ref_placeholder(
          label = "Content Placeholder 2", label_match = "exact"
        )
      )
    )
  new_phs <- read_slide_placeholders(pptx, index = 1, only_slide = TRUE)
  new_id <- new_phs$slide_ph_id[new_phs$slide_ph_name == "Content Placeholder 2"]
  expect_equal(nrow(old_phs), nrow(new_phs))
  expect_equal(old_id, new_id)
})

test_that("update_slide() with table > read_slide_placeholder() only one", {
  local_options(powerup.verbose = FALSE)

  pptx <- load_pptx() |>
    add_slide(index = 1, layout = 'Title Slide') |>
    update_slide(index = 1,
                 content(
                   value = head(mtcars, 2),
                   ph = new_placeholder(type = "body", x_offset = "10%", y_offset = "10%", width = "80%", height = "80%", label = "New Placeholder")
                 )
    )

  df <- read_slide_placeholders(pptx, index = 1, only_slide = TRUE)
  expect_equal(nrow(df), 1)
  expect_equal(df$slide_ph_name, "New Placeholder")
})

test_that("add a piece of content and then replace it", {
  local_options(powerup.verbose = FALSE)

  pptx <- example_pptx() |>
    add_slide(layout = "Blank",
      content("Test Value", ph = ph_title())
    )

  old_phs <- read_slide_placeholders(pptx, index = 4, only_slide = TRUE)
  old_content_xml <- read_slide(pptx, 4) |>
    xml_find_all(paste0("p:cSld/p:spTree/*[*/p:cNvPr[@id='",old_phs$slide_ph_id,"']]")) |>
    xml2::xml_text()

  pptx <- pptx |>
    update_slide(
      index = 4,
      content("New Value",  ph = ph_title())
    )

  new_phs <- read_slide_placeholders(pptx, index = 4, only_slide = TRUE)
  updated_old_content_xml <- read_slide(pptx, 4) |>
    xml_find_all(paste0("p:cSld/p:spTree/*[*/p:cNvPr[@id='",new_phs$slide_ph_id,"']]")) |>
    xml2::xml_text()

  expect_equal(nrow(old_phs), nrow(new_phs))
  expect_equal(new_phs$slide_ph_id, old_phs$slide_ph_id)

  expect_equal(old_content_xml, "Test Value")
  expect_equal(updated_old_content_xml, "New Value")

  updated_old_content_ph <- read_slide(pptx, 4) |>
    xml_find_all(paste0("p:cSld/p:spTree/*[*/p:cNvPr[@id='",new_phs$slide_ph_id,"']]")) |>
    xml_find_all(".//p:ph") |>
    as.character()
  expect_equal(updated_old_content_ph, "<p:ph type=\"body\"/>")


})

test_that("add a piece of content (String) and then replace it with some different object type (table)", {
  local_options(powerup.verbose = FALSE)

  pptx <- example_pptx() |>
    add_slide(layout = "Blank",
      content("Test Value", ph = ph_title())
    )

  old_phs <- read_slide_placeholders(pptx, index = 4, only_slide = TRUE)
  old_content_xml <- read_slide(pptx, 4) |>
    xml_find_all(paste0("p:cSld/p:spTree/*[*/p:cNvPr[@id='",old_phs$slide_ph_id,"']]")) |>
    xml2::xml_text()
  old_content_ph <- read_slide(pptx, 4) |>
    xml_find_all(paste0("p:cSld/p:spTree/*[*/p:cNvPr[@id='",old_phs$slide_ph_id,"']]")) |>
    xml_find_all(".//p:ph") |>
    as.character()

  expect_equal(old_content_ph, "<p:ph type=\"body\"/>")

  pptx <- pptx |>
    update_slide(
      index = 4,
      content(head(mtcars,1),  ph = ph_title())
    )

  new_phs <- read_slide_placeholders(pptx, index = 4, only_slide = TRUE)
  updated_old_content_xml <- read_slide(pptx, 4) |>
    xml_find_all(paste0("p:cSld/p:spTree/*[*/p:cNvPr[@id='",new_phs$slide_ph_id,"']]")) |>
    xml2::xml_text()

  expect_equal(nrow(old_phs), nrow(new_phs))
  expect_equal(new_phs$slide_ph_id, old_phs$slide_ph_id)

  expect_equal(old_content_xml, "Test Value")
  expect_equal(updated_old_content_xml, "mpgcyldisphpdratwtqsecvsamgearcarb2161601103.92.6216.460144")

  updated_old_content_ph <- read_slide(pptx, 4) |>
    xml_find_all(paste0("p:cSld/p:spTree/*[*/p:cNvPr[@id='",new_phs$slide_ph_id,"']]")) |>
    xml_find_all(".//p:ph") |>
    as.character()
  ## tables don't use ph
  expect_equal(updated_old_content_ph, character(0))

})


test_that("add a piece of content (table) and then replace it with some different object type (string)", {
  local_options(powerup.verbose = FALSE)

  pptx <- example_pptx() |>
    add_slide(layout = "Title and Content",
      content(head(mtcars), ph = ph_body())
    )

  old_phs <- read_slide_placeholders(pptx, index = 4, only_slide = TRUE)
  old_content_xml <- read_slide(pptx, 4) |>
    xml_find_all(paste0("p:cSld/p:spTree/*[*/p:cNvPr[@id='",old_phs$slide_ph_id,"']]")) |>
    xml2::xml_text()

  pptx <- pptx |>
    update_slide(
      index = 4,
      content("New Value",  ph = ph_body())
    )

  new_phs <- read_slide_placeholders(pptx, index = 4, only_slide = TRUE)
  updated_old_content_xml <- read_slide(pptx, 4) |>
    xml_find_all(paste0("p:cSld/p:spTree/*[*/p:cNvPr[@id='",new_phs$slide_ph_id,"']]")) |>
    xml2::xml_text()

  expect_equal(nrow(old_phs), nrow(new_phs))
  expect_equal(new_phs$slide_ph_id, old_phs$slide_ph_id)

  expect_equal(old_content_xml, "mpgcyldisphpdratwtqsecvsamgearcarb21.061601103.902.62016.46014421.061601103.902.87517.02014422.84108933.852.32018.61114121.462581103.083.21519.44103118.783601753.153.44017.02003218.162251052.763.46020.221031")
  expect_equal(updated_old_content_xml, "New Value")

  updated_old_content_ph <- read_slide(pptx, 4) |>
    xml_find_all(paste0("p:cSld/p:spTree/*[*/p:cNvPr[@id='",new_phs$slide_ph_id,"']]")) |>
    xml_find_all(".//p:ph") |>
    as.character()

  expect_equal(updated_old_content_ph, "<p:ph type=\"body\"/>")

})


test_that("add a piece of content (table) and then replace it with some different object type (ggplt)", {
  local_options(powerup.verbose = FALSE)

  pptx <- example_pptx() |>
    add_slide(layout = "Title and Content",
      content(head(mtcars), ph = ph_body())
    )

  old_phs <- read_slide_placeholders(pptx, index = 4, only_slide = TRUE)
  old_content_xml <- read_slide(pptx, 4) |>
    xml_find_all(paste0("p:cSld/p:spTree/*[*/p:cNvPr[@id='",old_phs$slide_ph_id,"']]")) |>
    xml2::xml_text()

  gg <- ggplot(mtcars) +
    geom_point(aes(x = disp, y = mpg))

  pptx <- pptx |>
    update_slide(
      index = 4,
      content(gg,  ph = ph_body())
    )

  new_phs <- read_slide_placeholders(pptx, index = 4, only_slide = TRUE)
  updated_old_content_xml <- read_slide(pptx, 4) |>
    xml_find_all(paste0("p:cSld/p:spTree/*[*/p:cNvPr[@id='",new_phs$slide_ph_id,"']]")) |>
    xml_name()

  expect_equal(nrow(old_phs), nrow(new_phs))
  expect_equal(new_phs$slide_ph_id, old_phs$slide_ph_id)

  expect_equal(old_content_xml, "mpgcyldisphpdratwtqsecvsamgearcarb21.061601103.902.62016.46014421.061601103.902.87517.02014422.84108933.852.32018.61114121.462581103.083.21519.44103118.783601753.153.44017.02003218.162251052.763.46020.221031")
  expect_equal(updated_old_content_xml, "pic")

  updated_old_content_ph <- read_slide(pptx, 4) |>
    xml_find_all(paste0("p:cSld/p:spTree/*[*/p:cNvPr[@id='",new_phs$slide_ph_id,"']]")) |>
    xml_find_all(".//p:ph") |>
    as.character()

  expect_equal(updated_old_content_ph, "<p:ph type=\"body\"/>")

})

test_that("add a piece of content and then layer over it", {
  local_options(powerup.verbose = FALSE)

  pptx <- example_pptx() |>
    add_slide(layout = "Title and Content",
      content("Test Value", ph = ph_title())
    )

  old_phs <- read_slide_placeholders(pptx, index = 4, only_slide = TRUE)
  old_content_xml <- read_slide(pptx, 4) |>
    xml_find_all(paste0("p:cSld/p:spTree/*[*/p:cNvPr[@id='",old_phs$slide_ph_id,"']]")) |>
    xml2::xml_text()

  pptx <- pptx |>
    update_slide(
      index = 4,
      content("New Value",  ph = ph_title(replace = FALSE)$fallback)
    )

  new_phs <- read_slide_placeholders(pptx, index = 4, only_slide = TRUE)
  updated_old_content_xml <- read_slide(pptx, 4) |>
    xml_find_all(paste0("p:cSld/p:spTree/*[*/p:cNvPr[@id='",new_phs$slide_ph_id[1],"']]")) |>
    xml2::xml_text()
  updated_new_content_xml <- read_slide(pptx, 4) |>
    xml_find_all(paste0("p:cSld/p:spTree/*[*/p:cNvPr[@id='",new_phs$slide_ph_id[2],"']]")) |>
    xml2::xml_text()

  expect_true(nrow(old_phs) < nrow(new_phs))
  expect_true(old_phs$slide_ph_id %in% new_phs$slide_ph_id, )

  expect_equal(old_content_xml, "Test Value")
  expect_equal(updated_old_content_xml, "Test Value")
  expect_equal(updated_new_content_xml, "New Value")

})

test_that("update previously custom placeholder (replace first time, preserve second)", {
  local_options(powerup.verbose = FALSE)

  pptx <- load_pptx() |>
    add_slide(index = 1, layout = 'Title Slide') |>
    update_slide(index = 1, content(
      value = head(mtcars, 2),
      ph = new_placeholder(
        type = "body",
        x_offset = "10%",
        y_offset = "10%",
        width = "80%",
        height = "80%",
        label = "New Placeholder"
      )
    ))

  old_phs <- read_slide_placeholders(pptx, index = 1, only_slide = TRUE)
  old_content_xml <- read_slide(pptx, 1) |>
    xml_find_all(paste0("p:cSld/p:spTree/*[*/p:cNvPr[@id='",old_phs$slide_ph_id,"']]")) |>
    xml2::xml_text()

  pptx <- pptx |>
    update_slide(
      index = 1,
      content("New Value",  ph = ref_placeholder("New Placeholder", replace = TRUE))
    )

  new_phs <- read_slide_placeholders(pptx, index = 1, only_slide = TRUE)
  new_content_xml <- read_slide(pptx, 1) |>
    xml_find_all(paste0("p:cSld/p:spTree/*[*/p:cNvPr[@id='",new_phs$slide_ph_id,"']]")) |>
    xml2::xml_text()


  expect_equal(nrow(old_phs), nrow(new_phs))
  expect_equal(new_phs$slide_ph_id, old_phs$slide_ph_id)

  expect_equal(old_content_xml, "mpgcyldisphpdratwtqsecvsamgearcarb2161601103.92.62016.4601442161601103.92.87517.020144")
  expect_equal(new_content_xml, "New Value")

  expect_snapshot(error = TRUE,
    pptx |>
      update_slide(
        index = 1,
        content("My Final Value",  ph = ref_placeholder("New Placeholder", replace = FALSE))
      )
  )

  final_phs <- read_slide_placeholders(pptx, index = 1, only_slide = TRUE)
  final_content_previous_xml <- read_slide(pptx, 1) |>
    xml_find_all(paste0("p:cSld/p:spTree/*[*/p:cNvPr[@id='",new_phs$slide_ph_id,"']]")) |>
    xml2::xml_text()

  expect_true(nrow(final_phs) == nrow(new_phs))
  expect_equal(final_content_previous_xml, "New Value")

})

test_that("update_slide() + new_placeholder() + plot", {
  local_options(powerup.verbose = FALSE)
  withr::local_package("ggplot2")

  pptx <- load_pptx() |>
    add_slide(index = 1, layout = 'Title Slide') |>
    update_slide(
      index = 1,
       content(
         value = ggplot(mtcars, aes(mpg, cyl)) + geom_point(),
         ph = new_placeholder(type = "body", x_offset = "0%", y_offset = "0%", width = "100%", height = "100%", label = "New Placeholder")
       )
    )

  slides_data <- read_slide_placeholders(pptx, index = 1, only_slide = TRUE)
  dims <- officer::slide_size(pptx$rpptx)
  expect_equal(slides_data$offx, 0)
  expect_equal(slides_data$offy, 0)
  expect_equal(slides_data$cx, dims$width)
  expect_equal(slides_data$cy, dims$height)

  pptx <- load_pptx() |>
    add_slide(index = 1, layout = 'Title Slide') |>
    update_slide(
      index = 1,
      content(
        value = ggplot(mtcars, aes(mpg, cyl)) + geom_point(),
        ph = new_placeholder(type = "body", x_offset = "10%", y_offset = "20%", width = "80%", height = "40%", label = "New Placeholder")
      )
    )

  slides_data <- read_slide_placeholders(pptx, index = 1, only_slide = TRUE)
  dims <- officer::slide_size(pptx$rpptx)
  expect_equal(slides_data$offx, dims$width * .1)
  expect_equal(slides_data$offy, dims$height * .2)
  expect_equal(slides_data$cx, dims$width * .8)
  expect_equal(slides_data$cy, dims$height * .4)
})

test_that("update_slide() + new_placeholder() + df", {
  local_options(powerup.verbose = FALSE)
  withr::local_package("ggplot2")

  pptx <- load_pptx() |>
    add_slide(index = 1, layout = 'Title Slide') |>
    update_slide(
      index = 1,
      content(
        value = head(mtcars, 2),
        ph = new_placeholder(type = "body", x_offset = "0%", y_offset = "0%", width = "100%", height = "100%", label = "New Placeholder")
      )
    )

  slides_data <- read_slide_placeholders(pptx, index = 1, only_slide = TRUE)
  dims <- officer::slide_size(pptx$rpptx)
  expect_equal(slides_data$offx, 0)
  expect_equal(slides_data$offy, 0)
  expect_equal(slides_data$cx, dims$width)
  expect_equal(slides_data$cy, dims$height)

  pptx <- load_pptx() |>
    add_slide(index = 1, layout = 'Title Slide') |>
    update_slide(
      index = 1,
      content(
        value = head(mtcars, 2),
        ph = new_placeholder(type = "body", x_offset = "10%", y_offset = "20%", width = "80%", height = "30%", label = "New Placeholder")
      )
    )

  slides_data <- read_slide_placeholders(pptx, index = 1, only_slide = TRUE)
  expect_equal(slides_data$offx, dims$width * .1)
  expect_equal(slides_data$offy, dims$height * .2)
  expect_equal(slides_data$cx, dims$width * .8)
  expect_equal(slides_data$cy, dims$height * .3)
})


test_that("Wrap values with multiple ph with a grpSp", {

  local_methods(
    polish_content_pptx.foo = function(x, ph = '<p:ph/>', ..., error_call = current_env()) {
      map(x, polish::polish_content_pptx, ph = ph, ..., error_call = error_call) |>
        map_chr(~as.character(.x)) |>
        paste0(collapse = "\n") |>
        polish::as_xml_nodeset(ns = "pptx")
    }
  )

  foo <- structure(c("test","grouping"), class = "foo")

  pptx <- load_pptx()
  expect_equal(length(pptx), 0)

  expect_snapshot({
    pptx <- pptx |>
      add_slide(
        layout = "Title Slide",
        content(
          foo,
          ph = new_placeholder(
            label = "my content",
            x_offset = "5%",
            y_offset = "50%",
            width = "90%",
            height = "10%"
            )
          )
      )
  })

  expect_equal(length(pptx), 1)
  expect_snapshot(
    pptx$rpptx$slide$get_slide(1)$get() |>
      xml_find_all(".//p:spTree") |>
      xml_children() |>
      (\(x){x[[3]]})() |>
      as.character() |>
      gsub(
        "p:cNvPr id=\".+?\"",
        "p:cNvPr id=\"AN ID\"",
        x = _
        )
    )

  ## update content
  expect_snapshot({
    pptx <- pptx |>
      update_slide(
        index = 1,
        content(
          "new text",
          ph = ref_placeholder(
            label = "my content",
            label_match = "exact"
          )
        )
      )

  })

  expect_equal(length(pptx), 1)
  expect_snapshot(
    pptx$rpptx$slide$get_slide(1)$get() |>
      xml_find_all(".//p:spTree") |>
      xml_children() |>
      (\(x){x[[3]]})() |>
      as.character() |>
      gsub(
        "p:cNvPr id=\".+?\"",
        "p:cNvPr id=\"AN ID\"",
        x = _
      )
  )
})

test_that("errors are recorded (#56)", {
  local_options(powerup.verbose = FALSE)

  pptx <- load_pptx()
  errors <- slide_errors(pptx)
  expect_equal(nrow(errors), 0L)

  ## Throw an error when adding a slide with invalid content
  expect_snapshot(error = TRUE, {
    pptx <- pptx |>
        add_slide(index = 1, layout = "Title and Content", content(BAD_CONTENT, ph = ph_body()), polish_error_continue = TRUE)
  })

  errors <- slide_errors(pptx)
  expect_equal(nrow(errors), 1L)
  expect_equal(errors$index, 1)
  ## could not find object 'BAD_CONTENT', but stops
  expect_equal(rlang::cnd_header(errors$errors[[1]])[[1]], "Error evaluating content at position 1: \"content(BAD_CONTENT, ph = ph_body())\".")

  ## don't throw an error when adding a slide with the inability to polish the content, but record the error
  expect_snapshot({
    pptx <- pptx |>
      add_slide(index = 1, layout = "Title and Content", content(rnorm, ph = ph_body()), polish_error_continue = TRUE)
  })

  errors <- slide_errors(pptx)
  expect_equal(nrow(errors), 1L)
  expect_equal(errors$index, 1)
  ## No applicable polish method for object of class "function"
  expect_true(
    grepl("^Cannot polish content for.*documents[.]", rlang::cnd_header(errors$errors[[1]]))
  )

})

