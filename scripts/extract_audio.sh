#!/bin/bash

# Colors for output
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# Function to print to stderr with red color
error() {
    echo -e "${RED}$1${NC}" >&2
}

# Function to print success messages in green
success() {
    echo -e "${GREEN}$1${NC}"
}

# Function to show usage
show_help() {
    echo "Extract MP3 audio from video files (.mp4 or .mov)"
    echo ""
    echo "Usage:"
    echo "  Single file:  $0 input.mp4 output_directory"
    echo "  Directory:    $0 -d input_directory [output_directory]"
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo "  -d            Process all video files in the input directory"
    echo ""
    echo "Examples:"
    echo "  $0 video.mp4 /path/to/output"
    echo "  $0 -d /path/to/videos /path/to/output"
    echo "  $0 -d /path/to/videos     # outputs to same directory"
}

# Function to extract audio from a single file
extract_audio() {
    local input_file="$1"
    local output_dir="$2"
    local filename=$(basename "$input_file")
    local base="${filename%.*}"
    local output_file="$output_dir/${base}.mp3"

    if [[ ! -f "$input_file" ]]; then
        error "Input file '$input_file' does not exist."
        return 1
    fi

    if [[ -f "$output_file" ]]; then
        success "Skipping \"$filename\" because \"$(basename "$output_file")\" already exists."
        return 0
    fi

    success "Extracting audio from \"$filename\" to \"$(basename "$output_file")\"..."
    if ffmpeg -i "$input_file" -vn -q:a 2 "$output_file" 2>/dev/null; then
        success "✓ Done."
        return 0
    else
        error "Failed to extract audio from \"$filename\""
        return 1
    fi
}

# Parse arguments
if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

if [[ "$1" == "-d" ]]; then
    # Directory mode
    if [[ $# -lt 2 || $# -gt 3 ]]; then
        error "Directory mode requires input directory and optional output directory."
        show_help
        exit 1
    fi

    input_dir="$2"
    output_dir="${3:-$input_dir}"  # Use input_dir if output_dir not provided

    if [[ ! -d "$input_dir" ]]; then
        error "Input directory '$input_dir' does not exist."
        exit 1
    fi

    if [[ ! -d "$output_dir" ]]; then
        success "Creating output directory '$output_dir'"
        mkdir -p "$output_dir"
    fi

    # Process all video files in directory
    success "Processing all video files in '$input_dir'..."
    find "$input_dir" -type f \( -iname "*.mp4" -o -iname "*.mov" \) -print0 | 
    while IFS= read -r -d '' file; do
        extract_audio "$file" "$output_dir"
    done

else
    # Single file mode
    if [[ $# -ne 2 ]]; then
        error "Single file mode requires input file and output directory."
        show_help
        exit 1
    fi

    input_file="$1"
    output_dir="$2"

    if [[ ! -d "$output_dir" ]]; then
        success "Creating output directory '$output_dir'"
        mkdir -p "$output_dir"
    fi

    extract_audio "$input_file" "$output_dir"
fi

success "All done!"

