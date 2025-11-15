#!/bin/bash

echo "=========================================="
echo "EQEmu Server Container Starting..."
echo "=========================================="

# Run the installer
cd /root/eqemu-universal-installer
./install.sh

# Detect and configure server IP
echo ""
echo "Configuring server IP address..."
SERVER_IP=$(ip route get 1 | awk '{print $7}' | head -1)

if [ -z "$SERVER_IP" ] || [ "$SERVER_IP" = "127.0.0.1" ]; then
    # Fallback to eth0 IP
    SERVER_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f1 | head -1)
fi

if [ -z "$SERVER_IP" ] || [ "$SERVER_IP" = "127.0.0.1" ]; then
    # Final fallback - use 127.0.0.1
    SERVER_IP="127.0.0.1"
    echo "  Using localhost (127.0.0.1) - client must run on same machine"
else
    echo "  Detected IP: $SERVER_IP"
    echo "  Use this IP in your EQ client from other machines"
fi

# Update eqemu_config.json with detected IP
if [ -f /home/eqemu/server/eqemu_config.json ]; then
    echo "  Updating eqemu_config.json with server IP..."
    sed -i "s/\"address\": \"[^\"]*\",/\"address\": \"$SERVER_IP\",/g" /home/eqemu/server/eqemu_config.json
    echo "  ✓ Server configured with IP: $SERVER_IP"
fi

echo ""
echo "=========================================="
echo "Server IP Configuration:"
echo "=========================================="
echo "Server Address: $SERVER_IP"
echo ""
echo "Connection Info:"
if [ "$SERVER_IP" != "127.0.0.1" ]; then
    echo "  - From this machine: use 127.0.0.1 or localhost"
    echo "  - From other machines/Windows: use $SERVER_IP"
else
    echo "  - Use 127.0.0.1 or localhost"
fi
echo "=========================================="
echo ""

# Start the server
if [ -f /home/eqemu/server/start.sh ]; then
    cd /home/eqemu/server
    ./start.sh
fi

# Keep container running
tail -f /home/eqemu/server/logs/*.log 2>/dev/null || tail -f /dev/null
