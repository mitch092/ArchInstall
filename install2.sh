#!/bin/bash

set -e

# User set variables.
FIRST_USER="steven"
FIRST_USER_PASSWORD="changeme"

# Set time and date.
timedatectl set-ntp true
timedatectl set-local-rtc false

# Set locale
locale-gen

# Add first non-root user.
useradd -m -G wheel -s /bin/bash "${FIRST_USER}"
echo "${FIRST_USER}:${FIRST_USER_PASSWORD}" | chpasswd

pacman -S --noconfirm linux linux-firmware

bootctl install

# Enable various services.
systemctl enable systemd-timesyncd.service
systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service
systemctl enable systemd-boot-update.service
