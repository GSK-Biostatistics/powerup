HTMLWidgets.widget({
  name: "pptx_preview",
  type: "output",

  factory: function (el, width, height) {
    let viewer = null;
    let canvas = null;
    let wrap = null;
    let aspect = 16 / 9;
    let resizeTimer = null;

    function resizeCanvas() {
      if (!canvas || !wrap) return;
      const pad = 24;
      const availW = wrap.clientWidth - pad;
      const availH = wrap.clientHeight - pad;
      let w = availW;
      let h = w / aspect;
      if (h > availH) { h = availH; w = h * aspect; }
      w = Math.max(1, Math.floor(w));
      h = Math.max(1, Math.floor(h));
      canvas.width = w;
      canvas.height = h;
      canvas.style.width = w + "px";
      canvas.style.height = h + "px";
    }

    return {
      renderValue: function (x) {
        aspect = x.aspect;
        el.classList.add("pptx-preview");
        el.innerHTML =
          '<div class="pptx-toolbar">' +
          '<button class="pptx-prev" disabled>&#8592; Prev</button>' +
          '<span class="pptx-info">Loading...</span>' +
          '<button class="pptx-next" disabled>Next &#8594;</button>' +
          '<span class="pptx-status"></span></div>' +
          '<div class="pptx-wrap"><canvas class="pptx-canvas"></canvas></div>';

        const info = el.querySelector(".pptx-info");
        const status = el.querySelector(".pptx-status");
        const btnPrev = el.querySelector(".pptx-prev");
        const btnNext = el.querySelector(".pptx-next");
        wrap = el.querySelector(".pptx-wrap");
        canvas = el.querySelector(".pptx-canvas");
        resizeCanvas();

        const binary = atob(x.data);
        const bytes = new Uint8Array(binary.length);
        for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
        const type = "application/vnd.openxmlformats-officedocument.presentationml.presentation";
        const file = new File([new Blob([bytes], { type: type })], "presentation.pptx", { type: type });

        viewer = new PptxViewJS.PPTXViewer({ canvas: canvas });

        // Empty slides can throw; draw a placeholder so navigation keeps working
        async function safeRender() {
          try {
            await viewer.render();
          } catch (e) {
            const ctx = canvas.getContext("2d");
            if (ctx) {
              ctx.fillStyle = "#f8f8f8";
              ctx.fillRect(0, 0, canvas.width, canvas.height);
              ctx.fillStyle = "#aaa";
              ctx.font = "16px system-ui, sans-serif";
              ctx.textAlign = "center";
              ctx.textBaseline = "middle";
              ctx.fillText("(empty slide)", canvas.width / 2, canvas.height / 2);
            }
          }
          const cur = viewer.getCurrentSlideIndex() + 1;
          const total = viewer.getSlideCount() || 1;
          info.textContent = "Slide " + cur + " / " + total;
          btnPrev.disabled = cur <= 1;
          btnNext.disabled = cur >= total;
        }

        async function step(fn) {
          try { await fn(); } catch (e) {}
          await safeRender();
        }

        viewer.on("loadComplete", async function (data) {
          const total = data.slideCount;
          status.textContent = total + " slide" + (total !== 1 ? "s" : "");
          const start = Math.min(x.slide, total - 1);
          if (start > 0) {
            try { await viewer.goToSlide(start); } catch (e) {}
          }
          await safeRender();
        });

        btnPrev.addEventListener("click", () => step(() => viewer.previousSlide()));
        btnNext.addEventListener("click", () => step(() => viewer.nextSlide()));
        el.tabIndex = 0;
        el.addEventListener("keydown", function (e) {
          if (e.key === "ArrowRight" || e.key === "ArrowDown") step(() => viewer.nextSlide());
          if (e.key === "ArrowLeft" || e.key === "ArrowUp") step(() => viewer.previousSlide());
        });

        viewer.loadFile(file);
      },

      resize: function (w, h) {
        if (!viewer) return;
        resizeCanvas();
        clearTimeout(resizeTimer);
        resizeTimer = setTimeout(function () {
          viewer.render().catch(function () {});
        }, 100);
      }
    };
  }
});
