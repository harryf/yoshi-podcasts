#!/usr/bin/env python3
import os
import sys
import argparse
import logging
import subprocess

def convert_to_wav16(input_path, output_path):
    """
    Convert audio file (MP3 or WAV) to WAV format optimized for speech recognition.
    Uses 16kHz sample rate, mono channel, and 16-bit PCM format.
    
    Args:
        input_path (str): Path to input audio file (MP3 or WAV)
        output_path (str): Path to output WAV file
    
    Returns:
        bool: True if conversion successful, False otherwise
    """
    logger.debug(f"Converting {input_path} to {output_path}")
    
    try:
        # FFmpeg command with optimized settings for speech recognition
        command = [
            "ffmpeg",
            "-i", input_path,
            "-ar", "16000",     # 16kHz sample rate
            "-ac", "1",         # Mono channel
            "-sample_fmt", "s16",  # 16-bit PCM
            output_path
        ]
        
        logger.debug(f"Running command: {' '.join(command)}")
        
        # Run ffmpeg with stderr redirected to subprocess.PIPE
        result = subprocess.run(
            command,
            stderr=subprocess.PIPE,
            text=True
        )
        
        # Log ffmpeg output at debug level
        if result.stderr:
            logger.debug("FFmpeg output:")
            for line in result.stderr.split('\n'):
                if line.strip():
                    logger.debug(line)
        
        if result.returncode == 0:
            logger.info(f"Successfully converted audio to {output_path}")
            return True
        else:
            logger.error("FFmpeg conversion failed")
            return False
            
    except Exception as e:
        logger.error(f"Error during conversion: {str(e)}")
        return False

if __name__ == "__main__":
    # Parse command line arguments
    parser = argparse.ArgumentParser(
        description='''
        Convert audio files to WAV format optimized for speech recognition.
        
        This script converts input audio (MP3 or WAV) to a WAV file with settings optimized 
        for speech recognition models. The conversion process applies these optimizations:
        
        Input:
        - Any audio file supported by ffmpeg (MP3 or WAV)
        
        Output:
        - WAV file with the following specifications:
          * 16 kHz sample rate (standard for most speech models)
          * Mono channel (single channel audio)
          * 16-bit PCM format (standard for speech recognition)
        
        The script uses ffmpeg for conversion and ensures the output format is 
        compatible with common speech recognition models. These settings provide
        the optimal balance between audio quality and speech recognition accuracy
        while keeping file sizes manageable.
        '''
    )
    parser.add_argument('-d', '--debug', action='store_true', help='Enable debug logging')
    parser.add_argument('-i', '--input', required=True,
                        help='Input audio file path (MP3 or WAV format)')
    parser.add_argument('-o', '--output', required=True,
                        help='Output WAV file path')
    parser.add_argument('-r', '--regenerate', action='store_true',
                        help='Force regeneration of the output wav')
    args = parser.parse_args()

    # Configure logging
    log_level = logging.DEBUG if args.debug else logging.INFO
    logging.basicConfig(level=log_level, format='%(levelname)s: %(message)s')
    logger = logging.getLogger(__name__)

    # Check if input file exists
    if not os.path.exists(args.input):
        logger.error(f"Input file not found: {args.input}")
        sys.exit(1)

    # Create output directory if it doesn't exist
    output_dir = os.path.dirname(args.output)
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)

    # Check if output file exists and handle regeneration
    if os.path.exists(args.output) and not args.regenerate:
        logger.info(f"WAV file already exists at {args.output}. Use --regenerate to convert again.")
        sys.exit(0)
    elif os.path.exists(args.output) and args.regenerate:
        logger.info("Removing existing WAV file for regeneration")
        os.remove(args.output)

    # Perform the conversion
    success = convert_to_wav16(args.input, args.output)
    sys.exit(0 if success else 1)

