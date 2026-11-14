SHELL := /bin/bash

# NOTE: never put a comment on the same line as a variable assignment.
# Make keeps the spaces before the "#" as part of the value.

# ---- Configuration (override with: make start_llama PORT=9000) -------------
MODEL_DIR     ?= $(HOME)/.lmstudio/models
DOCKER_IMAGE  ?= local/llama.cpp:server-cuda

PORT          ?= 8081
HOST          ?= 0.0.0.0

FIT           ?= on
FIT_TARGET    ?= 1024
FIT_CTX       ?= 8192

# 1 = hide mmproj files from the model list
FILTER_MMPROJ ?= 1
# 1 = add --mmproj automatically when found next to the model
USE_MMPROJ    ?= 1

REASONING_BUDGET ?=
REASONING_EFFORT ?=

# extra llama-server args, e.g. ARGS="-c 16384 --jinja"
ARGS          ?=
# 1 = only print the docker command
DRY_RUN       ?= 0

PYTHON        := $(CURDIR)/.venv/bin/python
SCRIPTS       := $(CURDIR)/.scripts

export MODEL_DIR DOCKER_IMAGE PORT HOST FIT FIT_TARGET FIT_CTX \
       FILTER_MMPROJ USE_MMPROJ REASONING_BUDGET REASONING_EFFORT \
       ARGS DRY_RUN PYTHON

.PHONY: start_llama check install test_script_model_info

install:
	$(PYTHON) -m pip install -r requirements.txt

test_script_model_info:
	$(PYTHON) $(SCRIPTS)/gguf_info.py "$(MODEL_DIR)/IFM/K2-Horizon-3.7B-GGUF/K2-Horizon-4B-Q4_K_M.gguf"

check:
	@bash $(SCRIPTS)/start_llama.sh --check

start_llama:
	@bash $(SCRIPTS)/start_llama.sh
