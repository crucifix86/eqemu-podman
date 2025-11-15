#!/bin/bash

echo "=========================================="
echo "EQEmu Server Container Starting..."
echo "=========================================="

# Run the installer
cd /root/eqemu-universal-installer
./install.sh

# Start the server
if [ -f /home/eqemu/server/start.sh ]; then
    cd /home/eqemu/server
    ./start.sh
fi

# Keep container running
tail -f /home/eqemu/server/logs/*.log 2>/dev/null || tail -f /dev/null
