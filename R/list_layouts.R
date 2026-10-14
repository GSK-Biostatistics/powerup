#' List layouts
#'
#' @param pptx A PowerPoint wrapped in a <pptx_container> object. see [load_pptx()]
#' @inheritParams rlang::args_error_context
#'
#' @return
#' A tibble with information about the layouts
#'
#' @examples
#' list_layouts(load_pptx())
#'
#' @export
list_layouts <- function(pptx, error_call = current_env()) {
  layouts <- get_rpptx(pptx, error_call = error_call)$slideLayouts$get_metadata()

  # arrange by filename, i.e. the number in slideLayout(1..).xml
  layouts <- as_tibble(layouts) |>
    arrange(
      as.numeric(gsub("[^[:digit:]]", "", filename))
    ) |>
    select(name, filename)

  placeholders <- read_layout_placeholders(pptx, error_call = current_env()) |>
    arrange(case_when(
        grepl("^Title", layout_ph_name)    ~ 1,
        grepl("^Subtitle", layout_ph_name) ~ 2,
        grepl("^Text", layout_ph_name)     ~ 3,
        TRUE                               ~ 4
      ),
      offy, offx
    ) |>
    group_by(name = layout_name)|>
    summarise(
      placeholders_data        = list(pick(everything())),
      placeholders_count       = n(),
      placeholders_summary     = summary_placeholder_name(layout_ph_name)
    ) |>
    select("name", "placeholders_count", "placeholders_summary", "placeholders_data")

  left_join(layouts, placeholders, by = "name")

}

summary_placeholder_name <- function(name) {
  rx <- "^(.*) ([[:digit:]]+[.]?[[:digit:]]*)$"
  name <- name[!is.na(name)]

  tibble(
      type = sub(rx, "\\1", name),
      num  = as.numeric(sub(rx, "\\2", name))
    ) |>
    group_by(type) |>
    summarise(text = paste0(type[1], " (", paste0(sort(unique(num)), collapse = ", "), ")")) |>
    arrange(
      case_when(
        grepl("^Title"   , text) ~ 1,
        grepl("^Subtitle", text) ~ 2,
        grepl("^Text"    , text) ~ 3,
        TRUE                     ~ 4
      )
    ) |>
    pull("text") |>
    paste0(collapse = ", ")

}
