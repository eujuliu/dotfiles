#!/usr/bin/env python3
"""
gguf_info.py - Extract information from a .gguf model using the `gguf` library.

The result is cached in a .txt file next to the model, so the model is only
parsed once. The cache is rebuilt automatically if the model file changes
(or if an mmproj file is added/removed from the folder).

Icons need a Nerd Font set as the terminal font: https://www.nerdfonts.com

Install:  pip install gguf
Usage:    python gguf_info.py path/to/model.gguf
          python gguf_info.py path/to/model.gguf --refresh   (ignore the cache)
"""

import os
import sys
from collections import Counter

CACHE_SUFFIX = ".info.txt"  # model.gguf -> model.gguf.info.txt
CACHE_HEADER = "# gguf_info cache v2"

# Nerd Font icons + ANSI colors for each capability (display order)
CAPABILITIES = [
    # key,         label,       icon,     ansi color
    ("vision", "vision", "\uf06e", "33"),  # eye
    ("tool_use", "tool use", "\uf0ad", "34"),  # wrench
    ("reasoning", "reasoning", "\uf0eb", "32"),  # lightbulb
    ("audio", "audio", "\uf130", "35"),  # microphone
    ("embedding", "embedding", "\uf1b3", "36"),  # cubes
]


# ----------------------------------------------------------------------------
# mmproj lookup (vision projector files live next to the model)
# ----------------------------------------------------------------------------
def find_mmproj_files(model_path):
    folder = os.path.dirname(os.path.abspath(model_path))
    me = os.path.basename(model_path)
    try:
        return sorted(
            f
            for f in os.listdir(folder)
            if "mmproj" in f.lower() and f.lower().endswith(".gguf") and f != me
        )
    except OSError:
        return []


# ----------------------------------------------------------------------------
# Cache
# ----------------------------------------------------------------------------
def cache_path_for(model_path):
    return model_path + CACHE_SUFFIX


def file_signature(model_path):
    """Size + mtime + mmproj files: changes whenever the result could change."""
    st = os.stat(model_path)
    mmproj = ",".join(find_mmproj_files(model_path))
    return f"size={st.st_size} mtime={int(st.st_mtime)} mmproj={mmproj}"


def load_cache(model_path):
    """Return the cached report, or None if missing/outdated/corrupted."""
    cache = cache_path_for(model_path)
    if not os.path.isfile(cache):
        return None
    try:
        with open(cache, "r", encoding="utf-8") as f:
            lines = f.read().splitlines()
        if len(lines) < 3 or lines[0] != CACHE_HEADER:
            return None
        if lines[1] != f"# {file_signature(model_path)}":
            return None
        return "\n".join(lines[2:])
    except OSError:
        return None


def save_cache(model_path, report):
    cache = cache_path_for(model_path)
    try:
        with open(cache, "w", encoding="utf-8") as f:
            f.write(f"{CACHE_HEADER}\n# {file_signature(model_path)}\n{report}\n")
    except OSError as e:
        print(f"(warning: could not write cache file: {e})", file=sys.stderr)


# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------
def get_field(reader, key, default=None):
    """Read a metadata value from the GGUF header (works across gguf versions)."""
    field = reader.fields.get(key)
    if field is None:
        return default
    try:
        return field.contents()  # newer gguf versions
    except AttributeError:
        pass
    try:
        part = field.parts[field.data[0]]
        if field.types and field.types[0].name == "STRING":
            return bytes(part).decode("utf-8", errors="replace")
        value = part.tolist()
        return value[0] if len(value) == 1 else value
    except Exception:
        return default


def array_length(reader, key):
    """Length of an array field without decoding every element."""
    field = reader.fields.get(key)
    return len(field.data) if field is not None else None


def format_size(num_bytes):
    return (
        f"{num_bytes / 1024**3:.2f} GB | "
        f"{num_bytes / 1024**2:.2f} MB | "
        f"{num_bytes / 1024:.2f} KB"
    )


def format_params(n):
    if n >= 1e9:
        return f"{n / 1e9:.2f}B"
    if n >= 1e6:
        return f"{n / 1e6:.0f}M"
    if n >= 1e3:
        return f"{n / 1e3:.0f}K"
    return str(n)


def detect_quantization(reader):
    """Return the quantization label (e.g. Q4_K_M)."""
    from gguf import GGMLQuantizationType

    try:
        from gguf import LlamaFileType
    except ImportError:  # very old gguf versions
        LlamaFileType = None

    # 1) Official file type stored in the metadata
    file_type = get_field(reader, "general.file_type")
    if file_type is not None and LlamaFileType is not None:
        try:
            return LlamaFileType(int(file_type)).name.replace("MOSTLY_", "")
        except ValueError:
            pass

    # 2) Fallback: most common tensor type (ignoring F32 norm/bias tensors)
    counts = Counter()
    for t in reader.tensors:
        counts[t.tensor_type] += int(t.n_elements)
    if not counts:
        return "unknown"
    non_f32 = {k: v for k, v in counts.items() if k != GGMLQuantizationType.F32}
    pool = non_f32 or counts
    return GGMLQuantizationType(max(pool, key=pool.get)).name


def detect_capabilities(reader, arch, name, mmproj_files):
    """Heuristics based on metadata, tensor names, chat template and mmproj files."""
    template = get_field(reader, "tokenizer.chat_template", "") or ""
    template_l = (template if isinstance(template, str) else str(template)).lower()
    name_l = (name or "").lower()
    tensor_names = [t.name for t in reader.tensors]

    caps = {}

    # Vision: this file is a projector, has vision tensors, or an mmproj sits next to it
    caps["vision"] = (
        arch == "clip"
        or bool(mmproj_files)
        or bool(get_field(reader, "clip.has_vision_encoder", False))
        or any(
            n.startswith(("v.", "visual.", "vision_tower.", "mm."))
            for n in tensor_names
        )
    )

    caps["audio"] = bool(get_field(reader, "clip.has_audio_encoder", False)) or any(
        n.startswith(("a.", "audio.")) for n in tensor_names
    )

    caps["tool_use"] = any(
        k in template_l
        for k in (
            "tools",
            "tool_call",
            "<tool_call>",
            "function_call",
            "[tool_calls]",
            "available_tools",
        )
    )

    caps["reasoning"] = any(
        k in template_l
        for k in ("<think>", "</think>", "enable_thinking", "reasoning", "<|thinking|>")
    ) or any(k in name_l for k in ("reason", "thinking", "-r1", "qwq", "deepseek-r1"))

    caps["embedding"] = get_field(reader, f"{arch}.pooling_type") is not None
    caps["chat_template"] = bool(template)
    return caps


# ----------------------------------------------------------------------------
# Report (plain text, this is what gets cached)
# ----------------------------------------------------------------------------
def build_report(path):
    """Parse the GGUF file (the expensive part) and return the text report."""
    from gguf import GGUFReader

    reader = GGUFReader(path)
    mmproj_files = find_mmproj_files(path)

    arch = get_field(reader, "general.architecture", "unknown")
    name = (
        get_field(reader, "general.name") or os.path.splitext(os.path.basename(path))[0]
    )
    size_label = get_field(reader, "general.size_label")
    context_len = get_field(reader, f"{arch}.context_length")

    total_params = sum(int(t.n_elements) for t in reader.tensors)
    caps = detect_capabilities(reader, arch, name, mmproj_files)

    # Capabilities: icons side by side + plain names as fallback (no Nerd Font)
    enabled = [(label, icon) for key, label, icon, _ in CAPABILITIES if caps.get(key)]
    if enabled:
        cap_line = (
            " ".join(icon for _, icon in enabled)
            + "  ("
            + ", ".join(l for l, _ in enabled)
            + ")"
        )
    else:
        cap_line = "none"

    lines = [
        f"File           : {os.path.basename(path)}",
        f"Model Name     : {name}",
        f"Architecture   : {arch}",
        f"Quantization   : {detect_quantization(reader)}",
        f"Parameters     : {format_params(total_params)} ({total_params:,})"
        + (f"  [{size_label}]" if size_label else ""),
        f"File Size      : {format_size(os.path.getsize(path))}",
        f"Context Length : {context_len:,}" if context_len else "Context Length : n/a",
        f"Capabilities   : {cap_line}",
    ]

    # --- Extra info (kept short) -------------------------------------------
    extra = []

    def add(label, value):
        if value not in (None, "", []):
            extra.append(f"  {label:<14}: {value}")

    add(
        "Author",
        get_field(reader, "general.organization")
        or get_field(reader, "general.author"),
    )
    add("License", get_field(reader, "general.license"))
    add("Layers", get_field(reader, f"{arch}.block_count"))
    add("Embedding dim", get_field(reader, f"{arch}.embedding_length"))
    heads = get_field(reader, f"{arch}.attention.head_count")
    kv_heads = get_field(reader, f"{arch}.attention.head_count_kv")
    if heads is not None and not isinstance(heads, list):
        add(
            "Attn heads",
            f"{heads}" + (f" (KV: {kv_heads})" if isinstance(kv_heads, int) else ""),
        )
    vocab = array_length(reader, "tokenizer.ggml.tokens")
    add("Vocab size", f"{vocab:,}" if vocab else None)
    add("Tokenizer", get_field(reader, "tokenizer.ggml.model"))
    add("Tensors", f"{len(reader.tensors):,}")
    if mmproj_files:
        add("Vision file", ", ".join(mmproj_files))
    elif arch == "clip":
        add("Note", "this file is a vision projector (mmproj)")

    lines.append("")
    lines.append("Extra info")
    lines.extend(extra)
    return "\n".join(lines)


# ----------------------------------------------------------------------------
# Output
# ----------------------------------------------------------------------------
def print_report(report, source=None):
    """Print the report; colorize the capability icons when stdout is a terminal."""
    if sys.stdout.isatty() and not os.environ.get("NO_COLOR"):
        for _, _, icon, color in CAPABILITIES:
            report = report.replace(icon, f"\033[{color}m{icon}\033[0m")
    width = 50
    print("=" * width)
    print(report)
    print("=" * width)
    if source:
        print(f"(loaded from cache: {source})")


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # icons on Windows consoles
    except Exception:
        pass

    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    refresh = "--refresh" in sys.argv[1:]

    if len(args) != 1:
        print(f"Usage: python {os.path.basename(sys.argv[0])} <model.gguf> [--refresh]")
        sys.exit(1)

    path = args[0]
    if not os.path.isfile(path):
        print(f"File not found: {path}")
        sys.exit(1)

    if not refresh:
        cached = load_cache(path)
        if cached is not None:
            print_report(cached, source=os.path.basename(cache_path_for(path)))
            return

    report = build_report(path)
    save_cache(path, report)
    print_report(report)


if __name__ == "__main__":
    main()
