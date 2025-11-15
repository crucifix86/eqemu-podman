#!/bin/bash

cd /home/doug/eqemu-podman
podman-compose build

if [ $? -eq 0 ]; then
    echo "Build successful! Run './start.sh' to start the server."
fi
