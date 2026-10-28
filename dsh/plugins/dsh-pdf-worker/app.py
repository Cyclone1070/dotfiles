"""dsh-pdf-worker — one endpoint, no state.

``POST /convert`` takes a PDF and a base name, and answers with a
``multipart/form-data`` body holding the Markdown and its figures. Nothing is
persisted: the document is converted in memory, streamed back, and dropped.

Deliberately absent: a job queue, a database, storage, and a health route. The
client posts a file and receives files; if it cannot reach this process it says
so, which is more useful than a status page nobody reads.
"""

from __future__ import annotations

import io
import uuid

from fastapi import FastAPI, File, HTTPException, Form, UploadFile
from fastapi.responses import StreamingResponse

from convert import convert

MAX_BYTES = 200 * 1024 * 1024
CONTENT_TYPES = {
    ".md": "text/markdown; charset=utf-8",
    ".png": "image/png",
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
}

app = FastAPI(title="dsh-pdf-worker", docs_url=None, redoc_url=None, openapi_url=None)


def _multipart(parts: list[tuple[str, bytes]]) -> tuple[bytes, str]:
    """Encode parts as multipart/form-data keyed by relative path.

    ``filename`` carries the path, so a client can reconstruct the tree without
    a second metadata channel.
    """
    boundary = f"----dshpdf{uuid.uuid4().hex}"
    body = io.BytesIO()
    for name, data in parts:
        content_type = CONTENT_TYPES.get("." + name.rsplit(".", 1)[-1].lower(), "application/octet-stream")
        body.write(
            f"--{boundary}\r\n"
            f'Content-Disposition: form-data; name="files"; filename="{name}"\r\n'
            f"Content-Type: {content_type}\r\n\r\n".encode()
        )
        body.write(data)
        body.write(b"\r\n")
    body.write(f"--{boundary}--\r\n".encode())
    return body.getvalue(), boundary


@app.post("/convert")
def convert_endpoint(
    file: UploadFile = File(...),
    name: str = Form(default="document"),
):
    """Convert one uploaded PDF; respond with its Markdown and figures."""
    data = file.file.read(MAX_BYTES + 1)
    if len(data) > MAX_BYTES:
        raise HTTPException(status_code=413, detail=f"file exceeds {MAX_BYTES} bytes")
    if not data.startswith(b"%PDF"):
        raise HTTPException(status_code=415, detail="not a PDF")

    stem = "".join(ch for ch in name if ch.isalnum() or ch in "-_")[:80] or "document"
    try:
        result = convert(data, stem)
    except Exception as error:  # surface a usable message, not a traceback
        raise HTTPException(status_code=500, detail=f"{type(error).__name__}: {error}") from error

    parts = sorted(result["files"].items())
    body, boundary = _multipart(parts)
    return StreamingResponse(
        io.BytesIO(body),
        media_type=f"multipart/form-data; boundary={boundary}",
        headers={
            "X-Dsh-Pages": str(result["pages"]),
            "X-Dsh-Images": str(result["images"]),
            "X-Dsh-Elapsed-Ms": str(result["elapsed_ms"]),
        },
    )
