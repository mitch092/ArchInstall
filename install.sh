#!/bin/bash

# Variables
DISK="/dev/sda"
EFI_SIZE="512M"
SWAP_SIZE="4G"
ROOT_LABEL="arch_root"
EFI_LABEL="arch_efi"
SWAP_LABEL="arch_swap"
MOUNT_DIR="/mnt/arch"

# Update system clock
timedatectl set-ntp true

# Partition Disk
sgdisk --zap-all --clear \
    -n 1:0:+$EFI_SIZE -t 1:ef00 -c 1:$EFI_LABEL \
    -n 2:0:+$SWAP_SIZE -t 2:8200 -c 2:$SWAP_LABEL \
    -n 3:0:0 -t 3:8300 -c 3:$ROOT_LABEL "$DISK"

# Format Partitions
mkfs.fat -F32 "${DISK}1"
mkswap "${DISK}2"
swapon "${DISK}2"
mkfs.f2fs "${DISK}3"

# Mount Partitions
mkdir -p "$MOUNT_DIR"
mount "${DISK}3" "$MOUNT_DIR"
mkdir -p "$MOUNT_DIR/boot"
mount "${DISK}1" "$MOUNT_DIR/boot"

# Install Base System
pacstrap "$MOUNT_DIR" base linux linux-firmware sudo

# Prepare for systemd-nspawn
genfstab -U "$MOUNT_DIR" >>"$MOUNT_DIR/etc/fstab"
cp /etc/resolv.conf "$MOUNT_DIR/etc/resolv.conf"

# Use systemd-nspawn to configure the system
systemd-nspawn -bD "$MOUNT_DIR" /bin/bash install2.sh

# Final Steps
umount -R "$MOUNT_DIR"
reboot
