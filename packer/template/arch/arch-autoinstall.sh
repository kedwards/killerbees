#!/usr/bin/env bash
# Minimal Arch install script based on LinuxVox tutorial
# Usage: run this from Arch live environment as root

set -euo pipefail

DISK="/dev/sda"
HOSTNAME="archlinux"
TIMEZONE="UTC"
LOCALE="en_US.UTF-8"
KEYMAP="us"
# Optionally install GNOME: set INSTALL_DE="gnome"; else leave blank
INSTALL_DE="" # "xfce" | "gnome"

# 1. Connect to internet (wired assumed; for wifi use iwctl)
timedatectl set-ntp true

# 2. Partition (simple single root) – customize as needed
sgdisk --zap-all "$DISK"
sgdisk -n1:0:+512M -t1:ef00 "$DISK"
sgdisk -n2:0:0 -t2:8300 "$DISK"

mkfs.fat -F32 "${DISK}1"
mkfs.ext4 "${DISK}2"
mount "${DISK}2" /mnt
mkdir /mnt/boot
mount "${DISK}1" /mnt/boot

# 3. Install base system
pacstrap /mnt base base-devel linux linux-firmware

# 4. Generate fstab
genfstab -U /mnt >>/mnt/etc/fstab

# 5. Chroot for configuration
arch-chroot /mnt /bin/bash <<EOF
set -e

# Timezone
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Locale
echo "$LOCALE UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf

# Keyboard layout
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# Hostname and hosts
echo "$HOSTNAME" > /etc/hostname
cat <<HOSTS > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
HOSTS

# Install GRUB for BIOS or EFI
pacman --noconfirm -S grub efibootmgr openssh openssl
g rub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Optional Desktop Environment
if [[ "$INSTALL_DE" == "gnome" ]]; then
  pacman --noconfirm -S gnome gnome-extra
  systemctl enable gdm.service
elif [[ "$INSTALL_DE" == "xfce" ]]; then
  pacman --noconfirm -S xfce4 lightdm lightdm-gtk-greeter
  systemctl enable lightdm.service
fi

PASSWORD=$(/usr/bin/openssl passwd -crypt 'vagrant')

# Vagrant-specific configuration
/usr/bin/useradd --password ${PASSWORD} --comment 'Vagrant User' --create-home --user-group vagrant
echo -e 'vagrant\nvagrant' | /usr/bin/passwd vagrant
echo 'Defaults env_keep += "SSH_AUTH_SOCK"' >/etc/sudoers.d/10_vagrant
echo 'vagrant ALL=(ALL) NOPASSWD: ALL' >>/etc/sudoers.d/10_vagrant
/usr/bin/chmod 0440 /etc/sudoers.d/10_vagrant
/usr/bin/systemctl start sshd.service
EOF

# 6. Finish up
umount -R /mnt
echo "Installation complete. Powering off."
poweroff
