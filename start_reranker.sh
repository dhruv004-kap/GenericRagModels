#!/bin/bash

export MODEL="BAAI/bge-reranker-v2-m3"
export API_KEY="my-api-key"

vllm serve $MODEL \
  --api-key $API_KEY \
  --gpu-memory-utilization 0.45 \
  --port 8081