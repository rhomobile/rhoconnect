require 'net/http'
require 'net/https'


def fetch(uri_str, version, limit = 10)

  raise ArgumentError, 'Too many HTTP redirects' if limit == 0

  url = URI(uri_str)
  response = Net::HTTP.get_response(url)
  case response
  when Net::HTTPOK then
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    file_name = "dtach-#{version}.tar.gz"
    download_file = open(file_name, "wb")
    begin
      http.request_get(url.path) do |resp|
        resp.read_body {|segment| download_file.write(segment)}
      end
    ensure
      download_file.close
    end

  when Net::HTTPRedirection then
    location = response['location']
    puts "Redirected to #{location}"
    fetch(location, version, limit - 1)
  else
    puts "Failed to download dtach-#{version}.tar.gz file. Response code: #{response.value}"
  end
end

Execute.define_task do
  desc 'dtach-install', 'Install dtach program from sources'
  def dtach_install
    version = '0.9'
    dtach_about

    unless windows?
      Dir.chdir('/tmp/')
      system "rm /tmp/dtach-#{version}.tar.gz" if File.exist?("/tmp/dtach-#{version}.tar.gz")
      system "rm -rf /tmp/dtach-#{version}" if File.directory?("/tmp/dtach-#{version}")

      uri_str = "https://sourceforge.net/projects/dtach/files/dtach/#{version}/dtach-#{version}.tar.gz"
      fetch(uri_str, version, limit = 10)

      raise "Failed to download dtach-#{version}.tar.gz file." unless File.exist?("dtach-#{version}.tar.gz") && File.stat("dtach-#{version}.tar.gz").size != 0

      system("tar xzf dtach-#{version}.tar.gz")
      Dir.chdir("/tmp/dtach-#{version}/")
      system "cd /tmp/dtach-#{version}/ && ./configure && make"

      ENV['PREFIX'] and bin_dir = "#{ENV['PREFIX']}/bin" or bin_dir = "#{RedisRunner.prefix}bin"
      mkdir_p(bin_dir) unless File.exist?(bin_dir)
      system "sudo cp /tmp/dtach-#{version}/dtach #{bin_dir}"

      system "rm /tmp/dtach-#{version}.tar.gz"
      system "rm -rf /tmp/dtach-#{version}"
      puts "Dtach successfully installed to #{bin_dir}"
    end
  end
end
