#!/bin/bash

set -e

# User set variables.
EFI_LABEL="efi"
SWAP_LABEL="swap"
ROOT_LABEL="root"

EFI_SIZE="4GiB"
SWAP_SIZE="8GiB"

DISK="/dev/sda"
MOUNT_DIR="/mnt"
ESP_PATH="/${EFI_LABEL}"
BOOT_PATH="${MOUNT_DIR}${ESP_PATH}"
UKI_PATH="${ESP_PATH}/EFI/Linux/vmlinuz-linux.efi"

HOST_NAME="vengeance"
ROOT_PASSWORD="changeme"
FIRST_USER="steven"
FIRST_USER_PASSWORD="changeme"

# Partition Disk
sgdisk --zap-all --clear \
    --new=1:0:+$EFI_SIZE --typecode=1:ef00 --change-name=1:$EFI_LABEL \
    --new=2:0:+$SWAP_SIZE --typecode=2:8200 --change-name=2:$SWAP_LABEL \
    --new=3:0:0 --typecode=3:8300 --change-name=3:$ROOT_LABEL $DISK

# Format Partitions
mkfs.fat -F32 -n $EFI_LABEL "${DISK}1"
mkswap -L $SWAP_LABEL "${DISK}2"
mkfs.f2fs -f -l $ROOT_LABEL "${DISK}3"

# Mount Partitions
mkdir -p $MOUNT_DIR
mount -L $ROOT_LABEL $MOUNT_DIR
mkdir -p $BOOT_PATH
mount -L $EFI_LABEL $BOOT_PATH
swapon --discard -L $SWAP_LABEL

# Install Base System
pacstrap -K $MOUNT_DIR base sudo vim

systemd-firstboot --root=$MOUNT_DIR --locale=en_US.UTF-8 --locale-messages=en_US.UTF-8 \
    --keymap=us --timezone=America/Los_Angeles --hostname=$HOST_NAME --root-password=$ROOT_PASSWORD \
    --root-shell=/bin/bash --kernel-command-line="root=LABEL=root rw" --setup-machine-id

# Generate an fstab using labels.
genfstab -L -p $MOUNT_DIR >"${MOUNT_DIR}/etc/fstab"

# Create a symbolic link for the systemd-resolved stub to resolv.conf.
ln -sf "../run/systemd/resolve/stub-resolv.conf" "${MOUNT_DIR}/etc/resolv.conf"

# Enable nss-myhostname instead of changing /etc/hosts.
sed -i '/^hosts: /s/files dns/files myhostname dns/' "${MOUNT_DIR}/etc/nsswitch.conf"

# Uncomment a locale for locale-gen.
sed -i '/en_US\.UTF-8 UTF-8/s/^#//' "${MOUNT_DIR}/etc/locale.gen"

# Uncomment the wheel group in the sudoers file.
sed -i '/%wheel ALL=(ALL:ALL) ALL/s/^# //' "${MOUNT_DIR}/etc/sudoers"

# Change the mkinitcpio hooks.
sed -i '/^HOOKS=/s/[(][^)]*[)]/(systemd fsck autodetect microcode modconf kms keyboard sd-vconsole block filesystems)/' "${MOUNT_DIR}/etc/mkinitcpio.conf"

# Use a heredoc to set mkinitcpio linux.preset to generate one UKI file in the correct location.
cat <<EOF >"${MOUNT_DIR}/etc/mkinitcpio.d/linux.preset"
ALL_kver="${UKI_PATH}"
PRESETS=('default')
default_uki="${UKI_PATH}"
EOF

# Run a heredoc script inside of arch-chroot to configure the rest.
arch-chroot $MOUNT_DIR /bin/bash <<EOF
set -e

# Set time and date.
timedatectl set-ntp true
timedatectl set-local-rtc false

# Generate locale files.
locale-gen

# Add first non-root user.
useradd -m -G wheel -s /bin/bash $FIRST_USER
echo "${FIRST_USER}:${FIRST_USER_PASSWORD}" | chpasswd

# Install the linux kernel, which should run mkinitcpio once and create a UKI.
pacman -S --noconfirm linux linux-firmware

bootctl install

# Enable various services.
systemctl enable systemd-timesyncd.service
systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service
systemctl enable systemd-boot-update.service
EOF

# Final Steps
umount -R $MOUNT_DIR
swapoff -L $SWAP_LABEL
echo "Install finished. Ready to reboot."
