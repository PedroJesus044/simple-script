#!/bin/bash

docker compose up -d

firewall-cmd --add-port=8080/tcp --permanent
firewall-cmd --reload
