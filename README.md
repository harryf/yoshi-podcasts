# Yoshi Podcasts

A Jekyll-based site for cataloging and viewing podcast/audio/video files along with their transcriptions, for the purpose of planning the editing process. Uses transcription with [whisper.cpp](https://github.com/openai/whisper) and search with [Algolia](https://www.algolia.com/).

## Prerequisites

Before starting, you'll need:

1. A Mac ideally with an M1/M2 chip for faster transcription. (note you could fairly easily switch this to run on Linux)
2. Basic familiarity with using the Terminal
3. An Algolia account for search functionality (free tier available - all that's needed for low search volumes)

## Initial Setup

1. Open Terminal

2. Install Homebrew (if not already installed):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

3. Install Git:
   ```bash
   brew install git
   ```

4. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/yoshi-podcasts.git
   cd yoshi-podcasts
   ```

5. Run the setup script:
   ```bash
   chmod +x setup_osx.sh
   ./setup_osx.sh
   ```

This will install all necessary dependencies including:
- Ruby and Jekyll to run the website
- Python for command line tools
- FFmpeg for audio processing
- Whisper.cpp (and dependencies) for transcription plus a model (this may take a while)

6. Configure Algolia Search:
   - Sign up for a free Algolia account at https://www.algolia.com/ - you can just login with Google
   - Create a new application
   - Create a new index e.g. called 'yoshi_podcasts'
   - Get your API keys from the Algolia dashboard
   - Create a `.env` file in the root directory of this project with:
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
Note you may want to copy the template file from `_template/episode-XXX.md` as a starting point

2. Editing the episode-XXX.md files.

The structure of the episode-XXX.md files is as follows:

   ```yaml
   ---
   layout: episode
   title: Episode XXX - Another Epic Podcast Episode
   short_title: A short title - this is just for your notes
   date: '2024-11-23' # updated automatically by update_media_metadata.rb from the first video file list
   time: '13:35' # updated automatically by update_media_metadata.rb from the first video file list
   duration: 1h6m34s # updated automatically by update_media_metadata.rb from the first video file list
   permalink: "/episodes/episode-XXX/" # permalink for the episode page
   description: One sentence description for the home page
   video_files:
      - file_name: C0001.mp4
        description: Full room camera - Camcorder # description for the episode page
        file_path: "/Volumes/EXTDRIVE/Podcast/Camcorder/C0001.mp4" # replace with actual path
      - file_name: IMG_0001.MOV
        description: Person One (iPhone 1)
        file_path: "/Volumes/EXTDRIVE/Podcast/IPhone1/IMG_0001.mp4"
      - file_name: IMG_0002.MOV
        description: Person Two (iPhone 2)
        file_path: "/Volumes/EXTDRIVE/Podcast/IPhone2/IMG_0002.mp4"
   audio_files:
      - file_name: ZOOM0001_Tr1.WAV
        mic_owner: Person One
        file_path: "/Volumes/EXTDRIVE/Podcast/Zoom/ZOOM0001/ZOOM0001_Tr1.WAV"
      - file_name: ZOOM0001_Tr2.WAV
        mic_owner: Person Two
        file_path: "/Volumes/EXTDRIVE/Podcast/Zoom/ZOOM0001/ZOOM0001_Tr2.WAV"
   ---
   Long description of episode - this appears at the bottom of the episode page
   ```

3. If you have video files and want to extract all the audios to the same directory:
   ```bash
   ./scripts/extract_audio.sh -d /path/to/video/directory
   ```

4. To generate a transcript:
   ```bash
   ./scripts/convert_to_wav16.py -i /path/to/audio.mp3 -o /path/to/audio.wav
   ./scripts/transcribe_wav.sh /path/to/audio.wav /path/to/transcript
   ```
Note that transcribe_wav.sh automatically adds the .srt extension to the output file


5. Convert the SRT transcript to markdown:
   ```bash
   ./scripts/srt_to_markdown.py -i /path/to/transcript.srt -m _transcripts/episode-XXX.md
   ```

## Adding New Episodes

1. Create a new markdown file in the `_episodes` directory
2. Add the required front matter (see `_episodes/episode-001.md` for an example)
3. Add the corresponding transcript in the `_transcripts` directory if available
4. Update the file paths to point to your media files

Note that when the website is running locally, if you look at an episode page the folder and file icons give you a quick way to copy the path to the file to your clipboard for running local scripts.

## File Structure

```
.
├── .gitignore         # Specifies which files Git should ignore
├── _config.yml        # Main Jekyll configuration
├── _config_local.yml  # Local Jekyll configuration (gitignored)
├── _episodes/         # Episode markdown files
├── _layouts/         # HTML layouts for Jekyll
├── _plugins/         # Jekyll plugins
├── _template/        # Template files for new episodes
│   └── episode-XXX.md # Base template for new episodes
├── _transcripts/     # Episode transcripts
├── assets/          # CSS and other assets
│   └── css/
│       └── style.css
├── media_server.py   # Local media file server
├── scripts/         # Utility scripts
│   ├── convert_to_wav16.py    # Convert audio to WAV format
│   ├── extract_audio.sh       # Extract audio from video
│   ├── srt_to_markdown.py     # Convert SRT to markdown
│   ├── transcribe_wav.sh      # Generate transcripts
│   └── update_media_metadata.rb # Update media metadata
├── whisper.cpp/      # Whisper transcription engine (gitignored)
├── index.html       # Homepage
├── narrative.html   # Narrative view of episodes
├── people.html      # People mentioned in episodes
├── places.html      # Places mentioned in episodes
├── search.html      # Search interface
├── topics.html      # Topics covered in episodes
├── setup_osx.sh    # Setup script
└── README.md       # This file
```

### Git Ignored Files
The following files and directories are excluded from version control:
- `whisper.cpp/`: The transcription engine (downloaded during setup)
- `_site/`: Jekyll's generated site
- `_config_local.yml`: Local configuration overrides
- Various macOS system files (`.DS_Store`, etc.)
- Editor files (`.vscode/`, `.idea/`, etc.)
- Build and cache files (`.jekyll-cache/`, `.sass-cache/`, etc.)

This ensures that only the essential source files are tracked in Git, while build artifacts, local configurations, and system-specific files are kept out of the repository.

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
After setting up your Algolia account and configuring the API keys in `_config_local.yml`, you'll need to index your content. This process scans your site content and pushes it to Algolia's search index.

Never commit API keys with write access to version control - that's why we use `_config_local.yml` which is in `.gitignore`.

a. Build the site using local config:
   ```bash
   JEKYLL_ENV=production bundle exec jekyll build --config _config.yml,_config_local.yml
   ```

b. Push indexed data to Algolia:
   ```bash
   JEKYLL_ENV=production bundle exec jekyll algolia --config _config.yml,_config_local.yml
   ```

You'll need to rerun these commands whenever you update content that should be searchable.

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
   ```

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
-- Summary of topics
-- Episode title
-- One-sentence summary
-- One-paragraph summary
-- YouTube Content Review
- Insert this information at the top of the episode markdown file.

#### Prompt for Summary

   ```
   The uploaded file is the transcript from a podcast. I want you to give me a summary of the major topics discussed as a list with time at which they start in markdown format. The timestamps you use in the summary should be links like <a href="#00-00-00">00:00:00</a> to link to lines the file

   Each major topic should be a title like this;

   ## 1. Introduction and Setup (<a href="#00-00-00">00:00:00</a>)

   Followed by a line describing that part

   The output must be in markdown that I can copy and paste
   ```

#### Prompt for Title and One-paragraph summary

   ```
   Now can you give me the following;
   - a title for the episode
   - a 1 sentence summary of the episode
   - a 1 paragraph summary of the episode
   ```

#### Prompt for YouTube Content Review

   ```
   Looking at the transcript I uploaded, can you give me a list of all the parts of the episode that might be problematic for YouTubes guidelines or be offensive to listeners.

   For each part of the transcript where you discover issues, I want you to give me the following;

   - A short summary of the topic - this should be formatted like ## <Summary of Topic> (<a href="#00-00-00">00:00:00</a>) - replace <Summary of Topic> with a title for this topic
   - A grading from 1 to 5 in terms of how sensitive it is, using the 😱 emoji to indicate how shocking it is (1 to 5 five of these emojis)
   - A short explanation of why it might be a problem
   - The start and end timestamps for the bit (so it's possible to edit it out of the podcast video)

   I want the output in markdown for a jekyll website so I can easily find all the problematic parts

   I need to be able to copy and paste the raw markdown
   ```

### 7. AI Analysis & Search Integration
- Example Custom GPT for Podcast Analysis e.g. [Yoshi GPT](https://chatgpt.com/g/g-67a26cb91b28819181e052f64401f295-yoshi-podcast-gpt)

- Upload all transcript files.
- Ask questions like:
- Who are all the people mentioned?
- What locations are discussed?
- What topics are covered?
- Generate a narrative summary.




