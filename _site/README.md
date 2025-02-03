# Yoshi Podcasts

A Jekyll-based site for cataloging and viewing podcast/audio/video files along with their transcriptions.

## Features

- Episode catalog with metadata
- Support for multiple video and audio files per episode
- Transcript viewing
- Direct file access (when mounted)
- Responsive design

## Setup

1. Install Ruby and Bundler if you haven't already
2. Clone this repository
3. Run `bundle install` to install dependencies
4. Run `bundle exec jekyll serve` to start the local server
5. Visit `http://localhost:4000` in your browser

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
├── index.html          # Homepage
└── README.md          # This file
```

## License

This project is open source and available under the MIT License.
