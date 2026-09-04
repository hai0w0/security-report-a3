# INTE2547-2580 Security Testing - Assignment 3 template

This is a clean Assignment 3 starter using the same navy/red RMIT report design
as the Assignment 2 report. It retains the typography, page geometry, headers,
geometric cover, contents styling, captions, code listings, tables, evidence
placeholders, and student details, but it does not copy Assignment 2 answers or
evidence.

## Build

Run the commands from this directory:

```powershell
xelatex -interaction=nonstopmode -halt-on-error security_report.tex
xelatex -interaction=nonstopmode -halt-on-error security_report.tex
xelatex -interaction=nonstopmode -halt-on-error security_report.tex
```

Alternatively:

```powershell
latexmk -xelatex security_report.tex
```

The project is standalone: its design package, RMIT assets, cover artwork,
sections, and figure directory are all stored locally.

## Adapt it to the Assignment 3 brief

1. Update metadata in `security_report.tex` if the course, lecturer, or
   submission type has changed.
2. Replace the starter question and answer in `sections/section1.tex`.
3. Duplicate the question block for every question and add more section files
   when needed.
4. Put genuine screenshots in `figures/` and replace each `\drfigurestub` with
   `\drfigure`.
5. Remove all visible `TODO` markers and unused placeholder material.
6. Build three times and inspect the final PDF before submission.

Reusable figure, listing, and table snippets are available in
`examples/component-examples.tex`; that file is not included in the report.
To preview the components separately, run:

```powershell
xelatex -interaction=nonstopmode -halt-on-error examples/component-preview.tex
```
