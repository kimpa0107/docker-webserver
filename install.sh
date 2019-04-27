#!/bin/bash

docker build -t kimpa/webserver:1.1 .

docker-compose up -d
