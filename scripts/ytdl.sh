#!/usr/bin/env bash
#------------------------------------------------------------------------------
# ytdl - Enhanced yt-dlp wrapper with quality presets and passthrough support
#------------------------------------------------------------------------------
set -euo pipefail

readonly VERSION="1.0.0"
readonly SCRIPT_NAME="${0##*/}"

# Defaults
: "${YTDL_DIR:=$HOME/Downloads/ytdl}"
: "${YTDL_COOKIES_FILE:=}"
: "${YTDL_COOKIES_FROM_BROWSER:=}"

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

PLAYLIST OPTIONS:
  --playlist-items R    Download specific items (e.g., "1-3,5,7-10")
  --no-playlist         Download only the video, not playlist

NETWORK OPTIONS:
  -r, --rate LIMIT      Limit download rate (e.g., 5M, 500K)
  --no-aria2c           Don't use aria2c accelerated downloader

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
  YTDL_DIR                   Base output directory (default: ~/Downloads/ytdl)
  YTDL_COOKIES_FILE          Path to cookies file
  YTDL_COOKIES_FROM_BROWSER  Browser to extract cookies from (chrome, brave, firefox)

EXAMPLES:
  ytdl URL                          # Download best quality video (mkv)
  ytdl -a URL                       # Download audio (opus)
  ytdl -a -f mp3 URL                # Download as MP3
  ytdl -q 720 URL                   # Download 720p video
  ytdl -q 1080 -f mp4 URL           # Download 1080p as MP4 (may transcode)
  ytdl -F URL                       # List available formats
  ytdl -w URL                       # Download and transcribe with Whisper
  ytdl -o ~/Videos URL              # Download to custom directory
  ytdl -- --geo-bypass URL          # Pass extra args to yt-dlp
  ytdl -n URL                       # Dry run - show command without running

EOF
}

die() {
    printf '%s: %s\n' "$SCRIPT_NAME" "$*" >&2
    exit 1
}

info() {
    (( QUIET )) || printf '%s: %s\n' "$SCRIPT_NAME" "$*" >&2
}

debug() {
    (( VERBOSE )) && printf '%s: [debug] %s\n' "$SCRIPT_NAME" "$*" >&2
    return 0
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
                    if [[ "$1" =~ ^https?:// ]] || [[ "$1" =~ ^www\. ]] || [[ "$1" =~ ^youtu ]]; then
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

    # Temp file for tracking downloaded files
    local tmp_list=""
    if (( DO_WHISPER )); then
        tmp_list=$(mktemp "${TMPDIR:-/tmp}/ytdl.XXXXXX") || die "mktemp failed"
    fi

    # Start building command
    cmd=(yt-dlp)

    # Basic options
    cmd+=(--no-color --ignore-errors --restrict-filenames)

    # aria2c downloader
    if (( USE_ARIA2C )) && command -v aria2c >/dev/null 2>&1; then
        cmd+=(
            --downloader aria2c
            --downloader-args 'aria2c:-x16 -s16 -k1M -j16 --file-allocation=none --continue=true --min-split-size=1M --max-connection-per-server=16 --summary-interval=0'
        )
    fi

    # Output template
    local template
    if [[ -n "$CUSTOM_TEMPLATE" ]]; then
        template="$CUSTOM_TEMPLATE"
    else
        template="${OUTDIR}/%(uploader)s/%(upload_date)s - %(title).200B [%(id)s].%(ext)s"
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
        [[ -n "$tmp_list" ]] && rm -f "$tmp_list"
        return 0
    fi

    debug "running: ${cmd[*]}"

    if ! "${cmd[@]}"; then
        info "download failed for: $url"
        [[ -n "$tmp_list" ]] && rm -f "$tmp_list"
        return 1
    fi

    # Run Whisper if requested
    if (( DO_WHISPER )) && [[ -n "$tmp_list" ]] && [[ -s "$tmp_list" ]]; then
        while IFS= read -r filepath; do
            [[ -n "$filepath" ]] && run_whisper "$filepath"
        done < "$tmp_list"
    fi

    [[ -n "$tmp_list" ]] && rm -f "$tmp_list"
    return 0
}

main() {
    check_deps
    parse_args "$@"

    if (( ${#URLS[@]} == 0 )); then
        die "missing URL. Try: $SCRIPT_NAME --help"
    fi

    # List formats mode
    if (( LIST_FORMATS )); then
        for url in "${URLS[@]}"; do
            list_formats "$url"
        done
        exit 0
    fi

    # Download each URL
    local failed=0
    for url in "${URLS[@]}"; do
        download "$url" || (( ++failed )) || true
    done

    (( failed > 0 )) && info "$failed download(s) failed"
    (( failed > 0 )) && exit 1
    exit 0
}

main "$@"
