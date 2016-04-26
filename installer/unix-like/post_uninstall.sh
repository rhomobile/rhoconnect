#!/bin/bash

#echo "after_remove script is running ..."

if [ -d "/opt/rhoconnect" ]; then
  rm -rf /opt/rhoconnect
fi

if [ -d "/opt/nginx" ]; then
  rm -rf /opt/nginx
fi
