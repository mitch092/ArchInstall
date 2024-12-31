#!/bin/bash

set -e

# User set variables.
DISK="/dev/sda"
MOUNT_DIR="/mnt"

EFI_SIZE="550MiB"
SWAP_SIZE="8GiB"

EFI_LABEL="EFI"
SWAP_LABEL="swap"
ROOT_LABEL="root"

# Auto variables to simplify the script.
LABEL_PATH="/dev/disk/by-partlabel/"
EFI_PATH="${LABEL_PATH}${EFI_LABEL}"
SWAP_PATH="${LABEL_PATH}${SWAP_LABEL}"
ROOT_PATH="${LABEL_PATH}${ROOT_LABEL}"
BOOT_PATH="${MOUNT_DIR}/boot"

# Update system clock.
systemctl start systemd-timesyncd.service

# Partition Disk
sgdisk "--zap-all --clear \
    --new=1:0:+${EFI_SIZE} --typecode=1:ef00 --change-name=1:${EFI_LABEL} \
    --new=2:0:+${SWAP_SIZE} --typecode=2:8200 --change-name=2:${SWAP_LABEL} \
    --new=3:0:0 --typecode=3:8300 --change-name=3:${ROOT_LABEL} ${DISK}"

# Format Partitions
mkfs.fat -F32 -n "${EFI_LABEL}" "${EFI_PATH}"
mkswap -L "${SWAP_LABEL}" "${SWAP_PATH}"
mkfs.f2fs -l "${ROOT_LABEL}" "${ROOT_PATH}"

# Mount Partitions
mkdir -p "${MOUNT_DIR}"
mount -L "${ROOT_LABEL}" "${MOUNT_DIR}"
mkdir -p "${BOOT_PATH}"
mount -L "${EFI_LABEL}" "${BOOT_PATH}"
swapon -L "${SWAP_LABEL}"

# Install Base System
pacstrap -K "${MOUNT_DIR}" base linux linux-firmware sudo base-devel git util-linux networkmanager \
    pipewire pipewire-alsa pipewire-jack pipewire-pulse wireplumber gptfdisk \
    sddm plasma-meta \
    grub efibootmgr reflector openssh man \
    systemd-resolvconf cups print-manager qt5-declarative flatpak

# Generate an fstab using labels.
genfstab -L -p "${MOUNT_DIR}" >>"${MOUNT_DIR}/etc/fstab"

# Create a link for the systemd-resolved stub to resolv.conf.
ln -sf "../run/systemd/resolve/stub-resolv.conf" "${MOUNT_DIR}/etc/resolv.conf"

# Enable nss-myhostname instead of changing /etc/hosts.
sed -i s+files dns+files myhostname dns+ "${MOUNT_DIR}/etc/nsswitch.conf"

# Enable a locale.
echo "en_US.UTF-8 UTF-8" >>"${MOUNT_DIR}/etc/locale.gen"

# Add the wheel group to the sudoers file.
echo "%wheel ALL=(ALL:ALL) ALL" >>"${MOUNT_DIR}/etc/sudoers"

# Use systemd-nspawn to configure the rest of the system from inside a container, running another install script.
systemd-nspawn --boot --directory="${MOUNT_DIR}" "/bin/bash install2.sh"

# Final Steps
umount -R "${MOUNT_DIR}"
#reboot
