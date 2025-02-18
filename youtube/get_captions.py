import argparse
import json
import logging
from pathlib import Path
from typing import List, Optional

import google.auth
import google.auth.transport.requests
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

# Set up logging
logger = logging.getLogger(__name__)

def setup_logging(debug: bool = False) -> None:
    """Configure logging based on debug level"""
    level = logging.DEBUG if debug else logging.INFO
    logging.basicConfig(
        level=level,
        format='%(asctime)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )

# OAuth configuration
SCOPES = ["https://www.googleapis.com/auth/youtube.force-ssl"]
CLIENT_SECRET_FILE = "client_secret.json"
TOKEN_FILE = "token.json"

def get_authenticated_service():
    """Get authenticated YouTube service using OAuth."""
    creds = None
    token_path = Path(TOKEN_FILE)
    client_secret_path = Path(CLIENT_SECRET_FILE)

    if not client_secret_path.exists():
        raise FileNotFoundError(f"Client secret file not found: {CLIENT_SECRET_FILE}")

    # Load existing token if available
    if token_path.exists():
        try:
            creds, _ = google.auth.load_credentials_from_file(TOKEN_FILE, scopes=SCOPES)
        except Exception as e:
            logger.debug(f"Error loading existing token: {e}")

    # If no credentials available or invalid, authenticate
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            logger.debug("Refreshing expired credentials")
            creds.refresh(Request())
        else:
            logger.info("Initiating OAuth flow...")
            flow = InstalledAppFlow.from_client_secrets_file(CLIENT_SECRET_FILE, SCOPES)
            creds = flow.run_local_server(port=8080)

        # Save credentials for next use
        logger.debug("Saving credentials to token file")
        token_path.write_text(creds.to_json())

    return build("youtube", "v3", credentials=creds)

# Initialize YouTube API client
youtube = get_authenticated_service()

def get_video_captions(video_id: str) -> Optional[str]:
    """Get captions for a specific video ID."""
    logger.debug(f'Fetching captions for video ID: {video_id}')
    request = youtube.captions().list(
        part='snippet',
        videoId=video_id
    )
    response = request.execute()

    captions = response.get('items', [])
    if not captions:
        logger.info(f'No captions found for video ID: {video_id}')
        return None

    # Get the first available caption
    caption = captions[0]
    caption_id = caption['id']
    logger.debug(f'Found caption ID: {caption_id}')
    return caption_id

def download_caption(caption_id: str, output_dir: Path) -> Path:
    """Download caption by ID and save to file."""
    logger.debug(f'Downloading caption ID: {caption_id}')
    request = youtube.captions().download(id=caption_id, tfmt='srt')
    response = request.execute()
    
    output_file = output_dir / f'{caption_id}.srt'
    output_file.write_bytes(response)
    logger.info(f'Downloaded subtitles to: {output_file}')
    return output_file

def get_channel_videos(channel_id: str) -> List[str]:
    """Get all video IDs from a channel."""
    logger.debug(f'Fetching videos for channel ID: {channel_id}')
    request = youtube.search().list(
        part='id',
        channelId=channel_id,
        maxResults=50,
        type='video'
    )
    response = request.execute()
    video_ids = [item['id']['videoId'] for item in response['items']]
    logger.info(f'Found {len(video_ids)} videos in channel')
    return video_ids

def main():
    parser = argparse.ArgumentParser(description='Download YouTube video captions')
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('-v', '--video-id', help='YouTube video ID')
    group.add_argument('-c', '--channel-id', help='YouTube channel ID')
    parser.add_argument('-o', '--output-dir', type=Path, default=Path.cwd(),
                        help='Output directory for caption files')
    parser.add_argument('-d', '--debug', action='store_true',
                        help='Enable debug logging')
    
    args = parser.parse_args()
    setup_logging(args.debug)
    
    # Create output directory if it doesn't exist
    args.output_dir.mkdir(parents=True, exist_ok=True)
    
    if args.video_id:
        logger.info(f'Processing single video: {args.video_id}')
        caption_id = get_video_captions(args.video_id)
        if caption_id:
            download_caption(caption_id, args.output_dir)
    else:
        logger.info(f'Processing channel: {args.channel_id}')
        video_ids = get_channel_videos(args.channel_id)
        for video_id in video_ids:
            caption_id = get_video_captions(video_id)
            if caption_id:
                download_caption(caption_id, args.output_dir)

if __name__ == '__main__':
    main()


