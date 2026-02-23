#!/usr/bin/env bash
#------------------------------------------------------------------------------
# wh - Whisper transcription wrapper using whisper-ctranslate2
#------------------------------------------------------------------------------
set -euo pipefail

# GLOBAL_HF_TOKEN can be:
#   - Direct token: "hf_xxxx..."
#   - 1Password reference: "op://vault/item/field" (requires `op run`)
: "${GLOBAL_HF_TOKEN:=}"

if [[ -z "${1:-}" ]]; then
    cat <<EOF
Usage: wh <input_file> [extra whisper-ctranslate2 args...]

Transcribes audio/video using whisper-ctranslate2 with pyannote diarization.
Output saved to <input_file>_whisper/ directory.

Environment:
  GLOBAL_HF_TOKEN    HuggingFace token (required for pyannote)
              Can be direct token or 1Password ref (op://...)

Examples:
  wh video.mp4
  wh audio.mp3 --model large-v3
  wh interview.wav --language auto
EOF
    exit 1
fi

if [[ -z "$GLOBAL_HF_TOKEN" ]]; then
    echo "wh: GLOBAL_HF_TOKEN not set. Required for pyannote diarization." >&2
    echo "Set in \$DOTLOC/.env or export GLOBAL_HF_TOKEN=..." >&2
    exit 1
fi

infile="$1"
shift

if [[ ! -f "$infile" ]]; then
    echo "wh: file not found: $infile" >&2
    exit 1
fi

outdir="${infile%.*}_whisper"
mkdir -p "$outdir"

run_whisper() {
    uvx --python 3.12 \
        --with 'torch==2.5.1' \
        --with 'torchaudio==2.5.1' \
        --with 'huggingface_hub==0.36.0' \
        --with 'pyannote.audio>=3.1,<4.0.0' \
        --from whisper-ctranslate2 whisper-ctranslate2 \
        "$infile" \
        --device auto \
        --hf_token "$GLOBAL_HF_TOKEN" \
        --language en \
        --compute_type int8 \
        --batched True \
        --batch_size 32 \
        --vad_filter True \
        --output_dir "$outdir" \
        "$@"
}

if [[ "$GLOBAL_HF_TOKEN" == op://* ]]; then
    if ! command -v op >/dev/null 2>&1; then
        echo "wh: GLOBAL_HF_TOKEN is an op:// reference but 1Password CLI not found" >&2
        exit 1
    fi
    export infile outdir
    exec op run -- bash -c "$(declare -f run_whisper); run_whisper \"\$@\"" _ "$@"
else
    run_whisper "$@"
fi
