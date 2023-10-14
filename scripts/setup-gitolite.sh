#!/bin/bash

if [ ! -f $GIT_HOME_DIR/.ssh/$GIT_ADMIN.pub ]; then
    echo "--------------------------------------------------"
    echo ""
    echo "Creating custom ssh keys."
    echo ""
    echo "--------------------------------------------------"
    ssh-keygen -N ""  -f $GIT_HOME_DIR/.ssh/$GIT_ADMIN
fi 


echo "--------------------------------------------------"
echo ""
echo "Running gitolite setup"
echo ""
echo "--------------------------------------------------"
gitolite setup -pk $GIT_HOME_DIR/.ssh/$GIT_ADMIN.pub
