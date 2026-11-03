#' Preview a powerup PPTX
#'
#' Renders a `pptx_container` (or a path to a `.pptx` file) as an interactive
#' slide viewer htmlwidget. Uses PptxViewJS (bundled offline; no internet
#' connection required).
#'
#' @param pptx A `pptx_container` object or a file path to a `.pptx` file.
#' @param slide Integer. Which slide to show first (1-based). Default `1`.
#' @param view Logical. If `TRUE`, displays the widget (see `launch.browser`).
#'   If `FALSE`, only returns the widget. Defaults to `rlang::is_interactive()`.
#' @param launch.browser Where to display the widget when `view = TRUE`. If
#'   `FALSE` (default), the IDE Viewer pane is used (falling back to the
#'   browser if there is no viewer). If `TRUE`, the system default browser is
#'   used. May also be a function taking a file path or URL, as in
#'   [shiny::runApp()]. Defaults to `getOption("powerup.launch.browser", FALSE)`.
#' @param width,height Widget width and height. Defaults to `"100%"`
#'
#' @return A `pptx_preview` htmlwidget (invisibly when displayed).
#' @export
#'
#' @examples
#' \dontrun{
#' pptx <- example_pptx()
#' preview_pptx(pptx)
#' preview_pptx(pptx, launch.browser = TRUE)
#' }
preview_pptx <- function(pptx,
                         slide = 1L,
                         view = rlang::is_interactive(),
                         launch.browser = getOption("powerup.launch.browser", FALSE),
                         width = "100%",
                         height = "100%") {

  if (inherits(pptx, "pptx_container")) {
    pptx_path <- tempfile(fileext = ".pptx")
    on.exit(unlink(pptx_path), add = TRUE)
    save_pptx(pptx, pptx_path)
  } else if (is.character(pptx) && length(pptx) == 1 && file.exists(pptx)) {
    pptx_path <- pptx
  } else {
    cli::cli_abort(
      "{.arg pptx} must be a {.cls pptx_container} or a path to an existing .pptx file."
    )
  }

  if (!(is.logical(launch.browser) && length(launch.browser) == 1 && !is.na(launch.browser)) &&
      !is.function(launch.browser)) {
    cli::cli_abort("{.arg launch.browser} must be `TRUE`, `FALSE`, or a function.")
  }

  b64 <- base64enc::base64encode(pptx_path)

  # Read true slide dimensions for correct aspect ratio
  rpptx <- officer::read_pptx(pptx_path)
  slide_dims <- officer::slide_size(rpptx)
  n_slides <- length(rpptx)
  if (slide < 1 || slide > n_slides) {
    cli::cli_abort("{.arg slide} must be between 1 and {n_slides}.")
  }

  widget <- htmlwidgets::createWidget(
    name = "pptx_preview",
    x = list(
      data   = b64,
      aspect = slide_dims$width / slide_dims$height,
      slide  = as.integer(slide) - 1L  # 0-based for JS
    ),
    width = width,
    height = height,
    package = "powerup",
    sizingPolicy = htmlwidgets::sizingPolicy(
      defaultWidth = "100%",
      defaultHeight = "100%",
      viewer.fill = TRUE,
      browser.fill = TRUE,
      padding = 0
    ),
    # Load order matters: JSZip and Chart.js before PptxViewJS
    dependencies = list(
      pptx_dep("jszip", "jszip.min.js"),
      pptx_dep("chartjs", "chart.umd.min.js"),
      pptx_dep("pptxviewjs", "PptxViewJS.js"),
      htmltools::htmlDependency(
        name = "pptx-preview-style",
        version = "1.0.0",
        src = system.file("htmlwidgets", package = "powerup"),
        stylesheet = "pptx_preview.css"
      )
    )
  )

  if (view) {
    display_widget(widget, launch.browser)
    return(invisible(widget))
  }
  widget
}

#' Shiny bindings for preview_pptx
#'
#' Output and render functions for using [preview_pptx()] in Shiny apps and
#' R Markdown documents. Inside `preview_pptx_render()` call
#' `preview_pptx(..., view = FALSE)` so the widget is returned rather than
#' opened in the Viewer.
#'
#' @param outputId Output variable to read from.
#' @param width,height Must be a valid CSS unit (like `"100%"`, `"400px"`,
#'   `"auto"`) or a number, which will be coerced to a string and have `"px"`
#'   appended.
#' @param expr An expression that returns a [preview_pptx()] widget.
#' @param env The environment in which to evaluate `expr`.
#' @param quoted Is `expr` a quoted expression (with `quote()`)? Default `FALSE`.
#'
#' @return `preview_pptx_ui()` returns a Shiny output element;
#'   `preview_pptx_render()` returns a Shiny render function.
#' @name pptx_preview-shiny
#' @export
#'
#' @examples
#' \dontrun{
#' library(shiny)
#'
#' ui <- fluidPage(
#'   numericInput("slide", "Start slide", value = 1, min = 1),
#'   preview_pptx_ui("preview", height = "500px")
#' )
#'
#' server <- function(input, output, session) {
#'   output$preview <- preview_pptx_render({
#'     preview_pptx(example_pptx(), slide = input$slide, view = FALSE)
#'   })
#' }
#'
#' shinyApp(ui, server)
#' }
preview_pptx_ui <- function(outputId, width = "100%", height = "600px") {
  htmlwidgets::shinyWidgetOutput(
    outputId, "pptx_preview", width, height, package = "powerup"
  )
}

#' @rdname pptx_preview-shiny
#' @export
preview_pptx_render <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) {
    expr <- substitute(expr)
  }
  htmlwidgets::shinyRenderWidget(expr, preview_pptx_ui, env, quoted = TRUE)
}

pptx_dep <- function(name, script) {
  htmltools::htmlDependency(
    name = name,
    version = "1.0.0",
    src = system.file("pptxviewjs", package = "powerup"),
    script = script
  )
}

# Mirrors shiny::runApp(): TRUE = browser, FALSE = viewer, function = custom
display_widget <- function(widget, launch.browser) {
  if (is.function(launch.browser)) {
    viewer <- launch.browser
  } else if (isTRUE(launch.browser)) {
    viewer <- utils::browseURL
  } else {
    viewer <- getOption("viewer", utils::browseURL)
  }

  html_file <- tempfile(fileext = ".html")
  
  # Wrap widget with full-height HTML structure for browsers
  html_content <- htmltools::tagList(
    htmltools::tags$html(
      htmltools::tags$head(
        htmltools::tags$meta(charset = "UTF-8"),
        htmltools::tags$meta(name = "viewport", content = "width=device-width, initial-scale=1.0"),
        htmltools::tags$style(htmltools::HTML("
          html, body { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; }
          body { display: flex; flex-direction: column; }
        "))
      ),
      htmltools::tags$body(widget)
    )
  )
  
  htmltools::save_html(html_content, file = html_file)
  viewer(html_file)
  invisible(html_file)
}
