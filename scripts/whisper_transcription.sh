#!/bin/bash

set -euo pipefail

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command '$1' not found on PATH." >&2
    exit 1
  fi
}

if [[ $# -gt 0 ]]; then
  filepath="$1"
else
  read -rp "Enter the full path to the media file to transcribe: " filepath
fi

if [[ -z "${filepath}" ]]; then
  echo "No file provided. Exiting." >&2
  exit 1
fi

if [[ ! -f "${filepath}" ]]; then
  echo "File not found: ${filepath}" >&2
  exit 2
fi

filename="$(basename "${filepath}")"
basename="${filename%.*}"
filedir="$(cd "$(dirname "${filepath}")" && pwd)"
extension="${filename##*.}"
extension="$(printf '%s' "${extension}" | tr '[:upper:]' '[:lower:]')"

whisperdir="${WHISPER_CPP_DIR:-}"
if [[ -z "${whisperdir}" ]]; then
  echo "Set WHISPER_CPP_DIR (see .env.example) to the whisper.cpp build directory." >&2
  exit 3
fi
model="${WHISPER_MODEL:-ggml-medium.en-q5_0.bin}"

if [[ ! -x "${whisperdir}/main" ]]; then
  echo "Unable to find whisper.cpp executable at ${whisperdir}/main" >&2
  echo "Set WHISPER_CPP_DIR if you keep the project elsewhere." >&2
  exit 4
fi

audio_path="${filedir}/${basename}.wav"
cleanup=false

case "${extension}" in
  wav)
    audio_path="${filepath}"
    ;;
  mp3|m4a|aac|flac|ogg|oga|opus|mp4|mkv|mov)
    require_cmd ffmpeg
    echo "Extracting audio track via ffmpeg..."
    ffmpeg -y -i "${filepath}" -vn -acodec pcm_s16le -ar 16000 -ac 2 "${audio_path}"
    cleanup=true
    ;;
  *)
    require_cmd ffmpeg
    echo "Unsupported extension '.${extension}'. Attempting to continue via ffmpeg..."
    ffmpeg -y -i "${filepath}" -vn -acodec pcm_s16le -ar 16000 -ac 2 "${audio_path}"
    cleanup=true
    ;;
esac

# Ensure cleanup happens even if script exits due to error
trap 'if [[ "${cleanup}" == "true" ]]; then rm -f "${audio_path}"; fi' EXIT

echo "Transcribing audio with Whisper using model ${model}..."

"${whisperdir}/main" \
  -t 10 \
  -p 1 \
  -otxt -ovtt -osrt -olrc -ocsv -oj \
  -of "${filedir}/${basename}" \
  -l en \
  -sow \
  -bs 3 \
  -bo 3 \
  -m "${whisperdir}/models/${model}" \
  -f "${audio_path}" \
  -pp -pc

if [[ "${cleanup}" == "true" ]]; then
  rm -f "${audio_path}"
fi

if command -v bat >/dev/null 2>&1; then
  bat "${filedir}/${basename}.txt"
else
  cat "${filedir}/${basename}.txt"
fi
