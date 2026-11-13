# ref_placeholder() checks arguments

    Code
      ref_placeholder(label = "label", type = "foo")
    Condition
      Error in `ref_placeholder()`:
      ! `type` must be one of "body", "title", "ctrTitle", "ftr", "subTitle", "tbl", "chart", "img", or "any", not "foo".

---

    Code
      ref_placeholder(label = "label", label_match = "foo")
    Condition
      Error in `ref_placeholder()`:
      ! `label_match` must be one of "exact" or "match", not "foo".

---

    Code
      ref_placeholder(label = "label", label_from = "foo")
    Condition
      Error in `ref_placeholder()`:
      ! `label_from` must be one of "slide" or "layout", not "foo".

---

    Code
      ref_placeholder(label = "label", tie_breaker = "foo")
    Condition
      Error in `ref_placeholder()`:
      ! `tie_breaker` must be one of "largest", "smallest", "left", "right", "top", or "bottom", not "foo".

# new_placeholder() checks arguments

    Code
      new_placeholder(label = "label", type = "foo")
    Condition
      Warning:
      The `type` argument of `new_placeholder()` is deprecated as of powerup 0.4.0.
      i The `type` argument is no longer used in `new_placeholder()`.
    Message
      -- new placeholder with settings:  ---------------------------------------------
    Output
      List of 6
       $ label: chr "label"
       $ type : chr "body"
       $ offx : chr "10%"
       $ offy : chr "20%"
       $ cx   : chr "80%"
       $ cy   : chr "60%"

---

    Code
      new_placeholder(label = "label", units = "foo")
    Condition
      Error in `new_placeholder()`:
      ! `units` must be one of "%", "in", or "cm", not "foo".

# new_placeholder() checks units

    Code
      new_placeholder(label = "label", x_offset = "foo")
    Condition
      Error in `new_placeholder()`:
      ! Invalid value for `x_offset` unit: "foo".
      i Only `%` (percent), `cm` (centimeters), or `in` (inches) are accepted, or a numeric value with no units (which will be assumed to be "in").

---

    Code
      new_placeholder(label = "label", x_offset = "120%")
    Condition
      Error in `new_placeholder()`:
      ! Numeric value for `x_offset` must be between 0 and 100
      x Provided value: 120.

---

    Code
      new_placeholder(label = "label", y_offset = "foo")
    Condition
      Error in `new_placeholder()`:
      ! Invalid value for `y_offset` unit: "foo".
      i Only `%` (percent), `cm` (centimeters), or `in` (inches) are accepted, or a numeric value with no units (which will be assumed to be "in").

---

    Code
      new_placeholder(label = "label", width = "foo")
    Condition
      Error in `new_placeholder()`:
      ! Invalid value for `width` unit: "foo".
      i Only `%` (percent), `cm` (centimeters), or `in` (inches) are accepted, or a numeric value with no units (which will be assumed to be "in").

---

    Code
      new_placeholder(label = "label", height = "foo")
    Condition
      Error in `new_placeholder()`:
      ! Invalid value for `height` unit: "foo".
      i Only `%` (percent), `cm` (centimeters), or `in` (inches) are accepted, or a numeric value with no units (which will be assumed to be "in").

---

    Code
      new_placeholder(label = "label", height = "10", units = "foo")
    Condition
      Error in `new_placeholder()`:
      ! `units` must be one of "%", "in", or "cm", not "foo".

---

    Code
      new_placeholder(label = "label", height = 10, units = "foo")
    Condition
      Error in `new_placeholder()`:
      ! `units` must be one of "%", "in", or "cm", not "foo".

