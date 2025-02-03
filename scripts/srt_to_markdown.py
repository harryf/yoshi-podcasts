#!/usr/bin/env python3
import argparse
import re
from datetime import datetime

def parse_timestamp(timestamp):
    """Convert SRT timestamp to human readable format."""
    # Parse timestamp like 00:00:00,000
    pattern = r'(\d{2}):(\d{2}):(\d{2}),(\d{3})'
    match = re.match(pattern, timestamp)
    if match:
        hours, minutes, seconds, _ = match.groups()
        # Format as HH:MM:SS
        return f"{hours}:{minutes}:{seconds}"
    return timestamp

def convert_srt_to_markdown(srt_file, markdown_file):
    """Convert SRT file to markdown format."""
    with open(srt_file, 'r', encoding='utf-8') as f:
        content = f.read().strip()

    # Split into blocks (groups of 4 lines)
    blocks = content.split('\n\n')
    
    with open(markdown_file, 'w', encoding='utf-8') as f:
        # Write header
        f.write("# Transcript\n\n")
        
        for block in blocks:
            lines = block.split('\n')
            if len(lines) >= 3:  # Ensure we have at least number, timestamp, and text
                # Get timestamp and text
                timestamp_line = lines[1]
                text = lines[2]
                
                # Extract start timestamp
                start_time = timestamp_line.split(' --> ')[0]
                formatted_time = parse_timestamp(start_time)
                
                # Write formatted line
                f.write(f"[{formatted_time}] {text}\n\n")

def main():
    parser = argparse.ArgumentParser(description='Convert SRT file to markdown format')
    parser.add_argument('-t', '--transcript', required=True, help='Input SRT file')
    parser.add_argument('-m', '--markdown', required=True, help='Output markdown file')
    
    args = parser.parse_args()
    
    convert_srt_to_markdown(args.transcript, args.markdown)

if __name__ == '__main__':
    main()
