$:.unshift File.expand_path(File.join(File.dirname(__FILE__),'..','unix-like'))

require 'optparse'
require 'rho_connect_install_constants'
require 'fileutils'

options = {}

optparse = OptionParser.new do |opts|
  options[:dist] = nil
  opts.on( '-d', '--dist DISTRO', 'Specify DISTRO as the current distribution.' ) do |dist|
    options[:dist] = dist
  end #do

  options[:prefix] = '/opt/rhoconnect'
  opts.on( '-p', '--prefix RHODIR', 'Specify RHODIR as the prefix directory.' ) do |dir|
    options[:prefix] = dir
  end #do

  options[:redis] = true
  opts.on( '--no-redis', '', 'Skip installing the redis server.' ) do
    options[:redis] = false
  end #do

  options[:rubyVersion] = 'rubyee'
  opts.on( '-r', '--rubyVer VERSION', 'Specify VERSION as the verion of ruby that is installed.' ) do |rubyVer|
    options[:rubyVersion] = rubyVer
  end #do

  options[:web_server] = "nginx"
  opts.on('-w', '--web-server Server', ' Specify that you are using web server SERVER') do |server|
    options[:web_server] = server
  end #do

  opts.on('-l', '--Logfile file', ' Specify installtion log file') do |file|
    options[:log_file] = file
  end #do

end #do

optparse.parse!

@prefix = options[:prefix]
@dist = options[:dist]
@redis = options[:redis]
@ruby_version = options[:rubyVersion]
@profile = (@dist == 'debian') ? '~/.profile' : '~/.bash_profile'
@server = options[:web_server]
@log_file = options[:log_file]

@passenger_root = Constants::PASSENGER_ROOT

def passenger_version
  (`#{@prefix}/bin/passenger --version`.match /\d+\.\d+\.\d+/)[0]
end

# create_redis_init
# Creates the redis initialization file and places it into the correct directory
def create_redis_init
  redis_init_script = <<'_REDIS_INIT_SCRIPT_'
#!/usr/bin/env bash
### BEGIN INIT INFO
# Provides:          redis-server
# Required-Start:    $syslog
# Required-Stop:     $syslog
# Should-Start:      $local_fs
# Should-Stop:       $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: redis-server - Persistent key-value db
# Description:       redis-server - Persistent key-value db
### END INIT INFO
#
# Author:  Wayne E. Seguin <wayneeseguin@gmail.com>
# License: The same licence as Redis, New BSD
#          http://www.opensource.org/licenses/bsd-license.php
#

# Source the system config file, if it exists.
if [[ -s /etc/conf.d/redis ]] ; then
  source /etc/conf.d/redis
fi

# Default config variables that have not been set.
port="${port:-6379}"
prefix="${prefix:-/opt/rhoconnect}"
redis="${prefix}/bin/redis-server"
redis_cli="${prefix}/bin/redis-cli"
pidfile="${pidfile:-/var/run/redis.pid}"
config="${config:-/opt/rhoconnect/etc/redis.conf}"
user="${user:-root}"
#prefix="${prefix:-/usr/local}"
#config="${config:-/usr/local/etc/redis.conf}"
#pidfile="${pidfile:-/var/run/redis/redis.pid}"
#config="${config:-/etc/redis/redis.conf}"
#user="${user:-redis}"

# If the redis-cli file is not found, terminate the script.
test -x $redis_cli || exit 0

#
# Set the running $pid value based on $pidfile.
#
if [[ -s "$pidfile" ]] ; then
  pid=$(cat $pidfile)
else
  rm -f $pidfile
fi

# In case there was pidfile corruption...
if [[ "Linux" = "$(uname)" ]] ; then
  # /proc does not exist on say, Darwin
  if [[ ! -z "${pid}" ]] && [[ ! -x "/proc/${pid}" ]] ;then
    pid="$(ps auxww | grep [r]edis | grep "$config" | grep -v 'grep' | awk '{print $2}')"
  elif [[ -z "${pid}" ]] ; then
    pid="$(ps auxww | grep [r]edis | grep "$config" | grep -v 'grep' | awk '{print $2}')"
  fi
else
  if [[ -z "${pid}" ]] ; then
    pid="$(ps auxww | grep [r]edis | grep "$config" | grep -v 'grep' | awk '{print $2}')"
  fi
fi

#
# Start redis using redis-server as user 'redis'.
#
redis_start() {
  if [[ -f $pidfile ]] ; then
    echo "$pidfile exists, redis-server is either already running or crashed."
    exit 1
  elif [[ ! -z "$pid" ]] ; then
    echo -e "\nRedis is already running with configuration '$config'."
    echo "$pid" > $pidfile # Ensure pidfile exists with the pid.
  else
    echo "Starting Redis server..."
    su $user -c "$redis $config"
    exit 0
  fi
}

#
# Stop redis using redis-cli SHUTDOWN.
#
redis_stop() {
  echo -n "Stopping redis server on port ${port} ... "
  "$redis_cli" -p ${port} SHUTDOWN

  # Keep user informed while server shuts down.
  echo "Waiting for the redis server to shutdown "

  if [[ "Linux" = "$(uname)" ]] ; then
    if [[ "${pid}" = "" ]] ; then
      echo "redis server is not running."
      # Clear out the old pidfile if available
      rm -f $pidfile
      exit 1
    fi
    while [[ -x /proc/${pid} ]] ; do
      echo -n '.' ; sleep 1
    done
  else # Darwin, etc ...
    while [[ ! -z "$(ps auxww | grep [r]edis | grep "$config" | grep -v grep | awk '{print $2}')" ]] ; do
      echo -n '.' ; sleep 1
    done
  fi

  # Clear out the old pidfile.
  rm -f $pidfile

  # Notify user of successful completion.
  echo -e "redis server stopped."
  exit 0
}

redis_usage() {
  echo -e "Usage: $0 {start,stop,restart,status}"
  exit 1
}

redis_status() {
  "$redis_cli" -p ${port} INFO > /dev/null 2>&1
  info=$?
  if (( $info )) ; then
    echo "Redis server not running";
  else
    echo "Redis server running";
  fi
  exit $info
}

#
# CLI logic.
#
case "$1" in
  start)  redis_start  ;;
  stop)   redis_stop   ;;
  restart)
          $0 stop
          $0 start
          ;;
  status) redis_status ;;
  *)      redis_usage   ;;
esac
_REDIS_INIT_SCRIPT_

  redisInit="/etc/init.d/redis"
  File.open(redisInit, 'w') { |f| f << redis_init_script }

  # Make the init script executable
  `chmod +x #{redisInit}`
  # Set run levels
  if @dist == 'debian'
    `update-rc.d -f redis defaults` 
  else
    `/sbin/chkconfig redis on`
    # `/sbin/chkconfig --list redis`
  end

  redis_init_script
end #create_redis_init

def create_redis_logrotate
  redis_logrotate_conf = <<'_REDIS_LOGRORATE_CONF_'
/var/log/redis.log {
    rotate 3
    missingok
    notifempty
    size 250k
    create 0644 root root
    compress
}
_REDIS_LOGRORATE_CONF_

  File.open('/etc/logrotate.d/redis', 'w') { |f| f << redis_logrotate_conf }  
end

#
# Nginx stuff ...
def create_nginx_init
  nginx_init_script = <<'_NGINX_INIT_SCRIPT_'
#!/bin/sh
### BEGIN INIT INFO
# Provides:          nginx
# Required-Start:    $local_fs $remote_fs
# Required-Stop:     $local_fs $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      S 0 1 6
# Short-Description: nginx initscript
# Description:       nginx
### END INIT INFO
# Author: Ryan Norbauer http://norbauerinc.com
# Modified: Geoffrey Grosenbach http://topfunky.com
# Modified: Clement NEDELCU
# Modified: Alexander Babichev 
# Reproduced with express authorization from its contributors

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin 
DESC="nginx daemon"
NAME=nginx
DAEMON=/opt/nginx/sbin/$NAME
SCRIPTNAME=/etc/init.d/$NAME

# If the daemon file is not found, terminate the script.
test -x $DAEMON || exit 0

d_start() {
  $DAEMON || echo -n " already running"
}

d_stop() {
  $DAEMON -s quit || echo -n " not running"
}

d_reload() {
  $DAEMON -s reload || echo -n " could not reload"
}

case "$1" in
  start)
    echo -n "Starting $DESC: $NAME"
    d_start
    echo "."
    ;; 
  stop)
    echo -n "Stopping $DESC: $NAME"
    d_stop
    echo "."
    ;; 
  reload)
    echo -n "Reloading $DESC configuration ... "
    d_reload
    echo "reloaded."
    ;;
  restart)
    echo -n "Restarting $DESC: $NAME"
    d_stop
    # Sleep for two seconds before starting again, this should give the
    # Nginx daemon some time to perform a graceful stop.
    sleep 2
    d_start
    echo "."
    ;; 
  *)
    echo "Usage: $SCRIPTNAME {start|stop|restart|reload}" >&2
    exit 3 
    ;;
esac
 
exit 0  
_NGINX_INIT_SCRIPT_

  nginx_script = '/etc/init.d/nginx'
  File.open(nginx_script, 'w') { |f| f << nginx_init_script }
  # Make the init script executable
  `chmod +x #{nginx_script}`

  # Set run levels
  #  if @dist == 'debian'
  #    #`update-rc.d -f nginx defaults`
  #  else
  #    #`/sbin/chkconfig nginx on`
  #  end

end

def create_nginx_logrotate
  nginx_logrorate_conf = <<'_NGINX_LOGRORATE_CONF_'
/opt/nginx/logs/*log {
  missingok
  notifempty
  rotate 4
  size 100k
  delaycompress
  sharedscripts
  postrotate
    test ! -f /opt/nginx/logs/nginx.pid || kill -USR1 `cat /opt/nginx/logs/nginx.pid`
  endscript
}
_NGINX_LOGRORATE_CONF_

  File.open('/etc/logrotate.d/nginx', 'w') { |f| f << nginx_logrorate_conf }
end

def create_nginx_conf_files(app_name)
  nginx_server_conf = <<'_NGINX_CONF_'
user              nginx;
worker_processes  4;

error_log         logs/error.log;
pid               logs/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    log_format time_combined '$remote_addr - $remote_user [$time_local] "$request" '
                      	'$status $body_bytes_sent "$http_referer" '
                      	'"$http_user_agent" "$http_x_forwarded_for" "$request_time"';
    access_log logs/access.log time_combined;

    sendfile        on;
    keepalive_timeout  30;
    client_max_body_size 4m;
    client_body_buffer_size 128k;
    #gzip  on;

    include /opt/nginx/conf/conf.d/*.conf;
}
_NGINX_CONF_

  # Creating 'nginx' group if it isn't already there
  `getent group nginx > /dev/null`
  if $? != 0
    puts "Creating 'nginx' group ..."
    if @dist == 'debian'
      `addgroup --system nginx > /dev/null`
    else
      `/usr/sbin/groupadd -r nginx > /dev/null`
    end
  end
  # Creating 'nginx' user if it isn't already there
  `getent passwd nginx >/dev/null`
  if $? != 0
    puts "Creating 'nginx' user ..."
    if @dist == 'debian'
      `adduser --system --home /opt/nginx/html --no-create-home --disabled-login --disabled-password --group nginx`
    else
      `/usr/sbin/useradd -M -r -s /sbin/nologin -d /opt/nginx/html -g nginx nginx`
    end
  end
   
  FileUtils.mv("/opt/nginx/conf/nginx.conf", "/opt/nginx/conf/nginx.conf.bak") unless File.exist? "/opt/nginx/conf/nginx.conf.bak"
  File.open('/opt/nginx/conf/nginx.conf', 'w' ) { |f| f << nginx_server_conf }

  Dir.mkdir "/opt/nginx/conf/conf.d" unless File.exist? "/opt/nginx/conf/conf.d"
  rho_vhost_conf = <<_VHOST_CONF_
upstream thin_cluster {
  least_conn;
  server unix:/tmp/thin.0.sock;
  server unix:/tmp/thin.1.sock;
  # Add additional copies if need more Thin servers
  #server unix:/tmp/thin.2.sock;
  #server unix:/tmp/thin.3.sock;
}

server {
  listen  80; # listen for ipv4
  # listen  [::]:80 default ipv6only=on; # listen for ipv6

  root  /opt/nginx/html/#{app_name}/public; # <-- be sure to point to 'public' folder of your application!
  #  access_log off;                           # <-- disable access logging
  #  error_log /dev/null crit;                 # <-- disable error logging, but critical errors only
    
  location / {
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_redirect off;

    proxy_connect_timeout 30;
    proxy_send_timeout    30;
    proxy_read_timeout    30;

    proxy_pass http://thin_cluster;
  }

  error_page 500 502 503 504 /50x.html;
  location = /50x.html {
    root html;
  }

  # Uncomment the following location to get some status from nginx
  # location /nginx_status {
  #   stub_status on;
  #   access_log   off;
  #   allow 127.0.0.1;
  #   allow SOME.IP.ADD.RESS;
  #   deny all;
  # }
}     
_VHOST_CONF_

  File.open('/opt/nginx/conf/conf.d/rhoconnect.conf', 'w' ) { |f| f << rho_vhost_conf }
end
# End of nginx stuff ...

# generate_common_info
# Generates the readme info that is common across all distributions
def generate_common_info

  readme = <<_README_

Thank you for choosing Rhoconnect for your mobile app sync needs!
To finish this setup, please complete the following...

1) Add necessary bins to the path(s) of the users who will
   be using this software.  You may also wish to add these items
   to your #{@profile} to automatically add them upon login.
      export PATH=#{@prefix}/bin:$PATH

   If you had other versions of ruby installed previously to running
   this installation, you may instead wish to simply create an alias
   for the newly installed ruby:
      alias #{@ruby_version}=#{@prefix}/bin/ruby

_README_

  if @dist == "yum"
    rpm_lib = <<_RPM_LIB_
   Add #{@prefix}/lib to your library path like so:
      export LD_LIBRARY_PATH=#{@prefix}/lib:$LD_LIBRARY_PATH

   Note: You may also want to add this line to #{@profile}

_RPM_LIB_
  # concatenate _RPM_LIB_ onto _README_
  readme = readme + rpm_lib
  end #if

  readme_2 = <<_README2_
2) Rhoconnect installer configured redis server with the following settings:

   A) redis.conf file is located in #{@prefix}/etc/ directory with properties:
      daemonize yes
      pidfile /var/run/redis.pid
      logfile /var/log/redis.log

   B) Redis logrotate settings for /var/log/redis.log files defined in '/etc/logrotate.d/redis': 

      /var/log/redis.log {
          rotate 3
          missingok
          notifempty
          size 250k
          create 0644 root root
          compress
      }

  C) Redis start-up script '/etc/init.d/redis'. 
     You can start/stop redis server by running the following commands:
       /etc/init.d/redis {start|stop}

3) Setup rhoconnect application directory

   Put your application code in a directory called /var/www/rhoconnect
   (make sure this is the root of your application directory, i.e. /var/www/rhoconnect/config.ru should exist).

_README2_
  readme = readme + readme_2

  readme
end #generate_common_info

def nginx_readme
  readme = <<_NGINX_README_
4) Installer compiled Nginx web server (/opt/nginx) with the following configuration files:
   - Nginx start-up script (/etc/init.d/nginx)
   - Nginx logrotate settings (/etc/logrotate.d/nginx)
   - Nginx configuration file (/opt/nginx/conf/nginx.conf) 
   - virtual host template for rhoconnect application 
     (/opt/nginx/conf/conf.d/rhoconnect.conf)

     To change default setup of web server
     A) Configure virtual host for rhoconnect application:
        Edit the file /opt/nginx/conf/conf.d/rhoconnect.conf so that it reflects your specifications.
     B) As root user start server to pick up the changes:
        /etc/init.d/nginx start
    
5) Installer also configured Thin app server with the following configuration files:
   - Thin start-up script (/etc/init.d/thin)
   - Thin configuration file (/etc/thin/rhoapp.yml)
   
   By default, init script start cluster of 2 servers running on UNIX domain sockets.
   Nginx connected to cluster via upstream block in nginx config file.

To deploy and develop your rhoconnect app on nginx and thin servers:
   a) Copy your rhoconnect project to default location to `/opt/nginx/html` directory

   b) Set up for it `nginx` owner
         $ cd /opt/nginx/html
         $ sudo chown -R nginx:nginx your_rhoconnect_app/

   c) Make sure that your app is bundled properly
         $ cd your_rhoconnect_app
         $ sudo /opt/rhconnect/bin/bundle install

   d) Configure Nginx virtual host for your rhoconnect application. For that edit the file 
     `/opt/nginx/conf/conf.d/rhoconnect.conf`, so that it reflects your specifications (root directive)
         # ...
         server {
           listen      80;
           root  /opt/nginx/html/your_rhoconnect_app/public; # Be sure your app have 'public' folder and root directive 
                                                             # point to it!
           # ...
         }

   e) Edit thin `/etc/thin/rhoapp.yml` configuration file directly 
         ---
         chdir: /opt/nginx/html/your_rhoconnect_app
         # ...

      or as root user generate a new one
         $ env PATH=/opt/rhoconnect/bin:$PATH thin config -C /etc/thin/your_rhoconnect_app.yml
         -c /opt/nginx/html/your_rhoconnect_app/ 
         --socket /tmp/thin.sock --servers 2 
         --user nginx --group nginx 
         --log /var/log/thin/thin.log --pid /var/run/thin/thin.pid -e production`

   f) As root user restart Nginx, and Thin servers
          /etc/init.d/nginx restart
          /etc/init.d/thin restart

   For monitoring and troubleshooting purposes visit web console of your app and look at log files in `/opt/nginx/logs`.
_NGINX_README_
  readme
end

def generate_rhoapp(rho_path)
  puts "Generating rhoconnect application: /opt/nginx/html/rhoapp ..."

  Dir.chdir "/opt/nginx/html"
  `rm -rf rhoapp` if File.directory? "/opt/nginx/html/rhoapp"

  `#{rho_path}/bin/rhoconnect app rhoapp`
  Dir.chdir "rhoapp"
  log = `#{rho_path}/bin/bundle install --without=test development 2>&1`
  raise "Generatiion of rhoconnect application failured:\n#{log}" if $? != 0
  Dir.chdir "../"
  `chown -R nginx:nginx rhoapp/`
end

def config_and_install_thin_scripts(rho_path)
  puts "Configuring and installing thin scripts ..."
  thin_script = <<'_THIN_INIT_'
#!/bin/sh
### BEGIN INIT INFO
# Provides:          thin
# Required-Start:    $local_fs $remote_fs
# Required-Stop:     $local_fs $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      S 0 1 6
# Short-Description: thin initscript
# Description:       thin
### END INIT INFO

# Original author: Forrest Robertson

# Do NOT "set -e"

export PATH=/opt/rhoconnect/bin:$PATH
DAEMON=/opt/rhoconnect/bin/thin
SCRIPT_NAME=/etc/init.d/thin
CONFIG_PATH=/etc/thin

# Exit if the package is not installed
#[ -x "$DAEMON" ] || exit 0

case "$1" in
  start)
        $DAEMON start --all $CONFIG_PATH
        ;;
  stop)
        $DAEMON stop --all $CONFIG_PATH
        ;;
  restart)
        $DAEMON restart --all $CONFIG_PATH
        ;;
  *)
        echo "Usage: $SCRIPT_NAME {start|stop|restart}" >&2
        exit 3
        ;;
esac

:
_THIN_INIT_

  thin_init_script="/etc/init.d/thin"
  File.open(thin_init_script, 'w') { |f| f << thin_script }
  `chmod +x #{thin_init_script}`
  Dir.mkdir "/etc/thin" unless File.exist? "/etc/thin"
  Dir.mkdir "/var/run/thin" unless File.exist? "/var/run/thin"
  `chown nginx:nginx /var/run/thin`

  `env PATH=#{rho_path}/bin:$PATH \
  thin config -C /etc/thin/rhoapp.yml -c /opt/nginx/html/rhoapp/ \
  --socket /tmp/thin.sock --servers 2 \
  --user nginx --group nginx \
  --log /var/log/thin/thin.log --pid /var/run/thin/thin.pid -e production`

  raise "Thin failed to configure rhoconnect application" if $? != 0
end

def config_thin_logrotate
  Dir.mkdir "/var/log/thin" unless File.exist? "/var/log/thin"
  `chown nginx:nginx /var/log/thin`

  thin_logrorate_conf = <<'_THIN_LOGRORATE_CONF_'
/var/log/thin/*.log {
  daily
  missingok
  rotate 4
  compress
  delaycompress
  notifempty
#  create 640 root adm
  sharedscripts
  postrotate
    /etc/init.d/thin restart >/dev/null
  endscript
}
_THIN_LOGRORATE_CONF_
  File.open('/etc/logrotate.d/thin', 'w') { |f| f << thin_logrorate_conf }
end

def create_texts
  if @redis
    create_redis_init 
    create_redis_logrotate
  end

  if @server == 'nginx'
    create_nginx_init
    create_nginx_logrotate

    create_nginx_conf_files "rhoapp"
    generate_rhoapp @prefix

    config_and_install_thin_scripts(@prefix)
    config_thin_logrotate

    distro_info = nginx_readme
  end

  common_info = generate_common_info
  readme = common_info + distro_info  
  File.open("#{@prefix}/README", 'w') { |f| f << readme }

  afterwords = <<_IT_SHOULD_BE_DONE_

Thank you for choosing Rhomobile for your cross-platform app needs!
To finish this setup, please complete the following...
 
1) Add necessary bins to the path(s) of the users who will
   be using this software. You may also wish to add these items
   to your #{@profile} to automatically add them upon login.
     export PATH=#{@prefix}/bin:$PATH

_IT_SHOULD_BE_DONE_

  about_app =
    if @use_bench_app
      server_todo_list = <<_NGINX_TO_DO_
2) Rhoconnect 'benchapp' application is created in /opt/nginx/html directory. To run it
  A) As root user start redis and nginx servers:
     /etc/init.d/redis start
     /etc/init.d/nginx start
  B) To verify that application up and running open web console in your browser:
     http://server_ip_address

_NGINX_TO_DO_
    else
      server_todo_list = <<_NGINX_TO_DO_
2) Try rhoconnect 'rhoapp' application, created in /opt/nginx/html directory
  A) As root user start redis, thin and nginx servers:
     /etc/init.d/redis start
     /etc/init.d/thin start
     /etc/init.d/nginx start
  B) Open RhoConnect application web console in your browser:
     http://servername

_NGINX_TO_DO_
    end

  afterwords << about_app
  afterwords << "For more details see #{@prefix}/README file."
  puts afterwords
  File.open("#{@log_file}", 'a') { |f| f << afterwords } if @log_file

end

begin
  create_texts
rescue => ex
  File.open("#{@log_file}", 'a') { |f| f << ex.message } if @log_file
  puts
  puts "#{ex.message}"
  exit(1)
end

