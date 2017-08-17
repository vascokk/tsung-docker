#!/usr/bin/env bash

docker tag tsung-docker:latest 192.168.128.109/tsung-docker:latest
docker push 192.168.128.109/tsung-docker:latest