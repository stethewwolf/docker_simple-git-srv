#!/bin/sh

docker-compose build
docker tag simple-git-server:latest fenrir.stobi.local:5000/simple-git-server:latest
docker push  fenrir.stobi.local:5000/simple-git-server:latest
