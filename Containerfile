FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install systemd and dependencies
RUN apt-get update && apt-get install -y \
    systemd \
    systemd-sysv \
    curl \
    wget \
    git \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Copy installer
COPY eqemu-universal-installer /root/eqemu-universal-installer
RUN cd /root/eqemu-universal-installer && chmod +x install.sh scripts/install_linux.sh

# Copy startup script
COPY start-eqemu.sh /root/start-eqemu.sh
RUN chmod +x /root/start-eqemu.sh

# Expose EQEmu ports
EXPOSE 5998 5999 9000 7100-7400

# Use systemd as init
CMD ["/usr/sbin/init"]
