#!/usr/bin/env ruby
require 'rubygems'
require 'digest/sha1'
require 'yaml'

if ARGV.length != 2
  puts "Usage: #{$0} checksum_hash directory_to_compare"
  exit 1
end

def cmd(cmd)
  puts cmd
  system(cmd)
end

def checksum keys
  sha1 = Digest::SHA1.new
  # Order important!
  keys.sort.each { |k| sha1 << k.to_s }
  sha1
end

checksum_hash  = ARGV[0]
dir_to_compare = ARGV[1]

# Downoad Packages from S3
cmd "ruby ./installer/utils/download_from_s3.rb #{dir_to_compare}"
# Create the checksum to compare against the one from the S3 repo
cmd "ruby ./installer/utils/create_sha1.rb #{dir_to_compare} ."
old_sha1_h = YAML.load(File.read(checksum_hash))
new_sha1_h = YAML.load(File.read("./sha1_hash"))

match = true
old_sha1_h.each do |k,v|
  unless new_sha1_h[k]
    puts "Error! Checksum mismatch for file #{v}"
    match = false
  end
end

unless match
  puts
  puts "Checksums do not match!"
  puts "Expected sha1/file"
  old_sha1_h = YAML.load(File.read(checksum_hash)).sort
  old_sha1_h.each { |k,v| puts "#{k}: #{v}" }
  puts "Got sha1/file"
  new_sha1_h = YAML.load(File.read("./sha1_hash")).sort
  new_sha1_h.each { |k,v| puts "#{k}: #{v}" }
  puts
  exit 2
end

puts "Checksums match!"
