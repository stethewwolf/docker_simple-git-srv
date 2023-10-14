#!/bin/bash
#
# Suexec wrapper for gitolite-shell
#

export GIT_PROJECT_ROOT="/home/git/repositories"
export GITOLITE_HTTP_HOME="/home/git"

exec /usr/share/gitolite3/gitolite-shell
