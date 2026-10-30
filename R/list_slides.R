#' List slides
#'
#' @param pptx A PowerPoint wrapped in a <pptx_container> object. see [load_pptx()]
#' @inheritParams rlang::args_error_context
#' @param keep_all if FALSE, only keep non missing placeholders
#'
#' @return
#' A tibble with information about the slides
#'
#' @examples
#' list_slides(load_pptx())
#'
#' @export
list_slides <- function(pptx, keep_all = FALSE, error_call = current_env()) {
  slide_metadata <- get_rpptx(pptx, error_call = error_call)$slideLayouts$get_metadata()
  data <- tibble(
    slide_index = seq_len(length(pptx)),
    slide_file  = map_chr(slide_index, \(i) basename(get_slide_file_name(pptx, index = i))),
    layout_name = map_chr(slide_index, \(i){
      layout_file <- get_presentation_slide(pptx, index = i)$layout_name()
      slide_metadata$name[slide_metadata$filename == layout_file]
    })
  )

  parts <- read_slide_placeholders_parts(pptx, keep_all = keep_all, error_call = error_call)
  data$slide_ph <- map_chr(parts, \(part) {
    glue_collapse(part$slide_ph_name[!is.na(part$slide_ph_name)], sep = ", ")
  })
  data$layout_ph <- map_chr(parts, \(part) {
    summary_placeholder_name(part$layout_ph_name)
  })
  data$n_slide_ph <- map_int(parts, \(part) {
    sum(!is.na(part$slide_ph_name))
  })

  data
}
