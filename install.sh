#!/bin/bash

docker build -t kimpa0107/webserver:1.0 .

docker-compose up -d
