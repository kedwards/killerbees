#!/bin/bash

# Arch Linux Installation Script

# Step 1: Set the keyboard layout
loadkeys us

# Step 2: Verify boot mode
ls /sys/firmware/efi/efivars

# Step 3: Connect to the internet
ping -c 3 archlinux.org

# Step 4: Update the system clock
timedatectl set-ntp true

# Step 5: Partition the disk
# Replace /dev/sda with the target disk
echo "Partitioning the disk..."
parted /dev/sda --script mklabel gpt
parted /dev/sda --script mkpart primary 1MiB 512MiB
parted /dev/sda --script set 1 esp on
parted /dev/sda --script mkpart primary 512MiB 100%

# Step 6: Format the partitions
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2

# Step 7: Mount the file systems
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

# Step 8: Install essential packages
pacstrap /mnt base linux linux-firmware

# Step 9: Generate an fstab file
genfstab -U /mnt >> /mnt/etc/fstab

# Step 10: Chroot into the new system
arch-chroot /mnt

# Step 11: Set the time zone
ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
hwclock --systohc

# Step 12: Localization
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Step 13: Network configuration
echo "arch" > /etc/hostname
cat <<EOL >> /etc/hosts
127.0.0.1	localhost
::1	localhost
127.0.1.1	arch.localdomain	arch
EOL

# Step 14: Set root password
passwd

# Step 15: Install the bootloader
bootctl install
cat <<EOL > /boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=/dev/sda2 rw
EOL

# Step 16: Exit chroot and unmount partitions
exit
umount -R /mnt

# Step 17: Reboot the system
reboot

# Note: Replace placeholders like 'Region/City' and '/dev/sda' with actual values specific to your setup.

