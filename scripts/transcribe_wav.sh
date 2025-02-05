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

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Get the root directory (parent of scripts)
ROOT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

# Paths for whisper
WHISPER_CLI="$ROOT_DIR/whisper.cpp/build/bin/whisper-cli"
WHISPER_MODEL="$ROOT_DIR/whisper.cpp/models/ggml-large-v1.bin"

# Display help if no arguments provided or help requested
if [ $# -eq 0 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "Generate SRT subtitles from a WAV audio file using Whisper"
    echo
    echo "Usage: $0 <input_wav_file> <output_srt_name>"
    echo
    echo "Arguments:"
    echo "  input_wav_file    Path to input WAV file"
    echo "  output_srt_name   Name for output SRT file (extension will be added automatically)"
    echo
    echo "Example:"
    echo "  $0 input.wav output"
    exit 1
fi

# Check if both arguments are provided
if [ $# -ne 2 ]; then
    error "Error: Both input WAV file and output SRT name are required"
    error "Run '$0 --help' for usage information"
    exit 1
fi

INPUT_WAV="$1"
OUTPUT_SRT="$2"

# Check if whisper-cli exists
if [ ! -f "$WHISPER_CLI" ]; then
    error "Error: whisper-cli not found at '$WHISPER_CLI'"
    error "Have you run setup_osx.sh to build whisper.cpp?"
    exit 1
fi

# Check if model exists
if [ ! -f "$WHISPER_MODEL" ]; then
    error "Error: Whisper model not found at '$WHISPER_MODEL'"
    error "Have you run setup_osx.sh to download the model?"
    exit 1
fi

# Check if input file exists
if [ ! -f "$INPUT_WAV" ]; then
    error "Error: Input WAV file '$INPUT_WAV' not found"
    exit 1
fi

success "Starting transcription of '$INPUT_WAV'..."

# Run the transcription command
"$WHISPER_CLI" \
    --model "$WHISPER_MODEL" \
    --file "$INPUT_WAV" \
    --output-srt \
    --output-file "$OUTPUT_SRT" \
    --threads 8 \
    --language en

# Check if the command was successful
if [ $? -eq 0 ]; then
    success "✓ Transcription completed successfully"
    success "Output written to ${OUTPUT_SRT}.srt"
else
    error "Error: Transcription failed"
    exit 1
fi
