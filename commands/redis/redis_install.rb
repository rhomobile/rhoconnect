Execute.define_task do
desc "redis-install", 'Install the latest verison of Redis from Github (requires git, duh)'
  def redis_install
    redis_about
    redis_download
    redis_make

    unless windows?
      ENV['PREFIX'] and bin_dir = "#{ENV['PREFIX']}/bin" or bin_dir = "#{RedisRunner.prefix}bin"

      mk_bin_dir(bin_dir)

      %w(redis-benchmark redis-cli redis-server).each do |bin|
        system "cp /tmp/redis/src/#{bin} #{bin_dir}"
      end #do

      puts "Installed redis-benchmark, redis-cli and redis-server to #{bin_dir}"

      ENV['PREFIX'] and conf_dir = "#{ENV['PREFIX']}/etc" or conf_dir = "#{RedisRunner.prefix}etc"
      unless File.exists?("#{conf_dir}/redis.conf")
        system "mkdir #{conf_dir}" unless File.exists?("#{conf_dir}")
        system "cp /tmp/redis/redis.conf #{conf_dir}/redis.conf"
        puts "Installed redis.conf to #{conf_dir} \n You should look at this file!"
      end #unless
    end #unless
  end #redis_install
end #do