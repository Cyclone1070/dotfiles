---
name: pdf
description: Use when a task involves reading a PDF from disk — pulling out text, page ranges, tables, or page images, including scanned/image-only PDFs that need OCR before they can be read.
---

# Reading PDFs

The harness has no PDF reader: `read` cannot decode the format, and a PDF's size on
disk says nothing about its content. Extract first, then reason. Never infer what a
document says from its filename.

## 0. Prefer the converter when you need the document, not just its words

If a `pdf_to_markdown` tool is available, it is the better first move for anything
structural — headings, reading order, tables, figures:

```
pdf_to_markdown({ path: "paper.pdf" })
```

It writes `paper.md` beside the source (or into `outputDir`) with figures in
`paper.assets/`, and returns paths rather than the body, so you read the exact
section you need. It runs on a remote worker: a 40-page paper takes about a minute
warm, and much longer on the very first call while models download.

Use the shell routes below instead when you want a quick text skim, a single page
range, or the converter is unavailable.

## 1. Text layer or scanned?

```bash
gs -q -dNOPAUSE -dBATCH -sDEVICE=txtwrite -o - file.pdf | wc -c
```

Tens of kilobytes per few pages means a real text layer. A few hundred bytes on a
multi-page document means there is no text layer — go to §3 instead of extracting
empty strings and concluding the file is blank.

## 2. Text layer

Preferred, when poppler is installed:

```bash
pdftotext -layout file.pdf -                # whole document
pdftotext -layout -f 3 -l 5 file.pdf -      # pages 3-5 only
```

Portable fallback, always available (Ghostscript ships with the profile):

```bash
gs -q -dNOPAUSE -dBATCH -sDEVICE=txtwrite -o - file.pdf
gs -q -dNOPAUSE -dBATCH -dFirstPage=3 -dLastPage=5 -sDEVICE=txtwrite -o - file.pdf
```

`-layout` preserves columns. Without it, a two-column résumé or paper interleaves
lines from both columns into nonsense, which is easy to misread as corrupt text.

## 3. Scanned / image-only

Rasterize, then OCR or look:

```bash
gs -q -dNOPAUSE -dBATCH -sDEVICE=png16m -r200 -sOutputFile=/tmp/pg-%d.png file.pdf
tesseract /tmp/pg-1.png -              # text, fast
read_image /tmp/pg-1.png               # when layout, figures, or stamps matter
```

200 dpi is the sweet spot: 150 degrades small print, 300 only buys time. Installed
tesseract languages are `eng`, `osd`, `snum`; any other script needs language data
(`brew install tesseract-lang`) or OCR returns confident garbage rather than an
error. Prefer `read_image` over OCR when a vision model is on the active route.

## 4. Tables

Neither extractor preserves table structure — it flattens a grid into prose, and the
row/column relationship is lost. Render the page and read it visually, or extract the
text and rebuild the grid deliberately. Do not report a table as if it survived
extraction.

## 5. Discipline

- A 50-page PDF does not belong in context whole: extract, then slice by page.
- OCR misreads digits — student IDs, amounts, dates. Re-read the rendered page before
  repeating a number from OCR as fact.
- Cite the page number for anything specific, so the claim can be re-checked against
  the image.
