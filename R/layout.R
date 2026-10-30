
# read_slide_placeholders() -----------------------------------------------------

#' Read placeholders information from PowerPoint presentation
#'
#' @inheritParams read_slide
#' @param only_slide if TRUE only extract placeholders from the slide, i.e. not from its associated layout
#' @param only_layout if TRUE only extract placeholders from the layout, i.e. not occupied in the slide
#' @param keep_all if FALSE, only keep non missing placeholders
#'
#' @return
#' A tibble with columns describing the placeholders:
#'   \item{slide_index}{numeric; slide index}
#'   \item{slide_file}{character; basename of the slide file}
#'   \item{layout_file}{character; basename of the layout file}
#'   \item{layout_name}{character; name of the layout}
#'   \item{id}{character; placeholder id}
#'   \item{offx}{numeric; x offset in inches}
#'   \item{offy}{numeric; y offset in inches}
#'   \item{cx}{numeric; width in inches}
#'   \item{cy}{numeric; height in inches}
#'   \item{ph_type}{character; placeholder type}
#'   \item{ph}{character; placeholder XML node as glue object}
#'   \item{ph_id}{character; placeholder idx attribute}
#'   \item{slide_ph_name}{character; placeholder name from slide}
#'   \item{slide_ph_id}{character; placeholder id from slide}
#'   \item{layout_ph_name}{character; placeholder name from layout}
#'   \item{metadata}{list; metadata extracted from placeholder}
#'
#' The tibble has a \code{dimensions} attribute containing the slide size.
#'
#' @examples
#' ppt <- example_pptx()
#' read_slide_placeholders(ppt)
#' read_slide_placeholders(ppt, index = 1)
#' read_slide_placeholders(ppt, index = 1:2)
#'
#' read_slide_placeholders(ppt, only_slide = TRUE)
#' read_slide_placeholders(ppt, index = 2, only_slide = TRUE)
#'
#' @export
read_slide_placeholders <- function(pptx, index, only_slide = FALSE, only_layout = FALSE, keep_all = FALSE, error_call = current_env()) {
  parts <- read_slide_placeholders_parts(
    pptx,
    index = index, only_slide = only_slide, only_layout = only_layout, keep_all = keep_all, error_call = error_call
  )

  out <- list_rbind(parts, ptype = placeholders_df_ptype())
  attr(out, "dimensions") <- officer::slide_size(get_rpptx(pptx))
  out
}

read_slide_placeholders_parts <- function(pptx, index, only_slide = FALSE, only_layout = FALSE, keep_all = FALSE, error_call = caller_env()) {
  if (missing(index)) {
    index <- seq_len(length(pptx))
  }

  parts <- vector("list", length(index))
  for (i in seq_along(index)) {
    parts[[i]] <- withCallingHandlers(
      read_one_slide_placeholders(pptx, index[i], only_slide = only_slide, only_layout = only_layout, keep_all = keep_all),
      error = function(err) {
        cli_abort("Error getting placeholders for slide {index[i]}.", call = error_call, parent = err)
      }
    )
  }

  parts
}

placeholders_df_ptype <- function() {
  tibble::tibble(
    slide_index = numeric(0),
    slide_file = character(0),
    layout_file = character(0),
    layout_name = character(0),
    id = character(0),
    offx = numeric(0),
    offy = numeric(0),
    cx = numeric(0),
    cy = numeric(0),
    ph_type = character(0),
    ph = character(0) |> structure(class = c("glue", "character")),
    ph_id = character(0),
    slide_ph_name = character(0),
    slide_ph_id = character(0),
    layout_ph_name = character(0),
    metadata = list(0)
  )
}

# read_one_slide_placeholders() --------------------------------------------------

#' get placeholder information
#'
#' @noRd
read_one_slide_placeholders <- function(pptx, index, only_slide = FALSE, only_layout = FALSE, keep_all = FALSE, error_call = current_env()){
  df_layout <- layout_ph_df(pptx, index, error_call = error_call) |>
    replace_ph_id_na(prefix = "layout") |>
    mutate(layout_ph_name = make.unique(layout_ph_name))

  df_slide  <- slide_ph_df(pptx, index, error_call = error_call) |>
    replace_ph_id_na(prefix = "slide")

  if (only_slide) {
    out <- left_join(df_slide, df_layout, by = c("ph_type", "ph_id"))
  } else if(only_layout) {
    out <- full_join(df_slide, df_layout, by = c("ph_type", "ph_id"))
    out <- anti_join(out, df_slide, by = c("ph_type", "ph_id"))
  } else {
    out <- full_join(df_slide, df_layout, by = c("ph_type", "ph_id"))
    out <- filter(out, !(layout_ph_name %in% slide_ph_name & layout_ph_name != slide_ph_name & !is.na(layout_name)))
  }

  ## standardize off/c
  out <- out |>
    mutate(
      offx      = ifelse(!is.na(offx.x)    , offx.x    , offx.y),
      offy      = ifelse(!is.na(offy.x)    , offy.x    , offy.y),
      cx        = ifelse(!is.na(cx.x)      , cx.x      , cx.y),
      cy        = ifelse(!is.na(cy.x)      , cy.x      , cy.y),
      ph        = ifelse(!is.na(ph.x)      , ph.x      , ph.y),
    ) |>
    select(-ends_with(".y"), -ends_with(".x")) |>
    standardize_dimensions() |>
    mutate(
      slide_index = index,
      slide_file = basename(get_slide_file_name(pptx, index, error_call = error_call)),
      layout_file = basename(get_slide_layout_file_name(pptx, index, error_call = error_call))
    ) |>
    select(c(
      "slide_index", "slide_file", "layout_file", "layout_name",
      "id", "offx", "offy", "cx", "cy",
      "ph_type", "ph", "ph_id",
      "slide_ph_name", "slide_ph_id", "layout_ph_name", "metadata"
    ))
  class(out$ph) <- "glue"

  if (!isTRUE(keep_all)) {
    out <- filter(out, !is.na(ph))
  }

  # restore NA
  out$ph_id[grepl("_", out$ph_id)] <- NA_character_

  out
}

replace_ph_id_na <- function(data, prefix = "layout") {
  na <- which(is.na(data$ph_id))
  data$ph_id[na] <- paste0(prefix, "_", seq_along(na))
  data
}

# read_layout_placeholders() ----------------------------------------------

#' Read layout placeholders
#'
#' @param layout layout
#' @param keep_all if FALSE, only keep non missing placeholders
#' @inheritParams read_slide_placeholders
#' @inheritParams rlang::args_error_context
#'
#' @return
#' A tibble with columns describing the layout placeholders:
#'   \item{layout_file}{character; basename of the layout file}
#'   \item{layout_name}{character; name of the layout}
#'   \item{id}{character; placeholder id}
#'   \item{offx}{numeric; x offset in inches}
#'   \item{offy}{numeric; y offset in inches}
#'   \item{cx}{numeric; width in inches}
#'   \item{cy}{numeric; height in inches}
#'   \item{ph_type}{character; placeholder type}
#'   \item{ph}{character; placeholder XML node as glue object}
#'   \item{ph_id}{character; placeholder idx attribute}
#'   \item{layout_ph_name}{character; placeholder name}
#'
#' The tibble has a \code{dimensions} attribute containing the slide size.
#'
#' @examples
#'
#' pptx <- example_pptx()
#' read_layout_placeholders(pptx, layout = "Title Slide")
#' 
#'
#' @export
read_layout_placeholders <- function(pptx, layout, keep_all = FALSE, error_call = current_env()) {
  if (!missing(layout)) {
    check_layout(pptx, layout, error_call = error_call)
  }

  data <- get_rpptx(pptx)$slideLayouts$get_xfrm_data() |>
    as_tibble() |>
    mutate(
      ph_id = map_chr(ph, extract_ph_id),
      layout_file = match_layout_file(name, pptx)
    ) |>
    select(
      "layout_file", layout_name = "name",
      "id", "offx", "offy", "cx", "cy",
      ph_type = "type", "ph", "ph_id",
      layout_ph_name = "ph_label"
    ) |>
    standardize_dimensions() |>
    arrange(layout_file)

  if (!isTRUE(keep_all)) {
    data <- filter(data, !is.na(ph))
  }
  class(data$ph) <- "glue"

  if (!missing(layout)) {
    data <- filter(data, layout_name == layout) |>
      mutate(layout_ph_name = make.unique(layout_ph_name))
  }

  attr(data, "dimensions") <- officer::slide_size(get_rpptx(pptx))

  data
}

standardize_dimensions <- function(data) {
  mutate(data,
    across(c("offx", "offy", "cx", "cy"), function(x) as.numeric(x) / 914400)
  )
}

extract_ph_id <- function(x) {
  if (!is.na(x)) {
    as_xml_pptx(x) |> xml_attr_or_na("idx")
  } else {
    NA
  }
}

match_layout_file <- function(name, pptx) {
  layouts <- get_rpptx(pptx)$slideLayouts$names()
  pos <- match(name, layouts)
  names(layouts)[pos]
}

# slide_ph_df() -----------------------------------------------------------

slide_ph_df <- function(pptx, index, error_call = caller_env()) {
  slide_xml <- read_slide(pptx, index, error_call = error_call)

  out <- bind_rows(
    slide_ph_df_pic(slide_xml, error_call = error_call),
    slide_ph_df_sp(slide_xml, error_call = error_call),
    slide_ph_ptype()
  )

  class(out$ph) <- "glue"

  out
}

slide_ph_df_pic <- function(slide_xml, error_call = caller_env()) {
  xpath <- "p:cSld/p:spTree/*[self::p:graphicFrame or self::p:pic]"
  map(xml_find_all(slide_xml, xpath), function(x) {
    node_name <- xml_name(x)
    ph_node <- xml_find_all(x, ".//p:ph")
    if (identical(as.character(ph_node), character(0))){
      ph_node <- as_xml_node("<p:ph/>")
    }

    cNvPr <- xml_find_all(x, ".//p:cNvPr")
    tibble(
      slide_ph_name = xml_attr(cNvPr, "name"),
      slide_ph_id   = xml_attr(cNvPr, "id"),
      ph_type       = if (node_name == "graphicFrame") "body" else "img",
      ph_id         = ph_node    |> xml_attr_or_na("idx"),
      !!!extract_dimensions(x),
      ph            = ph_node    |> as.character() ,
      metadata      = list(extract_metadata(x))
    )

  })
}

slide_ph_df_sp <- function(slide_xml, error_call = caller_env()) {
  xpath <- "p:cSld/p:spTree/*[self::p:cxnSp or self::p:sp or self::p:grpSp]"
  map(xml_find_all(slide_xml, xpath), function(x) {
    if(xml_name(x) == "grpSp"){
      ph_node <- as_xml_node("<p:ph type='ph_group'/>")
      cNvPr <- xml_find_all(x, ".//p:nvGrpSpPr//p:cNvPr") ## just use the nvGrpSpPr
    }else{
      ph_node <- xml_find_all(xml_child(x), ".//p:ph")
      cNvPr <- xml_find_all(xml_child(x), ".//p:cNvPr")
    }

    tibble(
      slide_ph_name = xml_attr(cNvPr, "name"),
      slide_ph_id   = xml_attr(cNvPr, "id"),
      ph_type       = ph_node |> xml_attr("type") |> na_sub("body"),
      ph_id         = ph_node |> xml_attr("idx"),
      !!!extract_dimensions(x),
      ph            = ph_node |> as.character(),
      metadata      = list(extract_metadata(x))
    )
  })
}

extract_dimensions <- function(x) {
  metadata <- extract_metadata(x)

  if ("a:xfrm/a:off/@x" %in% names(metadata)) {
    # first look in the metadata
    offx  <- as.numeric(metadata[["a:xfrm/a:off/@x"]])
    offy  <- as.numeric(metadata[["a:xfrm/a:off/@y"]])
    cx <- as.numeric(metadata[["a:xfrm/a:ext/@cx"]])
    cy <- as.numeric(metadata[["a:xfrm/a:ext/@cy"]])
  } else {
    # fallback to the xfrm node
    a_off <- xml_find_all(x, ".//p:xfrm//a:off")
    a_ext <- xml_find_all(x, ".//p:xfrm//a:ext")

    offx  <- as.numeric(xml_attr_or_na(a_off, "x"))
    offy  <- as.numeric(xml_attr_or_na(a_off, "y"))
    cx <- as.numeric(xml_attr_or_na(a_ext, "cx"))
    cy <- as.numeric(xml_attr_or_na(a_ext, "cy"))
  }

  list(`offx` = offx, `offy` = offy, `cx` = cx, `cy` = cy)
}


slide_ph_ptype <- function() {
  tibble(
    slide_ph_name = character(),
    slide_ph_id = character(),
    ph_type = character(),
    ph_id = character(),
    offx = numeric(),
    offy = numeric(),
    cx = numeric(),
    cy = numeric(),
    ph = character() |> structure(class = c("glue", "character")),
    metadata = list()
  )
}

extract_metadata <- function(node) {
  properties <- xml_find_first(node, ".//p:extLst/p:ext/custom:meta", ns = polish::xml_nodeset_ns_spec("pptx")) |>
    xml_find_all(".//custom:property",ns = polish::xml_nodeset_ns_spec("pptx"))
  names  <- map_chr(properties, xml_attr, attr = "name")
  values <- map_chr(properties, xml_attr, attr = "value")
  names(values) <- names
  values
}

# layout_ph_df() ----------------------------------------------------------

layout_ph_df <- function(pptx, index, error_call = caller_env()) {
  layout_xml <- read_slide_layout(pptx, index)
  layout_sp  <- xml_find_all(layout_xml, ".//p:sp")

  layout_data <- map_dfr(layout_sp, \(node) {
    cNvPr <- xml_find_first(node, ".//p:cNvPr")
    ph    <- xml_find_first(node, ".//p:ph")

    list(
      layout_ph_name = xml_attr(cNvPr, "name"),
      ph_type        = xml_attr(ph   , "type") |> na_sub("body"),
      ph_id          = xml_attr(ph   , "idx" ),
      id             = xml_attr(cNvPr, "id")
    )
  })

  slide <- get_presentation_slide(pptx, index, error_call = error_call)

  slide_xfrm <- slide$get_xfrm()
  slide_data <- select(slide_xfrm,
    c("id", "ph_label", "offx", "offy", "cx", "cy", "ph")
  ) |> mutate(id = as.character(.data$id))

  class(slide_data$ph) <- "glue"

  out <- left_join(layout_data, slide_data,
    by = c(layout_ph_name = "ph_label", id = "id")
  )

  layout_name <- slide$layout_name()
  mutate(
    out,
    layout_name  = get_rpptx(pptx)$slideLayouts$names()[layout_name], .before = 1
  )
}

layout_ph_ptype <- function() {
  tibble(
    layout_name = character(0),
    layout_ph_name = character(0),
    ph_type = character(0),
    ph_id = character(0),
    id = character(0),
    offx = numeric(0),
    offy = numeric(0),
    cx = numeric(0),
    cy = numeric(0),
    ph = character(0) |> structure(class = c("glue", "character"))
  )
}
