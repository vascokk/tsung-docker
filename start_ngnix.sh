#!/usr/bin/env bash

MARATHON_HOST=http://192.168.128.123:8080

TSUNG_MASTER_HOST=$(dcos marathon task list | grep /tsung-master | awk '{print $4}') \
&& curl -X POST -H "Content-Type:application/json" ${MARATHON_HOST}/v2/apps?force=true --data '
{
  "id": "tsung-nginx",
  "cmd": "sed -i s/\"htm;\"/\"htm; autoindex on;\"/g /etc/nginx/conf.d/default.conf && nginx -g \"daemon off;\"",
  "container": {
    "type": "DOCKER",
    "volumes": [
      {
        "containerPath": "/usr/share/nginx/html",
        "hostPath": "/var/lib/log/tsung",
        "mode": "RO"
      }
    ],
    "docker": {
      "image": "nginx",
      "network": "BRIDGE",
      "portMappings": [
        { "containerPort": 80, "hostPort": 0, "protocol": "tcp" }
      ]
    }
  },
  "cpus": 0.5,
  "mem": 512.0,
  "constraints": [["hostname", "CLUSTER",  "'${TSUNG_MASTER_HOST}'"]],
  "ports": [
    0
  ],
  "instances": 1
}'