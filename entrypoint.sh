#!/usr/bin/env bash
#
# entrypoint.sh for NetKit
#
# Executed everytime the service is run
# This file is copied as /entrypoint.sh inside the container image.
#

# Variables
export CONFIG_ROOT=/config
CONFIG_ROOT_MOUNT_CHECK=$(mount | grep ${CONFIG_ROOT})
ROOTPASS="${ROOTPASS:-alpine}"
USERNAME="${USERNAME:-alpine}"
USERPASS="${USERPASS:-alpine}"

# Generate SSH host keys
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -A
fi

# Create the user if not already created
if ! id -u ${USERNAME} >/dev/null 2>&1; then
    echo "User '${USERNAME}' does not exist. Creating user."
    addgroup ${USERNAME}
    adduser -G ${USERNAME} -s /bin/bash -D ${USERNAME}
    echo "${USERNAME}:${USERPASS}" | chpasswd
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    mkdir -p /home/${USERNAME}/.nano
    # Generate SSH key pair for the user
    mkdir -p /home/${USERNAME}/.ssh && \
      ssh-keygen -t ed25519 -f /home/${USERNAME}/.ssh/id_ed25519 -N "" && \
      cat /home/${USERNAME}/.ssh/id_ed25519.pub > /home/${USERNAME}/.ssh/authorized_keys && \
      chmod 600 /home/${USERNAME}/.ssh/id_ed25519 && \
      chmod 644 /home/${USERNAME}/.ssh/id_ed25519.pub && \
      chmod 700 /home/${USERNAME}/.ssh && \
      chmod 644 /home/${USERNAME}/.ssh/authorized_keys
    # User owns his home
    chown -R ${USERNAME}:${USERPASS} /home/${USERNAME}
    chmod -R 755 /home/${USERNAME}
else
    echo "User 'alpine' already exists."
fi

# Set password of root and netkit
echo "root:${ROOTPASS}" | chpasswd

# Start custom script run.sh if any...
if [ -f ${CONFIG_ROOT}/run.sh ]; then
    cp ${CONFIG_ROOT}/run.sh /run.sh
    chmod +x /run.sh
    /run.sh
fi

# Start dbus
dbus-uuidgen --ensure

# Run the arguments from CMD in the Dockerfile
# In our case we are starting nginx by default
exec "$@"
