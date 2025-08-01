#!/usr/bin/env bash
set -euo pipefail

echo
echo "INFO: Preparing packer environment for building Ubuntu 25 base box"
echo

# Defaults
DEFAULT_MIRROR="http://ftp.ca.debian.org"
DEFAULT_MIRROR_DIR="/debian"
DEFAULT_SSH_KEY="${HOME}/.ssh/vagrant.id_rsa.pub"
DEFAULT_NETINST_ISO="$HOME/Downloads/debian-12.11.0-amd64-netinst.iso"
DEFAULT_OUTPUT_DIR="$HOME/vagrant/boxes"
TIMESTAMP=$(date +%Y%m%d%H%M)
BOX_BASE_NAME="debian-12-kevin"
VERSION="1.0.0"
DESCRIPTION="Debian 12 base image."

# CLI flag parsing
DEBIAN_MIRROR="$DEFAULT_MIRROR"
DEBIAN_MIRROR_DIR="$DEFAULT_MIRROR_DIR"
SSH_KEY="$DEFAULT_SSH_KEY"
NETINST_ISO="$DEFAULT_NETINST_ISO"
OUTPUT_DIR="$DEFAULT_OUTPUT_DIR"
BUILD_TARGET="vbox"

while [[ $# -gt 0 ]]; do
  case "$1" in
  --mirror)
    DEBIAN_MIRROR="$2"
    shift 2
    ;;
  --mirror-dir)
    DEBIAN_MIRROR_DIR="$2"
    shift 2
    ;;
  --ssh-key)
    SSH_KEY="$2"
    shift 2
    ;;
  --iso)
    NETINST_ISO="$2"
    shift 2
    ;;
  --box-output)
    OUTPUT_DIR="$2"
    shift 2
    ;;
  --target)
    case "$2" in
    vbox | kvm) BUILD_TARGET="$2" ;;
    *)
      echo "ERR: Invalid target: $2. Use 'vbox' or 'kvm'."
      exit 1
      ;;
    esac
    shift 2
    ;;
  *)
    echo "ERR: Unknown argument $1"
    exit 1
    ;;
  esac
done

# Ensure required files/directories exist
[[ -f "$NETINST_ISO" ]] || {
  echo "ERR: ISO not found at $NETINST_ISO"
  exit 1
}
[[ -f "$SSH_KEY" ]] || {
  echo "ERR: SSH public key not found at $SSH_KEY"
  exit 1
}
[[ -d "$OUTPUT_DIR" ]] || mkdir -p "$OUTPUT_DIR"

# Create http directory for preseed
[[ -d http ]] || mkdir http

# Read SSH key content
VAGRANT_PUBLIC_KEY=$(cat "$SSH_KEY")

# Build packer preseed
sed \
  -e "s#REPLACE_ME_MIRROR_DIR#${DEBIAN_MIRROR_DIR}#" \
  -e "s#REPLACE_ME_MIRROR#${DEBIAN_MIRROR}#" \
  -e "s#REPLACE_ME_SSHKEY#${VAGRANT_PUBLIC_KEY}#" \
  template/debian/preseed-debian-12-template.cfg >http/preseed.cfg

# Compute checksum
SHA256SUM=$(sha256sum "$NETINST_ISO" | awk '{print $1}')

# Determine architecture
if [[ "$BUILD_TARGET" == "vbox" ]]; then
  PACKER_SOURCE="source.virtualbox-iso.debian12vbox"
  PROVIDER="virtualbox"
elif [[ "$BUILD_TARGET" == "kvm" ]]; then
  PACKER_SOURCE="source.qemu.debian12qemu"
  PROVIDER="qemu"
fi

# Build box name and path
BOX_NAME="${BOX_BASE_NAME}-${TIMESTAMP}"
BOX_FILE="${OUTPUT_DIR}/${BOX_NAME}.box"

# Render packer template
sed \
  -e "s#REPLACE_ME_SHA256SUM#${SHA256SUM}#" \
  -e "s#REPLACE_ME_DEBIAN12_NETINST#${NETINST_ISO}#" \
  -e "s#REPLACE_ME_BOXNAME#${BOX_FILE}#" \
  -e "s#REPLACE_ME_BUILD_ARCH#${PACKER_SOURCE}#" \
  template/debian/vagrant-debian-12-template.pkr.hcl >vagrant-debian-12.pkr.hcl

# # Run packer build
# echo "INFO: Running packer..."
# packer init vagrant-debian-12.pkr.hcl
# packer validate vagrant-debian-12.pkr.hcl
# packer build vagrant-debian-12.pkr.hcl
#
# [[ -f "$BOX_FILE" ]] || {
#   echo "ERR: Box build failed"
#   exit 1
# }
#
# # Generate metadata
# BOX_SHA256SUM=$(sha256sum "$BOX_FILE" | awk '{print $1}')
# cat <<EOF >"${BOX_FILE}.json"
# {
#   "name": "${BOX_NAME}",
#   "description": "$DESCRIPTION",
#   "versions": [{
#     "version": "$VERSION",
#     "providers": [{
#       "name": "${PROVIDER}",
#       "url": "file:///${BOX_FILE}",
#       "checksum_type": "sha256",
#       "checksum": "$BOX_SHA256SUM"
#     }]
#   }]
# }
# EOF
#
# # Create Vagrantfile
# cat <<EOF >Vagrantfile
# # -*- mode: ruby -*-
# # vi: set ft=ruby :
#
# Vagrant.configure(2) do |config|
#   config.vm.box = "${BOX_NAME}"
#   config.vm.box_check_update = false
#   config.ssh.username = "vagrant"
#   config.ssh.private_key_path = "${SSH_KEY%.pub}"
# end
# EOF
#
# # Add box
# vagrant box add --clean "${BOX_FILE}.json"
#
# # Clean up
# rm Vagrantfile vagrant-debian-12.pkr.hcl
# rm -r .vagrant/ http/
#
# echo
# echo "INFO: Box '${BOX_NAME}' successfully created and added."
# echo "INFO: Vagrantfile generated. You can now run 'vagrant up'"
# echo "INFO: use vagrant init ${BOX_NAME}' to initialize a new Vagrant environment."
