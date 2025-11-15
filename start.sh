#!/bin/bash

cd /home/doug/eqemu-podman
podman-compose up -d

echo "Server starting. Run './logs.sh' to view logs."
