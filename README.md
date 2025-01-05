# Modern Automated Arch Linux Install Script
This is my custom Arch Linux install script. Systemd components in the "base" package are used as much as possible, to make installation quick and minimal. 

Some highlights:
* UKI kernel: Simplifies kernel management and booting. Also possibly faster than keeping initramfs separate.
* systemd-boot: Simplifies creating boot entries. Should automatically detect kernels placed in /efi/EFI/Linux
* systemd-networkd and systemd-resolved: Simpler than NetworkManager, builtin, easy to configure and use.
* F2FS: Should reduce wear on SSD.
* Uses systemd-firstboot to set most things that need to be configured during install.

This install is very light and minimal, but should be enough to bootstrap the rest of the system (i.e., graphics driver, desktop environment, web browser, dev tools, games).
