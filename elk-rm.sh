#!/bin/bash
docker-compose -f /root/docker-elk/docker-compose-nossl.yml down
docker-compose -f /root/docker-elk/docker-compose-ssl.yml down
docker volume rm docker-elk_elasticsearch1
docker volume rm docker-elk_elasticsearch2
docker volume rm docker-elk_elasticsearch3
docker volume ls
rm -rf /root/docker-elk/elastic-certificates.p12
