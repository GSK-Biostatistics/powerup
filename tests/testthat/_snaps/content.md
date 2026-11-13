# content() asserts ph= is a placeholder

    Code
      content(1, ph = 2)
    Condition
      Error in `content()`:
      ! `ph` must be a placeholder, not a number.
      i Use of the the predefined templated functions `ph_body()`, `ph_body_left()`, `ph_body_right()`, `ph_footer()`, `ph_footer_left()`, `ph_footer_right()`, `ph_subtitle()`, and `ph_title()`.
      i ... or create your own placeholder with `powerup::ref_placeholder()` or `powerup::new_placeholder()`.

# content() is lazy about the class of value=

    Code
      powerup_polish_content(x, ph = ph)
    Condition
      Error in `powerup_polish_content()`:
      ! Cannot polish content for pptx documents.
      Caused by error in `polish_content_pptx()`:
      ! No available method for objects of type <not_polishable>.

# check_powerup_content() checks ...

    Code
      check_powerup_content(1)
    Condition
      Error:
      ! All elements of `...` must be marked as powerup content.
      x Element at position 1 is a number.
      i You can create powerup content with `powerup::content()`.

---

    Code
      check_powerup_content(content(1, ph_body()), mtcars)
    Condition
      Warning:
      The `type` argument of `new_placeholder()` is deprecated as of powerup 0.4.0.
      i The `type` argument is no longer used in `new_placeholder()`.
      Error:
      ! All elements of `...` must be marked as powerup content.
      x Element at position 2 is a data frame.
      i You can create powerup content with `powerup::content()`.

# content() checks metadata=

    Code
      content(metadata = c("foo", "bar"))
    Condition
      Warning:
      The `type` argument of `new_placeholder()` is deprecated as of powerup 0.4.0.
      i The `type` argument is no longer used in `new_placeholder()`.
      Error in `check_metadata()`:
      ! `metadata` must be a named character vector.

---

    Code
      content(metadata = c(foo = 42))
    Condition
      Warning:
      The `type` argument of `new_placeholder()` is deprecated as of powerup 0.4.0.
      i The `type` argument is no longer used in `new_placeholder()`.
      Error in `check_metadata()`:
      ! `metadata` must be a named character vector.

