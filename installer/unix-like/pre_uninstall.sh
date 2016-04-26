#!/bin/bash

#echo "before_remove script is running ..."
echo "Stopping rhoconnect services and remove init scripts ..."

# Stop redis
if [ -e "/etc/init.d/redis" ]; then
  /etc/init.d/redis stop
  if [[ `which dpkg 2> /dev/null` != "" ]]; then  # Debian
    update-rc.d -f redis remove
  elif [[ `which rpm 2> /dev/null` != "" ]]; then # Red Hat
    /sbin/chkconfig redis off
  fi
fi

#stop thin
[ "$(ps aux | grep '[t]hin')" ] && [ -e "/etc/init.d/thin" ] && /etc/init.d/thin stop

#stop nginx
[ "$(ps aux | grep '[n]ginx')" ] && [ -e "/etc/init.d/nginx" ] && /etc/init.d/nginx stop

rm -f /etc/init.d/redis
rm -f /etc/logrotate.d/redis

rm -f /etc/init.d/nginx
rm -f /etc/logrotate.d/nginx

rm -f /etc/thin/rhoapp.yml
rm -f /etc/rc.d/thin
rm -f /etc/init.d/thin
