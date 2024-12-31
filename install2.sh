#!/bin/bash

set -e

# User set variables.
HOST_NAME="Vengeance"
ROOT_PASSWORD="changeme"
FIRST_USER="Steven"
FIRST_USER_PASSWORD="changeme"

# Auto variables.
TEMP_YAY="/tmp/yay"

# Enable various services.
systemctl enable systemd-timesyncd.service --now
systemctl enable systemd-resolved.service --now
systemctl enable NetworkManager.service --now
systemctl enable fstrim.timer --now

# Set time and date.
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

# Install necessary software.
sudo -u arch yay -S --noconfirm cachyos-keyring cachyos-mirrorlist linux-cachyos \
  pipewire pipewire-alsa pipewire-jack pipewire-pulse wireplumber bottles networkmanager \
  nvidia nvidia-utils nvidia-settings kde-plasma-desktop grub efibootmgr reflector openssh man \
  systemd-resolvconf

# Install yay.
mkdir -p "${TEMP_YAY}"
git clone https://aur.archlinux.org/yay.git "${TEMP_YAY}"
cd "${TEMP_YAY}"
makepkg -si --noconfirm

# Configure bootloader.
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
