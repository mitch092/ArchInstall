#!/bin/bash

set -e

# Set locale
echo "en_US.UTF-8 UTF-8" >/etc/locale.gen
locale-gen
localectl set-locale LANG=en_US.UTF-8

# Configure timezone and hostname
timedatectl set-ntp true
timedatectl set-timezone America/Los_Angeles
hostnamectl set-hostname myhostname

# Setup hosts file
echo "127.0.0.1   localhost" >/etc/hosts
echo "::1         localhost" >>/etc/hosts
echo "127.0.1.1   myhostname.localdomain myhostname" >>/etc/hosts

# Configure DNS resolver
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
systemctl enable systemd-resolved

# Enable hardware clock synchronization
hwclock --systohc

# Configure root password and add user
echo "root:password" | chpasswd
useradd -m -G wheel -s /bin/bash arch
echo "arch:password" | chpasswd
echo "%wheel ALL=(ALL:ALL) ALL" >>/etc/sudoers

# Install yay
pacman -Sy --noconfirm git base-devel
git clone https://aur.archlinux.org/yay.git /tmp/yay
chown -R arch:arch /tmp/yay
cd /tmp/yay && sudo -u arch makepkg -si --noconfirm

# Install necessary software
sudo -u arch yay -S --noconfirm cachyos-keyring cachyos-mirrorlist linux-cachyos \
  pipewire pipewire-alsa pipewire-jack pipewire-pulse bottles networkmanager \
  nvidia nvidia-utils nvidia-settings kde-plasma-desktop grub efibootmgr

# Configure bootloader
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Enable NetworkManager
systemctl enable NetworkManager

# Enable SSD optimizations
systemctl enable fstrim.timer

# Final Steps
umount -R "$MOUNT_DIR"
reboot
