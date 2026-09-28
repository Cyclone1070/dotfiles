# Vendored: dsh-mermaid

This directory is an **unmodified copy** of the `dsh-mermaid` DeepSeek Harness
plugin, vendored so that no third-party package has to be fetched and executed
from the network to use it.

| | |
|---|---|
| Upstream | https://github.com/MrmoLabs/dsh-mermaid |
| Commit | `4953d95` ("fix: detect graph Mermaid blocks") |
| Version | `0.4.1` (npm `dsh-mermaid@0.4.1`) |
| License | MIT — see [LICENSE](LICENSE), copyright remains with the upstream authors |
| Vendored | 2026-09-28 |

Nothing here has been modified. If you change anything, say so at the top of this
file and bump the version (`0.4.1+vendored.N`) so the divergence is visible.

## Provenance: the shipped bundle is exactly this source

`lib/` is build output, so it was verified rather than trusted. The pinned
toolchain in `package.json` / `package-lock.json` (esbuild `0.28.2`,
`mermaid@11.17.0`) rebuilds the published files **byte for byte**:

```sh
npm ci --no-audit --no-fund          # uses the vendored lockfile
node scripts/build.mjs
```

| File | SHA-256 |
|---|---|
| `lib/mermaid-runtime.js` | `d7c361216dced78adf8c582bacfb54ec3256ab9fd7113b604378cfcdaae5922f` (3.45 MB) |
| `lib/client.js` | `0a41c6bd720222fa8327b2c0749f9f80ef84d6728a9e7cdebe5ddc2a824e3615` |
| `lib/index.js` | `2bbcf6f22ee3c6aa8be3e6a119985c5204defa28d9a2d4b82f6d6b674ddd0367` |
| `lib/mermaid-runtime.js.LEGAL.txt` | `d65f5fb98a0783b63c447a448bdc59bb84e69888f21b2731a5b9fb1a8a05f2ef` |

All four rebuilt files hash-match the npm artifact and the copy this profile was
running before vendoring.

`lib/mermaid-runtime.js` is not hand-written code: `src/mermaid-runtime.js` is
three lines (`import mermaid from 'mermaid'; export default mermaid;`), and
esbuild turns that into the 3.45 MB bundle with legal comments externalised into
`lib/mermaid-runtime.js.LEGAL.txt`.

## Audit (read in full, 2026-09-28)

| File | Finding |
|---|---|
| `bin/dsh-mermaid.mjs` (85 lines) | Installer CLI, only runs if you invoke it. Its single `spawnSync` runs `dsh plugin … add/remove`; no network, no file writes, Windows argument sanitising. |
| `src/index.js` (32 lines) | Host half: one fixed-path static route (`/dsh-mermaid/mermaid-runtime.js`), GET/HEAD, serves a local file, 404 otherwise. No user input in the path. |
| `src/client.js` (496 lines) | Browser half. Only network access is a same-origin `import('/dsh-mermaid/mermaid-runtime.js?rev=…')`. No `eval`, no `new Function`, no storage, no cookies, no telemetry, no third-party origins. Renders with `securityLevel: 'strict'`, `maxTextSize: 50 000`, `maxEdges: 2 000`. |
| `src/detection.js`, `src/i18n.js`, `src/styles.js` | Pure helpers (language detection, dictionaries, CSS string). |
| `src/svg.js` (88 lines) | SVG namespace constants and DOM attribute rewriting for the fullscreen clone. |
| `src/viewer.js` (235 lines) | Fullscreen overlay: zoom/pan, focus trap, `inert` handling. DOM only. |
| `scripts/build.mjs` (46 lines) | esbuild config; writes only into `lib/`. |
| `package.json` | No `install`/`postinstall` hooks. It does define `prepare: npm run build`, which **git** installs run — a reason to prefer this vendored copy or a registry tarball over `npm i github:…`. |

Scans across `src/`, `bin/` and `scripts/` for `eval`, `new Function`,
`child_process`, `http(s)` clients, `XMLHttpRequest`, `sendBeacon`, `WebSocket`,
`localStorage`, `document.cookie`, credential paths and shell-outs found nothing
beyond the installer CLI above. The only external URLs in the source are the SVG
and XHTML namespace URIs.

### Residual risk (upstream behaviour, not introduced here)

The bundled mermaid runtime contains `fetch(` (28 call sites — icon packs and
image nodes) and no XHR/WebSocket/beacon. A **diagram source** that references an
external image URL can therefore make your browser request that URL. Mermaid's
`securityLevel: 'strict'` sanitises markup but does not disable image loading. If
that matters, restrict it with a Content-Security-Policy on the DSH origin.

The 3.45 MB bundle was verified by reproducible build and scanned for primitives;
it was not read line by line. Rebuilding it yourself with the commands above is
the strongest check available and takes seconds.
