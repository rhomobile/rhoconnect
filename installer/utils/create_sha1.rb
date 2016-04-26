#!/usr/bin/env ruby
require 'rubygems'
require 'digest/sha1'
require 'yaml'

if ARGV.length != 2 || !File.directory?(ARGV[0])
  puts "Usage: #{$0} directory_to_use location_for_SHA1_file"
  exit 1
end
dir      = ARGV[0]
dest_dir = ARGV[1]

sha1_hash = {}
Dir.glob(File.join("#{dir}", "**", "*")) do |path|
  next if File.directory?(path)
  file_sha1 = Digest::SHA1.file(path).to_s
  sha1_hash["#{file_sha1}".to_sym] = path
end

Dir.mkdir(dest_dir) unless File.directory?(dest_dir)
File.open("#{dest_dir}/sha1_hash", 'w') { |f| f.write(sha1_hash.to_yaml) }
