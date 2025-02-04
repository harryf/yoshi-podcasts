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
brew install cmake libomp git ccache ffmpeg ruby python@3.11

# Install Ruby dependencies
echo "💎 Installing Ruby and Jekyll dependencies..."
gem install bundler
bundle install

# Install Python dependencies
echo "🐍 Installing Python dependencies..."
pip3 install pydub

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
    echo "❌ ggml-metal.metal not found. Build may be incomplete."
    exit 1
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

echo "🚀 whisper.cpp setup complete! You can now run it with the following command:"
echo ""
echo "Run ./scripts/transcribe_wav.sh"
echo ""

cd ..
exit 0

