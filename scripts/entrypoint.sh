#!/bin/bash

# load environment vars
source /etc/environment

# print environment
/usr/local/bin/print-gitolite-env.sh

# setup gitolite
# this script is executed only if the file $GIT_HOME_DIR/.gitolite.rc does not exists
if [ ! -f $GIT_HOME_DIR/.gitolite.rc ]; then
    su -c '/usr/local/bin/setup-gitolite.sh' $GIT_USER
fi

# make sure permission are correct
chown -R $GIT_USER: $GIT_HOME_DIR

# start sshd
/etc/init.d/ssh start

# start apache2 
/etc/init.d/apache2 start

echo "##################################################"
echo ""
echo "Environment setup completed successfully."
echo "Running: $*"
echo ""
echo "##################################################"

# run CMD
"$@"
