# list_placeholders()

    Code
      list_placeholders(pptx)
    Condition
      Error in `list_placeholders()`:
      ! `layout` or `index` must be supplied.
      i Presentation has 0 slides.
      i Available layouts: "Title Slide", "Title and Content", "Section Header", "Two Content", "Comparison", "Title Only", and "Blank".

---

    Code
      list_placeholders(pptx, layout = "fdfadfa")
    Condition
      Error in `list_placeholders()`:
      ! Invalid layout supplied "fdfadfa".
      i Please use one of "Title Slide", "Title and Content", "Section Header", "Two Content", "Comparison", "Title Only", and "Blank".

---

    Code
      list_placeholders(pptx, layout = "Title Slide")
    Output
        ph_label                   type     `x (in)`      `y (in)`      
      
      -- From layout "Title Slide" ---------------------------------------------------
      1 Date Placeholder 3         dt       [0.50 - 2.83] [6.95 - 7.35] 
      2 Footer Placeholder 4       ftr      [3.42 - 6.58] [6.95 - 7.35] 
      3 Slide Number Placeholder 5 sldNum   [7.17 - 9.50] [6.95 - 7.35] 
      4 Subtitle 2                 subTitle [1.50 - 8.50] [4.25 - 6.17] 
      5 Title 1                    ctrTitle [0.75 - 9.25] [2.33 - 3.94] 

---

    Code
      list_placeholders(pptx, index = 1)
    Output
        ph_label                   type     `x (in)`      `y (in)`      
      
      -- From layout "Title Slide" ---------------------------------------------------
      1 Date Placeholder 3         dt       [0.50 - 2.83] [6.95 - 7.35] 
      2 Footer Placeholder 4       ftr      [3.42 - 6.58] [6.95 - 7.35] 
      3 Slide Number Placeholder 5 sldNum   [7.17 - 9.50] [6.95 - 7.35] 
      4 Subtitle 2                 subTitle [1.50 - 8.50] [4.25 - 6.17] 
      5 Title 1                    ctrTitle [0.75 - 9.25] [2.33 - 3.94] 

# list_placeholders() with new ppt

    Code
      list_placeholders(pptx, index = 1)
    Output
        ph_label                   type   `x (in)`      `y (in)`      
      
      -- From slide ------------------------------------------------------------------
      1 Content Placeholder 2      body   [0.50 - 9.50] [1.75 - 6.70] 
      
      -- From layout "Title and Content" ---------------------------------------------
      2 Date Placeholder 3         dt     [0.50 - 2.83] [6.95 - 7.35] 
      3 Footer Placeholder 4       ftr    [3.42 - 6.58] [6.95 - 7.35] 
      4 Slide Number Placeholder 5 sldNum [7.17 - 9.50] [6.95 - 7.35] 
      5 Title 1                    title  [0.50 - 9.50] [0.30 - 1.55] 

---

    Code
      list_placeholders(pptx, index = 2)
    Output
        ph_label                   type   `x (in)`      `y (in)`      
      
      -- From slide ------------------------------------------------------------------
      1 my new left label          body   [0.50 - 4.92] [1.75 - 6.70] 
      2 my new right label         body   [5.08 - 9.50] [1.75 - 6.70] 
      
      -- From layout "Two Content" ---------------------------------------------------
      3 Date Placeholder 4         dt     [0.50 - 2.83] [6.95 - 7.35] 
      4 Footer Placeholder 5       ftr    [3.42 - 6.58] [6.95 - 7.35] 
      5 Slide Number Placeholder 6 sldNum [7.17 - 9.50] [6.95 - 7.35] 
      6 Title 1                    title  [0.50 - 9.50] [0.30 - 1.55] 

---

    Code
      list_placeholders(pptx, index = 3)
    Output
        ph_label                   type   `x (in)`      `y (in)`      
      
      -- From layout "Comparison" ----------------------------------------------------
      1 Content Placeholder 3      body   [0.50 - 4.92] [2.38 - 6.70] 
      2 Content Placeholder 5      body   [5.08 - 9.50] [2.38 - 6.70] 
      3 Date Placeholder 6         dt     [0.50 - 2.83] [6.95 - 7.35] 
      4 Footer Placeholder 7       ftr    [3.42 - 6.58] [6.95 - 7.35] 
      5 Slide Number Placeholder 8 sldNum [7.17 - 9.50] [6.95 - 7.35] 
      6 Text Placeholder 2         body   [0.50 - 4.92] [1.68 - 2.38] 
      7 Text Placeholder 4         body   [5.08 - 9.50] [1.68 - 2.38] 
      8 Title 1                    title  [0.50 - 9.50] [0.30 - 1.55] 

# list_placeholders() with a grpSp

    Code
      list_placeholders(pptx, index = 1)
    Output
        ph_label                   type   `x (in)`      `y (in)`      
      
      -- From slide ------------------------------------------------------------------
      1 Content Placeholder 2      body   [0.50 - 9.50] [1.75 - 6.70] 
      
      -- From layout "Title and Content" ---------------------------------------------
      2 Date Placeholder 3         dt     [0.50 - 2.83] [6.95 - 7.35] 
      3 Footer Placeholder 4       ftr    [3.42 - 6.58] [6.95 - 7.35] 
      4 Slide Number Placeholder 5 sldNum [7.17 - 9.50] [6.95 - 7.35] 
      5 Title 1                    title  [0.50 - 9.50] [0.30 - 1.55] 

