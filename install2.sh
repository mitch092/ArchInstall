#!/bin/bash

set -e

# User set variables.
HOST_NAME="vengeance"
ROOT_PASSWORD="changeme"
FIRST_USER="steven"
FIRST_USER_PASSWORD="changeme"

pacman -S --noconfirm linux linux-firmware

# Set time and date.
timedatectl set-ntp true
timedatectl set-local-rtc false

# Set locale
locale-gen
localectl set-locale LANG=en_US.UTF-8

# Set hostname.
hostnamectl set-hostname "${HOST_NAME}"

# Configure root password and add a non-root user.
echo "root:${ROOT_PASSWORD}" | chpasswd
useradd -m -G wheel -s /bin/bash "${FIRST_USER}"
echo "${FIRST_USER}:${FIRST_USER_PASSWORD}" | chpasswd

bootctl install

# Enable various services.
systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service
systemctl enable systemd-boot-update.service
