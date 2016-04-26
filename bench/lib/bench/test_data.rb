require 'ffaker'
require 'securerandom'

module Bench
  module TestData
    def get_test_data(num=1000, generate=false, generate_blob=false)
      file_name = generate_blob ? "#{num}-blob_data.txt" : "#{num}-data.txt"
      file = File.join(File.dirname(__FILE__), '..', "testdata", file_name)
      data = nil
      if File.exists?(file) and not generate
        data = open(file, 'r') {|f| Marshal.load(f)}
      else
        data = generate_fake_data(num, generate_blob)
        f = File.new(file, 'w')
        f.write Marshal.dump(data)
        f.close
      end
      data
    end

    def get_image_data(objs)
      blobs = {}
      objs.keys.each do |key|
        img_file_name = objs["#{key}"]["filename"]
        blobs["img_file-rhoblob-#{key}"] =
          File.new(File.join(File.dirname(__FILE__), "..", "testdata", "images", "#{img_file_name}"), 'rb')
      end
      blobs
    end

    BenchUser = Struct.new(:user_name, :password)

    def get_bench_users(num=1)
      users = []
      num.times do |i|
        user_name = Faker::Internet.user_name
        password  = Faker::Lorem.words[0] # for more real passwords use 'forgery' gem
        users << BenchUser.new(user_name, password)
      end
      users
    end
    
    def generate_fake_data(num, generate_blob)
      res = {}
      num.times do |n|
        mock_id = SecureRandom.hex
        res[mock_id] = {
          "mock_id" => mock_id,
          "FirstName" => Faker::Name.first_name,
          "LastName" => Faker::Name.last_name,
          "Email" =>  Faker::Internet.free_email,
          "Company" => Faker::Company.name,
          "JobTitle" => title,
          "Phone1" => Faker::PhoneNumber.phone_number,
          "Geolocation" => Faker::Geolocation.lat.to_s + ":" + Faker::Geolocation.lng.to_s,
          "Education" => Faker::Education.degree,
          "School" => Faker::Education.school
        }
        if generate_blob
          img_file_name = IMAGE_FILES[rand(IMAGE_FILES.size)]
          res[mock_id]["img_file-rhoblob"] = img_file_name
          res[mock_id]["img_file_size"] = 
            File.size(File.join(File.dirname(__FILE__), "..", "testdata", "images", "#{img_file_name}")).to_s
          res[mock_id]["filename"] = img_file_name

          # Additional fields: from 0 to 50 will be added to existing 10 ones (total upto 60)
          words = Faker::Lorem.words(rand(50))
          words.each do |word|
            res[mock_id]["#{word}"] = word unless EXCLUDE_LIST.include?(word)
          end
        end
      end
      res
    end

    private

    PREFIX = ["Account", "Administrative", "Advertising", "Assistant", "Banking", "Business Systems", 
      "Computer", "Distribution", "IT", "Electronics", "Environmental", "Financial", "General", "Head", 
      "Laboratory", "Maintenance", "Medical", "Production", "Quality Assurance", "Software", "Technical", 
      "Chief", "Senior"] unless defined? PREFIX
    SUFFIX = ["Clerk", "Analyst", "Manager", "Supervisor", "Plant Manager", "Mechanic", "Technician", "Engineer", 
      "Director", "Superintendent", "Specialist", "Technologist", "Estimator", "Scientist", "Foreman", "Nurse", 
      "Worker", "Helper", "Intern", "Sales", "Mechanic", "Planner", "Recruiter", "Officer", "Superintendent",
      "Vice President", "Buyer", "Production Supervisor", "Chef", "Accountant", "Executive"] unless defined? SUFFIX

    IMAGE_FILES = %w{
      icon.ico                loading-LandscapeLeft.png   loading-PortraitUpsideDown.png
      icon.png                loading-LandscapeRight.png  loading.png
      loading-Landscape.png   loading-Portrait.png        loading@2x.png }

    EXCLUDE_LIST = %w{ id  mock_id  img_file-rhoblob  img_file_size  filename }

    def title
      prefix = PREFIX[rand(PREFIX.length)]
      suffix = SUFFIX[rand(SUFFIX.length)]
 
      "#{prefix} #{suffix}"
    end
  end
end