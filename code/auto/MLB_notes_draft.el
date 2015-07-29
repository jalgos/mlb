(TeX-add-style-hook
 "MLB_notes_draft"
 (lambda ()
   (TeX-run-style-hooks
    "latex2e"
    "article"
    "art10"
    "longtable"
    "pdflscape")
   (LaTeX-add-labels
    "long")))

