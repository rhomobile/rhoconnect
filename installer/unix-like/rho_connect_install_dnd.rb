require 'rho_connect_install_constants'

module DownloadAndDocompress
  # download_and_decompress
  # Delegates the download and decompression duties
  def download_and_decompress(prefix, tarballs)
    tarballs.each do |url|
      if !File.exist?("#{ get_tarball_name url }") || !File.exist?("#{ get_version url }")
        puts "Downloading #{url} ..."
        wget_download prefix, url
        decompress prefix, url
      end
    end
  end

  # wget_download
  # Takes a URL and the name of a tarball and issues a wget command on said
  # URL  unless the tarball or directory already exists
  def wget_download(prefix, url)
    if !File.exist?("#{ prefix }/#{ get_tarball_name url }") &&
       !File.directory?("#{ prefix }/#{ get_version url }")
       cmd "wget -P #{prefix} #{url} -o /dev/null"
       raise "ERROR: #{url} not found" if $? != 0
    end
  end

  # decompress
  # Decompress downloaded files unless already decompressed directory
  # exists
  def decompress(prefix, url)
    tarball = get_tarball_name(url)
    dir = get_version(url)
    cmd "tar -xzf #{prefix}/#{tarball} -C #{prefix} > /dev/null 2>&1" unless File.directory? "#{prefix}/#{dir}"
  end #decompress

  # get_version
  # This method extracts the untarballed name of files retrieved via wget
  # from their URL
  def get_version(url)
    url =~ /.*\/(.*)\.t.*\Z/
    $1
  end #get_version

  # get_tarball_name
  # This method extracts the name of files retrieved via wget from their URL
  def get_tarball_name(url)
    url =~ /.*\/(.*\.t.*)/
    $1
  end #get_tarball_name
end #DownloadAndDocompress
