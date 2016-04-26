#!/bin/sh
echo "Starting rhoconnect installer ..."

cd /opt/rhoconnect/installer
./install.sh
STATUS=$?
cd ../
rm -rf installer/

exit $STATUS
