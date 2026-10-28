# syntax=docker/dockerfile:1

# ── llama.cpp ────────────────────────────────────────────────────────────────
# surya 0.22 dropped its torch backend: OCR inference spawns `llama-server` over
# HTTP even on CPU, so the binary is a hard runtime dependency, not an optional
# accelerator. Upstream publishes no plain x86_64 CPU tarball any more, and the
# distro package is far behind, so it is compiled here and copied into the final
# image; the toolchain never ships.
#
# GGML_NATIVE=OFF + GGML_AVX2=ON keeps the binary portable across x86_64 hosts
# instead of baking in whatever the build machine happened to support.
FROM python:3.12-slim AS llama

ARG LLAMA_TAG=b11898

RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential cmake git ca-certificates \
 && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch "${LLAMA_TAG}" https://github.com/ggml-org/llama.cpp /src

RUN cmake -S /src -B /src/build \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=OFF \
      -DGGML_NATIVE=OFF \
      -DGGML_AVX2=ON \
      -DLLAMA_CURL=OFF \
      -DLLAMA_BUILD_TESTS=OFF \
      -DLLAMA_BUILD_EXAMPLES=OFF \
 && cmake --build /src/build --target llama-server -j"$(nproc)"

# ── worker ──────────────────────────────────────────────────────────────────
FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    HF_HOME=/models \
    HF_HUB_DISABLE_TELEMETRY=1 \
    LLAMA_CPP_BINARY=/opt/llama/llama-server

# libgl/libglib are marker's raster path; libgomp is llama.cpp's thread pool.
RUN apt-get update \
 && apt-get install -y --no-install-recommends libgl1 libglib2.0-0 libgomp1 \
 && rm -rf /var/lib/apt/lists/*

COPY --from=llama /src/build/bin/llama-server /opt/llama/llama-server

WORKDIR /app

# torch first, from the CPU index, so the later marker resolve reuses it
# instead of pulling the CUDA build from PyPI.
RUN pip install --index-url https://download.pytorch.org/whl/cpu torch==2.8.0

COPY requirements.txt .
RUN pip install --extra-index-url https://download.pytorch.org/whl/cpu -r requirements.txt

COPY convert.py app.py ./

VOLUME ["/models"]
EXPOSE 8765

# A TCP probe, not a status route: the service exposes exactly one endpoint.
HEALTHCHECK --interval=30s --timeout=5s --start-period=120s --retries=3 \
  CMD python -c "import socket,sys; s=socket.create_connection(('127.0.0.1',8765),4); s.close(); sys.exit(0)"

ENTRYPOINT ["python", "-m", "uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8765"]
