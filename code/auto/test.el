(TeX-add-style-hook
 "test"
 (lambda ()
   (TeX-run-style-hooks
    "latex2e"
    "article"
    "art10"
    "longtable"
    "lscape"
    "verbatim")
   (LaTeX-add-labels
    "long")))

