#!/usr/bin/env bash

set -euo pipefail

if ! command -v awk >/dev/null; then
  echo "awk is required"
  exit 1
fi

if [ $# -lt 1 ]; then
  echo "Usage: $0 <markdown-file> <project-name> [-p, --prefixes]"
  exit 1
fi

FILE="$1"
shift

if [ ! -f "$FILE" ]; then
  echo "File not found: $FILE"
  exit 1
fi

PROJECT="${1:-}"
shift

echo "=== Taskwarrior Markdown Importer ==="

if [ -z "$PROJECT" ]; then
  while true; do
    read -rp "Project name: " INPUT_PROJECT

    if [ ! -z "$INPUT_PROJECT" ]; then
      PROJECT="$INPUT_PROJECT"
      break
    fi
  done
fi

echo "Project: $PROJECT, File: $FILE"

get_task() {
  awk -v line="$1" '
    BEGIN {
      gsub(/\r/, "", line)
      gsub(/\t/, "    ", line)

      match(line, /^ */)
      indent = int(RLENGTH / 4)

      trimmed = substr(line, RLENGTH + 1)

      checked = "false"

      if (match(trimmed, /^[-*+][[:space:]]*\[([xX ])\][[:space:]]*/)) {
        if (substr(trimmed, RSTART+2, 3) ~ /[xX]/) {
          checked = "true"
        }

        trimmed = substr(trimmed, RLENGTH + 1)

        while (match(trimmed, /\[\[[^]]+\]\]/)) {
          link = substr(trimmed, RSTART + 2, RLENGTH - 4)  # content inside [[ ]]
          n = split(link, tmp, /\|/)
          replacement = tmp[n]  # last part (after | if exists)

          trimmed = substr(trimmed, 1, RSTART - 1) replacement substr(trimmed, RSTART + RLENGTH)
        }

        gsub(/  +/, " ", trimmed)

        n = split(trimmed, parts, /;;/)

        description = parts[1]
        priority = (n >= 2 && parts[2] != "" ? parts[2] : "L")
        due = (n >= 3 && parts[3] != "" ? parts[3] : "today")

        printf "%d\x1f%s\x1f%s\x1f%s\x1f%s\n",
        indent, checked, description, priority, due
      }
    }'
}

insert_uuid_on_file() {
  local file="$1"
  local lineno="$2"
  local uuid="$3"

  local short="${uuid:0:8}"

  if sed -n "${lineno}p" "$file" | grep -q "task:"; then
    return
  fi

  sed -i "${lineno}s|\$| <!-- task:${short} -->|" "$file"
}

PARENT=""
FILE_PATH=$(realpath "$FILE")
COLUMN=0

mapfile -t lines <"$FILE"

for ((i = 0; i < ${#lines[@]}; i++)); do
  line="${lines[i]}"
  next_line="${lines[i + 1]:-}"

  task=$(get_task "$line")
  IFS=$'\x1f' read -r indent _ description priority due <<<"$task"

  if ((indent < COLUMN)); then
    PARENT=""
  fi

  COLUMN="$indent"

  if [[ -z "${description// /}" || "$line" =~ task: ]]; then
    continue
  fi

  if [[ -n "$next_line" ]]; then
    next_task=$(get_task "$next_line")
    IFS=$'\x1f' read -r next_indent _ _ _ _ <<<"$next_task"

    if ((next_indent > indent)); then
      PARENT="$description"
      continue
    fi
  fi

  id=$(task add "$description" project:"${PARENT:-$PROJECT}" priority:"$priority" due:"$due" mdfile:"$FILE_PATH" |
    grep -oP 'Created task \K[0-9]+')

  uuid=$(task _get "$id".uuid)

  insert_uuid_on_file "$FILE" "$((i + 1))" "$uuid"
done
