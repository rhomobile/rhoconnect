require 'rubygems'
require 'rake'
require 'find'
require 'fileutils'


desc 'Creates and uploads apt and rpm repos.'
task "build:repos", :build_type, :build_number do |t, args|
  # Run dependent rake jobs first
  Rake::Task['build:deb'].invoke
  Rake::Task['build:rpm'].invoke
  args.with_defaults :build_type   => 'nightly'
  args.with_defaults :build_number => ''
  puts args

  build_type   = args[:build_type]
  build_number = args[:build_number]

  RHOCONNECT_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
  PKG_DIR = case build_type
            when 'release'  then '/packages'
            when 'test'     then '/test-packages'
            when 'beta'     then '/beta-packages'
            else '/nightly-packages'
            end
  BUCKET = 'rhoconnect'

  def cmd(cmd)
    puts cmd
    puts `#{cmd}`
  end

  def prepare_destination
    # Prompt to remove the /deb directory if it exists
    if File.directory?("#{PKG_DIR}/deb")
      cmd "sudo rm -rf #{PKG_DIR}/deb"
    end #if

    # Create deb directory if it does not already exist
    cmd "sudo mkdir -p #{PKG_DIR}/deb" unless File.directory?("#{PKG_DIR}/deb")

    # Create configuration file "ditributions" in deb directory
    filename = "#{PKG_DIR}/deb/conf"
    cmd "sudo mkdir -p #{filename}"
    distributions = "Origin: Symbol Technologies, Inc.\n" +
                    "Label: Symbol Technologies, Inc.\n" +
                    "Codename: rhoconnect\n" +
                    "Architectures: i386 amd64\n" +
                    "Components: main\n" +
                    "Description: Rhoconnect APT Repository\n"
    cmd "sudo touch #{filename}/distributions"
    cmd "sudo chmod -R 777 #{PKG_DIR}"

    # Write distributions string to corresponding file
    dist_file = File.new("#{filename}/distributions", "w")
    dist_file.write(distributions)
    dist_file.close

    # Create rpm directory if it does not already exist
    cmd "sudo mkdir -p #{PKG_DIR}/rpm" unless File.directory?("#{PKG_DIR}/rpm")

  end #prepare_destination


  def copy_files
    # Move back into rhoconnect repo root first
    Dir.chdir RHOCONNECT_ROOT
    # Copy the packages to their respective directory
    Find.find('./pkg') do |file|
      if !FileTest.directory?(file)
        dest_dir = File.extname(file)
        # Get rid of '.' before extension name
        dest_dir[0] = ''
        if dest_dir == 'deb' || dest_dir == 'rpm'
          if dest_dir == 'deb'
            @deb_pkg = File.basename(file)
          end #if
          file_path = File.expand_path(file)
          cmd "sudo cp -r #{file_path} #{PKG_DIR}/#{dest_dir}"
        end #if
      end #if
    end #do
  end #copy_files

  # SCRIPT
  prepare_destination

  copy_files

 if !build_number.empty?
   # Change name of packages to include build number
  ['deb', 'rpm'].each do |arch|
    Find.find("#{PKG_DIR}") do |file|
      if !File.directory?(file) and file =~ /#{arch}$/
        #file_to_rename = File.open(file, 'r')
        old_name = File.expand_path(file)
        new_name = old_name.gsub(/(#{arch})$/, "#{build_number}.\\1" )
        #File.rename(old_name, new_name)
        log = `sudo mv #{old_name} #{new_name} 2>&1`
        raise "#{log}" if $? != 0
        @deb_pkg = File.basename(new_name) if arch == 'deb'
      end
    end
  end
 end

  # REPOIFY!
  cmd "sudo reprepro -b #{PKG_DIR}/deb includedeb rhoconnect #{PKG_DIR}/deb/#{@deb_pkg}"
  cmd "sudo createrepo #{PKG_DIR}/rpm"

  # Create SHA1 checksum of repo dirs
  # checksum_dest = "#{PKG_DIR}/SHA1/"
  cmd "sudo ./installer/utils/create_sha1.rb #{PKG_DIR} #{PKG_DIR}/SHA1"

  # Call s3_upload.rb
  ['deb', 'rpm'].each do |dir|
    cmd "sudo ruby ./installer/utils/package_upload/s3_upload.rb #{PKG_DIR}/#{dir} #{BUCKET}"
  end #do
  cmd "sudo ruby ./installer/utils/package_upload/s3_upload.rb #{PKG_DIR}/SHA1 #{BUCKET}"
end #build:repos
