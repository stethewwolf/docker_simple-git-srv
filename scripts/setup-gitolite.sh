#!/bin/bash

# author: Stefano Prina stethewwolf@posteo.net
#
# This script will setup and customize gitolite installation
#

## create needed folders
echo "--------------------------------------------------"
echo ""
echo "Creating git folders if not present."
if [ ! -d $GIT_LOG_DIR ]; then
    mkdir -v $GIT_LOG_DIR
fi 

if [ ! -d $GIT_TMP_DIR ]; then
    mkdir -v $GIT_TMP_DIR
fi 

if [ ! -d $GIT_BIN_DIR ]; then
    mkdir -v $GIT_BIN_DIR
fi 

if [ ! -d $GIT_HOME_DIR/.ssh/ ]; then
	mkdir -v $GIT_HOME_DIR/.ssh
fi 
echo ""

## create or configure ssh keys
if [ ! -f $GIT_HOME_DIR/.ssh/$GIT_ADMIN.pub ]; then
    echo "--------------------------------------------------"
    echo ""
    echo "Creating custom ssh keys."
    echo ""
    ssh-keygen -N ""  -f $GIT_HOME_DIR/.ssh/$GIT_ADMIN
fi 

## run gitolite setup
if [ ! -d $GIT_HOME_DIR/.gitolite ]; then
    echo "--------------------------------------------------"
    echo ""
    echo "Running gitolite setup"
    echo ""
    gitolite setup -pk $GIT_HOME_DIR/.ssh/$GIT_ADMIN.pub
fi

## configure git
git config --global user.email "$GIT_ADMIN@simple-git-server"
git config --global user.name "$GIT_ADMIN"



## customize gitolite-admin 
### clone current gitolite-admin repo
cd $GIT_TMP_DIR
git clone $GIT_HOME_DIR/repositories/gitolite-admin.git $GIT_TMP_DIR/gitolite-admin/
cd $GIT_TMP_DIR/gitolite-admin/

## create server configuration default content
if [ ! -d $GIT_TMP_DIR/gitolite-admin/server/ ]; then
    ### create the server conf folder
    mkdir -p $GIT_TMP_DIR/gitolite-admin/server/

    ### copy current conf files into repo
    cp $GIT_HOME_DIR/gitweb.conf  $GIT_TMP_DIR/gitolite-admin/server/gitweb.conf
    cp $GIT_HOME_DIR/.gitolite.rc $GIT_TMP_DIR/gitolite-admin/server/gitolite.rc
    cp $GIT_HOME_DIR/.gitconfig   $GIT_TMP_DIR/gitolite-admin/server/gitconfig

    #### commit the changes
    git add $GIT_TMP_DIR/gitolite-admin/server/
    git commit -m "committed default server conf"
    /usr/bin/gitolite push

    ###  create repos folder
    mkdir -p $GIT_TMP_DIR/gitolite-admin/conf/repos/
    touch $GIT_TMP_DIR/gitolite-admin/conf/repos/.gitkeep
    echo "include \"repos/*.conf\"" >> $GIT_TMP_DIR/gitolite-admin/conf/gitolite.conf

    #### commit the changes
    git add $GIT_TMP_DIR/gitolite-admin/conf/repos/.gitkeep
    git add $GIT_TMP_DIR/gitolite-admin/conf/gitolite.conf
    git commit -m "create repos folder"
    /usr/bin/gitolite push

    ###  create repos specific hooks folder
    mkdir -p $GIT_TMP_DIR/gitolite-admin/local/hooks/repo-specific/
    touch $GIT_TMP_DIR/gitolite-admin/local/hooks/repo-specific/.gitkeep

    #### commit the changes
    git add $GIT_TMP_DIR/gitolite-admin/local/hooks/repo-specific/.gitkeep
    git commit -m "create repo specific hook folder"
    /usr/bin/gitolite push
fi

### clean CWD
cd $GIT_TMP_DIR
rm -rf $GIT_TMP_DIR/gitolite-admin/

## configure post-receive hook for gitolite repo
cp /usr/local/bin/post-receive $GIT_HOME_DIR/repositories/gitolite-admin.git/hooks/post-receive 

## update the gitolite.rc file: enable hooks
sed '/repo-specific-hooks/s/^[[:space:]]*#//g' -i $GIT_HOME_DIR/.gitolite.rc
sed '/GL_ADMIN_BASE/s/^[[:space:]]*#//g' -i $GIT_HOME_DIR/.gitolite.rc

exit 0
