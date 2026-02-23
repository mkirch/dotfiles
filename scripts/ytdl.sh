#!/usr/bin/env bash
#------------------------------------------------------------------------------
# ytdl - Enhanced yt-dlp wrapper with quality presets and passthrough support
#------------------------------------------------------------------------------
set -euo pipefail

readonly VERSION="1.0.0"
readonly SCRIPT_NAME="${0##*/}"

# Defaults
: "${YTDL_DIR:=$HOME/Media/ytdl}"
: "${YTDL_NAS_DIR:=}"
: "${YTDL_COOKIES_FILE:=}"
: "${YTDL_COOKIES_FROM_BROWSER:=chrome}"

# State
MODE="video"           # video | audio
QUALITY=""             # "", best, 1080, 720, 480, worst
OUTPUT_FORMAT=""       # "", mp4, mkv, webm, mp3, m4a, opus
DO_SUBS=1              # 1 = fetch subs, 0 = skip
DO_WHISPER=0           # 1 = run whisper, 0 = skip
OUTDIR="$YTDL_DIR"
CUSTOM_TEMPLATE=""
LIST_FORMATS=0
DRY_RUN=0
VERBOSE=0
QUIET=0
PLAYLIST_ITEMS=""
RATE_LIMIT=""
THUMBNAIL=0
INFO_JSON=0
USE_ARIA2C=1
NO_PLAYLIST=0
CONCURRENT=1
INPUT_FILE=""
FROM_CLIPBOARD=0
DIRECT=0
QUEUE_MODE=0
QUEUE_FILE="${YTDL_DIR}/.queue"
declare -a EXTRA_ARGS=()
declare -a URLS=()

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS] [--] URL [URL...]

A powerful yt-dlp wrapper with quality presets and passthrough support.

MODE OPTIONS:
  -a, --audio           Download audio only (default: video)
  -v, --video           Download video (default)

QUALITY OPTIONS:
  -q, --quality QUAL    Video quality preset:
                          best   - Best available (default for video)
                          4k     - 2160p or best below
                          1080   - 1080p or best below
                          720    - 720p or best below
                          480    - 480p or best below
                          worst  - Smallest file size
  -F, --list-formats    List available formats and exit

OUTPUT FORMAT:
  -f, --format FMT      Output container format:
                        Video: mp4, mkv, webm (default: mkv)
                        Audio: mp3, m4a, opus, flac, wav (default: opus)

OUTPUT OPTIONS:
  -o, --output DIR      Output directory (default: \$YTDL_DIR or ~/Downloads/ytdl)
  -t, --template TPL    Custom output template (yt-dlp syntax)

CONTENT OPTIONS:
  -s, --no-subs         Skip subtitles/transcripts (default: enabled)
  -S, --subs            Enable subtitles (default)
  -w, --whisper         Run Whisper transcription on downloaded files
  -W, --no-whisper      Skip Whisper (default)
  --thumbnail           Download thumbnail
  --info-json           Save video info as JSON

BATCH INPUT:
  -i, --input FILE      Read URLs from file (one per line, # comments ok)
                        Use "-" to read from stdin
  -c, --clipboard       Read URLs from clipboard (pbpaste/xclip)
  -d, --direct          Download now and block (default: enqueue to queue worker)
  -Q, --queue           Start queue worker: process queued URLs, wait for new ones
                        Stop with Ctrl+C. Runs automatically when no URLs given.

PLAYLIST OPTIONS:
  --playlist-items R    Download specific items (e.g., "1-3,5,7-10")
  --no-playlist         Download only the video, not playlist

NETWORK OPTIONS:
  -r, --rate LIMIT      Limit download rate (e.g., 5M, 500K)
  --no-aria2c           Don't use aria2c accelerated downloader
  -P, --concurrent N    Download N URLs in parallel (default: 1)

OTHER OPTIONS:
  -n, --dry-run         Show what would be done without downloading
  -V, --verbose         Show verbose output
  --quiet               Suppress most output
  -h, --help            Show this help message
  --version             Show version

PASSTHROUGH:
  --                    All arguments after -- are passed directly to yt-dlp
                        Example: ytdl -- --geo-bypass --sleep-interval 5 URL

ENVIRONMENT:
  YTDL_DIR                   Base output directory (default: ~/Media/ytdl)
  YTDL_NAS_DIR               NAS sync directory (set in .env, empty = skip sync)
                              Set to "" to disable NAS sync
  YTDL_COOKIES_FILE          Path to cookies file
  YTDL_COOKIES_FROM_BROWSER  Browser to extract cookies from (default: chrome)

EXAMPLES:
  ytdl URL                          # Enqueue URL for queue worker
  ytdl URL1 URL2 URL3               # Enqueue multiple URLs
  ytdl                              # Start queue worker (processes + waits)
  ytdl -Q -P 3                      # Queue worker with 3 concurrent downloads
  ytdl -d URL                       # Download directly (blocking)
  ytdl -d -a URL                    # Direct download, audio only (opus)
  ytdl -d -a -f mp3 URL             # Direct download as MP3
  ytdl -d -q 720 URL                # Direct download 720p video
  ytdl -F URL                       # List available formats
  ytdl -i urls.txt                  # Enqueue URLs from file
  ytdl -c                           # Enqueue URLs from clipboard
  ytdl -w URL                       # Enqueue with Whisper transcription
  ytdl -- --geo-bypass URL          # Pass extra args to yt-dlp
  ytdl -n URL                       # Dry run - show command without running

EOF
}

HISTORY_FILE="${YTDL_DIR}/.history"

# Colors (disabled when not a terminal or --no-color)
if [[ -t 2 ]]; then
    _C_RST=$'\033[0m'  _C_RED=$'\033[31m'  _C_GRN=$'\033[32m'
    _C_YLW=$'\033[33m' _C_CYN=$'\033[36m'  _C_DIM=$'\033[2m'
else
    _C_RST="" _C_RED="" _C_GRN="" _C_YLW="" _C_CYN="" _C_DIM=""
fi

die()   { printf '%s%s: %s%s\n' "$_C_RED" "$SCRIPT_NAME" "$*" "$_C_RST" >&2; exit 1; }
info()  { (( QUIET )) || printf '%s%s: %s%s\n' "$_C_CYN" "$SCRIPT_NAME" "$*" "$_C_RST" >&2; }
ok()    { (( QUIET )) || printf '%s%s: %s%s\n' "$_C_GRN" "$SCRIPT_NAME" "$*" "$_C_RST" >&2; }
warn()  { printf '%s%s: %s%s\n' "$_C_YLW" "$SCRIPT_NAME" "$*" "$_C_RST" >&2; }
debug() { (( VERBOSE )) && printf '%s%s: [debug] %s%s\n' "$_C_DIM" "$SCRIPT_NAME" "$*" "$_C_RST" >&2; return 0; }

notify() {
    (( QUIET )) && return
    if [[ "$(uname -s)" == "Darwin" ]]; then
        osascript -e "display notification \"$1\" with title \"ytdl\"" 2>/dev/null || true
    fi
}

log_history() {
    mkdir -p "$(dirname "$HISTORY_FILE")"
    printf '%s  %s  %s\n' "$(date '+%Y-%m-%d %H:%M')" "$1" "$2" >> "$HISTORY_FILE"
}

sync_to_nas() {
    local filepath="$1"
    [[ -z "$YTDL_NAS_DIR" ]] && return 0
    if [[ ! -d "$YTDL_NAS_DIR" ]]; then
        warn "NAS not mounted ($YTDL_NAS_DIR) — skipping sync"
        return 0
    fi
    local filename
    filename="$(basename "$filepath")"
    info "syncing to NAS: $filename"
    if rsync -a --partial --inplace "$filepath" "$YTDL_NAS_DIR/"; then
        ok "NAS: $filename"
    else
        warn "NAS sync failed: $filename"
    fi
}

# Check for required commands
check_deps() {
    command -v yt-dlp >/dev/null 2>&1 || die "yt-dlp not found in PATH"
}

# Parse arguments
parse_args() {
    while (( $# > 0 )); do
        case "$1" in
            -a|--audio)
                MODE="audio"
                shift
                ;;
            -v|--video)
                MODE="video"
                shift
                ;;
            -q|--quality)
                [[ -n "${2:-}" ]] || die "option $1 requires an argument"
                QUALITY="$2"
                shift 2
                ;;
            -F|--list-formats)
                LIST_FORMATS=1
                shift
                ;;
            -f|--format)
                [[ -n "${2:-}" ]] || die "option $1 requires an argument"
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            -o|--output)
                [[ -n "${2:-}" ]] || die "option $1 requires an argument"
                OUTDIR="$2"
                shift 2
                ;;
            -t|--template)
                [[ -n "${2:-}" ]] || die "option $1 requires an argument"
                CUSTOM_TEMPLATE="$2"
                shift 2
                ;;
            -s|--no-subs)
                DO_SUBS=0
                shift
                ;;
            -S|--subs)
                DO_SUBS=1
                shift
                ;;
            -w|--whisper)
                DO_WHISPER=1
                shift
                ;;
            -W|--no-whisper)
                DO_WHISPER=0
                shift
                ;;
            --thumbnail)
                THUMBNAIL=1
                shift
                ;;
            --info-json)
                INFO_JSON=1
                shift
                ;;
            --playlist-items)
                [[ -n "${2:-}" ]] || die "option $1 requires an argument"
                PLAYLIST_ITEMS="$2"
                shift 2
                ;;
            --no-playlist)
                NO_PLAYLIST=1
                shift
                ;;
            -r|--rate)
                [[ -n "${2:-}" ]] || die "option $1 requires an argument"
                RATE_LIMIT="$2"
                shift 2
                ;;
            --no-aria2c)
                USE_ARIA2C=0
                shift
                ;;
            -P|--concurrent)
                [[ -n "${2:-}" ]] || die "option $1 requires a number"
                CONCURRENT="$2"
                shift 2
                ;;
            -i|--input)
                [[ -n "${2:-}" ]] || die "option $1 requires a file path (or - for stdin)"
                INPUT_FILE="$2"
                shift 2
                ;;
            -c|--clipboard)
                FROM_CLIPBOARD=1
                shift
                ;;
            -d|--direct)
                DIRECT=1
                shift
                ;;
            -Q|--queue)
                QUEUE_MODE=1
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=1
                shift
                ;;
            -V|--verbose)
                VERBOSE=1
                shift
                ;;
            --quiet)
                QUIET=1
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            --version)
                printf '%s %s\n' "$SCRIPT_NAME" "$VERSION"
                exit 0
                ;;
            --)
                shift
                # Collect remaining args as passthrough
                while (( $# > 0 )); do
                    # Check if it looks like a URL
                    if [[ "$1" =~ ^https?:// ]] || [[ "$1" =~ ^www\. ]] || [[ "$1" =~ ^youtu\.?be ]]; then
                        URLS+=("$1")
                    else
                        EXTRA_ARGS+=("$1")
                    fi
                    shift
                done
                ;;
            -*)
                die "unknown option: $1 (use -- for yt-dlp passthrough)"
                ;;
            *)
                URLS+=("$1")
                shift
                ;;
        esac
    done
}

# Load URLs from a stream (file, stdin, clipboard) - strips comments and blanks
load_urls() {
    local src="$1"
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"         # strip comments
        line="${line#"${line%%[![:space:]]*}"}"  # trim leading whitespace
        line="${line%"${line##*[![:space:]]}"}"  # trim trailing whitespace
        [[ -n "$line" ]] && URLS+=("$line")
    done < "$src"
}

get_clipboard() {
    if command -v pbpaste >/dev/null 2>&1; then
        pbpaste
    elif command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard -o
    elif command -v xsel >/dev/null 2>&1; then
        xsel --clipboard --output
    elif command -v powershell.exe >/dev/null 2>&1; then
        powershell.exe -Command Get-Clipboard 2>/dev/null
    else
        die "no clipboard tool found (need pbpaste, xclip, xsel, or powershell.exe)"
    fi
}

# Build format selection string
get_format_selector() {
    if [[ "$MODE" == "audio" ]]; then
        echo "bestaudio/best"
    else
        case "${QUALITY:-best}" in
            best|"")
                echo "bv[vcodec^=av01]+ba/bv*+ba/best"
                ;;
            4k|2160)
                echo "bv[height<=2160][vcodec^=av01]+ba/bv[height<=2160]+ba/best[height<=2160]"
                ;;
            1080)
                echo "bv[height<=1080][vcodec^=av01]+ba/bv[height<=1080]+ba/best[height<=1080]"
                ;;
            720)
                echo "bv[height<=720][vcodec^=av01]+ba/bv[height<=720]+ba/best[height<=720]"
                ;;
            480)
                echo "bv[height<=480]+ba/best[height<=480]"
                ;;
            worst)
                echo "worstvideo+worstaudio/worst"
                ;;
            *)
                # Allow raw format specifier passthrough
                echo "$QUALITY"
                ;;
        esac
    fi
}

# List formats for a URL
list_formats() {
    local url="$1"
    local -a cmd=(yt-dlp -F)

    # Cookies
    if [[ -n "$YTDL_COOKIES_FROM_BROWSER" ]]; then
        cmd+=(--cookies-from-browser "$YTDL_COOKIES_FROM_BROWSER")
    elif [[ -n "$YTDL_COOKIES_FILE" ]]; then
        cmd+=(--cookies "$YTDL_COOKIES_FILE")
    fi

    cmd+=("$url")

    info "listing formats for: $url"
    "${cmd[@]}"
}

# Run whisper on a file (requires wh command)
run_whisper() {
    local filepath="$1"

    if ! command -v wh >/dev/null 2>&1; then
        info "wh command not found, skipping Whisper transcription"
        return 0
    fi

    if [[ ! -f "$filepath" ]]; then
        info "file not found for Whisper: $filepath"
        return 1
    fi

    info "running Whisper on: $filepath"
    wh "$filepath" || {
        info "Whisper failed for: $filepath"
        return 1
    }
}

# Main download function
download() {
    local url="$1"
    local -a cmd=()

    info "preparing: $url"

    # Create output directory
    mkdir -p "$OUTDIR" || die "cannot create output dir: $OUTDIR"

    local tmp_list=""
    if (( DO_WHISPER )); then
        tmp_list=$(mktemp "${TMPDIR:-/tmp}/ytdl.XXXXXX") || die "mktemp failed"
        trap 'rm -f "$tmp_list"' EXIT INT TERM
    fi

    # Start building command
    cmd=(yt-dlp)

    # Basic options
    cmd+=(--no-color --ignore-errors --restrict-filenames --console-title)

    # Progress: clean single-line output with video ID, percent, speed, ETA
    if (( ! QUIET )); then
        cmd+=(
            --progress-template 'download:[%(info.id)s] %(progress._percent_str)s %(progress._speed_str)s ETA %(progress._eta_str)s'
            --progress-template 'postprocess:[%(info.id)s] post-processing...'
        )
    fi
    (( CONCURRENT > 1 )) && cmd+=(--newline)

    # Post-download summary: print title and filepath after each video
    local summary_file
    summary_file=$(mktemp "${TMPDIR:-/tmp}/ytdl-summary.XXXXXX")
    cmd+=(--print-to-file 'after_move:%(title)s\t%(filesize_approx,filesize)s\t%(filepath)s' "$summary_file")

    # aria2c downloader (quiet mode: suppress aria2c's own output)
    if (( USE_ARIA2C )) && command -v aria2c >/dev/null 2>&1; then
        local aria_args='-x16 -s16 -k1M -j16 --file-allocation=none --continue=true --min-split-size=1M --max-connection-per-server=16 --summary-interval=0 --optimize-concurrent-downloads=true'
        (( QUIET )) && aria_args+=' --quiet=true'
        cmd+=(
            --downloader aria2c
            --downloader-args "aria2c:${aria_args}"
        )
    fi

    # Output template
    local template
    if [[ -n "$CUSTOM_TEMPLATE" ]]; then
        template="$CUSTOM_TEMPLATE"
    else
        template="${OUTDIR}/%(title).200B - %(uploader)s [%(id)s].%(ext)s"
    fi
    cmd+=(-o "$template")

    # Cookies
    if [[ -n "$YTDL_COOKIES_FROM_BROWSER" ]]; then
        cmd+=(--cookies-from-browser "$YTDL_COOKIES_FROM_BROWSER")
    elif [[ -n "$YTDL_COOKIES_FILE" ]]; then
        cmd+=(--cookies "$YTDL_COOKIES_FILE")
    fi

    # Format selection
    local format_selector
    format_selector=$(get_format_selector)
    cmd+=(-f "$format_selector")

    # Audio extraction
    if [[ "$MODE" == "audio" ]]; then
        cmd+=(--extract-audio)
        case "${OUTPUT_FORMAT:-opus}" in
            mp3)
                cmd+=(--audio-format mp3 --audio-quality 0)
                ;;
            m4a)
                cmd+=(--audio-format m4a --audio-quality 0)
                ;;
            opus)
                cmd+=(--audio-format opus)
                ;;
            flac)
                cmd+=(--audio-format flac)
                ;;
            wav)
                cmd+=(--audio-format wav)
                ;;
            *)
                cmd+=(--audio-format "$OUTPUT_FORMAT")
                ;;
        esac
    else
        # Video output format (default: mkv for compatibility without transcoding)
        local video_fmt="${OUTPUT_FORMAT:-mkv}"
        case "$video_fmt" in
            mp4|mkv|webm)
                cmd+=(--remux-video "$video_fmt")
                ;;
        esac
    fi

    # Subtitles
    if (( DO_SUBS )) && [[ "$MODE" == "video" ]]; then
        cmd+=(
            --write-sub
            --write-auto-sub
            --sub-langs 'en.*,en'
            --sub-format vtt
            --convert-subs srt
            --embed-subs
        )
    fi

    # Thumbnail
    (( THUMBNAIL )) && cmd+=(--write-thumbnail)

    # Info JSON
    (( INFO_JSON )) && cmd+=(--write-info-json)

    # Playlist options
    (( NO_PLAYLIST )) && cmd+=(--no-playlist)
    [[ -n "$PLAYLIST_ITEMS" ]] && cmd+=(--playlist-items "$PLAYLIST_ITEMS")

    # Rate limit
    [[ -n "$RATE_LIMIT" ]] && cmd+=(-r "$RATE_LIMIT")

    # Verbose/quiet
    (( VERBOSE )) && cmd+=(--verbose)
    (( QUIET )) && cmd+=(--quiet)

    # Track downloaded files for whisper
    if [[ -n "$tmp_list" ]]; then
        cmd+=(--print-to-file 'after_move:%(filepath)s' "$tmp_list")
    fi

    # Extra passthrough args
    if (( ${#EXTRA_ARGS[@]} > 0 )); then
        cmd+=("${EXTRA_ARGS[@]}")
    fi

    # URL
    cmd+=("$url")

    if (( DRY_RUN )); then
        info "would run:"
        # Print command in a readable way
        printf '  %s' "${cmd[0]}"
        for arg in "${cmd[@]:1}"; do
            if [[ "$arg" == *" "* ]] || [[ "$arg" == *"'"* ]]; then
                printf " '%s'" "$arg"
            else
                printf " %s" "$arg"
            fi
        done
        printf '\n'
        rm -f "$summary_file"
        [[ -n "$tmp_list" ]] && rm -f "$tmp_list"
        return 0
    fi

    debug "running: ${cmd[*]}"

    if ! "${cmd[@]}"; then
        warn "download failed: $url"
        rm -f "$summary_file"
        [[ -n "$tmp_list" ]] && rm -f "$tmp_list"
        return 1
    fi

    # Print download summary + sync to NAS
    if [[ -s "$summary_file" ]]; then
        while IFS=$'\t' read -r title size filepath; do
            [[ -z "$title" ]] && continue
            local size_h=""
            if [[ -n "$size" && "$size" != "NA" ]]; then
                size_h=" (${size})"
            fi
            ok "done: ${title}${size_h}"
            debug "saved: $filepath"
            log_history "$title" "${filepath:-$url}"
            [[ -n "$filepath" && -f "$filepath" ]] && sync_to_nas "$filepath"
        done < "$summary_file"
    fi
    rm -f "$summary_file"

    # Run Whisper if requested
    if (( DO_WHISPER )) && [[ -n "$tmp_list" ]] && [[ -s "$tmp_list" ]]; then
        while IFS= read -r filepath; do
            [[ -n "$filepath" ]] && run_whisper "$filepath"
        done < "$tmp_list"
    fi

    [[ -n "$tmp_list" ]] && rm -f "$tmp_list"
    return 0
}

# Enqueue: append URLs to the queue file
enqueue() {
    mkdir -p "$(dirname "$QUEUE_FILE")"
    local count=0
    for url in "${URLS[@]}"; do
        printf '%s\n' "$url" >> "$QUEUE_FILE"
        (( ++count ))
    done
    ok "enqueued $count URL(s)"
}

# Queue worker: drain queue file, wait for new entries, repeat
queue_drain() {
    local failed=0 total=0

    while true; do
        if [[ ! -f "$QUEUE_FILE" ]] || [[ ! -s "$QUEUE_FILE" ]]; then
            info "queue empty — waiting (Ctrl+C to stop)..."
            while [[ ! -s "$QUEUE_FILE" ]] 2>/dev/null; do
                sleep 2
            done
        fi

        # Atomically grab current queue contents and truncate
        local batch
        batch=$(mktemp "${TMPDIR:-/tmp}/ytdl-batch.XXXXXX")
        mv "$QUEUE_FILE" "$batch"
        touch "$QUEUE_FILE"

        local -a batch_urls=()
        while IFS= read -r line || [[ -n "$line" ]]; do
            line="${line%%#*}"
            line="${line#"${line%%[![:space:]]*}"}"
            line="${line%"${line##*[![:space:]]}"}"
            [[ -n "$line" ]] && batch_urls+=("$line")
        done < "$batch"
        rm -f "$batch"

        (( ${#batch_urls[@]} == 0 )) && continue

        local batch_size=${#batch_urls[@]}
        info "processing $batch_size URL(s) from queue"

        if (( CONCURRENT > 1 )); then
            local running=0 pids=()
            for url in "${batch_urls[@]}"; do
                download "$url" &
                pids+=($!)
                (( ++running ))
                (( ++total ))
                if (( running >= CONCURRENT )); then
                    wait "${pids[0]}" || (( ++failed )) || true
                    pids=("${pids[@]:1}")
                    (( --running ))
                fi
            done
            for pid in "${pids[@]}"; do
                wait "$pid" || (( ++failed )) || true
            done
        else
            for url in "${batch_urls[@]}"; do
                download "$url" || (( ++failed )) || true
                (( ++total ))
            done
        fi

        if (( failed > 0 )); then
            warn "batch: $batch_size done, $failed failed ($total total)"
        else
            ok "batch: $batch_size done ($total total)"
        fi
        notify "$batch_size download(s) complete"
    done
}

download_urls() {
    local failed=0

    info "${#URLS[@]} URL(s) queued, concurrency=${CONCURRENT}"

    if (( CONCURRENT > 1 && !DRY_RUN )); then
        local running=0 pids=()
        for url in "${URLS[@]}"; do
            download "$url" &
            pids+=($!)
            (( ++running ))
            if (( running >= CONCURRENT )); then
                wait "${pids[0]}" || (( ++failed )) || true
                pids=("${pids[@]:1}")
                (( --running ))
            fi
        done
        for pid in "${pids[@]}"; do
            wait "$pid" || (( ++failed )) || true
        done
    else
        for url in "${URLS[@]}"; do
            download "$url" || (( ++failed )) || true
        done
    fi

    (( failed > 0 )) && info "$failed download(s) failed"
    return $failed
}

main() {
    check_deps
    parse_args "$@"

    # Batch input: file or stdin
    if [[ -n "$INPUT_FILE" ]]; then
        if [[ "$INPUT_FILE" == "-" ]]; then
            load_urls /dev/stdin
        elif [[ -f "$INPUT_FILE" ]]; then
            load_urls "$INPUT_FILE"
        else
            die "input file not found: $INPUT_FILE"
        fi
    fi

    # Clipboard input
    if (( FROM_CLIPBOARD )); then
        local clip
        clip="$(get_clipboard)"
        [[ -z "$clip" ]] && die "clipboard is empty"
        load_urls <(printf '%s\n' "$clip")
        info "loaded ${#URLS[@]} URL(s) from clipboard"
    fi

    # Queue worker mode (explicit -Q or no URLs given)
    if (( QUEUE_MODE )) || (( ${#URLS[@]} == 0 && !DIRECT )); then
        if (( ${#URLS[@]} > 0 )); then
            enqueue
            URLS=()
        fi
        info "queue worker started (queue: $QUEUE_FILE)"
        info "enqueue URLs from another terminal with: ytdl URL"
        queue_drain
        exit 0
    fi

    # List formats mode (always direct)
    if (( LIST_FORMATS )); then
        for url in "${URLS[@]}"; do
            list_formats "$url"
        done
        exit 0
    fi

    # Direct mode: download now and block
    if (( DIRECT )); then
        download_urls
        local rc=$?
        (( rc > 0 )) && exit 1
        exit 0
    fi

    # Default: enqueue URLs and exit
    enqueue
    exit 0
}

main "$@"
