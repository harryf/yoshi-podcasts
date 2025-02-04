# Yoshi Podcasts

A Jekyll-based site for cataloging and viewing podcast/audio/video files along with their transcriptions. Features powerful search capabilities powered by Algolia.

## Features

- Episode catalog with metadata
- Support for multiple video and audio files per episode
- Transcript viewing with timestamps
- Direct file access (when mounted)
- Responsive design
- Full-text search powered by Algolia
- Automatic audio extraction and transcription

## Prerequisites

Before starting, you'll need:

1. A Mac computer (this guide is for macOS)
2. Internet connection
3. Basic familiarity with using the Terminal
4. An Algolia account for search functionality (free tier available)

## Initial Setup

1. Open Terminal on your Mac

2. Install Homebrew (if not already installed):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

3. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/yoshi-podcasts.git
   cd yoshi-podcasts
   ```

4. Run the setup script:
   ```bash
   chmod +x setup_osx.sh
   ./setup_osx.sh
   ```
   This will install all necessary dependencies including:
   - Ruby and Jekyll
   - Python and required packages
   - FFmpeg for audio processing
   - Whisper.cpp for transcription

5. Configure Algolia Search:
   - Sign up for a free Algolia account at https://www.algolia.com/
   - Create a new application
   - Create a new index called 'yoshi_podcasts'
   - Get your API keys from the Algolia dashboard
   - Create a `.env` file in the root directory with:
     ```
     ALGOLIA_API_KEY=your_admin_api_key
     ALGOLIA_APPLICATION_ID=your_application_id
     ALGOLIA_INDEX_NAME=yoshi_podcasts
     ```

## Running the Site

1. Start the Jekyll server:
   ```bash
   bundle exec jekyll serve
   ```

2. Open your web browser and visit:
   ```
   http://localhost:4000
   ```

## Adding New Episodes

1. Create a new markdown file in the `_episodes` directory:
   ```bash
   touch _episodes/episode-XXX.md
   ```

2. Add the required front matter:
   ```yaml
   ---
   layout: episode
   title: "Episode Title"
   date: YYYY-MM-DD
   episode_number: XXX
   duration: "HH:MM:SS"
   file_url: "/path/to/audio/file.mp3"
   transcript_file: "episode-XXX-transcript"
   ---
   ```

3. If you have a video file and want to extract audio:
   ```bash
   ./scripts/extract_audio.sh /path/to/video/directory
   ```

4. To generate a transcript:
   ```bash
   ./scripts/convert_to_wav16.py /path/to/audio.mp3
   ./scripts/transcribe_wav.sh /path/to/audio.wav
   ```

5. Convert the SRT transcript to markdown:
   ```bash
   ./scripts/srt_to_markdown.py /path/to/transcript.srt
   ```

## Adding New Episodes

1. Create a new markdown file in the `_episodes` directory
2. Add the required front matter (see `_episodes/episode-001.md` for an example)
3. Add the corresponding transcript in the `_transcripts` directory if available
4. Update the file paths to point to your media files

## File Structure

```
.
├── _config.yml           # Site configuration
├── _episodes/            # Episode markdown files
├── _layouts/            # HTML layouts
├── _transcripts/        # Episode transcripts
├── assets/             # CSS and other assets
│   └── css/
│       └── style.css
├── scripts/            # Utility scripts
│   ├── convert_to_wav16.py    # Convert audio to WAV format
│   ├── extract_audio.sh       # Extract audio from video
│   ├── srt_to_markdown.py     # Convert SRT to markdown
│   ├── transcribe_wav.sh      # Generate transcripts
│   └── update_media_metadata.rb # Update media metadata
├── index.html          # Homepage
├── setup_osx.sh       # Setup script
└── README.md          # This file
```

## Troubleshooting

1. If Jekyll fails to start:
   - Make sure all gems are installed: `bundle install`
   - Try updating gems: `bundle update`
   - Check Ruby version: `ruby -v` (should be 2.7.0 or higher)

2. If audio extraction fails:
   - Ensure FFmpeg is installed: `brew install ffmpeg`
   - Check video file format is supported

3. If transcription fails:
   - Ensure whisper.cpp is properly installed
   - Check audio file is in correct format
   - Try regenerating the WAV file

4. If search isn't working:
   - Verify Algolia credentials in .env file
   - Check browser console for errors
   - Try reindexing: `ALGOLIA_API_KEY=your_key bundle exec jekyll algolia`

## Indexing Content with Algolia

1. First-time setup:
   ```bash
   # Install the jekyll-algolia gem (should be done by setup_osx.sh)
   bundle install
   ```

2. Configure Algolia in `_config.yml`:
   ```yaml
   algolia:
     application_id: your_application_id
     index_name: yoshi_podcasts
     search_only_api_key: your_search_only_key
     files_to_exclude:
       - index.html
       - 404.html
   ```

3. Index your content:
   ```bash
   # Use your admin API key for indexing
   ALGOLIA_API_KEY=your_admin_api_key bundle exec jekyll algolia
   ```

4. Automatic indexing (optional):
   - Set up a GitHub Action or CI/CD pipeline
   - Add environment variables for Algolia credentials
   - Run the indexing command after each content update

5. Verify indexing:
   - Log into your Algolia dashboard
   - Check the 'yoshi_podcasts' index
   - Verify records are present and searchable
   - Test search functionality on your site

Note: Never commit your Algolia admin API key to version control. Always use environment variables or a `.env` file (which should be in `.gitignore`).

# Yoshi Podcast Website

This document outlines the step-by-step **WORKFLOW** for building the **Yoshi Podcast** website, from organizing content to generating transcripts and integrating search.

---

## **WORKFLOW**

### **1. Organizing Episode Content**
1. Gather all available **videos, audio files, and metadata** for each episode.
2. Create a new episode page:
   - Use the template file in `_template/`
   - Copy it into `episodes/`
   - Update it with relevant content

---

### **2. Updating Media Metadata**
1. Run the **Ruby script** to update metadata:
   ```sh
   ruby scripts/updateMediaMetadata.ruby

- This script scans the specified file locations.
- It extracts metadata and updates the episode markdown file.
- ⚠️ After running this script, manual editing of the episode markdown becomes harder. Always start with the template first.

### **3. Running the Local Server
To preview episodes locally:
   ```sh
   bundle exec jekyll serve

Use this to navigate the website on http://localhost:4000, check episode pages, and copy filenames for further processing.

### 4. Converting Audio for Transcription
Extract Audio from Video Files
If you have video files and need to extract audio for example

   ```sh
   scripts/extract_audio.sh '/Volumes/Harry/Yoshi\ 2\ Podcast/Camcorder'
   ```

Uses ffmpeg to extract audio and convert it to MP3.

#### Convert MP3 to WAV
MP3 is not a good format for transcription, so we need to convert it to WAV with 16Khz...

Run the conversion script:
   ```sh
   ./scripts/convert_to_wav16.py -i '/Volumes/Harry/Yoshi\ 2\ Podcast/Camcorder/C0066.mp3' -o '/Volumes/Harry/Yoshi\ 2\ Podcast/Camcorder/C0066.wav'
   ```

### 5. Transcribing Audio
Run the Whisper C++ transcription model:

   ```
   scripts/transcribe_wav.sh <WAV_FILE> <OUTPUT_NAME>
   ```

e.g.

   ```sh
   scripts/transcribe_wav.sh '/Volumes/Harry/Yoshi 2 Podcast/Camcorder/C0066.wav' '/Volumes/Harry/Yoshi 2 Podcast/Camcorder/C0066'
   ```

This will generate a transcript .srt file in the same directory as the audio file.

#### Convert the transcript to Markdown:

   ```sh
   scripts/srt_to_markdown.py -i '/Volumes/Harry/Yoshi 2 Podcast/Camcorder/C0066.srt' -o '_transcripts/episode-123.md'
   ```

### 6. Generating Episode Summaries & Titles
- Upload the transcript to ChatGPT.
- Use prompts to generate:
-- Episode title
-- One-sentence summary
-- One-paragraph summary
- Insert this information at the top of the episode markdown file.

YouTube Content Review
- Ask ChatGPT to analyze sensitive content based on YouTube guidelines.
- Store the review results in the episode metadata.

### 7. AI Analysis & Search Integration
- Custom GPT for Podcast Analysis e.g. [Yoshi GPT](https://chatgpt.com/g/g-67a26cb91b28819181e052f64401f295-yoshi-podcast-gpt)
- Upload all transcript files.
- Ask questions like:
- Who are all the people mentioned?
- What locations are discussed?
- What topics are covered?
- Generate a narrative summary.

#### Algolia Search Setup
- Create an Algolia account (Sign in with Google).
- Set up API access:
- Go to API Access > Choose a programming language (Ruby).
- Upload any test file to generate API keys.
- Store the generated API keys in your environment settings (not included in the repo).

