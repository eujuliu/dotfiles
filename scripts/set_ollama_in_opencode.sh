#!/bin/bash

CONFIG_FILE="$HOME/.config/opencode/opencode.json"

models_json=$(ollama list | tail -n +2 | awk '{
  name=$1
  gsub(/"/, "\\\"", name)
  print "\"" name "\": {\"name\": \""name"\"}"
}' | paste -sd ',' | sed 's/^/{/;s/$/}/')

jq --argjson models "$models_json" \
  '.provider.ollama.models = $models' \
  "$CONFIG_FILE" >"${CONFIG_FILE}.tmp" &&
  mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
