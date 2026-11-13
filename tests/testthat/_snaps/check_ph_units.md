# check_ph_units()

    Code
      check(NULL)
    Condition
      Error in `check()`:
      ! Units for `x` cannot be `NULL`.

---

    Code
      check("-5")
    Condition
      Error in `check()`:
      ! Invalid value for `x` unit: "-5".
      i Only `%` (percent), `cm` (centimeters), or `in` (inches) are accepted, or a numeric value with no units (which will be assumed to be "%", "in", and "cm").

---

    Code
      check("-5%")
    Condition
      Error in `check()`:
      ! Invalid value for `x` unit: "-5%".
      i Only `%` (percent), `cm` (centimeters), or `in` (inches) are accepted, or a numeric value with no units (which will be assumed to be "%", "in", and "cm").

---

    Code
      check("110%")
    Condition
      Error in `check()`:
      ! Numeric value for `x` must be between 0 and 100
      x Provided value: 110.

---

    Code
      check("-5cm")
    Condition
      Error in `check()`:
      ! Invalid value for `x` unit: "-5cm".
      i Only `%` (percent), `cm` (centimeters), or `in` (inches) are accepted, or a numeric value with no units (which will be assumed to be "%", "in", and "cm").

---

    Code
      check("-5in")
    Condition
      Error in `check()`:
      ! Invalid value for `x` unit: "-5in".
      i Only `%` (percent), `cm` (centimeters), or `in` (inches) are accepted, or a numeric value with no units (which will be assumed to be "%", "in", and "cm").

---

    Code
      check("4inch")
    Condition
      Error in `check()`:
      ! Invalid value for `x` unit: "4inch".
      i Only `%` (percent), `cm` (centimeters), or `in` (inches) are accepted, or a numeric value with no units (which will be assumed to be "%", "in", and "cm").

---

    Code
      check("4c")
    Condition
      Error in `check()`:
      ! Invalid value for `x` unit: "4c".
      i Only `%` (percent), `cm` (centimeters), or `in` (inches) are accepted, or a numeric value with no units (which will be assumed to be "%", "in", and "cm").

