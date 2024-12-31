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

# Partition Disk
sgdisk --zap-all --clear \
    --new=1:0:+${EFI_SIZE} --typecode=1:ef00 \
    --new=2:0:+${SWAP_SIZE} --typecode=2:8200 \
    --new=3:0:0 --typecode=3:8300 ${DISK}

# Format Partitions
mkfs.fat -F32 -n "${EFI_LABEL}" "${DISK}1"
mkswap -L "${SWAP_LABEL}" "${DISK}2"
mkfs.f2fs -f -l "${ROOT_LABEL}" "${DISK}3"

# Mount Partitions
mkdir -p "${MOUNT_DIR}"
mount -L "${ROOT_LABEL}" "${MOUNT_DIR}"
mkdir -p "${BOOT_PATH}"
mount -L "${EFI_LABEL}" "${BOOT_PATH}"
swapon -L "${SWAP_LABEL}"

# Install Base System
pacstrap -K "${MOUNT_DIR}" base linux linux-firmware sudo base-devel git util-linux networkmanager \
    pipewire pipewire-audio wireplumber gptfdisk sddm plasma-meta grub efibootmgr reflector openssh man \
    systemd-resolvconf cups print-manager qt5-declarative flatpak

# Generate an fstab using labels.
genfstab -L -p "${MOUNT_DIR}" >>"${MOUNT_DIR}/etc/fstab"

# Enable nss-myhostname instead of changing /etc/hosts.
sed -i '/^hosts:/ s/files dns/files myhostname dns/' "${MOUNT_DIR}/etc/nsswitch.conf"

# Uncomment a locale for locale-gen.
sed -i '/en_US\.UTF-8 UTF-8/s/^#//g' "${MOUNT_DIR}/etc/locale.gen"

# Uncomment the wheel group in the sudoers file.
sed -i '/%wheel ALL=(ALL:ALL) ALL/s/^# //g' "${MOUNT_DIR}/etc/sudoers"

# Use systemd-nspawn to configure the rest of the system from inside a container, running another install script.
systemd-nspawn --boot --notify-ready=yes --machine=installer --console=passive --bind=".:/scripts" --directory="${MOUNT_DIR}"
systemd-run --pipe --machine=installer "/bin/bash /scripts/install2.sh; poweroff"

# Create a symbolic link for the systemd-resolved stub to resolv.conf.
ln -sf "../run/systemd/resolve/stub-resolv.conf" "${MOUNT_DIR}/etc/resolv.conf"

# Final Steps
umount -R "${MOUNT_DIR}"
echo "Install finished. Ready to reboot."
