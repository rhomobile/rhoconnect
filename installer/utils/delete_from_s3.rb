#!/usr/bin/env ruby

require 'rubygems'
require 'aws/s3'

include AWS::S3

USER_DATA = `wget -q -O - http://169.254.169.254/latest/user-data`.split("\n")

bucket_name = ARGV[0].strip
channel     = ARGV[1].strip

def get_access_keys
  access_key        = USER_DATA[0].to_s.strip
  secret_access_key = USER_DATA[1].to_s.strip
  keys = { :access_key_id => access_key,
           :secret_access_key => secret_access_key}
end #get_access_keys

AWS::S3::Base.establish_connection!(get_access_keys)

objects = Bucket.objects(bucket_name, :prefix => channel)
files = []
objects.each { |obj| files << "#{obj.key}" }

files.each do |file|
  puts "Deleting #{file}"
  S3Object.delete file, bucket_name
end #do