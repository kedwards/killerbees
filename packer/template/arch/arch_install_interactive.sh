#!/bin/bash

# Arch Linux Installation Script - Interactive Version
# WARNING: This script will format disks and install Arch Linux
# Use at your own risk and ensure you have backups!

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Function to prompt for user input
prompt_user() {
    local prompt="$1"
    local variable="$2"
    echo -n "$prompt: "
    read $variable
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (from Arch Linux live environment)"
   exit 1
fi

print_header "Arch Linux Installation Script"
print_warning "This script will install Arch Linux on your system"
print_warning "ALL DATA on the selected disk will be DESTROYED!"
echo
read -p "Do you want to continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    print_status "Installation cancelled"
    exit 0
fi

# Step 1: Set keyboard layout
print_header "Setting Keyboard Layout"
prompt_user "Enter keyboard layout (default: us)" keymap
keymap=${keymap:-us}
loadkeys $keymap
print_status "Keyboard layout set to $keymap"

# Step 2: Check boot mode
print_header "Checking Boot Mode"
if ls /sys/firmware/efi/efivars &> /dev/null; then
    BOOT_MODE="UEFI"
    print_status "UEFI boot mode detected"
else
    BOOT_MODE="BIOS"
    print_status "BIOS boot mode detected"
fi

# Step 3: Check internet connection
print_header "Checking Internet Connection"
if ping -c 3 8.8.8.8 &> /dev/null; then
    print_status "Internet connection is working"
else
    print_error "No internet connection. Please configure network first"
    exit 1
fi

# Step 4: Update system clock
print_header "Updating System Clock"
timedatectl set-ntp true
print_status "System clock synchronized"

# Step 5: List available disks and select target
print_header "Available Disks"
lsblk -d -o NAME,SIZE,TYPE | grep disk
echo
prompt_user "Enter target disk (e.g., sda, nvme0n1)" target_disk
target_disk="/dev/$target_disk"

if [ ! -b "$target_disk" ]; then
    print_error "Disk $target_disk does not exist"
    exit 1
fi

print_warning "Selected disk: $target_disk"
print_warning "ALL DATA on $target_disk will be ERASED!"
read -p "Are you absolutely sure? Type 'DELETE ALL DATA' to continue: " final_confirm

if [ "$final_confirm" != "DELETE ALL DATA" ]; then
    print_status "Installation cancelled"
    exit 0
fi

# Step 6: Partition the disk
print_header "Partitioning Disk"
if [ "$BOOT_MODE" == "UEFI" ]; then
    print_status "Creating GPT partition table for UEFI"
    parted $target_disk --script mklabel gpt
    parted $target_disk --script mkpart primary fat32 1MiB 512MiB
    parted $target_disk --script set 1 esp on
    parted $target_disk --script mkpart primary ext4 512MiB 100%
    
    if [[ $target_disk == *"nvme"* ]]; then
        boot_partition="${target_disk}p1"
        root_partition="${target_disk}p2"
    else
        boot_partition="${target_disk}1"
        root_partition="${target_disk}2"
    fi
else
    print_status "Creating MBR partition table for BIOS"
    parted $target_disk --script mklabel msdos
    parted $target_disk --script mkpart primary ext4 1MiB 100%
    parted $target_disk --script set 1 boot on
    
    if [[ $target_disk == *"nvme"* ]]; then
        root_partition="${target_disk}p1"
    else
        root_partition="${target_disk}1"
    fi
fi

# Step 7: Format partitions
print_header "Formatting Partitions"
if [ "$BOOT_MODE" == "UEFI" ]; then
    print_status "Formatting EFI partition"
    mkfs.fat -F32 $boot_partition
fi

print_status "Formatting root partition"
mkfs.ext4 -F $root_partition

# Step 8: Mount partitions
print_header "Mounting Partitions"
mount $root_partition /mnt

if [ "$BOOT_MODE" == "UEFI" ]; then
    mkdir -p /mnt/boot
    mount $boot_partition /mnt/boot
fi

print_status "Partitions mounted successfully"

# Step 9: Install base system
print_header "Installing Base System"
print_status "Installing base packages (this may take a while)..."
pacstrap /mnt base linux linux-firmware base-devel nano vim networkmanager grub

if [ "$BOOT_MODE" == "UEFI" ]; then
    pacstrap /mnt efibootmgr
fi

# Step 10: Generate fstab
print_header "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab
print_status "fstab generated"

# Step 11: Create chroot configuration script
print_header "Creating Chroot Configuration Script"
cat > /mnt/arch_chroot_config.sh << 'EOF'
#!/bin/bash

# Get user input for configuration
echo "=== Configuring Arch Linux ==="

# Set timezone
echo "Available timezones:"
ls /usr/share/zoneinfo/
read -p "Enter your region (e.g., America, Europe): " region
ls /usr/share/zoneinfo/$region/
read -p "Enter your city: " city
ln -sf /usr/share/zoneinfo/$region/$city /etc/localtime
hwclock --systohc

# Set locale
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set hostname
read -p "Enter hostname for this machine: " hostname
echo "$hostname" > /etc/hostname

# Configure hosts file
cat > /etc/hosts << EOL
127.0.0.1	localhost
::1		localhost
127.0.1.1	$hostname.localdomain	$hostname
EOL

# Set root password
echo "Set root password:"
passwd

# Create user account
read -p "Enter username for new user: " username
useradd -m -G wheel -s /bin/bash $username
echo "Set password for $username:"
passwd $username

# Configure sudo
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Enable NetworkManager
systemctl enable NetworkManager

echo "Basic configuration complete!"
EOF

chmod +x /mnt/arch_chroot_config.sh

# Step 12: Enter chroot and run configuration
print_header "Entering Chroot Environment"
print_status "Please complete the configuration when prompted"
arch-chroot /mnt /arch_chroot_config.sh

# Step 13: Install and configure bootloader
print_header "Installing Bootloader"
if [ "$BOOT_MODE" == "UEFI" ]; then
    arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ARCH
else
    arch-chroot /mnt grub-install --target=i386-pc $target_disk
fi

arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# Step 14: Cleanup
print_header "Cleaning Up"
rm /mnt/arch_chroot_config.sh

# Step 15: Unmount and finish
print_header "Finishing Installation"
umount -R /mnt
print_status "Installation complete!"
print_status "You can now reboot into your new Arch Linux system"

read -p "Reboot now? (yes/no): " reboot_confirm
if [ "$reboot_confirm" == "yes" ]; then
    reboot
fi
EOF
