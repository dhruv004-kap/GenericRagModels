# GenericRagModels Setup Guide

This repository contains small startup scripts and Supervisor configs for serving
embedding and reranking models with vLLM.

## Models

| Service | Model | Startup script |
| --- | --- | --- |
| Embeddings | `BAAI/bge-m3` | `start_embedding.sh` |
| Reranker | `BAAI/bge-reranker-v2-m3` | `start_reranker.sh` |

## Prerequisites

- Ubuntu or another Linux host with `apt`
- NVIDIA GPU drivers and CUDA-compatible runtime for vLLM
- Python 3.13
- `sudo` access

## 1. Clone the Repository

```bash
git clone https://github.com/dhruv004-kap/GenericRagModels.git
cd GenericRagModels
```

If you are deploying on the included Supervisor configs without editing paths,
place the repo at:

```bash
/home/jovyan/GenericRagModels
```

Otherwise, update `command`, `directory`, and `environment=PATH=...` in the
Supervisor config files before copying them into `/etc/supervisor/conf.d/`.

## 2. Install uv

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Restart your shell, or source the uv environment file printed by the installer,
so the `uv` command is available.

## 3. Create the Python Environment

```bash
uv venv --python 3.13
source .venv/bin/activate
```

## 4. Install Dependencies

```bash
uv pip install -r requirements.txt --torch-backend=auto
```

The current dependency set installs:

```text
vllm==0.23.0
```

## 5. Configure the Services

Before starting the services, review the startup scripts:

- `start_embedding.sh`
- `start_reranker.sh`

Both scripts currently use:

```bash
export API_KEY="my-api-key"
--port 80
```

Change `API_KEY` before deploying. If both services will run on the same host,
put them on different ports, for example:

```bash
# start_embedding.sh
--port 8001

# start_reranker.sh
--port 8002
```

## 6. Install Supervisor

```bash
sudo apt-get update
sudo apt-get install supervisor -y
sudo supervisord -c /etc/supervisor/supervisord.conf
```

If Supervisor is already running, the final command may not be necessary.

## 7. Register the Services

```bash
sudo cp ./serve_embedding.service /etc/supervisor/conf.d/serve_embedding.conf
sudo cp ./serve_reranker.service /etc/supervisor/conf.d/serve_reranker.conf
```

Reload Supervisor:

```bash
sudo supervisorctl reread
sudo supervisorctl update
```

## 8. Start and Check Services

Start the services:

```bash
sudo supervisorctl start serve_embedding
sudo supervisorctl start serve_reranker
```

Check status:

```bash
sudo supervisorctl status
```

Follow logs:

```bash
tail -f /var/log/serve_embedding-stdout.log
tail -f /var/log/serve_reranker-stdout.log
```

## 9. Quick API Checks

Embedding service:

```bash
curl http://localhost:8001/v1/embeddings \
  -H "Authorization: Bearer my-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "BAAI/bge-m3",
    "input": "GenericRagModels is serving embeddings with vLLM."
  }'
```

Reranker service:

```bash
curl http://localhost:8002/v1/score \
  -H "Authorization: Bearer my-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "BAAI/bge-reranker-v2-m3",
    "text_1": "What does this repository serve?",
    "text_2": "It serves embedding and reranking models with vLLM."
  }'
```

## Troubleshooting

- `command not found: uv`: restart the shell or source the uv environment file
  printed during installation.
- Service exits immediately: check `/var/log/*stderr.log` for dependency,
  model download, CUDA, or permission errors.
- `supervisorctl start serve_embedding` cannot find the service: confirm the
  Supervisor config uses `[program:serve_embedding]`.
- Port conflict: each running vLLM server needs a unique port.
- Model download fails: confirm the host has internet access and any required
  Hugging Face credentials are configured.
