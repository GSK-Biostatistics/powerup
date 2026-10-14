#' List Table Styles
#'
#' List the available table styles within the document
#'
#' @param pptx A PowerPoint wrapped in a <pptx_container> object. see [load_pptx()]
#'
#' @examples
#' pptx <- example_pptx()
#' get_table_styles(pptx)
#'
#' @return A data frame with columns `style_id` and `style_name` for each table style in the presentation.
#'
#' @export
get_table_styles <- function(pptx){

  table_style_list_xml <- read_table_style_file(pptx)

  styles <- xml_find_all(table_style_list_xml, "//a:tblStyle")

  if( length(styles) == 0 ){
    return(data.frame(style_id = character(), style_name = character()))
  }else{
    styles |>
      map(function(x) {
        tibble(style_id = xml_attr(x, "styleId"),
               style_name = xml_attr(x, "styleName"))
      }) |>
      bind_rows()
  }
}


#' Add Table Style
#'
#' Given a provided table style, add it to the tableStyle file in the document.
#' this makes it available to tables that get added to the PowerPoint as a table
#' style option
#'
#' @param pptx A PowerPoint wrapped in a <pptx_container> object. see [load_pptx()]
#' @inheritParams rlang::args_error_context
#' @param table_style an xml_node that defines a tblStyle. Created by [new_table_style()].
#' @param verbose if TRUE, some information is [cli::cli_inform()]ed along the way
#'
#' @examples
#' pptx <- example_pptx()
#' table_style <- new_table_style("My New Style")
#' pptx <- add_table_style(pptx, table_style) #'
#'
#' @return a `pptx_container` object with the new table style added
#'
#' @export
#'
add_table_style <- function(pptx, table_style, verbose = getOption("powerup.verbose", default = FALSE), error_call = caller_env()){

  stopifnot(inherits(table_style,"xml_node"))
  stopifnot(identical(xml_name(table_style),"a:tblStyle"))

  style_name <- xml_attr(table_style, "styleName")

  if(style_name %in% get_table_styles(pptx)$style_name){
    cli_abort(
      glue("Pre-existing style `{style_name}` already exists. Overwritting may have unintended side effects."),
      error_call = error_call
    )
  }

  ## Add style to TableStyle File
  table_style_list_xml <- read_table_style_file(pptx)
  table_style_list_xml |>
    xml_add_child(table_style)

  write_table_style_file(pptx, table_style_list_xml)

  if (verbose) {
    powerup_inform(
      c("v" = "Successfully added new table style {.val {style_name}}."),
      class = "powerup_adding_table_style_message"
    )

  }

  invisible(pptx)

}

#' Create a new table style node
#'
#' Helper function to make it simple to define a table style node.
#'
#' @param style_name The new name of the style. This is what will be referenced
#'   when defining the table style..
#' @param style_id a unique string containing 8, 4, 4, 4, then 12 random values
#'   between A-F and 0-9, separated by dashes:
#'   `\\{[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}\\}`
#'
#' @param text_color,cell_color,border_color,row_header_text_color,row_total_text_color,col_first_text_color,col_last_text_color,row_header_cell_color,row_total_cell_color,col_first_cell_color,col_last_cell_color,cell_color_tint1,cell_color_tint2,major_border_color
#'   either a color name (as listed by colors()), a hexadecimal string
#'
#' @param border_style,major_border_style Define how borders should be styled.
#'   Options include: "sng","dbl","thickThin","thinThick","tri"
#'
#' @param border_weight,major_border_weight Define the thickness of the borders.
#'   Must be a value between 0 and 20116800.
#'
#' @inheritParams rlang::args_error_context
#'
#' @examples
#' example_table_style <- new_table_style("Example Style", text_color = "blue", border_color = "pink")
#'
#' @return An xml_node that defines a tblStyle. Added to a PowerPoint via add_table_style().
#'
#' @export
new_table_style <- function(style_name,
                            style_id = make_style_id(),

                            text_color = "#000000",
                            cell_color = "#f36633",
                            border_color = "#959595",
                            border_style = "sng",
                            border_weight = 12700,

                            row_header_text_color = text_color,
                            row_total_text_color = text_color,
                            col_first_text_color = text_color,
                            col_last_text_color = text_color,

                            row_header_cell_color = cell_color,
                            row_total_cell_color = cell_color,
                            col_first_cell_color = cell_color,
                            col_last_cell_color = cell_color,
                            cell_color_tint1 = tint_color(cell_color, tint = .4),
                            cell_color_tint2 = tint_color(cell_color, tint = .2),

                            major_border_color = border_color,
                            major_border_style = border_style,
                            major_border_weight = border_weight * 3,

                            error_call = caller_env()
) {

  check_valid_style_id(style_id, error_call = error_call)

  text_color <- as_hex_codes(text_color)
  cell_color <- as_hex_codes(cell_color)
  border_color <- as_hex_codes(border_color)

  border_style <- check_valid_border_style(border_style, error_call = error_call)

  row_header_text_color <- as_hex_codes(row_header_text_color)
  row_total_text_color <- as_hex_codes(row_total_text_color)
  col_first_text_color <- as_hex_codes(col_first_text_color)
  col_last_text_color <- as_hex_codes(col_last_text_color)
  cell_color_tint1 <- as_hex_codes(cell_color_tint1)
  cell_color_tint2 <- as_hex_codes(cell_color_tint2)

  row_header_cell_color <- as_hex_codes(row_header_cell_color)
  row_total_cell_color <- as_hex_codes(row_total_cell_color)
  col_first_cell_color <- as_hex_codes(col_first_cell_color)
  col_last_cell_color <- as_hex_codes(col_last_cell_color)

  major_border_color <- as_hex_codes(major_border_color)
  major_border_style <- check_valid_border_style(major_border_style, error_call = error_call)


  table_xml <- glue('
  <a:tblStyle styleId="{style_id}" styleName="{style_name}">
		<a:wholeTbl>
			<a:tcTxStyle>
			  <a:fontRef idx="minor">
					<a:srgbClr val="{text_color}"/>
				</a:fontRef>
			</a:tcTxStyle>
			<a:tcStyle>
				<a:tcBdr>
					<a:left>
						<a:ln w="{border_weight}" cmpd="{border_style}">
							<a:solidFill>
								<a:srgbClr val="{border_color}"/>
							</a:solidFill>
						</a:ln>
					</a:left>
					<a:right>
					  <a:ln w="{border_weight}" cmpd="{border_style}">
							<a:solidFill>
								<a:srgbClr val="{border_color}"/>
							</a:solidFill>
						</a:ln>
					</a:right>
					<a:top>
					  <a:ln w="{border_weight}" cmpd="{border_style}">
							<a:solidFill>
								<a:srgbClr val="{border_color}"/>
							</a:solidFill>
						</a:ln>
					</a:top>
					<a:bottom>
					  <a:ln w="{border_weight}" cmpd="{border_style}">
							<a:solidFill>
								<a:srgbClr val="{border_color}"/>
							</a:solidFill>
						</a:ln>
					</a:bottom>
					<a:insideH>
					  <a:ln w="{border_weight}" cmpd="{border_style}">
							<a:solidFill>
								<a:srgbClr val="{border_color}"/>
							</a:solidFill>
						</a:ln>
					</a:insideH>
					<a:insideV>
					  <a:ln w="{border_weight}" cmpd="{border_style}">
							<a:solidFill>
								<a:srgbClr val="{border_color}"/>
							</a:solidFill>
						</a:ln>
					</a:insideV>
				</a:tcBdr>
				<a:fill>
					<a:solidFill>
						<a:srgbClr val="{cell_color_tint2}">
						</a:srgbClr>
					</a:solidFill>
				</a:fill>
			</a:tcStyle>
		</a:wholeTbl>
		<a:band1H>
			<a:tcStyle>
				<a:tcBdr/>
				<a:fill>
					<a:solidFill>
						<a:srgbClr val="{cell_color_tint1}">
						</a:srgbClr>
					</a:solidFill>
				</a:fill>
			</a:tcStyle>
		</a:band1H>
		<a:band2H>
			<a:tcStyle>
				<a:tcBdr/>
			</a:tcStyle>
		</a:band2H>
		<a:band1V>
			<a:tcStyle>
				<a:tcBdr/>
				<a:fill>
					<a:solidFill>
						<a:srgbClr val="{cell_color_tint1}">
						</a:srgbClr>
					</a:solidFill>
				</a:fill>
			</a:tcStyle>
		</a:band1V>
		<a:band2V>
			<a:tcStyle>
				<a:tcBdr/>
			</a:tcStyle>
		</a:band2V>

		<a:lastCol>
			<a:tcTxStyle b="on">
				<a:fontRef idx="minor">
					<a:srgbClr val="{col_last_text_color}"/>
				</a:fontRef>
				<a:srgbClr val="{col_last_text_color}"/>
			</a:tcTxStyle>
			<a:tcStyle>
				<a:tcBdr/>
				<a:fill>
					<a:solidFill>
						<a:srgbClr val="{col_last_cell_color}"/>
					</a:solidFill>
				</a:fill>
			</a:tcStyle>
		</a:lastCol>

		<a:firstCol>
			<a:tcTxStyle b="on">
				<a:fontRef idx="minor">
					<a:srgbClr val="{col_first_text_color}"/>
				</a:fontRef>
				<a:srgbClr val="{col_first_text_color}"/>
			</a:tcTxStyle>
			<a:tcStyle>
				<a:tcBdr/>
				<a:fill>
					<a:solidFill>
						<a:srgbClr val="{col_first_cell_color}"/>
					</a:solidFill>
				</a:fill>
			</a:tcStyle>
		</a:firstCol>

		<a:lastRow>
			<a:tcTxStyle b="on">
				<a:srgbClr val="{row_total_text_color}"/>
			</a:tcTxStyle>
			<a:tcStyle>
				<a:tcBdr>
					<a:top>
						<a:ln w="{major_border_weight}" cmpd="{major_border_style}">
							<a:solidFill>
								<a:srgbClr val="{major_border_color}"/>
							</a:solidFill>
						</a:ln>
					</a:top>
				</a:tcBdr>
				<a:fill>
					<a:solidFill>
						<a:srgbClr val="{row_total_cell_color}"/>
					</a:solidFill>
				</a:fill>
			</a:tcStyle>
		</a:lastRow>

		<a:firstRow>
			<a:tcTxStyle b="on">
				<a:srgbClr val="{row_header_text_color}"/>
			</a:tcTxStyle>
			<a:tcStyle>
				<a:tcBdr>
					<a:bottom>
						<a:ln w="{major_border_weight}" cmpd="{major_border_style}">
							<a:solidFill>
								<a:srgbClr val="{major_border_color}"/>
							</a:solidFill>
						</a:ln>
					</a:bottom>
				</a:tcBdr>
				<a:fill>
					<a:solidFill>
						<a:srgbClr val="{row_header_cell_color}"/>
					</a:solidFill>
				</a:fill>
			</a:tcStyle>
		</a:firstRow>
	</a:tblStyle>
  ')

  as_xml_node(table_xml, )

}



## Table Style utilities

read_table_style_file <- function(pptx){

  table_style_xml_file <- file.path(pptx$rpptx$package_dir, "ppt/tableStyles.xml")

  if(!file.exists(table_style_xml_file)){
    table_style_list_xml <- xml2::read_xml(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <a:tblStyleLst xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
      </a:tblStyleLst>
      ')

  }else{
    table_style_list_xml <- read_xml(table_style_xml_file)
  }

  table_style_list_xml
}

write_table_style_file <- function(pptx, x) {
  table_style_xml_file <- file.path(pptx$rpptx$package_dir, "ppt/tableStyles.xml")
  write_xml(x, table_style_xml_file)
}


## Style ID utilities ----
make_style_id <- function(){

  # paste0("{5C22544A-7EE",rand_alphanumeric(1),"-4342-B048-1716B250A1E",rand_alphanumeric(1),"}")
  paste0("{",
         rand_alphanumeric(8),"-",
         rand_alphanumeric(4),"-",
         rand_alphanumeric(4),"-",
         rand_alphanumeric(4),"-",
         rand_alphanumeric(12),
         "}"
  )

}

rand_alphanumeric <- function(n){
  paste0(sample(c(0:9,LETTERS[1:6]),size = n), collapse = "")
}

check_valid_style_id <- function(x, error_call = caller_env()){


  valid <- grepl("\\{[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}\\}", x = x)

  valid_style_id_string <- "{[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}}"

  if(!valid){
    cli_abort(
      "Invalid style id. Format must be {valid_style_id_string}",
      call = error_call
    )
  }

}

## Border Style utilities ----

check_valid_border_style <- function(x, error_call = caller_env()){

  x_name <- as.character(substitute(substitute(x))[[2]])

  if(length(x) > 1 | length(x) == 0){
    cli_abort(
      paste0("Argument `",x_name,"` can only be of length 1"),
      call = error_call
    )
  }

  styles <- c("sng","dbl","thickThin","thinThick","tri")

  if(!x %in% styles){
    cli_abort(
      c(
        paste0("Argument `",x_name,"` must be a valid border style."),
        i = paste0("Valid Border Styles: ", paste0("`",styles,"`", collapse = " ")),
        x = paste0("Provided value: `", x,"`")
      ),call = error_call)
  }

  x

}

# Color utilities ---
#' @importFrom grDevices col2rgb rgb
as_hex_codes <- function(x, tint = NULL) {
  ## if hex already, return the hex
  if (grepl("^(#)", x) | grepl("^(#)*[0-9A-Fa-f]{6}$", x, perl = TRUE)) {
    x <-toupper(x)
  }else{
    font_colors <- col2rgb(x)
    x <- rgb(font_colors[1], font_colors[2], font_colors[3], maxColorValue=255)
  }

  gsub("^(#)","",x)
}

#' Apply tint to a provided color
#'
#' @param x  either a color name (as listed by colors()), a hexadecimal string
#' @param tint the percentage to tint the color. Must be a value between 0 and 1
#'
#' @examples
#' tint_color("blue", tint = .5)
#' tint_color("#0000FF", tint = .5)
#'
#' @return A hexadecimal color string representing the tinted color.
#'
#' @export
tint_color <- function(x, tint){

  if(tint > 1 | tint < 0){
    cli_abort("`tint` must be a value between 0 and 1")
  }

  if (grepl("^[0-9A-Fa-f]{6}$", x, perl = TRUE)) {
    x <- paste0("#",x)
  }

  font_colors <- col2rgb(x)

  for(i in 1:3){
    font_colors[i] = font_colors[i] + ((255 - font_colors[i]) * tint)
  }

  rgb(font_colors[1], font_colors[2], font_colors[3], maxColorValue=255)

}

