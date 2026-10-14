# make_ph_shape() ----------------------------------------------------

make_ph_shape <- function(ph, pptx){

  label = ifelse(
    na_sub(ph$slide_ph_name, "") == "",
    ph$layout_ph_name,
    ph$slide_ph_name
  )

  ph_loc <- officer::ph_location(
    newlabel = label,
    type     = ph$type,
    left     = ph$offx,
    top      = ph$offy,
    width    = ph$cx,
    height   = ph$cy
  )

  ## post-process ph
  type_col <- ifelse("type" %in% names(ph),"type","ph_type")
  ph_node <-  as_xml_node(ph$ph)
  xml_attr(ph_node,"type") <- ph[[type_col]]
  if(!is.na(ph$slide_ph_id)){
    xml_attr(ph_node,"idx") <- ph$slide_ph_id
  }
  ph_loc$ph <- ph_node |> as.character()

  ## fortify location
  location <- officer::fortify_location(ph_loc, doc = get_rpptx(pptx))

  officer::shape_properties_tags(
    left   = location$left,
    top    = location$top,
    width  = location$width,
    height = location$height,
    label  = location$ph_label,
    ph     = location$ph,
    bg     = location$bg,
    ln     = location$ln,
    geom   = location$geom
  )

}

# process_placeholder() ---------------------------------------------------

#' Internal method for processing placeholder requests
#'
#' @param ph placeholder
#' @param pptx A PowerPoint wrapped in a <pptx_container> object. see [load_pptx()]
#' @param index Slide number
#' @inheritParams rlang::args_dots_empty
#' @inheritParams rlang::args_error_context
#' @noRd
process_placeholder <- function(ph, pptx, index, ..., error_call = current_env()){
  UseMethod("process_placeholder")
}

try_process_placeholder <- function(ph, pptx, index, ..., error_call = current_env()) {
  check_dots_empty(call = error_call)

  withCallingHandlers({
    process_placeholder(ph, pptx, index, ...)
  }, error = function(e) {
    cli_abort(
      "Failed to process placeholder.",
      parent = e, class = "powerup_polish_ph_failure", call = error_call
    )
  })
}

#' @export
process_placeholder.existing_placeholder <- function(ph, pptx, index, ..., error_call = current_env()){
  get_selection_pane_xfrm(
    pptx        = pptx,
    index       = index,
    type        = ph$type,
    label       = ph$label,
    label_match = ph$label_match,
    label_from  = ph$label_from,
    tie_breaker = ph$tie_breaker,
    replace     = ph$replace,
    error_call  = error_call
  )
}

#' @export
process_placeholder.new_placeholder <- function(ph, pptx, index, ..., error_call = current_env()){
  check_dots_empty(call = error_call)

  slide_dims <- officer::slide_size(get_rpptx(pptx))
  ph$offx <- convert_pct(ph$offx, slide_dims$width)
  ph$offy <- convert_pct(ph$offy, slide_dims$height)

  ph$cx   <- convert_pct(ph$cx  , slide_dims$width)
  ph$cy   <- convert_pct(ph$cy  , slide_dims$height)

  ph$layout_ph_name <- generate_layout_ph_name(ph, pptx, index)

  ph_node <-  as_xml_node(ph$ph %||% "<p:ph/>")
  xml_attr(ph_node, "type") <- ph$type

  list(
    type           = ph$type,
    slide_ph_name  = ph$label,
    slide_ph_id    = NA,
    layout_ph_name = ph$layout_ph_name,
    offx           = ph$offx,
    offy           = ph$offy,
    cx             = ph$cx,
    cy             = ph$cy,
    replace        = FALSE,
    ph             = as.character(ph_node)
  )
}

#' @export
process_placeholder.templated_placeholder <- function(ph, pptx, index, ... , error_call = current_env()){
  check_dots_empty(call = error_call)

  tryCatch({
    process_placeholder(ph[["preferred"]], pptx, index, ..., error_call = error_call)
  }, error = function(e){
    process_placeholder(ph[["fallback"]], pptx, index, ..., error_call = error_call)
  })
}
