#!/usr/bin/env bash
# start_llama.sh - Pick a GGUF model with fzf and start llama.cpp server in Docker.
#
# Configuration comes from environment variables (the Makefile exports them).
# If the model's folder contains an mmproj file, it is passed with --mmproj.
#
#   bash .scripts/start_llama.sh            # interactive
#   bash .scripts/start_llama.sh --check    # only validate config/dependencies
#   DRY_RUN=1 bash .scripts/start_llama.sh  # print the docker command, don't run it
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MODEL_DIR="${MODEL_DIR:-$HOME/.lmstudio/models}"
MODEL_DIR="${MODEL_DIR%/}"
DOCKER_IMAGE="${DOCKER_IMAGE:-local/llama.cpp:server-cuda}"
PORT="${PORT:-8081}"
HOST="${HOST:-0.0.0.0}"
FIT="${FIT:-on}"
FIT_TARGET="${FIT_TARGET:-1024}"
FIT_CTX="${FIT_CTX:-8192}"
FILTER_MMPROJ="${FILTER_MMPROJ:-1}" # 1 = hide mmproj files from the model list
USE_MMPROJ="${USE_MMPROJ:-1}"       # 1 = auto-add --mmproj when one is found
REASONING_BUDGET="${REASONING_BUDGET:-}"
REASONING_EFFORT="${REASONING_EFFORT:-}"
ARGS="${ARGS:-}"
PYTHON="${PYTHON:-python3}"
INFO_SCRIPT="${INFO_SCRIPT:-$SCRIPT_DIR/gguf_info.py}"
DRY_RUN="${DRY_RUN:-0}"

# Strip leading/trailing whitespace from every setting (e.g. values coming
# from a Makefile with an inline comment keep the spaces before the "#").
trim() {
  local s=$1
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

for _v in MODEL_DIR DOCKER_IMAGE PORT HOST FIT FIT_TARGET FIT_CTX FILTER_MMPROJ \
  USE_MMPROJ REASONING_BUDGET REASONING_EFFORT ARGS PYTHON INFO_SCRIPT DRY_RUN; do
  printf -v "$_v" '%s' "$(trim "${!_v}")"
done

unset _v
MODEL_DIR="${MODEL_DIR%/}"

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

# ----------------------------------------------------------------------------
# Validation
# ----------------------------------------------------------------------------
validate() {
  local cmd var
  for cmd in fzf docker find numfmt; do
    command -v "$cmd" >/dev/null 2>&1 || die "$cmd is required."
  done
  [[ -d $MODEL_DIR ]] || die "MODEL_DIR does not exist: $MODEL_DIR"

  for var in PORT FIT_TARGET FIT_CTX; do
    [[ ${!var} =~ ^[0-9]+$ ]] || die "Invalid $var: '${!var}' (must be an integer)."
  done
  for var in FILTER_MMPROJ USE_MMPROJ DRY_RUN; do
    [[ ${!var} =~ ^[01]$ ]] || die "$var must be 0 or 1."
  done
  [[ $FIT =~ ^(on|off)$ ]] || die "FIT must be 'on' or 'off'."
  [[ -z $REASONING_BUDGET || $REASONING_BUDGET =~ ^-?[0-9]+$ ]] ||
    die "REASONING_BUDGET must be an integer."
  [[ -z $REASONING_EFFORT || $REASONING_EFFORT =~ ^(none|low|medium|high|xhigh)$ ]] ||
    die "REASONING_EFFORT must be one of: none, low, medium, high, xhigh."
}

# ----------------------------------------------------------------------------
# Model listing / selection
# ----------------------------------------------------------------------------
# Prints: <full path> \t <size> \t <quant> \t <path relative to MODEL_DIR>
list_models() {
  local shard_re='-([0-9]+)-of-[0-9]+\.gguf$'
  local quant_re='(IQ[0-9]+(_[A-Z0-9]+)*|Q[0-9]+(_[A-Z0-9]+)*|BF16|F16|F32)'
  local size path name lower upper quant

  find "$MODEL_DIR" -type f -iname '*.gguf' -printf '%s\t%p\n' |
    sort -t$'\t' -k2 |
    numfmt -d $'\t' --field=1 --to=iec-i --suffix=B |
    while IFS=$'\t' read -r size path; do
      [[ -n $path ]] || continue
      name=${path##*/}
      lower=${name,,}
      upper=${name^^}

      # Hide mmproj files from the list (they are attached automatically)
      if [[ $FILTER_MMPROJ == 1 && $lower == *mmproj* ]]; then
        continue
      fi
      # Split models (xxx-00001-of-00003.gguf): list only the first shard
      if [[ $lower =~ $shard_re ]] && ((10#${BASH_REMATCH[1]} != 1)); then
        continue
      fi

      quant="Unknown"
      if [[ $upper =~ $quant_re ]]; then
        quant=${BASH_REMATCH[1]}
      fi
      printf '%s\t%-9s\t%-9s\t%s\n' "$path" "$size" "$quant" "${path#"$MODEL_DIR"/}"
    done
}

pick_model() {
  local entries preview_args=()
  entries=$(list_models)
  [[ -n $entries ]] || die "No GGUF models found in $MODEL_DIR"

  if [[ -f $INFO_SCRIPT ]]; then
    preview_args=(
      --preview "$(printf '%q %q {1}' "$PYTHON" "$INFO_SCRIPT") 2>&1"
      --preview-window 'right:55%:wrap'
    )
  fi

  fzf <<<"$entries" \
    --delimiter=$'\t' \
    --with-nth=2.. \
    --accept-nth=1 \
    --height=85% \
    --layout=reverse \
    --border \
    --header='SIZE      | QUANT     | MODEL' \
    --prompt='Select model > ' \
    "${preview_args[@]}"
}

# Prints the mmproj file that lives in the same folder as the model (if any).
# When there are several, lets you choose one.
select_mmproj() {
  local model=$1
  local -a found
  mapfile -t found < <(find "$(dirname "$model")" -maxdepth 1 -type f -iname '*mmproj*.gguf' | sort)

  case ${#found[@]} in
  0) return 0 ;;
  1) printf '%s\n' "${found[0]}" ;;
  *) printf '%s\n' "${found[@]}" | fzf \
    --delimiter=/ --with-nth=-1 \
    --height=40% --layout=reverse --border \
    --header='Multiple mmproj files found' \
    --prompt='Select mmproj > ' ;;
  esac
}

# Host path -> path inside the container
to_container_path() { printf '/models/%s' "${1#"$MODEL_DIR"/}"; }

# ----------------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------------
main() {
  validate
  if [[ ${1:-} == --check ]]; then
    echo "OK"
    return 0
  fi

  echo "Searching GGUF models..."
  local model
  model=$(pick_model) || die "No model selected or selection cancelled."

  local model_name=${model##*/}
  model_name=${model_name,,}

  # Vision projector: use the mmproj found next to the model
  local mmproj=""
  if [[ $USE_MMPROJ == 1 && $model_name != *mmproj* ]]; then
    mmproj=$(select_mmproj "$model" || true)
  fi

  echo
  echo "Model : $model"
  if [[ -n $mmproj ]]; then
    echo "mmproj: $mmproj"
  fi

  local -a cmd=(
    docker run --rm --init
    --name "llama-server-$PORT"
    --gpus all
    -p "$PORT:8080"
    -v "$MODEL_DIR:/models:ro"
    "$DOCKER_IMAGE"
    -m "$(to_container_path "$model")"
    --port 8080
    --host "$HOST"
    --fit "$FIT"
    --fit-target "$FIT_TARGET"
    --fit-ctx "$FIT_CTX"
  )

  if [[ -n $mmproj ]]; then
    cmd+=(--mmproj "$(to_container_path "$mmproj")")
  fi

  if [[ -n $REASONING_BUDGET ]]; then
    cmd+=(--reasoning-budget "$REASONING_BUDGET")
  fi

  if [[ -n $REASONING_EFFORT ]]; then
    cmd+=(--reasoning-effort "$REASONING_EFFORT")
  fi

  if [[ -n $ARGS ]]; then
    local -a extra
    read -r -a extra <<<"$ARGS"
    cmd+=("${extra[@]}")
  fi

  echo
  printf 'Command:'
  printf ' %q' "${cmd[@]}"
  echo
  echo

  if [[ $DRY_RUN == 1 ]]; then
    echo "(dry run, not starting the server)"
    return 0
  fi

  echo "Starting llama.cpp server on http://localhost:$PORT ..."
  exec "${cmd[@]}"
}

main "$@"
