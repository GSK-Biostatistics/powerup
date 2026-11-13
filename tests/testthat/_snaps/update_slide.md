# add_slide()

    Code
      pptx <- add_slide(add_slide(pptx, layout = "Title Slide", content("Title", ph = ph_title()),
      content("Subtitle", ph = ph_subtitle())), layout = "Comparison", content("left",
        ph = ph_body_left()), content("right", ph = ph_body_right()))
    Condition
      Warning:
      The `type` argument of `new_placeholder()` is deprecated as of powerup 0.4.0.
      i The `type` argument is no longer used in `new_placeholder()`.
      Warning:
      The `type` argument of `new_placeholder()` is deprecated as of powerup 0.4.0.
      i The `type` argument is no longer used in `new_placeholder()`.
    Message
      > powerup to add 2 contents at slide 1.
      v Successfully added content to placeholder "Title 1".
      v Successfully added content to placeholder "Subtitle 2".
    Condition
      Warning:
      The `type` argument of `new_placeholder()` is deprecated as of powerup 0.4.0.
      i The `type` argument is no longer used in `new_placeholder()`.
      Warning:
      The `type` argument of `new_placeholder()` is deprecated as of powerup 0.4.0.
      i The `type` argument is no longer used in `new_placeholder()`.
    Message
      > powerup to add 2 contents at slide 2.
      v Successfully added content to placeholder "Content Placeholder 3".
      v Successfully added content to placeholder "Content Placeholder 5".

---

    Code
      pptx <- add_slide(pptx)
    Condition
      Error in `add_slide()`:
      ! The `layout` argument is mandatory.
      i The suggested layout for index 3 is "Comparison".
      i Use `powerup::list_layouts()` to see the available layouts.

---

    Code
      pptx <- add_slide(pptx, index = 2)
    Condition
      Error in `add_slide()`:
      ! The `layout` argument is mandatory.
      i The suggested layout for index 2 is "Title Slide".
      i Use `powerup::list_layouts()` to see the available layouts.

# add_slide() with polish_error_continue

    Code
      pptx <- add_slide(pptx, layout = "Title Slide", content("Title", ph = ph_title()),
      content("Subtitle", ph = ph_subtitle()))
    Condition
      Warning:
      The `type` argument of `new_placeholder()` is deprecated as of powerup 0.4.0.
      i The `type` argument is no longer used in `new_placeholder()`.
      Warning:
      The `type` argument of `new_placeholder()` is deprecated as of powerup 0.4.0.
      i The `type` argument is no longer used in `new_placeholder()`.
    Message
      > powerup to add 2 contents at slide 1.
      v Successfully added content to placeholder "Title 1".
      v Successfully added content to placeholder "Subtitle 2".

---

    Code
      pptx <- add_slide(pptx, layout = "Title Slide", content(foo, ph = ph_title()))
    Condition
      Warning:
      The `type` argument of `new_placeholder()` is deprecated as of powerup 0.4.0.
      i The `type` argument is no longer used in `new_placeholder()`.
    Message
      > powerup to add 1 content at slide 2.
      x Failed to polish content of class <foo> for slide 2.
      Caused by error in `powerup_polish_content()`:
      ! Polished content must be an <xml_nodeset> object, not a string.
      i Check the `polish_content_pptx()` method objects of class <>.
        => polish_content_pptx.foo
        * polish_content_pptx.default

# add_slide() with with actual error fails

    Code
      pptx <- add_slide(pptx, layout = "Title Slide", content(foo, ph = ph_body()))
    Condition
      Warning:
      The `type` argument of `new_placeholder()` is deprecated as of powerup 0.4.0.
      i The `type` argument is no longer used in `new_placeholder()`.
      Error in `add_slide()`:
      ! Failed to add slide 1.
      Caused by error in `add_slide()`:
      ! Error evaluating content at position 1: "content(foo, ph = ph_body())".
      i Error message: object 'foo' not found

---

    Code
      pptx <- add_slide(pptx, layout = "Title Slide", content(foo, ph = ph_body()),
      content(1, ph = ph_body()))
    Condition
      Warning:
      The `type` argument of `new_placeholder()` is deprecated as of powerup 0.4.0.
      i The `type` argument is no longer used in `new_placeholder()`.
      Error in `add_slide()`:
      ! Failed to add slide 1.
      Caused by error in `add_slide()`:
      ! Error evaluating content at position 1: "content(foo, ph = ph_body())".
      i Error message: object 'foo' not found

---

    Code
      pptx <- add_slide(pptx, layout = "Title Slide", content(1, ph = ph_body()),
      content(foo, ph = ph_body()))
    Condition
      Warning:
      The `type` argument of `new_placeholder()` is deprecated as of powerup 0.4.0.
      i The `type` argument is no longer used in `new_placeholder()`.
      Warning:
      The `type` argument of `new_placeholder()` is deprecated as of powerup 0.4.0.
      i The `type` argument is no longer used in `new_placeholder()`.
      Error in `add_slide()`:
      ! Failed to add slide 1.
      Caused by error in `add_slide()`:
      ! Error evaluating content at position 2: "content(foo, ph = ph_body())".
      i Error message: object 'foo' not found

# update_slide(), errors on unknown arguments

    Code
      pptx <- update_slide(pptx, index = 1, ct)
    Message
      > powerup to add 1 content at slide 1.
      x Failed to polish content of class <ggplot2::ggplot/ggplot/ggplot2::gg/S7_object/gg> for slide 1.
      Caused by error in `powerup_polish_content()`:
      ! Cannot polish content for pptx documents.
      Caused by error in `polish_content_pptx()`:
      ! `...` must be empty.
      x Problematic argument:
      * description = "plot"

# update previously custom placeholder (replace first time, preserve second)

    Code
      update_slide(pptx, index = 1, content("My Final Value", ph = ref_placeholder(
        "New Placeholder", replace = FALSE)))
    Condition
      Error in `update_slide()`:
      ! Cannot create a new placeholder with the existing label "New Placeholder".
      i Choose a label that is not already in use.

# Wrap values with multiple ph with a grpSp

    Code
      pptx <- add_slide(pptx, layout = "Title Slide", content(foo, ph = new_placeholder(
        label = "my content", x_offset = "5%", y_offset = "50%", width = "90%",
        height = "10%")))
    Message
      > powerup to add 1 content at slide 1.
      v Successfully added content to placeholder "my content".

---

    Code
      gsub("p:cNvPr id=\".+?\"", "p:cNvPr id=\"AN ID\"", x = as.character((function(x)
        {
          x[[3]]
        })(xml_children(xml_find_all(pptx$rpptx$slide$get_slide(1)$get(),
      ".//p:spTree")))))
    Output
      [1] "<p:grpSp>\n  <p:nvGrpSpPr>\n    <p:cNvPr id=\"AN ID\" name=\"my content\">\n\t\t</p:cNvPr>\n    <p:cNvGrpSpPr/>\n    <p:nvPr/>\n  </p:nvGrpSpPr>\n  <p:grpSpPr>\n    <a:xfrm>\n      <a:off x=\"457200\" y=\"3429000\"/>\n      <a:ext cx=\"8229600\" cy=\"685800\"/>\n      <a:chOff x=\"457200\" y=\"3429000\"/>\n      <a:chExt cx=\"8229600\" cy=\"685800\"/>\n    </a:xfrm>\n  </p:grpSpPr>\n  <p:sp>\n    <p:nvSpPr>\n      <p:cNvPr id=\"AN ID\" name=\"my content\"/>\n      <p:cNvSpPr>\n        <a:spLocks noGrp=\"1\"/>\n      </p:cNvSpPr>\n      <p:nvPr>\n        <p:ph type=\"body\"/>\n      </p:nvPr>\n    </p:nvSpPr>\n    <p:spPr>\n      <a:xfrm>\n        <a:off x=\"457200\" y=\"3429000\"/>\n        <a:ext cx=\"8229600\" cy=\"685800\"/>\n      </a:xfrm>\n    </p:spPr>\n    <p:txBody>\n      <a:bodyPr/>\n      <a:lstStyle/>\n      <a:p>\n        <a:r>\n          <a:t>test</a:t>\n        </a:r>\n      </a:p>\n    </p:txBody>\n  </p:sp>\n  <p:sp>\n    <p:nvSpPr>\n      <p:cNvPr id=\"AN ID\" name=\"my content\"/>\n      <p:cNvSpPr>\n        <a:spLocks noGrp=\"1\"/>\n      </p:cNvSpPr>\n      <p:nvPr>\n        <p:ph type=\"body\"/>\n      </p:nvPr>\n    </p:nvSpPr>\n    <p:spPr>\n      <a:xfrm>\n        <a:off x=\"457200\" y=\"3429000\"/>\n        <a:ext cx=\"8229600\" cy=\"685800\"/>\n      </a:xfrm>\n    </p:spPr>\n    <p:txBody>\n      <a:bodyPr/>\n      <a:lstStyle/>\n      <a:p>\n        <a:r>\n          <a:t>grouping</a:t>\n        </a:r>\n      </a:p>\n    </p:txBody>\n  </p:sp>\n  <p:extLst>\n    <p:ext uri=\"r://package/powerup\">\n      <custom:meta xmlns:custom=\"urn:schemas-microsoft-com:office:custom-properties\">\n        <custom:property name=\"a:xfrm/a:off/@x\" value=\"457200\"/>\n        <custom:property name=\"a:xfrm/a:off/@y\" value=\"3429000\"/>\n        <custom:property name=\"a:xfrm/a:ext/@cx\" value=\"8229600\"/>\n        <custom:property name=\"a:xfrm/a:ext/@cy\" value=\"685800\"/>\n      </custom:meta>\n    </p:ext>\n  </p:extLst>\n</p:grpSp>"

---

    Code
      pptx <- update_slide(pptx, index = 1, content("new text", ph = ref_placeholder(
        label = "my content", label_match = "exact")))
    Message
      > powerup to add 1 content at slide 1.
      v Successfully added content to placeholder "my content".

---

    Code
      gsub("p:cNvPr id=\".+?\"", "p:cNvPr id=\"AN ID\"", x = as.character((function(x)
        {
          x[[3]]
        })(xml_children(xml_find_all(pptx$rpptx$slide$get_slide(1)$get(),
      ".//p:spTree")))))
    Output
      [1] "<p:sp>\n  <p:nvSpPr>\n    <p:cNvPr id=\"AN ID\" name=\"my content\"/>\n    <p:cNvSpPr>\n      <a:spLocks noGrp=\"1\"/>\n    </p:cNvSpPr>\n    <p:nvPr>\n      <p:ph/>\n    </p:nvPr>\n  </p:nvSpPr>\n  <p:spPr>\n    <a:xfrm>\n      <a:off x=\"457200\" y=\"3429000\"/>\n      <a:ext cx=\"8229600\" cy=\"685800\"/>\n    </a:xfrm>\n  </p:spPr>\n  <p:txBody>\n    <a:bodyPr/>\n    <a:lstStyle/>\n    <a:p>\n      <a:r>\n        <a:t>new text</a:t>\n      </a:r>\n    </a:p>\n  </p:txBody>\n  <p:extLst>\n    <p:ext uri=\"r://package/powerup\">\n      <custom:meta xmlns:custom=\"urn:schemas-microsoft-com:office:custom-properties\">\n        <custom:property name=\"a:xfrm/a:off/@x\" value=\"457200\"/>\n        <custom:property name=\"a:xfrm/a:off/@y\" value=\"3429000\"/>\n        <custom:property name=\"a:xfrm/a:ext/@cx\" value=\"8229600\"/>\n        <custom:property name=\"a:xfrm/a:ext/@cy\" value=\"685800\"/>\n      </custom:meta>\n    </p:ext>\n  </p:extLst>\n</p:sp>"

# errors are recorded (#56)

    Code
      pptx <- add_slide(pptx, index = 1, layout = "Title and Content", content(
        BAD_CONTENT, ph = ph_body()), polish_error_continue = TRUE)
    Condition
      Warning:
      The `type` argument of `new_placeholder()` is deprecated as of powerup 0.4.0.
      i The `type` argument is no longer used in `new_placeholder()`.
      Error in `add_slide()`:
      ! Failed to add slide 1.
      Caused by error in `add_slide()`:
      ! Error evaluating content at position 1: "content(BAD_CONTENT, ph = ph_body())".
      i Error message: object 'BAD_CONTENT' not found

---

    Code
      pptx <- add_slide(pptx, index = 1, layout = "Title and Content", content(rnorm,
        ph = ph_body()), polish_error_continue = TRUE)
    Condition
      Warning:
      The `type` argument of `new_placeholder()` is deprecated as of powerup 0.4.0.
      i The `type` argument is no longer used in `new_placeholder()`.

