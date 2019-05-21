#!/bin/bash

docker build -t kimpa0107/webserver:1.1 .

docker-compose up -d
