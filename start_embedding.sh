#!/bin/bash

export MODEL="BAAI/bge-m3"
export API_KEY="my-api-key"

vllm serve $MODEL \
  --api-key $API_KEY \
  --port 80