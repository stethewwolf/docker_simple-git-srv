#!/bin/bash

# load environment vars
source /etc/environment

# print environment
/usr/local/bin/print-gitolite-env.sh

# make sure permission are correct
chown -R $GIT_USER: $GIT_HOME_DIR

# setup gitolite
# this script is executed only if the file $GIT_HOME_DIR/.gitolite.rc does not exists
if [ ! -f $GIT_HOME_DIR/.gitolite.rc ]; then
    su -c '/usr/local/bin/setup-gitolite.sh' $GIT_USER
fi

# start sshd
/etc/init.d/ssh start

# spawn fcgi 
spawn-fcgi -s /var/run/fcgiwrap.socket -M 766 /usr/sbin/fcgiwrap

# start nginx 
/etc/init.d/nginx start

echo "##################################################"
echo ""
echo "Environment setup completed successfully."
echo "Running: $*"
echo ""
echo "##################################################"

# run CMD
"$@"
