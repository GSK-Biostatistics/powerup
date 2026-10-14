#' @title Working with Slides
#'
#' @description `add_slide()` Adds a new slide at a specified position, and
#' populate it with content from `...`.
#'
#' `update_slide()` updates an existing slide from a specific index and populate
#' it with content from `...`.
#'
#' `move_slide()` moves the slide from one index to another.
#'
#' `delete_slide()` deletes the slide based on the index.
#'
#'
#' @param pptx A PowerPoint wrapped in a <pptx_container> object. see [load_pptx()]
#' @param layout slide layout to use when creating a slide in `add_slide()`
#' @param ... content objects created with [content()]
#' @param index slide index. By default `add_slide()` creates a new slide at the
#'   end of the slide deck.
#' @param transition Defines the type of transition to use when moving to this slide. See `?slide_transitions` to see viable values.
#' @param to new index to move the slide to
#'
#' @param polish_error_continue Boolean indicating if when an error is throwing
#'   in either polishing or converting the placeholder if it should be
#'   propagated as an error (FALSE) or just inform the user and continue (TRUE).
#'   Defaults to TRUE.
#'
#' @inheritParams rlang::args_error_context
#' @param verbose if TRUE, some information is [cli::cli_inform()]ed along the
#'   way
#'
#' @examples
#'
#' library(powerup)
#'
#' ## Create a new presentation
#' ppt <- load_pptx()
#'
#' ## adding new slides
#' ppt <- ppt |>
#'   ## add first slide with content in title
#'   add_slide(layout = "Title and Content",
#'     content("hello world", ph = ph_title())
#'   ) |>
#'   ## add another slide with nothing on it yet
#'   add_slide(layout = "Title and Content") |>
#'   ## slide added at index 2 with content in title and body
#'   add_slide(layout = "Title and Content",
#'     index = 2,
#'     content("Hello World", ph = ph_title()),
#'     content("This is a body", ph = ph_body())
#'   )
#'
#' ## updating an existing slide wit new content
#' ppt <- ppt |>
#'    update_slide(index = 1,
#'      content("This placeholder now has a value", ph = ph_body())
#'    )
#'
#' ## moving a slide from index 2 to index 1
#' ppt <- ppt |>
#'    move_slide(index = 2, to = 1)
#'
#' ## deleting a slide at index 3
#' ppt <- ppt |>
#'    delete_slide(index = 3)
#'
#' @return a `pptx_container` object with the slide added, updated, moved, or deleted
#'
#' @export
add_slide <- function(pptx, layout, ..., index, transition = NULL, polish_error_continue = TRUE, error_call = current_env()) {
  # check index and layout
  index <- check_new_slide_index(index, pptx, error_call = error_call)
  layout <- check_slide_layout(pptx, layout, index = index, error_call = error_call)

  # make the slide
  pptx <- make_new_slide(pptx, index = index, layout = layout)

  # and update it with ...
  tryCatch({
    pptx <- update_slide(pptx = pptx, index = index, transition = transition,
      polish_error_continue = polish_error_continue,
      error_call = error_call,
      ...
    )
  }, error = function(e) {
    officer::remove_slide(pptx$rpptx, index)
    cli_abort("Failed to add slide {index}.", parent = e, call = error_call)
  })

  save_slides(pptx)
}

check_slide_layout <- function(pptx, layout, index, error_call = caller_env()) {
  if (missing(layout)) {
    suggestion <- default_slide_layout(pptx, index)$layout
    bullets <- c(
      "The {.arg layout} argument is mandatory.",
      i  = "The suggested layout for index {index} is {.val {suggestion}}.",
      i = "Use {.fn powerup::list_layouts} to see the available layouts."
    )
    cli::cli_abort(bullets, call = error_call)
  }
  layout
}

check_new_slide_index <- function(index, pptx, error_call = caller_env()) {
  new_slide_index <- new_slide_index(pptx)
  if (missing(index)) {
    return(new_slide_index)
  }

  if (index < 1 || index > new_slide_index) {
    cli_abort(c(
      "Invalid {.arg index} ({index}) for new slide in {.val {pptx$name}} presentation.",
      i = "{.arg index} must be between 1 and {new_slide_index}."
    ))
  }

  index
}

new_slide_index <- function(pptx){
  length(pptx$rpptx) + 1
}

slide_layout <- function(layout, master){
 structure(
    list(
      layout = layout,
      master = master
    ),
    class = "slide_layout"
  )
}

as_slide_layout <- function(layout, pptx, error_call = caller_env()){
  if (inherits(layout, "slide_layout")) {
    return(layout)
  }

  deck_styling <- pptx$rpptx$slideLayouts$get_metadata()
  candidates <- unique(deck_styling$name)

  if (!is.character(layout) || !layout %in% candidates){
    cli_abort(c(
      "Layout {.val {layout}} not found in presentation {.val {pptx$name}}.",
      i = "{.arg layout} must be one of {.val {candidates}}.",
      i = "Run {.fn powerup::list_layouts} for more information about each available layout."
    ), call = error_call)
  }

  prev_layout_def <- deck_styling[deck_styling$name == layout,][1,]
  slide_layout(
    layout = prev_layout_def$name,
    master = prev_layout_def$master_name
  )
}

make_new_slide <- function(pptx, index, layout, error_call = caller_env()){
  # index of slide before
  if (index <= 1){
    index <- 1
  } else if (index > new_slide_index(pptx)){
    index <- new_slide_index(pptx)
  }

  layout <- as_slide_layout(layout, pptx, error_call = error_call)

  pptx$rpptx <- officer::add_slide(pptx$rpptx, layout = layout$layout, master = layout$master)
  pptx$rpptx <- officer::move_slide(pptx$rpptx, index = length(pptx$rpptx), to = index)

  increment_revision(pptx)
}

default_slide_layout <- function(pptx, index){
  ## get the index of slide before
  if (index <= 1) {
    index <- 1
  } else if (index <= new_slide_index(pptx)){
    index <- index - 1
  } else {
    index <- length(pptx$rpptx)
  }

  deck_styling <- pptx$rpptx$slideLayouts$get_metadata()
  if (length(pptx$rpptx) > 0) {
    prev_slide <- get_presentation_slide(pptx, index)
    prev_slide_filename <- basename(prev_slide$get_metadata()$layout_file)
    prev_layout_def <- deck_styling[deck_styling$filename == prev_slide_filename,]
  } else {
    prev_layout_def <- deck_styling[1,]
  }

  slide_layout(
    layout = prev_layout_def$name,
    master = prev_layout_def$master_name
  )
}
