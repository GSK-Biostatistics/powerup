#' Read a single slide as xml
#'
#' @param pptx A PowerPoint wrapped in a <pptx_container> object. see [load_pptx()]
#' @param index slide index
#' @inheritParams rlang::args_error_context
#'
#' @return The slide, as read by [xml2::read_xml]
#'
#' @examples
#' ppt <- example_pptx()
#' read_slide(ppt, index = 1)
#'
#'
#'
#' @export
read_slide <- function(pptx, index, error_call = current_env()) {
  read_xml(
    get_slide_file_name(pptx, index, error_call = error_call)
  )
}

#' Read the layout for a given slide
#'
#' @inheritParams read_slide
#'
#' @return The slide layout, as read by [xml2::read_xml]
#'
#' @noRd
read_slide_layout <- function(pptx, index, error_call = current_env()) {
  read_xml(get_slide_layout_file_name(pptx, index, error_call = error_call))
}

#' Get the file name for a given slide
#'
#' @param pptx A PowerPoint wrapped in a <pptx_container> object. see [load_pptx()]
#' @inheritParams rlang::args_error_context
#' @param index slide index
#'
#' @examples
#' pptx <- example_pptx()
#' get_slide_file_name(pptx, index = 1)
#'
#' @return The file name for the slide, as a character string
#'
#' @export
get_slide_file_name <- function(pptx, index, error_call = current_env()) {
  slide <- get_presentation_slide(pptx, index = index, error_call = error_call)
  slide$file_name()
}

get_slide_layout_file_name <- function(pptx, index, error_call = current_env()) {
  slide <- get_presentation_slide(pptx, index, error_call = error_call)

  file.path(dirname(slide$file_name()), slide$get_metadata()$layout_file)
}

check_slide_index <- function(pptx, index, error_call = caller_env()) {
  n <- length(pptx)
  if (index > n || index <= 0) {
    bullets <- c(
      "{.arg index} is out of bounds: {index}.",
      i = "Presentation has {n} slide{?s}."
    )
    cli_abort(bullets, call = error_call)
  }
}

get_presentation_slide <- function(pptx, index, error_call = caller_env()) {
  check_slide_index(pptx, index, error_call = error_call)

  ppt <- get_rpptx(pptx, error_call = error_call)

  slide_name  <- basename(ppt$presentation$slide_data()$target)[index]
  slide_index <- ppt$slide$slide_index(slide_name)
  ppt$slide$get_slide(slide_index)
}

