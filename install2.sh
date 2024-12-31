#!/bin/bash

set -e

# User set variables.
HOST_NAME="vengeance"
ROOT_PASSWORD="changeme"
FIRST_USER="steven"
FIRST_USER_PASSWORD="changeme"

# Set time and date.
timedatectl set-ntp true
timedatectl set-timezone America/Los_Angeles

# Set locale
locale-gen
localectl set-locale LANG=en_US.UTF-8

# Set hostname.
hostnamectl set-hostname "${HOST_NAME}"

# Configure root password and add a non-root user.
echo "root:${ROOT_PASSWORD}" | chpasswd
useradd -m -G wheel -s /bin/bash "${FIRST_USER}"
echo "${FIRST_USER}:${FIRST_USER_PASSWORD}" | chpasswd

# Enable various services.
systemctl enable systemd-resolved.service
systemctl enable NetworkManager.service
systemctl enable fstrim.timer
#systemctl enable sddm.service
