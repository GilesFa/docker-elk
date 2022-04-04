#!/bin/bash
docker volume rm docker-elk_elasticsearch1
docker volume rm docker-elk_elasticsearch2
docker volume rm docker-elk_elasticsearch3
docker volume ls
rm -rf /root/docker-elk/elastic-stack-ca.p12
