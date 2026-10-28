/**
 * `dsh-pdf-markdown` — the `pdf_to_markdown` tool.
 *
 * One row, one model-facing tool: convert a PDF into a Markdown file with its
 * figures exported as linked PNG assets. The conversion runs in a worker on
 * another machine (see `dsh-pdf-worker`); this module is the thin client — it
 * uploads the document, receives the rendered files, and writes them where the
 * caller asked. It owns the tool contract, file placement, and failure
 * reporting, and nothing else.
 *
 * Results are bounded on purpose: the tool returns paths and counts, never the
 * Markdown body, so a 50-page document costs the model a few lines and one
 * targeted `read` instead of a context-sized dump.
 *
 * @module dsh-pdf-markdown
 */

import { Buffer } from 'node:buffer'
import { existsSync, mkdirSync, readFileSync, statSync, writeFileSync } from 'node:fs'
import { basename, dirname, extname, join, resolve } from 'node:path'

/** Cordis plugin name (the Loader entry id). */
export const name = 'pdf-markdown'

/** Services this row needs before it can register its tool. */
export const inject = ['tools']

/** The worker rejects anything larger, so refuse before spending the upload. */
const MAX_BYTES = 200 * 1024 * 1024

/**
 * Request schema.
 *
 * Two fields, matching what the job actually needs: which document, and where
 * the result goes. A page range was considered and left out — the worker
 * converts whole documents, and a slice is a `pdf` skill concern, not a
 * transport one.
 */
const PARAMETERS = {
  type: 'object',
  properties: {
    path: {
      type: 'string',
      description: 'Absolute or workspace-relative path of the PDF to convert.',
    },
    outputDir: {
      type: 'string',
      description:
        'Directory to write the Markdown and its figures into. Defaults to the PDF\u2019s own directory, so the result sits beside the source.',
    },
  },
  required: ['path'],
  additionalProperties: false,
}

const OUTPUT = {
  schema: {
    type: 'object',
    properties: {
      markdownPath: { type: 'string', description: 'Absolute path of the written Markdown file.' },
      imagesDir: { type: 'string', description: 'Absolute path of the assets directory.' },
      imageCount: { type: 'integer', description: 'Number of figures exported.' },
      pageCount: { type: 'integer', description: 'Pages in the converted document.' },
      elapsedMs: { type: 'integer', description: 'Wall-clock conversion time reported by the worker.' },
    },
    required: ['markdownPath', 'imagesDir', 'imageCount', 'pageCount', 'elapsedMs'],
    additionalProperties: false,
  },
  render(_args, value) {
    const seconds = (value.elapsedMs / 1000).toFixed(1)
    const figures = value.imageCount === 1 ? '1 figure' : `${value.imageCount} figures`
    return [
      {
        type: 'text',
        text: [
          `Converted ${value.pageCount} page(s) in ${seconds}s → ${figures}`,
          `markdown: ${value.markdownPath}`,
          `assets:   ${value.imagesDir}`,
        ].join('\n'),
      },
    ]
  },
}

/** Explain a connection failure in terms of the setting that caused it. */
function transportError(url, error) {
  const cause = error?.cause?.code || error?.code || error?.name || 'unknown error'
  return new Error(
    `pdf_to_markdown: cannot reach the PDF worker at ${url} (${cause}). ` +
      'Start it with `systemctl --user start dsh-pdf` on that host, or point ' +
      '`url` at another worker in this row\u2019s config.',
  )
}

/**
 * Register the tool.
 * @param ctx - host Cordis context.
 * @param config - deployment config: { url, timeoutMs? }.
 */
export function apply(ctx, config = {}) {
  const url = (config.url ?? process.env.DSH_PDF_URL ?? '').trim().replace(/\/+$/, '')
  const timeoutMs = config.timeoutMs ?? 900_000

  ctx.tools.register({
    name: 'pdf_to_markdown',
    description:
      'Convert a PDF into a Markdown file with its figures extracted as PNG assets and linked in place. ' +
      'Use this instead of reading a PDF directly: it recovers headings, reading order, tables and images, and it never returns the document body — read the returned markdown path. ' +
      'The conversion runs on a remote worker and can take a minute or more on a long document.',
    parameters: PARAMETERS,
    output: OUTPUT,
    async execute(args, exec) {
      const pdfPath = resolve(args.path)
      if (!existsSync(pdfPath)) throw new Error(`pdf_to_markdown: no such file: ${pdfPath}`)
      if (statSync(pdfPath).isDirectory()) throw new Error(`pdf_to_markdown: is a directory: ${pdfPath}`)
      if (extname(pdfPath).toLowerCase() !== '.pdf') {
        throw new Error(`pdf_to_markdown: not a .pdf file: ${pdfPath}`)
      }
      if (!url) {
        throw new Error(
          'pdf_to_markdown: no worker configured. Set `url` on the pdf-markdown row in ' +
            'cordis.patch.yml, or export DSH_PDF_URL.',
        )
      }

      const bytes = readFileSync(pdfPath)
      if (bytes.byteLength > MAX_BYTES) {
        throw new Error(`pdf_to_markdown: file is ${bytes.byteLength} bytes, over the ${MAX_BYTES}-byte limit`)
      }

      const stem = basename(pdfPath, extname(pdfPath))
      const outDir = args.outputDir ? resolve(args.outputDir) : dirname(pdfPath)

      const body = new FormData()
      body.append('file', new Blob([bytes], { type: 'application/pdf' }), `${stem}.pdf`)
      body.append('name', stem)

      const signals = [AbortSignal.timeout(timeoutMs)]
      if (exec?.signal) signals.push(exec.signal)

      let response
      try {
        response = await fetch(`${url}/convert`, {
          method: 'POST',
          body,
          signal: AbortSignal.any(signals),
        })
      } catch (error) {
        if (exec?.signal?.aborted) throw new Error('pdf_to_markdown: cancelled')
        if (error?.name === 'TimeoutError') {
          throw new Error(`pdf_to_markdown: worker did not answer within ${timeoutMs}ms`)
        }
        throw transportError(url, error)
      }

      if (!response.ok) {
        let detail = ''
        try {
          detail = (await response.json())?.detail ?? ''
        } catch {
          detail = await response.text().catch(() => '')
        }
        throw new Error(`pdf_to_markdown: worker rejected the conversion (${response.status}) ${detail}`.trim())
      }

      const form = await response.formData()
      mkdirSync(outDir, { recursive: true })

      let markdownPath = ''
      let imagesDir = ''
      let imageCount = 0
      for (const value of form.values()) {
        if (typeof value === 'string') continue
        const relative = value.name
        if (!relative || relative.includes('..') || relative.startsWith('/')) {
          throw new Error(`pdf_to_markdown: worker returned an unsafe path: ${relative}`)
        }
        const target = join(outDir, relative)
        mkdirSync(dirname(target), { recursive: true })
        writeFileSync(target, Buffer.from(await value.arrayBuffer()))
        if (relative.endsWith('.md')) markdownPath = target
        else if (relative.includes('.assets/')) {
          imageCount += 1
          imagesDir = join(outDir, relative.slice(0, relative.lastIndexOf('/')))
        }
      }

      if (!markdownPath) throw new Error('pdf_to_markdown: worker returned no Markdown file')

      return {
        markdownPath,
        imagesDir,
        imageCount,
        pageCount: Number(response.headers.get('x-dsh-pages') ?? 0),
        elapsedMs: Number(response.headers.get('x-dsh-elapsed-ms') ?? 0),
      }
    },
  })
}
