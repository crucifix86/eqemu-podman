#!/bin/bash

set -e

echo "=========================================="
echo "Podman Installation Script"
echo "=========================================="
echo ""

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
    echo "Detected OS: $PRETTY_NAME"
else
    echo "ERROR: Cannot detect OS. /etc/os-release not found."
    exit 1
fi

# Check if podman is already installed
if command -v podman >/dev/null 2>&1; then
    PODMAN_VERSION=$(podman --version)
    echo "Podman is already installed: $PODMAN_VERSION"

    # Check for podman-compose
    if command -v podman-compose >/dev/null 2>&1; then
        echo "podman-compose is already installed"
        echo "All dependencies satisfied!"
        exit 0
    else
        echo "podman-compose not found, installing..."
    fi
fi

echo ""
echo "Installing Podman and podman-compose..."
echo ""

case "$OS" in
    debian)
        echo "Debian detected (version $VER)"

        if [ "$VER" = "13" ]; then
            echo "Installing from Debian 13 repositories..."
            sudo apt update
            sudo apt install -y podman podman-compose

        else
            echo "WARNING: Debian $VER detected. Only Debian 13 has been tested."
            echo "Attempting to install from standard repositories..."
            sudo apt update
            sudo apt install -y podman podman-compose
        fi
        ;;

    ubuntu)
        echo "Ubuntu detected (version $VER)"

        case "$VER" in
            24.04)
                echo "Installing from Ubuntu 24.04 repositories..."
                sudo apt update
                sudo apt install -y podman podman-compose
                ;;

            22.04)
                echo "Ubuntu 22.04 detected - installing from Kubic repository..."

                # Remove any existing podman packages
                sudo apt remove -y podman podman-compose 2>/dev/null || true

                # Add Kubic repository for newer podman
                echo "Adding Kubic OBS repository..."
                echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/unstable/xUbuntu_22.04/ /" | \
                    sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:unstable.list

                # Add GPG key
                curl -fsSL https://download.opensuse.org/repositories/devel:kubic:libcontainers:unstable/xUbuntu_22.04/Release.key | \
                    gpg --dearmor | \
                    sudo tee /etc/apt/trusted.gpg.d/kubic-libcontainers-unstable.gpg > /dev/null

                # Install podman
                sudo apt update
                sudo apt install -y podman

                # Install podman-compose via pip (more reliable on 22.04)
                echo "Installing podman-compose via pip..."
                sudo apt install -y python3-pip
                sudo pip3 install podman-compose
                ;;

            *)
                echo "WARNING: Ubuntu $VER detected. Only 24.04 and 22.04 have been tested."
                echo "Attempting default installation..."
                sudo apt update
                sudo apt install -y podman podman-compose || {
                    echo "Standard installation failed. Trying pip for podman-compose..."
                    sudo apt install -y python3-pip
                    sudo pip3 install podman-compose
                }
                ;;
        esac
        ;;

    *)
        echo "ERROR: Unsupported OS: $OS"
        echo "This script supports Debian 13, Ubuntu 24.04, and Ubuntu 22.04"
        echo ""
        echo "You may try installing manually:"
        echo "  Debian/Ubuntu: sudo apt install podman podman-compose"
        echo "  OR via pip: sudo pip3 install podman-compose"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "Verifying installation..."
echo "=========================================="

# Verify podman
if command -v podman >/dev/null 2>&1; then
    PODMAN_VERSION=$(podman --version)
    echo "✓ Podman installed: $PODMAN_VERSION"
else
    echo "✗ ERROR: Podman installation failed"
    exit 1
fi

# Verify podman-compose
if command -v podman-compose >/dev/null 2>&1; then
    COMPOSE_VERSION=$(podman-compose --version 2>&1 || echo "installed")
    echo "✓ podman-compose installed: $COMPOSE_VERSION"
else
    echo "✗ ERROR: podman-compose installation failed"
    exit 1
fi

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Podman and podman-compose are ready to use."
echo "You can now run: ./install.sh"
echo ""
