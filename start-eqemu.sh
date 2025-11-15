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

# Try multiple methods to get the right IP
# Method 1: Check all network interfaces for non-loopback IPs
SERVER_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '^127\.' | head -1)

# Method 2: If that fails, try route-based detection
if [ -z "$SERVER_IP" ]; then
    SERVER_IP=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' | head -1)
fi

# Method 3: Fallback to eth0
if [ -z "$SERVER_IP" ] || [ "$SERVER_IP" = "127.0.0.1" ]; then
    SERVER_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f1 | head -1)
fi

# Final fallback
if [ -z "$SERVER_IP" ] || [ "$SERVER_IP" = "127.0.0.1" ]; then
    SERVER_IP="127.0.0.1"
    echo "  Using localhost (127.0.0.1) - client must run on same machine"
else
    echo "  Detected IP: $SERVER_IP"
    echo "  This IP will be used for world and zone servers"
fi

# Update eqemu_config.json with detected IP
if [ -f /home/eqemu/server/eqemu_config.json ]; then
    echo "  Updating eqemu_config.json with server IP..."

    # Update world server address
    sed -i "s/\"address\": \"[^\"]*\"/\"address\": \"$SERVER_IP\"/g" /home/eqemu/server/eqemu_config.json

    # Update zone server address (localaddress and worldaddress)
    sed -i "s/\"localaddress\": \"[^\"]*\"/\"localaddress\": \"$SERVER_IP\"/g" /home/eqemu/server/eqemu_config.json
    sed -i "s/\"worldaddress\": \"[^\"]*\"/\"worldaddress\": \"$SERVER_IP\"/g" /home/eqemu/server/eqemu_config.json

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
