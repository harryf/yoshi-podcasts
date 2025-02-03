require 'json'
require 'time'
require 'yaml'

module Jekyll
  class EpisodeMetadataGenerator < Generator
    safe true
    priority :high

    def generate(site)
      site.collections['episodes'].docs.each do |episode|
        update_episode_metadata(episode)
      end
    end

    private

    def update_episode_metadata(episode)
      # First try to get metadata from video files (most accurate)
      video_metadata = nil
      
      episode.data['video_files']&.each do |video|
        if video['file_path'].include?('Camcorder')  # Only use camcorder files
          video_metadata = extract_metadata_from_file(video['file_path'])
          break if video_metadata
        end
      end
      
      if video_metadata
        # Update the episode data in memory
        episode.data['date'] = video_metadata[:date]
        episode.data['time'] = video_metadata[:time]
        episode.data['duration'] = video_metadata[:duration]
        
        # Update the actual markdown file
        update_markdown_file(episode.path, video_metadata)
      end
    end

    def extract_metadata_from_file(path)
      return nil unless path && File.exist?(path)
      
      json_output = `ffprobe -v quiet -show_format -show_streams -print_format json "#{path}"`
      return nil if json_output.empty?

      begin
        data = JSON.parse(json_output)
        creation_time = data['format']['tags']['creation_time'] ||
                       data['streams']&.find { |s| s['codec_type'] == 'video' }&.dig('tags', 'creation_time')
        
        if creation_time && creation_time.include?('T')
          time = Time.parse(creation_time)
          {
            date: time.strftime("%Y-%m-%d"),
            time: time.strftime("%H:%M"),
            duration: format_duration(data['format']['duration'].to_f)
          }
        end
      rescue
        nil
      end
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

    def update_markdown_file(file_path, metadata)
      content = File.read(file_path)
      
      # Parse the front matter
      if content =~ /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m
        front_matter = $1
        content_after_front_matter = $'
        
        # Parse the existing front matter
        data = YAML.safe_load(front_matter, permitted_classes: [Date, Time]) || {}
        
        # Update the metadata
        data['date'] = metadata[:date]
        data['time'] = metadata[:time]
        data['duration'] = metadata[:duration]
        
        # Convert to YAML, ensuring proper formatting
        new_front_matter = data.to_yaml.sub("---\n", '')
        
        # Write the updated content back to the file
        File.write(file_path, "---\n#{new_front_matter}---\n#{content_after_front_matter}")
      end
    end
  end

  class MediaMetadata < Liquid::Tag
    def initialize(tag_name, file_path, tokens)
      super
      @file_path = file_path.strip
    end

    def render(context)
      path = if @file_path.start_with?('"') || @file_path.start_with?("'")
        @file_path.gsub(/^['"]|['"]$/, '')
      else
        context[@file_path.strip]
      end

      return "No file path provided" if path.nil? || path.empty?

      json_output = `ffprobe -v quiet -show_format -show_streams -print_format json "#{path}"`
      return "Error reading file metadata" if json_output.empty?

      begin
        data = JSON.parse(json_output)
        format_metadata_html(data, path, context)
      rescue JSON::ParserError
        "Error parsing metadata"
      end
    end

    private

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

    def format_datetime(datetime_str, context)
      return nil unless datetime_str
      
      begin
        if datetime_str.include?('T')
          # Full ISO format from camcorder
          time = Time.parse(datetime_str)
          time.strftime("%B %d, %Y at %I:%M %p")
        else
          # Time-only format from Zoom
          # Use the date from video file in the episode
          episode_date = context.registers[:page]['date']
          if episode_date
            date = Time.parse(episode_date).strftime("%B %d, %Y")
            time = Time.parse(datetime_str)
            "#{date} at #{time.strftime("%I:%M %p")}"
          else
            datetime_str
          end
        end
      rescue
        datetime_str
      end
    end

    def format_metadata_html(data, path, context)
      format_data = data['format']
      streams = data['streams']
      
      video_stream = streams.find { |s| s['codec_type'] == 'video' }
      audio_stream = streams.find { |s| s['codec_type'] == 'audio' }
      
      creation_time = format_data.dig('tags', 'creation_time') || 
                     video_stream&.dig('tags', 'creation_time') ||
                     format_data.dig('tags', 'date')
      
      if format_data.dig('tags', 'encoded_by')&.include?('ZOOM')
        zoom_time = format_data.dig('tags', 'creation_time')
        creation_time = zoom_time if zoom_time
      end
      
      device = format_data.dig('tags', 'encoded_by') ||
               video_stream&.dig('tags', 'handler_name') ||
               'Unknown device'

      html = []
      html << '<div class="media-metadata">'
      
      html << '<div class="metadata-section">'
      html << '<h4>Recording Info</h4>'
      if creation_time
        formatted_time = format_datetime(creation_time, context)
        html << "<p><strong>Recorded:</strong> #{formatted_time}</p>"
      end
      html << "<p><strong>Duration:</strong> #{format_duration(format_data['duration'])}</p>"
      html << "<p><strong>Device:</strong> #{device}</p>"
      html << '</div>'

      html << '<div class="metadata-section">'
      html << '<h4>Technical Details</h4>'
      if video_stream
        html << '<p><strong>Video:</strong></p>'
        html << "<ul>"
        html << "<li>Resolution: #{video_stream['width']}x#{video_stream['height']}</li>"
        html << "<li>Frame Rate: #{video_stream['r_frame_rate'].split('/').first} fps</li>"
        html << "<li>Codec: #{video_stream['codec_long_name']}</li>"
        html << "</ul>"
      end
      
      if audio_stream
        html << '<p><strong>Audio:</strong></p>'
        html << "<ul>"
        html << "<li>Sample Rate: #{audio_stream['sample_rate']} Hz</li>"
        html << "<li>Channels: #{audio_stream['channels']}</li>"
        html << "<li>Codec: #{audio_stream['codec_long_name']}</li>"
        html << "</ul>"
      end
      
      html << "<p><strong>File Size:</strong> #{format_size(format_data['size'].to_i)}</p>"
      html << "<p><strong>Format:</strong> #{format_data['format_long_name']}</p>"
      html << '</div>'

      html << '</div>'
      html.join("\n")
    end

    def format_size(size_in_bytes)
      units = ['B', 'KB', 'MB', 'GB', 'TB']
      unit_index = 0
      size = size_in_bytes.to_f

      while size > 1024 && unit_index < units.length - 1
        size /= 1024
        unit_index += 1
      end

      format("%.2f %s", size, units[unit_index])
    end
  end
end

Liquid::Template.register_tag('media_metadata', Jekyll::MediaMetadata)
