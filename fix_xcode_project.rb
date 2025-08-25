#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'VoiceAgentApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main group
main_group = project.main_group['VoiceAgentApp']
services_group = main_group['Services'] || main_group.new_group('Services')

# Files to add
files_to_add = {
  'VoiceAgentView.swift' => main_group,
  'VideoPlayerView.swift' => main_group,
  'Services/VAPIService.swift' => services_group,
  'Services/LocalToolExecutor.swift' => services_group
}

# Get the main target
target = project.targets.first

# Add each file
files_to_add.each do |file_path, group|
  # Don't add VoiceAgentApp/ prefix for files already in main group
  full_path = file_path.include?('Services/') ? "VoiceAgentApp/#{file_path}" : file_path
  
  # Check if file already exists in project
  existing = group.files.find { |f| f.path == File.basename(file_path) }
  
  unless existing
    puts "Adding #{file_path}..."
    file_ref = group.new_file(full_path)
    target.add_file_references([file_ref])
  else
    puts "#{file_path} already exists"
  end
end

# Add video resources
video_files = ['idle.mp4', 'Talk.mp4']
video_files.each do |video_file|
  video_path = "VoiceAgentApp/#{video_file}"
  
  # Check if file already exists in project
  existing = main_group.files.find { |f| f.path == video_file }
  
  unless existing
    puts "Adding #{video_file} as resource..."
    file_ref = main_group.new_file(video_path)
    # Add to resources build phase
    target.resources_build_phase.add_file_reference(file_ref)
  else
    puts "#{video_file} already exists"
  end
end

# Save the project
project.save
puts "Project updated successfully!"