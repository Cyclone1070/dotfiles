"""Convert one PDF into Markdown plus PNG figures, using marker.

The model dictionary is built once per process and reused for every request:
loading it is the expensive part (~20-40 s on CPU), and a warm server is the
entire reason this runs as a service instead of a per-call process.
"""

from __future__ import annotations

import re
import threading
import time
from pathlib import Path

# Serialise conversions: marker is CPU-bound and its converter is not written
# for concurrent use, so a second request waits rather than thrashing six cores.
_LOCK = threading.Lock()
_MODEL_DICT = None


def _models():
    """Build the marker model dictionary once, lazily."""
    global _MODEL_DICT
    if _MODEL_DICT is None:
        from marker.models import create_model_dict

        _MODEL_DICT = create_model_dict()
    return _MODEL_DICT


def _safe_stem(name: str, index: int) -> str:
    stem = Path(name).stem
    stem = re.sub(r"[^A-Za-z0-9._-]+", "-", stem).strip("-._") or f"image-{index}"
    return stem


def convert(pdf_bytes: bytes, base_name: str) -> dict:
    """Render one PDF.

    :param pdf_bytes: the document itself.
    :param base_name: stem used for the Markdown file and its assets directory.
    :returns: ``{"markdown": <file name>, "files": {<relative path>: bytes},
        "pages": int, "images": int, "elapsed_ms": int}``

    The Markdown refers to figures as ``<base_name>.assets/<file>.png``, so the
    caller can drop every returned file into one directory and the document is
    complete without rewriting a single link.
    """
    from marker.converters.pdf import PdfConverter
    from marker.output import text_from_rendered

    started = time.time()
    # A private temp file: marker reads by path, and every request is isolated.
    import tempfile

    with tempfile.NamedTemporaryFile(suffix=".pdf") as handle:
        handle.write(pdf_bytes)
        handle.flush()

        converter = PdfConverter(
            artifact_dict=_models(),
            config={"output_format": "markdown", "mode": "fast"},
        )
        with _LOCK:
            rendered = converter(handle.name)
        markdown, _ext, images = text_from_rendered(rendered)

    assets_dir = f"{base_name}.assets"
    files: dict[str, bytes] = {}
    for index, (original, image) in enumerate(sorted((images or {}).items())):
        target = f"{_safe_stem(original, index)}.png"
        if target in {p.split("/")[-1] for p in files}:
            target = f"{_safe_stem(original, index)}-{index}.png"
        import io

        buffer = io.BytesIO()
        image.save(buffer, format="PNG")
        files[f"{assets_dir}/{target}"] = buffer.getvalue()
        markdown = markdown.replace(f"]({original})", f"]({assets_dir}/{target})")
        markdown = markdown.replace(f"](<{original}>)", f"]({assets_dir}/{target})")

    markdown_name = f"{base_name}.md"
    files[markdown_name] = markdown.encode("utf-8")

    # Marker's rendered metadata carries no reliable page count, so ask the
    # document itself — pypdfium2 is already a marker dependency.
    import pypdfium2 as pdfium

    with pdfium.PdfDocument(pdf_bytes) as document:
        pages = len(document)

    return {
        "markdown": markdown_name,
        "assets": assets_dir,
        "files": files,
        "pages": pages,
        "images": len(files) - 1,
        "elapsed_ms": int((time.time() - started) * 1000),
    }
