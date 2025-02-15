#!/usr/bin/env ruby

require 'yaml'
require 'json'
require 'time'

def extract_metadata_from_file(path)
  return { error: "File does not exist: #{path}" } unless File.exist?(path)
  
  begin
    command = "ffprobe -v quiet -show_format -show_streams -print_format json \"#{path}\""
    json_output = `#{command}`
    
    if json_output.empty?
      return { error: "ffprobe command returned no output", command: command }
    end

    data = JSON.parse(json_output)
    unless data['format'] && data['streams']
      return { 
        error: "ffprobe output missing format or streams data",
        command: command,
        output: json_output
      }
    end
    
    # Get file stats
    file_stats = File.stat(path)
    
    # Extract all useful metadata
    metadata = {
      # File system metadata
      'file_size' => format_size(file_stats.size),
      'created_at' => file_stats.birthtime.strftime("%Y-%m-%d %H:%M:%S"),
      'modified_at' => file_stats.mtime.strftime("%Y-%m-%d %H:%M:%S"),
      
      # Format metadata
      'format' => data['format']['format_name'],
      'duration' => format_duration(data['format']['duration'].to_f),
      'bit_rate' => format_bitrate(data['format']['bit_rate'].to_i),
      
      # Try to get creation time from multiple possible locations
      'recording_date' => nil,
      'recording_time' => nil
    }
    
    # Get creation time from various possible locations
    creation_time = data['format']['tags']&.fetch('creation_time', nil) ||
                   data['streams']&.find { |s| s['codec_type'] == 'video' }&.dig('tags', 'creation_time') ||
                   data['format']['tags']&.fetch('date', nil)
    
    if creation_time && creation_time.include?('T')
      time = Time.parse(creation_time)
      metadata['recording_date'] = time.strftime("%Y-%m-%d")
      metadata['recording_time'] = time.strftime("%H:%M:%S")
    end
    
    # Add stream-specific metadata
    video_stream = data['streams'].find { |s| s['codec_type'] == 'video' }
    audio_stream = data['streams'].find { |s| s['codec_type'] == 'audio' }
    
    if video_stream
      metadata['video'] = {
        'codec' => video_stream['codec_name'],
        'width' => video_stream['width'],
        'height' => video_stream['height'],
        'frame_rate' => eval(video_stream['r_frame_rate']).round(2),
        'bit_depth' => video_stream['bits_per_raw_sample']
      }
    end
    
    if audio_stream
      metadata['audio'] = {
        'codec' => audio_stream['codec_name'],
        'channels' => audio_stream['channels'],
        'sample_rate' => audio_stream['sample_rate'],
        'bit_depth' => audio_stream['bits_per_sample']
      }
    end
    
    metadata
  rescue => e
    return { 
      error: "Error processing #{path}: #{e.message}",
      command: command
    }
  end
end

def format_size(bytes)
  units = ['B', 'KB', 'MB', 'GB', 'TB']
  unit_index = 0
  size = bytes.to_f
  
  while size > 1024 && unit_index < units.length - 1
    size /= 1024
    unit_index += 1
  end
  
  "#{size.round(2)}#{units[unit_index]}"
end

def format_bitrate(bps)
  return "0 kb/s" if bps.nil? || bps.zero?
  "#{(bps.to_f / 1000).round(0)} kb/s"
end

def format_duration(seconds)
  return "0s" if seconds.nil? || seconds.to_f.zero?
  
  total_seconds = seconds.to_f
  hours = (total_seconds / 3600).floor
  minutes = ((total_seconds % 3600) / 60).floor
  secs = (total_seconds % 60).round
  
  parts = []
  parts << "#{hours}h" if hours > 0
  parts << "#{minutes}m" if minutes > 0
  parts << "#{secs}s" if secs > 0 || parts.empty?
  
  parts.join
end

def process_episode_file(file_path)
  puts "Processing #{file_path}..."
  content = File.read(file_path)
  
  # Parse the front matter
  if content =~ /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m
    front_matter = $1
    content_after_front_matter = $'
    
    # Parse the existing front matter
    data = YAML.safe_load(front_matter, permitted_classes: [Date, Time]) || {}
    modified = false
    
    # Process video files
    if data['video_files']
      data['video_files'].map! do |video|
        if video['file_path']
          metadata = extract_metadata_from_file(video['file_path'])
          if metadata&.key?(:error)
            puts "\nError processing #{video['file_path']}:"
            puts "  #{metadata[:error]}"
            if metadata[:command]
              puts "  Command used: #{metadata[:command]}"
            end
            if metadata[:output]
              puts "  Command output: #{metadata[:output]}"
            end
          elsif metadata
            puts "Found metadata for #{video['file_path']}"
            modified = true
            video.merge!('metadata' => metadata)
          end
        end
        video
      end
    end
    
    # Process audio files
    if data['audio_files']
      data['audio_files'].map! do |audio|
        if audio['file_path']
          metadata = extract_metadata_from_file(audio['file_path'])
          if metadata&.key?(:error)
            puts "\nError processing #{audio['file_path']}:"
            puts "  #{metadata[:error]}"
            if metadata[:command]
              puts "  Command used: #{metadata[:command]}"
            end
            if metadata[:output]
              puts "  Command output: #{metadata[:output]}"
            end
          elsif metadata
            puts "Found metadata for #{audio['file_path']}"
            modified = true
            audio.merge!('metadata' => metadata)
          end
        end
        audio
      end
    end
    
    if modified && data['video_files']&.first&.dig('metadata')
      first_video = data['video_files'].first['metadata']
      
      # Update episode front matter if we have recording date/time
      if first_video['recording_date'] && first_video['recording_time']
        data['date'] = first_video['recording_date']
        data['time'] = first_video['recording_time'].split(':')[0..1].join(':') # HH:MM format
      end
      
      # Update duration if available
      if first_video['duration']
        data['duration'] = first_video['duration']
      end
      
      # Convert to YAML, ensuring proper formatting
      new_front_matter = data.to_yaml.sub("---\n", '')
      
      # Write the updated content back to the file
      File.write(file_path, "---\n#{new_front_matter}---\n#{content_after_front_matter}")
      puts "Updated #{file_path} with metadata from first video file"
    else
      puts "No changes needed for #{file_path}"
    end
  end
end

# Main script
episodes_dir = File.join(File.dirname(__FILE__), '..', '_episodes')
Dir.glob(File.join(episodes_dir, '*.md')).each do |file|
  process_episode_file(file)
end
