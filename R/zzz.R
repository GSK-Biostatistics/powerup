#' @import rlang
#' @import cli
#' @import ggplot2
#' @import polish
#' @importFrom xml2 xml_add_child xml_find_first read_xml xml_find_all xml_name xml_child xml_attr xml_children write_xml `xml_attr<-` xml_remove xml_attrs
#' @importFrom tools file_ext
#' @importFrom purrr map map_chr walk map_dfr list_rbind map_int imap
#' @importFrom dplyr mutate left_join bind_rows select across case_when full_join na_if filter slice rename ends_with arrange anti_join nest_by pull summarise group_by everything pick n ungroup desc
#' @importFrom tibble tibble as_tibble
#' @importFrom utils capture.output str
#' @importFrom glue glue glue_collapse
#' @importFrom htmltools tag
NULL

#' @importFrom ggplot2 ggplot
#' @export
ggplot2::ggplot

utils::globalVariables(
  c(
    "cx", "cy", "cx.x", "cx.y", "cy.x", "cy.y",
    "offx", "offy", "offx.x", "offx.y", "offy.x", "offy.y",
    "name",
    "ph", "ph_label", "ph.x", "ph.y", "ph_type",
    "area",
    "centroid_X", "centroid_y",
    "best",
    "layout_file", "layout_name",

    "width", "height",

    "filename", "layout_ph_name", "type", "num", "slide_ph_name", "slide_index"
  )
)

#' Documentation anchor for powerup functions
#'
#' Use `@inheritParams powerup::args_powerup` to document `pptx` for your functions
#'
#' @param pptx A PowerPoint wrapped in a <pptx_container> object. see [load_pptx()]
#'
#' @rdname args_powerup
#' @usage N/A - This documentation anchor is not intended to be called directly.
#' @keywords internal
#' @noRd
NULL
