#!/bin/bash

set -e

# Variables
DISK="/dev/sda"
MOUNT_DIR="/mnt"

EFI_SIZE="550MiB"
SWAP_SIZE="8GiB"

EFI_LABEL="EFI"
SWAP_LABEL="swap"
ROOT_LABEL="root"

LABEL_PATH="/dev/disk/by-partlabel/"
EFI_PATH="${LABEL_PATH}${EFI_LABEL}"
SWAP_PATH="${LABEL_PATH}${SWAP_LABEL}"
ROOT_PATH="${LABEL_PATH}${ROOT_LABEL}"

# Update system clock
systemctl enable systemd-timesyncd.service

# Partition Disk
sgdisk "--zap-all --clear \
    --new=1:0:+${EFI_SIZE} --typecode=1:ef00 --change-name=1:${EFI_LABEL} \
    --new=2:0:+${SWAP_SIZE} --typecode=2:8200 --change-name=2:${SWAP_LABEL} \
    --new=3:0:0 --typecode=3:8300 --change-name=3:${ROOT_LABEL} ${DISK}"

# Format Partitions
mkfs.fat -F32 -n "${EFI_LABEL}" "${EFI_PATH}"
mkswap -L "${SWAP_LABEL}" "${SWAP_PATH}"
mkfs.f2fs "${ROOT_PATH}"

# Mount Partitions
mkdir -p "$MOUNT_DIR"
mount "${DISK}3" "$MOUNT_DIR"
mkdir -p "$MOUNT_DIR/boot"
mount "${DISK}1" "$MOUNT_DIR/boot"
swapon "${DISK}2"

# Install Base System
pacstrap -K "$MOUNT_DIR" base base-devel git linux linux-firmware sudo

# Prepare for systemd-nspawn
genfstab -U "$MOUNT_DIR" >>"$MOUNT_DIR/etc/fstab"
ln -sf "../run/systemd/resolve/stub-resolv.conf" "$MOUNT_DIR/etc/resolv.conf"

# Use systemd-nspawn to configure the system
systemd-nspawn -bD "$MOUNT_DIR" /bin/bash install2.sh

# Final Steps
umount -R "$MOUNT_DIR"
reboot
