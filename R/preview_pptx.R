#' Preview a powerup PPTX in the Viewer pane
#'
#' Renders a `pptx_container` (or a path to a `.pptx` file) as an interactive
#' slide viewer in the RStudio / Positron Viewer pane, or in the default browser.
#' Uses PptxViewJS (bundled offline; no internet connection required).
#'
#' @param pptx A `pptx_container` object or a file path to a `.pptx` file.
#' @param slide Integer. Which slide to show first (1-based). Default `1`.
#' @param view Logical. If `TRUE` (default), opens the viewer. If `FALSE`, returns the html.
#'
#' @return An `htmltools::browsable` HTML object (invisibly). Called for its
#'   side-effect of opening the viewer.
#' @export
#'
#' @examples
#' \dontrun{
#' pptx <- example_pptx()
#' preview_pptx(pptx)
#' }
preview_pptx <- function(pptx, slide = 1L, view = rlang::is_interactive()) {

  # Resolve to a file path
  if (inherits(pptx, "pptx_container")) {
    tmp <- tempfile(fileext = ".pptx")
    save_pptx(pptx, tmp)
    pptx_path <- tmp
  } else if (is.character(pptx) && file.exists(pptx)) {
    pptx_path <- pptx
  } else {
    cli::cli_abort(
      "{.arg pptx} must be a {.cls pptx_container} or a path to an existing .pptx file."
    )
  }

  # Encode the PPTX as base64
  raw_bytes <- readBin(pptx_path, what = "raw", n = file.info(pptx_path)$size)
  b64 <- base64enc::base64encode(raw_bytes)
  data_uri <- paste0("data:application/vnd.openxmlformats-officedocument.presentationml.presentation;base64,", b64)

  # Paths to bundled JS (Chart.js must load before PptxViewJS)
  pkg_js_dir  <- system.file("pptxviewjs", package = "powerup")
  jszip_js    <- readLines(file.path(pkg_js_dir, "jszip.min.js"),      warn = FALSE)
  chartjs_js  <- readLines(file.path(pkg_js_dir, "chart.umd.min.js"),  warn = FALSE)
  viewer_js   <- readLines(file.path(pkg_js_dir, "PptxViewJS.js"), warn = FALSE)

  jszip_inline  <- paste(jszip_js,   collapse = "\n")
  chartjs_inline <- paste(chartjs_js, collapse = "\n")
  viewer_inline <- paste(viewer_js,  collapse = "\n")

  # Read true slide dimensions for correct aspect ratio
  rpptx <- officer::read_pptx(pptx_path)
  slide_dims <- officer::slide_size(rpptx)
  aspect_ratio <- slide_dims$width / slide_dims$height

  n_slides <- length(rpptx)
  if(slide < 1 || slide > n_slides) {
    cli::cli_abort(
      "{.arg slide} must be between 1 and {n_slides}."
    )
  }
  initial_slide <- as.integer(slide) - 1L  # 0-based for JS

  # Build HTML via paste0 - avoids sprintf misinterpreting '%' chars in minified JS
  html <- htmltools::HTML(paste0(
    '<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>PPTX Preview</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: system-ui, sans-serif; background: #1a1a2e; color: #eee;
           display: flex; flex-direction: column; height: 100vh; overflow: hidden; }
    #toolbar {
      display: flex; align-items: center; gap: 8px; padding: 6px 12px;
      background: #16213e; border-bottom: 1px solid #0f3460; flex-shrink: 0;
    }
    button {
      background: #0f3460; color: #eee; border: none; border-radius: 4px;
      padding: 4px 12px; cursor: pointer; font-size: 13px;
    }
    button:hover { background: #533483; }
    button:disabled { opacity: 0.4; cursor: default; }
    #slide-info { font-size: 13px; min-width: 80px; text-align: center; }
    #canvas-wrap {
      flex: 1; display: flex; align-items: center; justify-content: center;
      overflow: hidden; padding: 12px;
    }
    canvas { box-shadow: 0 4px 24px rgba(0,0,0,0.5); background: white; display: block; }
    #status { font-size: 12px; color: #aaa; }
  </style>
</head>
<body>

<div id="toolbar">
  <button id="btn-prev" disabled>&#8592; Prev</button>
  <span id="slide-info">Loading...</span>
  <button id="btn-next" disabled>Next &#8594;</button>
  <span id="status"></span>
</div>

<div id="canvas-wrap">
  <canvas id="pptx-canvas"></canvas>
</div>

<!-- Bundled JSZip -->
<script>', jszip_inline, '</script>
<!-- Bundled Chart.js (required peer dep for PptxViewJS) -->
<script>', chartjs_inline, '</script>
<!-- Bundled PptxViewJS -->
<script>', viewer_inline, '</script>

<script>
(async function () {
  const canvas   = document.getElementById("pptx-canvas");
  const info     = document.getElementById("slide-info");
  const status   = document.getElementById("status");
  const btnPrev  = document.getElementById("btn-prev");
  const btnNext  = document.getElementById("btn-next");

  // Size canvas to fill the container using the true slide aspect ratio.
  // Must set both the canvas pixel dimensions (width/height attributes) AND
  // the CSS display size - they are independent. The pixel dimensions control
  // what PptxViewJS actually renders into; CSS controls how it is displayed.
  const ASPECT = ', aspect_ratio, ';
  function resizeCanvas() {
    const wrap   = document.getElementById("canvas-wrap");
    const pad    = 24;
    const availW = wrap.clientWidth  - pad;
    const availH = wrap.clientHeight - pad;
    let w = availW;
    let h = w / ASPECT;
    if (h > availH) { h = availH; w = h * ASPECT; }
    w = Math.floor(w);
    h = Math.floor(h);
    // Pixel buffer dimensions (what the renderer draws into)
    canvas.width  = w;
    canvas.height = h;
    // CSS display dimensions (how it appears on screen)
    canvas.style.width  = w + "px";
    canvas.style.height = h + "px";
  }
  resizeCanvas();
  let _resizeTimer;
  window.addEventListener("resize", () => {
    resizeCanvas();
    clearTimeout(_resizeTimer);
    _resizeTimer = setTimeout(async () => { await safeRender(); }, 100);
  });

  // Decode the embedded base64 PPTX
  const dataUri = "', data_uri, '";
  const base64  = dataUri.split(",")[1];
  const binary  = atob(base64);
  const bytes   = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  const blob = new Blob([bytes],
    { type: "application/vnd.openxmlformats-officedocument.presentationml.presentation" });
  const file = new File([blob], "presentation.pptx", { type: blob.type });

  const viewer = new PptxViewJS.PPTXViewer({ canvas });

  // Safely render the current slide - empty slides can throw, so we catch and
  // clear the canvas instead of letting the error break navigation entirely.
  async function safeRender() {
    try {
      await viewer.render();
    } catch (e) {
      const ctx = canvas.getContext("2d");
      if (ctx) {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.fillStyle = "#f8f8f8";
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        ctx.fillStyle = "#aaa";
        ctx.font = "16px system-ui, sans-serif";
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        ctx.fillText("(empty slide)", canvas.width / 2, canvas.height / 2);
      }
    }
    updateNav();
  }

  function updateNav() {
    // getCurrentSlideIndex() is 0-based; convert to 1-based for display/logic
    const cur0  = viewer.getCurrentSlideIndex();  // 0-based
    const cur   = cur0 + 1;                       // 1-based for display
    const total = viewer.getSlideCount() || 1;
    info.textContent = "Slide " + cur + " / " + total;
    btnPrev.disabled = cur <= 1;
    btnNext.disabled = cur >= total;
  }

  viewer.on("loadComplete", async (data) => {
    const total = data.slideCount;
    status.textContent = total + " slide" + (total !== 1 ? "s" : "");
    // Render first, then navigate to the requested start slide if needed.
    // goToSlide alone does not render; safeRender() must follow it.
    const startSlide = Math.min(', initial_slide, ', total - 1);  // 0-based
    if (startSlide > 0) {
      try { await viewer.goToSlide(startSlide); } catch(e) {}  // goToSlide is 0-based
    }

    await safeRender();
  });

  btnPrev.addEventListener("click", async () => {
    try { await viewer.previousSlide(); } catch(e) {}
    await safeRender();
  });
  btnNext.addEventListener("click", async () => {
    try { await viewer.nextSlide(); } catch(e) {}
    await safeRender();
  });

  document.addEventListener("keydown", async (e) => {
    if (e.key === "ArrowRight" || e.key === "ArrowDown") {
      try { await viewer.nextSlide(); } catch(e) {}
      await safeRender();
    }
    if (e.key === "ArrowLeft" || e.key === "ArrowUp") {
      try { await viewer.previousSlide(); } catch(e) {}
      await safeRender();
    }
  });

  await viewer.loadFile(file);

})();
</script>
</body>
</html>'
  ))

  out <- htmltools::browsable(html)
  if (view) {
    print(out)
  }
  invisible(out)
}
