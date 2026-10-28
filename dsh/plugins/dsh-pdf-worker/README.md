# dsh-pdf-worker

The server half of [dsh-pdf-markdown](../dsh-pdf-markdown): a container that turns
one PDF into Markdown plus PNG figures, using [marker](https://github.com/datalab-to/marker).

**One endpoint, no state.** No database, no job queue, no storage, no health route.
The client posts a file and receives files.

```
POST /convert
  multipart/form-data:
    file = <pdf bytes>
    name = "attention"          ← stem for the output

200 multipart/form-data:
    files "attention.md"                 text/markdown
    files "attention.assets/page-3-figure-1.png"
    …
  headers:
    X-Dsh-Pages, X-Dsh-Images, X-Dsh-Elapsed-Ms
```

The Markdown already points at `attention.assets/…`, so the client writes the parts
verbatim into one directory and the document is complete — no link rewriting.

## Why a container

marker 2.x needs `torch>=2.7`, and PyTorch stopped publishing `macosx_x86_64` wheels
at 2.2.2. On an Intel Mac the newest installable marker is **0.2.6 (May 2024)**. On
Linux `x86_64` the current release installs normally, which is why this runs as an
image: the artefact is identical on any Linux host, and the Mac only ever speaks HTTP.

### Why llama.cpp is compiled in

`surya-ocr 0.22` dropped its torch backend. Layout still runs on rf-detr, but text
recognition spawns a `llama-server` subprocess and talks to it over HTTP — even on
CPU. Without that binary every request fails with:

```
SpawnError: llama-server binary not found
```

Upstream no longer publishes a plain x86_64 CPU tarball, and distro packages lag far
behind surya's expected flags, so the Dockerfile builds `llama-server` from the
pinned `${LLAMA_TAG}` in a builder stage and copies the static binary into the final
image. `GGML_NATIVE=OFF` + `GGML_AVX2=ON` keeps it runnable on any modern x86_64 CPU
instead of inheriting the build machine's feature set.

## Measured cost

On an i5-9600 (6 threads, no GPU), `hardware`, one 40-page paper:

| run | wall clock | why |
|---|---|---|
| very first ever | ~10 min | downloads the ~1.6 GB surya GGUF pair and initialises models |
| first after a container restart | ~100 s | weights are on the volume, but still load per process |
| warm | **56 s** (1.4 s/page) | models resident, conversion only |

So the deployment target should be kept running; the expensive states are all
one-time. A `systemd --user` unit with `Restart=always` does that.

## Build and run

```sh
podman build -t localhost/dsh-pdf-worker:0.1.0 .
podman run -d --name dsh-pdf --restart unless-stopped \
  -p 100.73.151.89:8765:8765 \
  -v dsh-pdf-models:/models \
  localhost/dsh-pdf-worker:0.1.0
```

- `-p <tailscale-ip>:8765:8765` publishes on the tailnet interface **only**. Use
  `tailscale ip -4` to print it. `0.0.0.0` would expose the endpoint to the whole
  LAN as well, which firewalld may or may not stop.
- `-v dsh-pdf-models:/models` holds the ~1.6 GB of weights, so upgrading the image
  does not re-download them. First conversion populates it.
- No `--memory` cap: marker wants ~4–6 GB resident on CPU. Give it a host with room.

Models load lazily on the first conversion (~20–40 s) and stay resident; that is the
reason this is a server and not a per-call process.

## Run it as a user service

`loginctl enable-linger $USER` first, so the unit survives logout. Then copy
[`dsh-pdf.service`](dsh-pdf.service) to `~/.config/systemd/user/` and:

```sh
systemctl --user daemon-reload
systemctl --user enable --now dsh-pdf
journalctl --user -u dsh-pdf -f
```

## Environment

| Variable | Default | Meaning |
|---|---|---|
| `HF_HOME` | `/models` | Model cache location; mount a volume here |
| `MAX_BYTES` | `209715200` | Upload ceiling, enforced before conversion |

## Licence

MIT for this code. marker and its weights are OpenRAIL-M: free for personal and
research use, commercial use above $5M revenue needs a Datalab licence.
