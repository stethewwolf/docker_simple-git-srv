#!/bin/bash

# load environment vars
source /etc/environment

# print environment
/usr/local/bin/print-gitolite-env.sh

# mv gitolite config file, if not yet done
if [ ! -L "/etc/gitweb.conf" ]; then
mv  -v /etc/gitweb.conf $GIT_HOME_DIR/gitweb.conf
ln -sv $GIT_HOME_DIR/gitweb.conf /etc/gitweb.conf
fi

# make sure permission are correct
chown -vR $GIT_USER: $GIT_HOME_DIR

# setup gitolite
# this script is executed only if the file $GIT_HOME_DIR/.gitolite.rc does not exists
su -c '/usr/local/bin/setup-gitolite.sh' $GIT_USER

# setup gitserver management repo
# this script create the repo server-admin and adds relevant config files
if [ ! -d "$GIT_HOME_DIR/repositories/server-admin.git" ]; then
    su -c '/usr/local/bin/create-server-admin-repo.sh' $GIT_USER
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
