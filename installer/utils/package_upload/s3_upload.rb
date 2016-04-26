#!/usr/bin/env ruby

require 'rubygems'
require 'aws/s3'
require 'find'

# CONSTANTS

START_DIR = ARGV[0]
BUCKET = ARGV[1]
USER_DATA = `wget -q -O - http://169.254.169.254/latest/user-data`.split("\n")

# METHODS

# Facilitates easy use of system calls
def cmd(cmd)
  puts cmd
  system cmd
end #cmd

# Makes sure parameters are correctly formed
def check_params
  if ARGV.size != 2
    puts "Wrong number of arguments (#{ARGV.size} for 2)"
    exit
  end #if

  if !FileTest.directory?(START_DIR)
    puts "#{START_DIR} is not a directory."
    exit
  end #if
  
  begin
    found = AWS::S3::Bucket.find(BUCKET)
  rescue => e
    puts "#{BUCKET} is not a valid bucket."
    puts e.inspect
    puts e.backtrace
    exit
  end
end #check_params

# Retrieves S3 credential information
def get_keys
   access_key = USER_DATA[0].to_s.strip
   secret_access_key = USER_DATA[1].to_s.strip
   keys = { :access_key_id => access_key,
            :secret_access_key => secret_access_key}
end #get_keys

# Establishes S3 connection
def establish_s3_connection
  @s3_connection = AWS::S3::Base.establish_connection!(get_keys)
end #establish_s3_connection

# Uploads given file to the specified S3 bucket
def upload(file)
  # Upload the given file
  AWS::S3::S3Object.store( file,
                           open( file ),
                           BUCKET,
                           :access => :public_read )

  # display the URL of the file just uploaded
  puts AWS::S3::S3Object.url_for((file), BUCKET)[/[^?]+/]
end #upload

# Traverses list of file to upload and calls Upload to upload them
def upload_files
  # Get list of files do be added
  number_of_files = 0
  paths = []
  Find.find(START_DIR) do |path|
    if FileTest.directory?(path)
      next
    else
      paths.push(path)
      number_of_files += 1
    end
  end

  puts "Uploading #{number_of_files} files."
  paths.each do |path|
    upload path
  end #do
  puts "#{number_of_files} files uploaded."
end #upload_files

# SCRIPT

begin
  establish_s3_connection
rescue => e
  puts "Error Connecting to S3!!"
  puts e.inspect
  puts e.backtrace
  exit 1
end #begin

begin
  check_params
rescue => e
  puts "Error Checking Parameters!!"
  puts e.inspect
  puts e.backtrace
  exit 2
end #begin

begin
  upload_files
rescue => e
  puts "Error Uploading files!!"
  puts e.inspect
  puts e.backtrace
  exit 3
end #begin