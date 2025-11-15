#!/bin/bash

set -e  # Exit on any error

echo "=========================================="
echo "EQEmu Server - Automated Installation"
echo "=========================================="
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Step 1: Clean up any existing installation
echo "[Step 1/6] Cleaning up previous installation..."
if command_exists podman-compose; then
    podman-compose down -v 2>/dev/null || true
    podman volume prune -f 2>/dev/null || true
fi

# Stop and free port 3306
echo ""
echo "[Step 2/6] Freeing port 3306..."
echo "Checking for processes using port 3306..."
if sudo ss -tlpn | grep -q ':3306'; then
    echo "  Port 3306 is in use. Stopping MariaDB/MySQL services..."
    sudo systemctl stop mariadb mysql 2>/dev/null || true
    sleep 2

    # Force kill if still running
    if sudo ss -tlpn | grep -q ':3306'; then
        echo "  Force stopping MariaDB processes..."
        sudo killall -9 mariadbd mysqld 2>/dev/null || true
        sleep 1
    fi

    if sudo ss -tlpn | grep -q ':3306'; then
        echo "  ERROR: Unable to free port 3306. Please manually stop the process."
        exit 1
    fi
    echo "  Port 3306 is now free"
else
    echo "  Port 3306 is already free"
fi

# Step 3: Check for Podman
echo ""
echo "[Step 3/6] Checking for Podman..."
if ! command_exists podman; then
    echo "  ERROR: Podman is not installed."
    echo "  Please install podman and podman-compose first:"
    echo "    sudo apt update"
    echo "    sudo apt install -y podman podman-compose"
    exit 1
fi

if ! command_exists podman-compose; then
    echo "  ERROR: podman-compose is not installed."
    echo "  Please install it first:"
    echo "    sudo apt install -y podman-compose"
    exit 1
fi

echo "  Podman and podman-compose are installed ✓"

# Step 4: Build the container
echo ""
echo "[Step 4/6] Building Podman container..."
echo "  This may take a few minutes..."
./build.sh

if [ $? -ne 0 ]; then
    echo "  ERROR: Container build failed"
    exit 1
fi

# Step 5: Start the container
echo ""
echo "[Step 5/6] Starting container..."
./start.sh

# Wait for systemd to be ready
echo "  Waiting for systemd to initialize..."
sleep 5

# Verify container is running
if ! podman ps | grep -q eqemu-server; then
    echo "  ERROR: Container failed to start"
    exit 1
fi

echo "  Container started successfully ✓"

# Step 6: Run the installer
echo ""
echo "[Step 6/6] Running EQEmu installer..."
echo "  This will take several minutes. Please wait..."
echo ""

podman exec -it eqemu-server /root/start-eqemu.sh

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Your EQEmu server should now be running."
echo ""
echo "Useful commands:"
echo "  ./logs.sh          - View server logs"
echo "  podman-compose down   - Stop the server"
echo "  ./start.sh         - Start the server again"
echo ""
echo "Server ports:"
echo "  5998  - Titanium clients"
echo "  5999  - Secrets of Faydwer clients"
echo "  9000  - World server"
echo "  7100-7400 - Zone servers"
echo ""
