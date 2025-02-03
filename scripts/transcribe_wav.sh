#!/bin/bash

# Display help if no arguments provided or help requested
if [ $# -eq 0 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "Usage: $0 <input_wav_file> <output_srt_name>"
    echo
    echo "Generate SRT subtitles from a WAV audio file using Whisper"
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
    echo "Error: Both input WAV file and output SRT name are required"
    echo "Run '$0 --help' for usage information"
    exit 1
fi

INPUT_WAV="$1"
OUTPUT_SRT="$2"

# Check if input file exists
if [ ! -f "$INPUT_WAV" ]; then
    echo "Error: Input WAV file '$INPUT_WAV' not found"
    exit 1
fi

# Run the transcription command
/Users/harry/Code/Youtube-Reddit-Videos-Generator/main \
    --model /Users/harry/Code/Youtube-Reddit-Videos-Generator/models/ggml-large-v1.bin \
    --file "$INPUT_WAV" \
    --output-srt \
    --output-file "$OUTPUT_SRT" \
    --threads 8 \
    --language en

# Check if the command was successful
if [ $? -eq 0 ]; then
    echo "Transcription completed successfully"
    echo "Output written to ${OUTPUT_SRT}.srt"
else
    echo "Error: Transcription failed"
    exit 1
fi
