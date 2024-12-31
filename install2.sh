#!/bin/bash

set -e

# Enable variou services.
systemctl enable systemd-timesyncd.service
systemctl enable systemd-resolved
systemctl enable NetworkManager
systemctl enable fstrim.timer

# Set time and date.
timedatectl set-timezone America/Los_Angeles

# Set locale
echo "en_US.UTF-8 UTF-8" >>/etc/locale.gen
locale-gen
localectl set-locale LANG=en_US.UTF-8

# Set hostname.
hostnamectl set-hostname myhostname

# Setup hosts file
echo "127.0.0.1   localhost" >/etc/hosts
echo "::1         localhost" >>/etc/hosts
echo "127.0.1.1   myhostname.localdomain myhostname" >>/etc/hosts

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
  pipewire pipewire-alsa pipewire-jack pipewire-pulse wireplumber bottles networkmanager \
  nvidia nvidia-utils nvidia-settings kde-plasma-desktop grub efibootmgr reflector openssh man

# Configure bootloader
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Final Steps
umount -R "$MOUNT_DIR"
reboot
