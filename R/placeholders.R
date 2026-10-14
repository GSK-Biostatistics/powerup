#' Placeholder object
#'
#' Object to define placeholders.
#'
#' `ref_placeholder()` defines what logic to apply when figuring out which a
#' placeholder in a slide or layout to use to insert content.
#'
#' `new_placeholder()` defines what logic to use when creating a
#' new placeholder in a slide.
#'
#' `empty_placeholder()` indicates that the content
#' should not be added to the slide, and does not expect any content.
#'
#' @param label The placeholder label to select. `ref_placeholder` allows to
#'   pass a pattern to search with if label_match is set to "match".
#' @param label_match Use "match" if `label` is a regex pattern, or "exact"
#'   for exact match. Defaults to "exact".
#' @param label_from Which placeholder label should be used, the one listed in
#'   the "slide" or from the "layout". Generally new slides should use "layout",
#'   while updating a slide may use either. Listing both allows to
#'   check the first listed location then the other before declaring it cannot
#'   find it.
#' @param type The type of placeholder. Options are "body", "title", "ftr",
#'   "subTitle", "tbl", "chart", "img".
#'   `ref_placeholder()` allows for "any" in
#'   this position to allow for referencing any type of placeholder, or any
#'   combination of to be types to be passed. `new_placeholder()` allows only
#'   one.
#' @param tie_breaker Which pane to select when multiple are returned from label
#'   matching ("largest","left","right","top","bottom"). can pass multiple to
#'   clarify if there are ties remaining.
#' @param replace Identify whether to replace the existing placeholder or not if
#'   it exists on the slide. defaults to TRUE
#' @inheritParams rlang::args_error_context
#'
#' @returns A placeholder object
#'
#' @rdname placeholder
#'
#' @examples
#'
#' # reference placeholder, find the top-most placeholder in the slide or layout
#' # with the word "title" in the placeholder label where type is "title" and
#' # replace the contents when new values are inserted
#' ref_placeholder(
#'     label = "[Tt]itle",
#'     type = "title",
#'     tie_breaker = "top",
#'     label_match = "match",
#'     label_from = c("slide","layout"),
#'     replace = TRUE
#'     )
#'
#' # reference placeholder, find the the exact placeholder with the label "Content Placeholder 5"
#' # based on the template layout
#' ref_placeholder(
#'     label = "Content Placeholder 5",
#'     label_match = "exact",
#'     label_from = "layout"
#'     )
#'
#' # Create a new placeholder 20% down from the top of the slide, 10% off from the left side, and
#' # make it 10cm tall and 15cm wide
#' new_placeholder(
#'     x_offset = "10%",
#'     y_offset = "20%",
#'     height = "10cm",
#'     width = "15cm"
#'     )
#'
#' @export
ref_placeholder <- function(
    label = "",
    label_match = c("exact", "match"),
    label_from = c("slide","layout"),
    type = c("body", "title", "ctrTitle", "ftr", "subTitle", "tbl", "chart", "img", "any"),
    tie_breaker = c("largest", "smallest","left", "right", "top", "bottom"),
    replace = TRUE,
    error_call = current_env()
) {

  type <- arg_match(type, multiple = TRUE, error_call = error_call)
  label_from <- arg_match(label_from, multiple = TRUE, error_call = error_call)
  label_match <- arg_match(label_match, multiple = FALSE, error_call = error_call)
  tie_breaker <- arg_match(tie_breaker, multiple = TRUE, error_call = error_call)

  structure(
    list(
      type        = type,
      label       = label,
      label_from  = label_from,
      label_match = label_match,
      tie_breaker = tie_breaker,
      replace     = isTRUE(replace)
    ),
    class = c("existing_placeholder", "placeholder")
  )
}

#' @param x_offset `x` offset in centimeters (cm), inches (in), or percent(in) of slide width
#' @param y_offset `y` offset in centimeters, inches, or percent of slide height
#' @param width Width in centimeters, inches, or percent of slide width
#' @param height Height in centimeters, inches, or percent of slide height
#' @inheritParams rlang::args_error_context
#'
#' @rdname placeholder
#'
#' @export
new_placeholder <- function(
    type = c("body", "title", "ctrTitle", "ftr", "subTitle", "tbl", "chart","img"),
    x_offset = "10%",
    y_offset = "20%",
    width = "80%",
    height = "60%",
    label = "",
    error_call = current_env()
    ){

  type <- arg_match(type, error_call = error_call)
  stopifnot(is.character(label))

  structure(
    list(
      label    = label,
      type     = type,
      offx     = check_ph_units(x_offset),
      offy     = check_ph_units(y_offset),
      cx       = check_ph_units(width),
      cy       = check_ph_units(height)
    ),
    class = c("new_placeholder","placeholder")
  )

}

#' check the units input into new_placeholder and make sure they are within a reasonable
#' value.
#'
#' @noRd
check_ph_units <- function(x, error_call = caller_env(), name = deparse(substitute(x))){
  if (is.null(x)){
    cli_abort("Units for {.arg {name}} cannot be `NULL`.", call = error_call)
  }

  rx <- "^(\\d*(?:[.]\\d+)*)(%|in|cm)$"
  if (!grepl(rx, x)) {
    cli_abort(c(
      "Invalid value for {.arg {name}} unit: {.val {x}}.",
      i = "Only `%` (percent), `cm` (centimeters), or `in` (inches) are accepted."
      ), call = error_call)
  }

  unit <- gsub(rx, "\\2", x)
  x_val <- as.numeric(gsub(rx, "\\1", x))

  if (unit == "%"){
    if (x_val < 0 | x_val > 100){
      cli_abort(c(
        "Numeric value for {.arg {name}} must be between 0 and 100",
        x = "Provided value: {x_val}."
        ), call = error_call)
    }
  } else if(unit == "cm") {
    x <- as.character(to_inch(x_val))
  } else {
    x <- as.character(x_val)
  }

  x
}

convert_pct <- function(x, full) {
  if (grepl("%$", x)){
    x <- as.numeric(gsub("%", "", x)) / 100 * full
  }
  as.numeric(x)
}

generate_layout_ph_name <- function(ph, pptx, index){

  if(!is.null(ph$label)){
    if (!identical(ph$label, "")) {
      return(ph$label)
    }
  }

  type <- ph$type
  new_placeholder_num <- nrow(list_placeholders(pptx, index)) + 1

  glue("new_{type}_placeholder_{new_placeholder_num}")


}

#' Get the selection pane position information
#' @noRd
get_selection_pane_xfrm <- function(
    pptx,
    index,
    type = c("body", "title", "ctrTitle", "ftr", "subTitle", "tbl", "chart", "img", "dt", "any"),
    label = "[Pp]laceholder",
    label_match = c("exact","match"),
    label_from = c("slide","layout"),
    tie_breaker = "largest",
    replace = TRUE,
    ...,
    error_call = current_env()
) {
  check_dots_empty(call = error_call)

  # TODO: make it so that this is either "any" or a vector of the other ones
  type <- arg_match(type, multiple = TRUE, error_call = error_call)

  label_from <- arg_match(label_from, multiple = TRUE, error_call = error_call)
  label_match <- arg_match(label_match, error_call = error_call)

  xfrm_data <- read_one_slide_placeholders(pptx, index = index, error_call = error_call)
  layout_type_ph_xfrm_data <- filter_xfrm_data(xfrm_data, ref_ph_type = type, error_call = error_call)

  layout_type_label_ph_xfrm_data <- vector("list", length = length(label_from))
  names(layout_type_label_ph_xfrm_data) <- label_from

  for (label_location in label_from) {
    layout_type_label_ph_xfrm_data[[label_location]] <- filter_label(
      layout_type_ph_xfrm_data,
      label = label,
      label_location = label_location,
      label_match = label_match
    )
  }

  layout_type_label_ph_xfrm_data <- map(layout_type_label_ph_xfrm_data, function(x) {
    if (nrow(x) > 1) {
      x <- select_ph_tie_breaker(x, tie_breaker = tie_breaker)
    }
    x
  })

  if(replace && "slide" %in% names(layout_type_label_ph_xfrm_data)){
    layout_type_label_ph_xfrm_data <- layout_type_label_ph_xfrm_data[unique(c("slide", names(layout_type_label_ph_xfrm_data)))]
  }

  layout_type_label_ph_xfrm_data <- bind_rows(layout_type_label_ph_xfrm_data)

  if (nrow(layout_type_label_ph_xfrm_data) == 0) {
    abort_ph_xfrm_selection(
      xfrm_data = xfrm_data,
      label = label, label_match = label_match, label_from = label_from,
      index = index,
      error_call = error_call
    )
  }

  if (nrow(layout_type_label_ph_xfrm_data) > 1) {
    layout_type_label_ph_xfrm_data <- select_ph_tie_breaker(layout_type_label_ph_xfrm_data, tie_breaker = tie_breaker)
  }

  out <- layout_type_label_ph_xfrm_data
  out$replace <- replace && !is.na(out$slide_ph_id)
  out
}

filter_label <- function(data, label, label_location, label_match, error_call = caller_env()) {

  compare <- switch(label_match,
    match = function(x, y) grepl(y, x),
    exact = function(x, y) x == y
  )

  var_name <- switch(label_location,
    slide  = "slide_ph_name",
    layout = "layout_ph_name"
  )

  filter(data, compare(.data[[var_name]], label))
}

filter_xfrm_data <- function(data, ref_ph_type, error_call = caller_env()) {
  if (!"any" %in% ref_ph_type) {
    data <- filter(data, ph_type %in% ref_ph_type)
    if (nrow(data) == 0) {
      available <- unique(data$ph_type)
      cli_abort(c(
        "Filtering to keep only placeholders of type {.val {ref_ph_type}} results in no placeholders remaining.",
        i = "Review and confirm the following placeholder types: {.val {available}}."
      ), call = error_call)
    }
  }

  data
}

abort_ph_xfrm_selection <- function(xfrm_data, label, label_match, label_from, index, layout, error_call = caller_env()) {
  what <- ifelse(label_match == "match", "using the pattern", "for an exact match for")
  bullets <- "Unable to identify selection labels {what} `{label}`. "

  if ("slide" %in% label_from) {
    slide_phs <- setdiff(unique(xfrm_data$slide_ph_name), c(NA,""))
    if (length(slide_phs)) {
      bullets <- c(
        bullets,
        i = "Valid slide placeholder labels: {.val {slide_phs}}."
      )
    }
  }

  if ("layout" %in% label_from) {
    layout_phs <- setdiff(unique(xfrm_data$layout_ph_name), c(NA,""))
    if (length(layout_phs)) {
      bullets <- c(
        bullets,
        i = "Valid layout placeholder labels: {.val {layout_phs}}."
      )
    }
  }

  cli_abort(bullets, call = error_call)
}

#' Selecting an existing placeholder based on a tiebreaker logic
#'
#' @param df data.frame of placeholder data (ph_label, offx, offy, cx, cy)
#' @param tie_breaker what determines which ph to select? largest, smallest, most left, right, top or bottom?. Pass multiple to
#'   allow for multiple tie breakers.
#' @inheritParams rlang::args_error_context
#'
#' @noRd
select_ph_tie_breaker <- function(df, tie_breaker = c("largest", "smallest", "left", "right", "top", "bottom"), error_call = caller_env()){
  tie_breaker <- arg_match(tie_breaker, multiple = TRUE, error_call = error_call)
  tie_breaker_used <- tie_breaker[1]

  df <- df |>
    mutate(
      area       = as.numeric(round(cx,1)) * as.numeric(round(cy,1)),
      centroid_X = round(offx + (cx/2),1),
      centroid_y = round(offy + (cy/2),1)
    )

  df <- switch(
    tie_breaker_used,

    largest  = filter(df, area == max(area))             |> mutate(best = TRUE),
    smallest = filter(df, area == min(area))             |> mutate(best = TRUE),
    left     = filter(df, centroid_X == min(centroid_X)) |> mutate(best = offx == min(offx)),
    right    = filter(df, centroid_X == max(centroid_X)) |> mutate(best = offx == max(offx)),
    top      = filter(df, centroid_y == min(centroid_y)) |> mutate(best = offy == min(offy)),
    bottom   = filter(df, centroid_y == max(centroid_y)) |> mutate(best = offy == max(offy))
  )

  df <- select(df, -area, -centroid_X, -centroid_y, best)

  if (nrow(df) > 1){
    if (length(tie_breaker) > 1){
      # go to the next tiebreaker
      df <- df |>
        select(-best) |>
        select_ph_tie_breaker(tie_breaker = tie_breaker[-1], error_call = error_call)
    } else {
      df <- df |>
        filter(best == TRUE) |>
        slice(1) |>
        select(-best)
    }
  }else{
    df <- df |>
      select(-best)
  }



  df
}

#' Remove placeholder from a slide
#'
#' @param pptx A PowerPoint wrapped in a <pptx_container> object. see [load_pptx()]
#' @param ph_id placeholder id
#' @param index index of slide
#' @param verbose inform about the removed placeholders
#' @inheritParams rlang::args_error_context
#' 
#' @returns Returns the modified \code{pptx} object (of class \code{pptx_container}) with the placeholder removed from the slide.
#'
#' @examples
#' pptx <- load_pptx() |>
#'   add_slide(layout = "Title and Content", index = 1, content("hello", ph = ph_title()))
#'
#' ## remove the placeholder from the slide
#' pptx <- remove_slide_ph(pptx,
#'           index = 1,
#'           ph_id = read_slide_placeholders(pptx, index = 1)$slide_ph_id[1]
#'         )
#'
#' @export
remove_slide_ph <- function(pptx, ph_id, index, error_call = current_env(), verbose = getOption("powerup.verbose", default = FALSE)) {

  if (is.na(ph_id)) {
    cli_abort("Cannot remove a placeholder with {.code ph_id = NA}.", call = error_call)
  }

  slide <- get_presentation_slide(pptx, index = index, error_call = error_call)$get()

  placeholders <- read_slide_placeholders(pptx, index = index, only_slide = TRUE)

  node <- xml_find_all(slide, glue("p:cSld/p:spTree/*[*/p:cNvPr[@id='{ph_id}']]"))

  if (!length(node)) {
    if (nrow(placeholders) == 0L) {
      cli_abort(c(
        "No occupied placeholder on presentation {.val {pptx$name}} / slide {index}."
      ), call = error_call)
    } else {
      cli_abort(c(
        "Placeholder with id {.val {ph_id}} not found on presentation {.val {pptx$name}} / slide {index}.",
        i = "Occupied placeholder{?s}: {.val {placeholders$slide_ph_id}}."
      ), call = error_call)
    }
  }

  if (isTRUE(verbose)) {
    powerup_inform(c(
      "i" = "Removing placeholder {.val {ph_id}} from presentation {.val {pptx$name}} / slide {index}."
    ))
  }

  xml_remove(node)
  save_slides(pptx)
  increment_revision(pptx)
}

#' List the available placeholders in a slide or a given layout
#'
#' @param pptx A PowerPoint wrapped in a <pptx_container> object. see [load_pptx()]
#' @param index Slide index
#' @param layout the name of the layout in the PowerPoint. Overridden if index is provided
#' @param units "in" or "cm", what units should be used for the values presented
#'   (offsets, dimensions)
#' @param keep_all Keep all the placeholders (TRUE), or only the ons with a \<ph\> node (FALSE)
#' @inheritParams rlang::args_error_context
#'
#' @examples
#'
#' pptx <- example_pptx()
#'
#' # what are the available placeholders on the slides
#' list_placeholders(pptx, layout = "Two Content")
#' list_placeholders(pptx, index = 2)
#'
#' @return a `placeholder_tbl` object with the available placeholders in the slide or layout
#'
#' @export
list_placeholders <- function(pptx, index = NULL, layout = NULL, units = c("in","cm"), keep_all = FALSE, error_call = current_env()){
  # Check that layout is valid
  check_valid_layout_or_index(pptx, layout = layout, index = index, error_call = error_call)

  if (!is.null(index)){
    list_slide_placeholders(pptx, index = index, units = units, keep_all = keep_all, error_call = error_call)
  } else {
    list_layout_placeholders(pptx, layout = layout, units = units, keep_all = keep_all, error_call = error_call)
  }

}

list_slide_placeholders <- function(pptx, index, units = c("in", "cm"), keep_all = FALSE, error_call = caller_env()) {
  # extract placeholders present on the slide
  slide_placeholders <- read_slide_placeholders(pptx, index = index, only_slide = TRUE, error_call = error_call)
  if (!isTRUE(keep_all)) {
    slide_placeholders <- filter(slide_placeholders, !is.na(ph))
  }
  slide_placeholders <- slide_placeholders |>
    select(
      ph_label = "slide_ph_name", type = "ph_type",
      "offx", "offy", width = "cx", height = "cy", "layout_ph_name"
    ) |>
    mutate(origin = "slide") |>
    arrange(ph_label)

  # and then placeholders available in its layout
  layout <- get_layout_name(pptx, index, error_call = error_call)
  layout_placeholders <- read_layout_placeholders(pptx, layout = layout, error_call = error_call)
  if (!isTRUE(keep_all)) {
    layout_placeholders <- filter(layout_placeholders, !is.na(ph))
  }
  layout_placeholders <- layout_placeholders |>
    select(
      ph_label = "layout_ph_name", type = "ph_type",
      "offx", "offy", width = "cx", height = "cy"
    ) |>
    mutate(origin = "layout") |>
    anti_join(slide_placeholders, by = c("ph_label" = "layout_ph_name")) |>
    arrange(ph_label)

  placeholders <- bind_rows(slide_placeholders, layout_placeholders)

  description <- glue('Slide {index} with layout "{layout}"')
  new_placeholder_tbl(placeholders, units, layout, pptx, description = description, error_call = error_call)
}

list_layout_placeholders <- function(pptx, layout, units = c("in","cm"), keep_all = FALSE, error_call = caller_env()) {
  placeholders <- read_layout_placeholders(pptx, layout = layout, error_call = error_call)

  if (!isTRUE(keep_all)) {
    placeholders <- filter(placeholders, !is.na(ph))
  }

  placeholders <- placeholders |>
    select(
      ph_label = "layout_ph_name", type = "ph_type",
      "offx", "offy", width = "cx", height = "cy"
    ) |>
    mutate(origin = "layout") |>
    arrange(ph_label)

  description <- glue('Layout "{layout}"')
  new_placeholder_tbl(placeholders, units, layout, pptx, description = description, error_call = error_call)

}

new_placeholder_tbl <- function(placeholders, units = c("in", "cm"), layout, pptx, description = "", error_call = caller_env()) {
  units <- arg_match(units, error_call = error_call)

  dimensions <- officer::slide_size(get_rpptx(pptx))

  if (units == "cm"){
    placeholders <- placeholders |>
      mutate(
        across(c("offx", "offy", "width", "height"), to_cm)
      )

    dimensions$width <- to_cm(dimensions$width)
    dimensions$height <- to_cm(dimensions$height)
  }

  class(placeholders) <- c("placeholder_tbl", class(placeholders))
  attr(placeholders, "unit") <- units
  attr(placeholders, "layout") <- layout
  attr(placeholders, "dimensions") <- dimensions
  attr(placeholders, "description") <- description

  placeholders
}


#' @export
print.placeholder_tbl <- function(x, ...) {
  unit <- attr(x, "unit")
  layout <- attr(x, "layout")

  tbl <- mutate(
    x,
    x_start = format(offx, digits = 3),
    x_end   = format(offx + width, digits = 3),

    y_start = format(offy, digits = 3),
    y_end   = format(offy + height, digits = 3),

    x = glue("[{x_start} - {x_end}]"),
    y = glue("[{y_start} - {y_end}]")
  ) |>
    select("ph_label", "type",
           "x ({unit})" := "x",
           "y ({unit})" := "y",
           "origin")

  fmt <- format(tbl, n = NULL)

  output_content <- format(
    cli::col_silver(sub("origin", "", fmt[2]))
  )

  from_slide <- grep("slide $", fmt, value = TRUE)
  from_slide <- sub("slide $", "", from_slide)
  if (length(from_slide)) {
    output_content <- c(output_content, "",     cli_fmt(cli_rule("From slide")))
    output_content <- c(output_content, format(from_slide))
  }

  from_layout <- grep("layout$", fmt, value = TRUE)
  from_layout <- sub("layout$", "", from_layout)
  if (length(from_layout)) {
    output_content <- c(output_content, "",     cli_fmt(cli_rule("From layout {.val {layout}}")))
    output_content <- c(output_content, format(from_layout))
  }

  cat(output_content, sep = "\n")

  invisible(x)
}

#' @export
ggplot.placeholder_tbl <- function(data, ...) {

  slide_base <- ggplot2::ggplot() +
    ggplot2::aes(
      xmin = offx,
      ymin = offy,
      xmax = offx + width,
      ymax = offy + height,
      fill = ph_label,
    ) +
    ggplot2::xlim(0, attr(data, "dimensions")$width) +
    ggplot2::ylim(attr(data, "dimensions")$height, 0) +
    ggplot2::coord_fixed() +
    ggplot2::geom_rect(
      data = data.frame(
        offx = 0, width = attr(data, "dimensions")$width,
        offy = 0, height = attr(data, "dimensions")$height
      ),
      fill = NA,
      col = "black"
    ) +
    ggplot2::theme_void() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5)
    ) +
    ggplot2::labs(
      title = attr(data, "description")
    )

  estimated_area_sorted_data <- data |>
    mutate(area = width * height) |>
    arrange(dplyr::desc(area))

  ## add placeholders in size order so that the first ones are on top of the others
   slide_base <- slide_base +
      ggplot2::geom_rect(
        data = estimated_area_sorted_data,
        ggplot2::aes(xmin = offx, xmax = offx + width, ymin = offy, ymax = offy + height, fill = ph_label),
      ) +
      ggplot2::geom_text(
        data = estimated_area_sorted_data,
        ggplot2::aes(x = offx + width/2, y = offy + height/2, label = ph_label),
        color = "black",
        size = 3
      )

  slide_base

}

check_valid_layout_or_index <- function(pptx, layout = NULL, index = NULL, error_call = caller_env()) {
  if (is.null(layout) && is.null(index)) {
    layouts <- get_rpptx(pptx)$slideLayouts$names()
    size <- length(pptx)
    bullets <- c(
      "{.arg layout} or {.arg index} must be supplied.",
      i = "Presentation has {size} slide{?s}.",
      i = "Available layouts: {.val {layouts}}."
    )
    cli_abort(bullets, call = error_call)
  }

  if (!is.null(index) && !is.numeric(index)) {
    cli_abort("{.arg index} must be numeric, not {.obj_type_friendly {index}}", call = error_call)
  }
}

#' Get layout name of PowerPoint
#'
#' @param pptx PowerPoint file
#' @param index Slide number
#'
#' @noRd
get_layout_name <- function(pptx, index, error_call = caller_env()) {
  slide <- get_presentation_slide(pptx, index, error_call = error_call)
  layout_file_name <- slide$layout_name()

  layout_names <- get_rpptx(pptx)$slideLayouts$names()
  layout_names[[layout_file_name]]
}

#' Get names for all the the slides
#'
#' @inheritParams powerup::args_powerup
#' @inheritParams rlang::args_error_context
#' @return character vector of layout names
#' @noRd
get_layout_names <- function(pptx, error_call = current_env()) {
  out <- list_slides(pptx, error_call = error_call)$layout_name
  names(out) <- NULL
  out
}

#' Checks the given layout is valid
#'
#' @param pptx A PowerPoint wrapped in a <pptx_container> object. see [load_pptx()]
#' @param layout Type of layout to apply. Must match one of the available layouts or NULL.
#'
#' @noRd
check_layout <- function(pptx, layout, error_call = caller_env()){
  if (!is.null(layout)){
    layouts <- as.character(get_rpptx(pptx)$slideLayouts$names())
    if(!layout %in% layouts){
      cli_abort(c(
        "Invalid layout supplied {.val {layout}}.",
        i = "Please use one of {.val {layouts}}."
      ), call = error_call)
    }
  }

  layout
}
