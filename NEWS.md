# 0.3.2

* `preview_pptx()` now returns an htmlwidget (class `pptx_preview`) instead of a browsable HTML object, and gains `launch.browser` (as in `shiny::runApp()`, also settable via `options(powerup.launch.browser)`), `width`, and `height` arguments
* Add `preview_pptx_ui()` and `preview_pptx_render()` Shiny bindings for `preview_pptx()`

# 0.3.1

* Add `preview_pptx()` function to preview PowerPoint presentations in html using a modified version of PptxViewJS
* Update `ggplot.placeholder_tbl()` to print placeholders in order of side to try to help preview shapes and prevent larger placeholders being placed over smaller ones
* Update error handling when invalid content are put into `update_slide()` and `add_slide()` to throw error when it is invalid. Still has ability to continue if polishing fails.
* rename package from "mirage" to "powerup"
* rename options/settings to use "powerup"

# 0.3.0

* Open Source the package

# 0.2.3

* `remove_slide_ph()` handles `ph_id = NA` gracefully #95.

* `update_slide()` and `add_slide()` capture and remember last error, which can 
  be retrieved with the new `slide_errors()` function (#56).
  
* `delete_slide()` and `move_slide()` change the document revision #101

* New internal function `get_layout_names()` to retrieve the names of all the 
  slide layout at once (#100).
  
* The `keep_all=` argument now defaults to `FALSE` in `list_placeholders()` 
  and `list_layout_placeholders()` (#104).

* The `add_slide(layout=)` argument becomes mandatory #107.

* `read_layout_placeholders()` and `read_slide_placeholders` gain a 
  `keep_all` argument that defaults to FALSE #112
  
* New function `extract_metadata_element()`

* The data returned by `read_slide_placeholders()` gains a "dimensions" attribute.  

* `list_slides()` works correctly with slides that have no placeholders and
  has a n_slide_ph column. 
  
* option "mirage.inform" can be set to "console" (default), or "shiny" so that 
  inform messages are shown as shiny notifications.

# 0.2.2

* Add ability to move slides (`move_slide()`) and delete slides (`delete_slide()`)

* Add ability to create slide transitions via `slide_transitions_*()` family of 
  functions and the `transition` argument in add_slide() and update_slide()
  
* Add ability to remove contents from a slide via `remove_contents()`

* New function `check_pkg_version()`, in the code that 
  it generates to gently check package versions and `inform()` if a version 
  is not recent enough to be sure this all works #92. 

# 0.2.1

* `list_placeholders()` gains a `keep_all` argument.

* Fix bug from replacing values previously added content

* Add default functionality to group multiple outputs from polishing into a 
  single grpSp so powerup sees all the content as one placeholder.
  
* Update to not allow for duplicated Placeholder names and update for when 
  placeholder names are loaded in they are made unique.

# 0.2.0

* `list_slides()` gains the `$slide_file` column and only returns one row per slide. 

* `get_slide_file_name()` is exported. 

* `add_table_style()`, `new_table_style()` are added. lets users create a new table 
   style format and add it to the powerpoint. This can then be used to style tables
   as they are added to the powerpoint, or when the powerpoint is open.
   
* `get_table_styles()` is exported. Lists the available table styles in the powerpoint

* `tint_color()` is exported. Lets users apply a tinting % to a color.

* Bug fixes and test updates from officer 0.6.7 release.

# 0.1.0

* Initial version of mirage

* `load_pptx()` and `save_pptx()` to respectively read from disk and save to disk
  powerpoint files using the custom `pptx_container` class that extend the 
  `pptx` objects from {officer}.

* `add_slide()` to add a slide with a given layout to an existing presentation
  and optionally add displays. 

* `update_slide()` to add one or more displays to a given slide identified by its 
  number. 
  
* `content()` to wrap an object that can be polished through `polish::polish_content_pptx()`, 
  a placeholder and optionally some metadata.
  
* `ph_*()` to create placeholder specifications to target either existing 
  placeholders from the slide or layout, or to create new placeholders given 
  position on the slide.
  
* `ref_placeholder()` to construct a placeholder specification that aims to 
  find an existing placeholder on a slide or its layout. 
  
* `new_placeholder()` to construct a specification for a new placeholder.

* `templated_placeholder()` to wrap existing (preferred) and new (fallback)
  placeholders. All the `ph_*()` functions are in fact templated placeholder
  specs. 
  
* `list_layouts()` to retrieve information about the available layouts. 

* `list_slides()` to retrieve information about each slide. 

* `list_placeholders()` to retrieve information about placeholders on a given 
  slide or available as part of a layout. 

* `read_slide_placeholders()` lower level function to read placeholders from 
   a slide. 
   
* `remove_slide_ph()` to remove a placeholder from a slide. 
