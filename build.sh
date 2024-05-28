#!/bin/bash

arch=$(dpkg --print-architecture)

IMAGE_TAG="latest"
IMAGE_NAME="simple-git-server"
REGISTRY_URL="fenrir.stobi.local:5000"

if [[ $arch == "arm64" ]]; then
  IMAGE_TAG="latest-arm64"
fi

docker build -t $REGISTRY_URL/$IMAGE_NAME:$IMAGE_TAG .
docker push $REGISTRY_URL/$IMAGE_NAME:$IMAGE_TAG

