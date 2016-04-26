module Constants

  PACKAGES                = ["zlib1g-dev",
                           "libcurl4-openssl-dev",
                           "apache2-mpm-prefork",
                           "apache2-prefork-dev",
                           "libapr1-dev",
                           "libaprutil1-dev",
                           "dtach"]

  RUBY                    = "ruby-2.2.1"
  REDIS                   = "redis-2.8.17"
  SQLITE3                 = "sqlite-autoconf-3080704"
  NGINX                   = "nginx-1.6.2"
  PASSENGER_ROOT          = "/opt/rhoconnect/lib/ruby/gems/1.9.1/gems/passenger"

  SOFTWARE                = [ REDIS, SQLITE3, RUBY, NGINX ]

  REDIS_URL               = "http://download.redis.io/releases/#{REDIS}.tar.gz"
  SQLITE3_URL             = "http://www.sqlite.org/2014/#{SQLITE3}.tar.gz"
  NGINX_URL               = "http://nginx.org/download/#{NGINX}.tar.gz"
  URLS                    = [ REDIS_URL, SQLITE3_URL, NGINX_URL]
  GEMS                    = ["bundler"] # foreman"

  SUPPORTED_PKG_MGRS      = ["apt-get", "yum"]
  SUPPORTED_WEB_SERVERS   = ["apache2", "nginx"]

  WEB_SERVER_URL          = "http://localhost/"

  CHECKS                  = ["check_all_packages", "check_all_gems", "check_web_server_running"]

  DEFAULT_INSTALL_DIR     = "/opt/rhoconnect"

  DEFAULTS                = {"Packages" => PACKAGES, "Software" => SOFTWARE, "Gems" => GEMS,
                             "Supported Package Managers" => SUPPORTED_PKG_MGRS,
                             "Supported Web Servers" => SUPPORTED_WEB_SERVERS,
                             "Default Install Directory" => DEFAULT_INSTALL_DIR}

end
