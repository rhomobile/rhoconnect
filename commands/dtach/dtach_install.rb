require 'net/http'

def fetch(uri_str, limit = 10)
  raise ArgumentError, 'Too many HTTP redirects' if limit == 0

  url = URI(uri_str)
  response = Net::HTTP.get_response(url)

  case response
  when Net::HTTPOK then
    Net::HTTP.start(url.host, url.port) do |http|
      download_file = open("dtach-0.8.tar.gz", "wb")
      begin
        http.request_get(url.path) do |resp|
        resp.read_body { |segment| download_file.write(segment) }
        end
      ensure
        download_file.close
      end
    end
  when Net::HTTPRedirection then
    location = response['location']
    puts "Redirected to #{location}"
    fetch(location, limit - 1)
  else
    puts "Failed to download dtach-0.8.tar.gz file. Response code: #{response.value}"
  end
end

Execute.define_task do
  desc 'dtach-install', 'Install dtach program from sources'
  def dtach_install
    dtach_about

    unless windows?
      Dir.chdir('/tmp/')
      system "rm /tmp/dtach-0.8.tar.gz" if File.exists?('/tmp/dtach-0.8.tar.gz')
      system "rm -rf /tmp/dtach-0.8" if File.directory?('/tmp/dtach-0.8')

      uri_str = "http://sourceforge.net/projects/dtach/files/dtach/0.8/dtach-0.8.tar.gz"
      fetch(uri_str, limit = 10)

      raise "Failed to download dtach-0.8.tar.gz file." unless File.exists?('dtach-0.8.tar.gz') && File.stat('dtach-0.8.tar.gz').size != 0

      system('tar xzf dtach-0.8.tar.gz')
      Dir.chdir('/tmp/dtach-0.8/')
      system 'cd /tmp/dtach-0.8/ && ./configure && make'

      ENV['PREFIX'] and bin_dir = "#{ENV['PREFIX']}/bin" or bin_dir = "#{RedisRunner.prefix}bin"
      mkdir_p(bin_dir) unless File.exists?(bin_dir)
      system "sudo cp /tmp/dtach-0.8/dtach #{bin_dir}"

      system "rm /tmp/dtach-0.8.tar.gz"
      system "rm -rf /tmp/dtach-0.8"
      puts "Dtach successfully installed to #{bin_dir}"
    end
  end
end