#!/bin/bash

# Exit immediately if a command fails
set -e

echo "🚀 Setting up Yoshi Podcasts on macOS..."

# Check if Homebrew is installed
if ! command -v brew &>/dev/null; then
    echo "❌ Homebrew is not installed. Please install it first: https://brew.sh/"
    exit 1
fi

# Update and install necessary dependencies
echo "🔄 Updating Homebrew and installing dependencies..."
brew update
brew install cmake libomp git ccache ffmpeg ruby python3

# Install Ruby dependencies
echo "💎 Installing Ruby and Jekyll dependencies..."
gem install bundler
bundle install

# Clone whisper.cpp if it doesn't already exist
WHISPER_DIR="whisper.cpp"
if [ ! -d "$WHISPER_DIR" ]; then
    echo "📂 Cloning whisper.cpp repository..."
    git clone https://github.com/ggerganov/whisper.cpp.git "$WHISPER_DIR"
else
    echo "📂 whisper.cpp directory already exists. Pulling latest changes..."
    cd "$WHISPER_DIR"
    git pull
    cd ..
fi

# Build whisper.cpp with Apple Silicon Metal support
echo "🔨 Building whisper.cpp with Metal support..."
cd whisper.cpp
rm -rf build # Clean any existing builds
cmake -B build -DWHISPER_METAL=ON -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release

# Verify ggml-metal.metal exists (needed for Metal acceleration)
if [ ! -f "ggml-metal.metal" ]; then
    echo "⚠️  Warning: ggml-metal.metal not found. Metal acceleration may not be available."
else
    echo "✅ Metal backend configured correctly."
fi

# Download the large model if missing
MODELS_DIR="models"
mkdir -p "$MODELS_DIR"
MODEL_PATH="$MODELS_DIR/ggml-large-v1.bin"

if [ ! -f "$MODEL_PATH" ]; then
    echo "⬇️ Downloading large English model (ggml-large-v1.bin)..."
    bash ./models/download-ggml-model.sh large-v1
else
    echo "📦 Model ggml-large-v1.bin already downloaded."
fi

echo "🚀 Setup complete! The following tools are available:"
echo ""
echo "1. Extract audio from video:"
echo "   ./scripts/extract_audio.sh"
echo "   Extracts MP3 audio from video files (MP4 or MOV)"
echo ""
echo "2. Prepare audio for transcription:"
echo "   ./scripts/convert_to_wav16.py"
echo "   Converts MP3 to WAV format optimized for transcription"
echo ""
echo "3. Generate transcription:"
echo "   ./scripts/transcribe_wav.sh"
echo "   Uses whisper.cpp to transcribe WAV file to SRT subtitles"
echo ""
echo "4. Convert to Jekyll format:"
echo "   ./scripts/srt_to_markdown.py"
echo "   Converts SRT subtitles to Jekyll-compatible markdown"
echo ""
echo "5. Update episode metadata:"
echo "   ./scripts/update_media_metadata.rb"
echo "   Enriches _episodes/episode-XXX.md files with media file information"
echo ""
echo "Run any script with -h or --help for usage information"
echo ""

cd ..
exit 0

