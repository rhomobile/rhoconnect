require 'ffaker'
require_relative '../spec_helper'

def get_test_data(num=1000)
  file = File.join(SPEC_PATH, "testdata","#{num}-data.txt")
  data = nil
  if File.exist?(file)
    data = open(file, 'r') {|f| Marshal.load(f)}
  else
    data = generate_fake_data(num)
    f = File.new(file, 'w')
    f.write Marshal.dump(data)
    f.close
  end
  data
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

def title
  prefix = PREFIX[rand(PREFIX.length)]
  suffix = SUFFIX[rand(SUFFIX.length)]

  "#{prefix} #{suffix}"
end

def generate_fake_data(num=1000,unique=false)
  res = {}
  num.times do |n|
    unique_prefix = ""
    if unique
      unique_prefix = "#{n}-#{Time.now.to_s}"
    end
    res[n.to_s] = {
      "FirstName" => FFaker::Name.first_name + unique_prefix,
      "LastName" => FFaker::Name.last_name + unique_prefix,
      "Email" =>  FFaker::Internet.free_email + unique_prefix,
      "Company" => FFaker::Company.name + unique_prefix,
      "JobTitle" => title + unique_prefix,
      "Phone1" => FFaker::PhoneNumber.phone_number + unique_prefix
    }
  end
  res
end
