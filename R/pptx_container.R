#' Load/Save a PowerPoint file
#'
#' @inheritParams officer::read_pptx
#' @param path output path of file to be saved
#' @param name name of the file
#'
#' @param pptx A PowerPoint wrapped in a <pptx_container> object. see [load_pptx()]
#' @inheritParams rlang::args_error_context
#'
#' @return `load_pptx()` returns a new `pptx_container` object that wraps objects
#'  created by [officer::read_pptx()] with custom functionality for powerup.
#'
#' @examples
#'
#' pptx <- load_pptx(system.file("ref_files/standard_powerpoint.pptx", package = "powerup"))
#'
#' pptx2<- load_pptx()
#'
#' @rdname pptx_container
#' @export
load_pptx <- function(path = NULL, name){
  rpptx <- officer::read_pptx(path = path)
  if (missing(name)) {
    if (is.null(path)) {
      name <- ""
    } else {
      name <- basename(path)
    }
  }
  new_pptx_container(rpptx, name = name)
}

new_pptx_container <- function(pptx, name, error_call = caller_env()) {
  errors_env <- new.env(parent = emptyenv())
  errors_env$data <- tibble(index = integer(), errors = list())

  structure(
    list(rpptx = pptx, revision = 0, name = name, errors = errors_env),
    class = "pptx_container"
  )
}

increment_revision <- function(pptx, verbose = getOption("powerup.verbose", default = FALSE)) {
  pptx$revision <- pptx$revision + 1L
  if (isTRUE(verbose)) {
    filename <- pptx$rpptx$presentation$file_name()
    revision <- pptx$revision
    powerup_inform(c(
      v = "Updated revision to {revision} for presentation {.file {filename}}."
    ))
  }
  pptx
}

add_pptx_error <- function(pptx, index = NA_integer_, error = NULL) {
  pptx$errors$data <- dplyr::bind_rows(pptx$errors$data, tibble(index = index, errors = list(error)))
  pptx
}

remove_pptx_error <- function(pptx, index = NA_integer_) {
  pptx$errors$data <- dplyr::filter(pptx$errors$data, !.data$index %in% index)
  pptx
}

#' @details
#' `slide_errors()` Extract a tibble of errors that occurred when adding and updating slides
#'
#' @rdname pptx_container
#' @export
slide_errors <- function(pptx) {
  pptx$errors$data
}

#' @export
print.pptx_container <- function(x, ...) {
  cli_text("{.cls pptx_container} with {length(x)} slide{?s}.")

  layouts <- x$rpptx$slideLayouts$names()
  powerup_inform(c(
    i = "Available layouts: {.val {layouts}}.",
    i = "Use {.code list_placeholders(index = )} or {.code list_placeholders(layout = )} to get information about available placeholders",
    i = "Use {.fn powerup::add_slide} or {.fn powerup::update_slide} to add content to new or existing slides"
  ))

  invisible(x)
}

#' @export
length.pptx_container <- function(x) {
  length(x$rpptx)
}

#' @rdname pptx_container
#' @export
save_pptx <- function(pptx, path, error_call = current_env()){
  check_extension(path, "pptx", error_call = error_call)
  check_pptx(pptx, error_call = error_call)

  print(pptx$rpptx, target = path)

  temp_pptx_unzip <- tempfile()
  officer::unpack_folder(file = path, temp_pptx_unzip)

  check_content_types(temp_pptx_unzip)

  officer::pack_folder(temp_pptx_unzip, path)
  invisible(path)
}

save_slides <- function(pptx, error_call = caller_env()) {
  get_rpptx(pptx, error_call = error_call)$slide$save_slides()
  invisible(pptx)
}

get_rpptx <- function(pptx, error_call = caller_env()) {
  check_pptx(pptx, error_call = error_call)$rpptx
}

check_pptx <- function(pptx, error_call = caller_env()) {
  if (!inherits(pptx, "pptx_container")) {
    cli_abort("{.arg pptx} must be a {.cls pptx_container}, not {.obj_type_friendly {pptx}}.", call = error_call)
  }

  invisible(pptx)
}

check_content_types <- function(dir){

  ct_path <- file.path(dir, "[Content_Types].xml")
  content_types_xml <- read_xml(ct_path)

  content_types_xml |>
    xml_children() |>
    walk(function(x) {
      if (xml_name(x) == "Override") {
        file <- xml_attr(x, "PartName")
        if (identical(tolower(file_ext(file)), "rtf")) {
          xml_attr(x, "ContentType") <- "application/rtf"
        }
        if (identical(tolower(file_ext(file)), "html")) {
          xml_attr(x, "ContentType") <- "text/html"
        }
      }
    })

  write_xml(content_types_xml, ct_path)

}

#' @rdname pptx_container
#' @export
example_pptx <- function() {

  df <- data.frame(x = 1:3, y = 1:3)

  ppt <- officer::read_pptx() |>
    officer::add_slide(layout = "Title and Content") |>
    officer::add_slide(layout = "Two Content") |>
    officer::add_slide(layout = "Comparison") |>
    officer::on_slide(1) |>
    officer::ph_with(
      value = df,
      location = officer::ph_location_type("body")) |>
    officer::on_slide(2) |>
    officer::ph_with(
      value = df,
      location = officer::ph_location_left("my new left label")) |>
    officer::ph_with(
      value = df,
      location = officer::ph_location_right("my new right label"))

  ppt$slide$save_slides()

  new_pptx_container(ppt, name = "powerup-example.pptx")
}
