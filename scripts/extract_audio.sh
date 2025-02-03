#!/bin/bash
# extract_audio.sh
# -----------------------------------
# 1) Takes one argument: a directory path containing video files
# 2) Extracts audio from all .mp4/.mov files to .mp3 with the same base name
# 3) Skips if the .mp3 file already exists
#
# Usage:
#   ./extract_audio.sh /path/to/videos

# Exit if no directory was provided
if [ -z "$1" ]; then
  echo "Usage: $0 /path/to/directory"
  exit 1
fi

# Directory where the script should operate
TARGET_DIR="$1"

# Check if the directory exists
if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: Directory '$TARGET_DIR' does not exist."
  exit 1
fi

# Change to the target directory
cd "$TARGET_DIR" || exit 1

# Loop over all .mp4/.MP4/.mov/.MOV files
for file in *.mp4 *.MP4 *.mov *.MOV; do
  # If the glob didn't match any files, skip
  [[ -f "$file" ]] || continue

  base="${file%.*}"      # Remove file extension, e.g. "C0037" from "C0037.mp4"
  output="${base}.mp3"

  # Skip if the .mp3 already exists
  if [[ -f "$output" ]]; then
    echo "Skipping \"$file\" because \"$output\" already exists."
    continue
  fi

  echo "Extracting audio from \"$file\" to \"$output\"..."
  # -vn  = no video
  # -q:a 2 = high-quality variable bitrate audio
  ffmpeg -i "$file" -vn -q:a 2 "$output"
  echo "Done."
done

echo "All done in '$TARGET_DIR'."

