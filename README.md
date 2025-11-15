# EQEmu Server - Podman Container Setup

## Quick Start (Automated Installation)

### One-Command Installation

```bash
git clone https://github.com/crucifix86/eqemu-podman.git
cd eqemu-podman
./install.sh
```

That's it! The script will:
1. Clean up any previous installations
2. Free port 3306 (stops host MariaDB if needed)
3. Build the Podman container
4. Start the container
5. Run the EQEmu installer
6. Start the EQEmu server

The entire process takes about 10-15 minutes depending on your internet connection.

### Server Management

**Start the server:**
```bash
./start.sh
```

**Stop the server:**
```bash
podman-compose down
```

**View logs:**
```bash
./logs.sh
```

**Restart the server:**
```bash
podman-compose down
./start.sh
```

**Complete reinstall (wipes all data):**
```bash
podman-compose down -v
podman volume prune -f
./install.sh
```

## Prerequisites

- Ubuntu 24.04 (or compatible Debian-based system)
- Podman and podman-compose installed:
  ```bash
  sudo apt update
  sudo apt install -y podman podman-compose
  ```

## Ports

The server uses the following ports:
- **5998** - Titanium clients
- **5999** - Secrets of Faydwer clients
- **9000** - World server
- **7100-7400** - Zone servers
- **3306** - MariaDB (internal)

## What We Learned

### Why Podman Instead of Docker?
The EQEmu universal installer requires **systemd** to be fully functional, particularly for managing MariaDB service. Docker has poor systemd support in containers, causing the installer to hang during MariaDB configuration. Podman natively supports systemd as PID 1 in containers, making it the ideal solution.

### Critical Prerequisites

1. **Stop Host MariaDB**: If you have MariaDB/MySQL running on the host system, you MUST stop it before starting the container:
   ```bash
   sudo systemctl stop mariadb mysql
   sudo killall -9 mariadbd  # If needed
   ```

   Why? We use `network_mode: host` to avoid zone server connectivity issues. This means the container shares the host's network stack, so port 3306 must be available.

2. **Fresh Installation**: The installer creates users and databases. If you need to reinstall:
   ```bash
   podman-compose down -v  # Removes volumes
   podman volume prune -f  # Cleans up
   ./start.sh              # Start fresh
   ```

### Installation Commands

From `/home/doug/eqemu-podman/`:

1. **Start the container**:
   ```bash
   ./start.sh
   ```

2. **Run the installer** (inside the container):
   ```bash
   podman exec -it eqemu-server /root/start-eqemu.sh
   ```

### Key Design Decisions

1. **Network Mode: Host**
   - Uses `network_mode: host` in docker-compose.yml
   - Avoids port mapping issues that cause zone server connectivity problems
   - Container shares host's network interface directly

2. **Systemd Support**
   - `systemd: always` in docker-compose.yml enables Podman's systemd support
   - `CMD ["/usr/sbin/init"]` in Containerfile starts systemd as PID 1
   - Required mounts: `/sys/fs/cgroup:/sys/fs/cgroup:ro`

3. **Bundled Installer**
   - EQEmu installer is copied into the image during build
   - No network download required during installation
   - Consistent, repeatable builds

### File Structure

```
/home/doug/eqemu-podman/
├── Containerfile              # Image definition with systemd
├── docker-compose.yml         # Podman compose config
├── start-eqemu.sh            # Runs installer inside container
├── build.sh                  # Builds the image
├── start.sh                  # Starts container
├── logs.sh                   # Views logs
└── eqemu-universal-installer/ # Bundled installer
```

### Ports Exposed

- 5998 - Titanium clients
- 5999 - Secrets of Faydwer clients
- 9000 - World server
- 7100-7400 - Zone servers

### Volumes

- `eqemu-data` - Server files (/home/eqemu)
- `eqemu-db` - MariaDB data (/var/lib/mysql)

### Testing Results

✅ Podman container starts with systemd
✅ MariaDB installs and starts via systemd
✅ EQEmu installer completes successfully
✅ Server starts and accepts login connections

### Troubleshooting

**Port 3306 already in use**:
```bash
sudo ss -tlpn | grep 3306  # Find what's using it
sudo systemctl stop mariadb mysql  # Stop host MariaDB
```

**Container won't start**:
```bash
podman logs eqemu-server  # Check logs
```

**Need to rebuild**:
```bash
./build.sh
```

### Next Steps / Refinements Needed

- [ ] Auto-start installer on container boot (systemd service)
- [ ] Health checks for server processes
- [ ] Backup/restore scripts for volumes
- [ ] Documentation for newbies
- [ ] Test external connectivity from clients
- [ ] Consider whether to stop host MariaDB automatically in start.sh
