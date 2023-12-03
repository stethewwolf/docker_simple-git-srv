#!/bin/bash

# This script create and configure the server admin repo

## configure git
git config --global user.email "$GIT_ADMIN@simple-git-server"
git config --global user.name "$GIT_ADMIN"

## update the gitolite.rc file: enable hooks
sed '/repo-specific-hooks/s/^[[:space:]]*#//g' -i $GIT_HOME_DIR/.gitolite.rc
sed '/GL_ADMIN_BASE/s/^[[:space:]]*#//g' -i $GIT_HOME_DIR/.gitolite.rc

## update gitolite-admin 
### clone current gitolite-admin repo
cd $GIT_TMP_DIR
git clone $GIT_HOME_DIR/repositories/gitolite-admin.git
cd $GIT_TMP_DIR/gitolite-admin/

### create the hooks folder
mkdir -p $GIT_TMP_DIR/gitolite-admin/local/hooks/repo-specific

### add the update-simple-git-server script
cp /usr/local/bin/update-simple-git-server $GIT_TMP_DIR/gitolite-admin/local/hooks/repo-specific/update-simple-git-server
chmod +x $GIT_TMP_DIR/gitolite-admin/local/hooks/repo-specific/update-simple-git-server

### add the server-admin repo
cat >> $GIT_TMP_DIR/gitolite-admin/conf/gitolite.conf <<EOF

# repository added when the server was creted
# this repository is used to administrate the server
# share carefully
repo server-admin
    RW+     =   $GIT_ADMIN
    option hook.post-update     =   update-simple-git-server
EOF

### commit the changes
git add $GIT_TMP_DIR/gitolite-admin/local/hooks/repo-specific/update-simple-git-server
git stage  $GIT_TMP_DIR/gitolite-admin/conf/gitolite.conf
git commit -am "Created server-admin"
/usr/bin/gitolite push

### clean CWD
cd $GIT_TMP_DIR
rm -rf $GIT_TMP_DIR/gitolite-admin/

## create default content on server-admin repo
### clone repo
git clone $GIT_HOME_DIR/repositories/server-admin.git
cd $GIT_TMP_DIR/server-admin

### create conf folder
mkdir $GIT_TMP_DIR/server-admin/conf
### copy current conf files into repo
cp $GIT_HOME_DIR/gitweb.conf  $GIT_TMP_DIR/server-admin/conf/gitweb.conf
cp $GIT_HOME_DIR/.gitolite.rc $GIT_TMP_DIR/server-admin/conf/gitolite.rc
cp $GIT_HOME_DIR/.gitconfig  $GIT_TMP_DIR/server-admin/conf/gitconfig

### create update-server.sh script, if missing this file update-simple-git-server will do nothing
cat > $GIT_TMP_DIR/server-admin/update-server.sh <<EOF
#!/bin/bash

# script used to update server configuration
# edit with caution
set -x
cp -v conf/gitconfig $HOME/.gitconfig
cp -v conf/gitolite.rc $HOME/.gitolite.rc
cp -v conf/gitweb.conf $HOME/gitweb.conf
cp -v conf/mirrors.yaml $HOME/mirrors.yaml

#git-mirror $HOME/mirrors.yaml
EOF
chmod +x $GIT_TMP_DIR/server-admin/update-server.sh

### create mirror cmd default config file
cat > $GIT_TMP_DIR/server-admin/conf/mirrors.yaml <<EOF
repos:
#  - remote-url: "https://github.com/bit-team/backintime.git"
#    remote-name: "github"
#    local-repo: /var/lib/git/repositories/backintime.git
#  - remote-url: "https://github.com/flathub/flathub.git"
#    remote-name: "github"
#    local-repo: /var/lib/git/repositories/flathub.git
EOF

### commit the changes
git add $GIT_TMP_DIR/server-admin/conf
git add $GIT_TMP_DIR/server-admin/
git commit -m "committed default conf"
/usr/bin/gitolite push

### clean CWD
cd $GIT_TMP_DIR
rm -rf $GIT_TMP_DIR/server-admin/
