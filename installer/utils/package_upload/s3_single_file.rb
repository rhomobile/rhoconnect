#!/usr/bin/env ruby

require 'rubygems'
require 'aws/s3'

# Constants

FILE      = File.expand_path(ARGV[0])
BUCKET    = ARGV[1]
USER_DATA = `wget -q -O - http://169.254.169.254/latest/user-data`.split("\n")

# Methods

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
def upload
  # Upload the given file
  AWS::S3::S3Object.store( FILE,
                           open( FILE ),
                           BUCKET,
                           :access => :public_read )

  # display the URL of the file just uploaded
  puts AWS::S3::S3Object.url_for((FILE), BUCKET)[/[^?]+/]
end #upload

# Script

begin
  establish_s3_connection
rescue => e
  puts "Error Connecting to S3!!"
  puts e.inspect
  puts e.backtrace
  exit 1
end #begin

begin
  upload 
rescue => e
  puts "Error Uploading files!!"
  puts e.inspect
  puts e.backtrace
  exit 3
end #begin
