#!/usr/bin/env ruby

require 'rubygems'
require 'aws/s3'

include AWS::S3

USER_DATA = `wget -q -O - http://169.254.169.254/latest/user-data`.split("\n")

bucket_name = 'rhoconnect'
channel     = ARGV[0]

exit if ARGV.length != 1

def cmd(cmd)
  puts cmd
  system(cmd)
end #cmd

def get_access_keys
  access_key        = USER_DATA[0].to_s.strip
  secret_access_key = USER_DATA[1].to_s.strip
  keys = { :access_key_id => access_key, :secret_access_key => secret_access_key}
end

AWS::S3::Base.establish_connection!(get_access_keys)
objects = Bucket.objects(bucket_name, :prefix => channel)
files = []
objects.each { |obj| files << "#{obj.key}" }

# Remove the files before downloading new in case they already exist
cmd "rm -rf #{channel}" if File.directory? channel
cmd "rm -f #{channel}/SHA1/checksum" if File.exist?("#{channel}/SHA1/checksum")

puts "Downloading S3 files"
files.each do |file|
  cmd = "wget -qx -t 3 -P #{channel} \"http://s3.amazonaws.com/#{bucket_name}/#{file}\""
  puts cmd
  puts "Failed to download #{file}" unless system(cmd)
end

# The download increases the depth of the files by two folders.
# Remove exess directory levels.
cmd "mv -f #{channel}/s3.amazonaws.com/#{bucket_name}/#{channel}/* #{channel}"
cmd "rm -rf #{channel}/s3.amazonaws.com"

# Pull the SHA1 checksum and hash out
cmd "mv -f #{channel}/SHA1/sha1_hash ./old_sha1_hash"
cmd "rm -rf #{channel}/SHA1"
