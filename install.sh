#!/bin/bash

set -e

# User set variables.
DISK="/dev/sda"
MOUNT_DIR="/mnt"
BOOT_PATH="${MOUNT_DIR}/efi"

EFI_SIZE="4GiB"
SWAP_SIZE="8GiB"

EFI_LABEL="efi"
SWAP_LABEL="swap"
ROOT_LABEL="root"

HOST_NAME="vengeance"
ROOT_PASSWORD="changeme"

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
pacstrap -K $MOUNT_DIR base sudo

systemd-firstboot --root=$MOUNT_DIR --locale=en_US.UTF-8 --locale-messages=en_US.UTF-8 \
    --keymap=us --timezone=America/Los_Angeles --hostname=$HOST_NAME --root-password=$ROOT_PASSWORD \
    --root-shell=/bin/bash --kernel-command-line="root=LABEL=root rw" --setup-machine-id

# Generate an fstab using labels.
genfstab -L -p $MOUNT_DIR >"${MOUNT_DIR}/etc/fstab"

# Enable nss-myhostname instead of changing /etc/hosts.
sed -i '/^hosts:/ s/files dns/files myhostname dns/' "${MOUNT_DIR}/etc/nsswitch.conf"

# Uncomment a locale for locale-gen.
sed -i '/en_US\.UTF-8 UTF-8/s/^#//g' "${MOUNT_DIR}/etc/locale.gen"

# Uncomment the wheel group in the sudoers file.
sed -i '/%wheel ALL=(ALL:ALL) ALL/s/^# //g' "${MOUNT_DIR}/etc/sudoers"

# Create a symbolic link for the systemd-resolved stub to resolv.conf.
ln -sf "../run/systemd/resolve/stub-resolv.conf" "${MOUNT_DIR}/etc/resolv.conf"

# Use systemd-nspawn to configure the rest of the system from inside a container, running another install script.
systemd-nspawn --boot --notify-ready=yes --machine=installer --console=passive --bind=".:/scripts" --directory="${MOUNT_DIR}" &
systemd-run --wait --machine=installer "/bin/bash /scripts/install2.sh; poweroff"

arch-chroot $MOUNT_DIR "grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB; grub-mkconfig -o /boot/grub/grub.cfg"

# Final Steps
umount -R $MOUNT_DIR
swapoff -L $SWAP_LABEL
echo "Install finished. Ready to reboot."
