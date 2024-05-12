#!/bin/bash

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

if [ ! -f $GIT_HOME_DIR/.ssh/$GIT_ADMIN.pub ]; then
    echo "--------------------------------------------------"
    echo ""
    echo "Creating custom ssh keys."
    echo ""
    ssh-keygen -N ""  -f $GIT_HOME_DIR/.ssh/$GIT_ADMIN
fi 

if [ ! -d $GIT_HOME_DIR/.gitolite ]; then
    echo "--------------------------------------------------"
    echo ""
    echo "Running gitolite setup"
    echo ""
    gitolite setup -pk $GIT_HOME_DIR/.ssh/$GIT_ADMIN.pub
fi

crontab -l > $GIT_TMP_DIR/mycron
echo "0 2 * * * /usr/local/bin/gitolite-mirror" >> $GIT_TMP_DIR/mycron 
crontab $GIT_TMP_DIR/mycron
rm $GIT_TMP_DIR/mycron

echo registerd crontab for git 
crontab -l 


