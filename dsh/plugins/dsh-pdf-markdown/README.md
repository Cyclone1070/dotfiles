# dsh-pdf-markdown

One model-facing tool for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness):
**PDF → Markdown + linked figures**.

```
pdf_to_markdown({ path: "papers/attention.pdf" })
→ { markdownPath: "/…/papers/attention.md",
    imagesDir:    "/…/papers/attention.assets",
    imageCount:   7, pageCount: 12, elapsedMs: 41300 }
```

The tool returns **paths, never the document body**. That is deliberate: a 50-page
PDF costs the model three lines and one targeted `read`, instead of a context-sized
dump that would then be compacted away.

This package is the **client half**. It uploads the PDF to a worker, receives the
rendered files, and writes them where you asked. The conversion itself lives in
[dsh-pdf-worker](../dsh-pdf-worker) — a container running
[marker](https://github.com/datalab-to/marker) — because marker needs modern
`torch`, and `torch` stopped publishing Intel-macOS wheels at 2.2.2.

## Install

```sh
dsh plugin --profile web add link:$(pwd)/dsh/plugins/dsh-pdf-markdown
```

Restart the host once — profile bundles load at boot.

Then point it at a worker. `elitedesk` below is a Tailscale MagicDNS name: it
resolves only inside the tailnet, so committing it leaks nothing usable.

```yaml
- id: pdf-markdown
  name: dsh-pdf-markdown
  config:
    url: http://elitedesk:8765
```

## Tool

| Parameter | Type | Meaning |
|---|---|---|
| `path` | string, required | PDF to convert |
| `outputDir` | string | Where to write. Default: the PDF's own directory |

Returns `markdownPath`, `imagesDir`, `imageCount`, `pageCount`, `elapsedMs`.

Default output, for `papers/attention.pdf`:

```
papers/
  attention.md            ← figures referenced as ![](attention.assets/page-3-figure-1.png)
  attention.assets/
    page-3-figure-1.png
    page-7-chart-2.png
```

Links are **relative and prefixed with the document name**, so two PDFs converted
into the same directory never collide, and moving the pair keeps the document intact.

## Config

| Key | Default | Meaning |
|---|---|---|
| `url` | `$DSH_PDF_URL` | Worker base URL, e.g. `http://elitedesk:8765` |
| `timeoutMs` | `900000` | Per-conversion budget; a 50-page scan on CPU is slow |

A missing `url` fails at call time with the setting name, not at boot.

## Limitations

- **The worker must be reachable.** If it is down the tool says so and names the URL;
  it does not silently fall back to a local engine.
- **Scanned PDFs** need OCR. The worker's marker build can do it, but slowly; the
  `pdf` skill covers the `gs` + `tesseract` route for text-only extraction.
- **Model weights are OpenRAIL-M**, not Apache-2.0: fine for personal, research, and
  companies under $5M revenue; above that needs a Datalab licence. This plugin's own
  code is MIT.
- **No page-range parameter.** The worker converts whole documents; slicing is a job
  for the `pdf` skill, not for the transport.

## License

MIT. See `LICENSE`. marker and its weights carry their own licences.
