#!/usr/bin/env bash

set -euo pipefail

echo
echo "INFO: preparing your packer environment for the creation of a Debian 12 Vagrant base box"
echo

# need to create the http directory, it will contain the customised preseed file
[[ ! -d http ]] && mkdir http

# step 1: create the preseed file

DEFAULT_MIRROR="http://ftp.ca.debian.org"
DEFAULT_MIRROR_DIR="/debian"
DEFAULT_SSH_KEY="${HOME}/.ssh/vagrant.id_rsa.pub"

read -p "Enter your local Debian mirror (${DEFAULT_MIRROR}): " DEBIAN_MIRROR
read -p "Enter the mirror directory (${DEFAULT_MIRROR_DIR}): " DEBIAN_MIRROR_DIR

if [[ ! -f "$HOME/.ssh/vagrant.id_rsa" ]]; then
  ssh-keygen -t rsa -C vagrant@localhost -f "$HOME/.ssh/vagrant.id_rsa" -N ''
fi

echo
/bin/ls -1 ${HOME}/.ssh/*.pub
echo

read -p "Enter the full path to your public SSH key (${DEFAULT_SSH_KEY}): " SSH_KEY
if [ ! -f "${SSH_KEY:=${DEFAULT_SSH_KEY}}" ]; then
  echo "ERR: ${SSH_KEY} cannot be found, exiting"
  exit 1
fi

VAGRANT_PUBLIC_KEY=$(/bin/cat "${SSH_KEY}")
echo
echo "INFO: adding the SSH key to the agent"
/usr/bin/env | /usr/bin/grep -qE "(AGENT_PID|AUTH_SOCK)" || {
  # start the SSH agent if it is not yet started
  echo "INFO: SSH agent not yet started, starting it now"
  eval $(/usr/bin/ssh-agent)
}

/usr/bin/ssh-add "${SSH_KEY%.pub}" || {
  echo "ERR: failed to add the SSH key to the agent, check logs"
  exit 1
}

/bin/sed \
  -e "s#REPLACE_ME_MIRROR_DIR#${DEBIAN_MIRROR_DIR:-${DEFAULT_MIRROR_DIR}}#" \
  -e "s#REPLACE_ME_MIRROR#${DEBIAN_MIRROR:-${DEFAULT_MIRROR}}#" \
  -e "s#REPLACE_ME_SSHKEY#${VAGRANT_PUBLIC_KEY}#" \
  template/preseed-debian-12-template.cfg >http/preseed.cfg

# -------------------------- step 2: create the packer build instructions

DEFAULT_NETINST_ISO="$HOME/Downloads/debian-12.11.0-amd64-netinst.iso"
# Extract version from the ISO filename
ISO_VERSION=$(basename "$DEFAULT_NETINST_ISO" | sed -n 's/^debian-\([0-9.]\+\)-amd64-netinst\.iso$/\1/p')
DEFAULT_BOX_LOC="${HOME}/vagrant/boxes/debian-$ISO_VERSION.box"

read -p "Enter the location of the Debian 12 network installation media (${DEFAULT_NETINST_ISO})": NETINST_ISO
if [ ! -f ${NETINST_ISO:=${DEFAULT_NETINST_ISO}} ]; then
  echo "ERR: cannot find ${NETINST_ISO}, exiting"
  exit 1
fi

SHA256SUM=$(/usr/bin/sha256sum "${NETINST_ISO}" | /usr/bin/awk '{print $1}')

read -p "Enter the full path to store the new vagrant box (${DEFAULT_BOX_LOC}):" VAGRANT_BOX_LOC
if [ ! -d $(/usr/bin/dirname ${VAGRANT_BOX_LOC:=${DEFAULT_BOX_LOC}}) ]; then
  echo "ERR: $(/usr/bin/dirname ${VAGRANT_BOX_LOC}) is not a directory, exiting"
  exit 1
elif [ -f "${VAGRANT_BOX_LOC:=${DEFAULT_BOX_LOC}}" ]; then
  echo "ERR: ${VAGRANT_BOX_LOC} exists, exiting"
  # exit 1
fi

# define target architecture (Virtualbox or KVM)
read -p "Should packer build this VM for Virtualbox (vbox) or KVM (kvm)? " VAGRANT_BUILD_TARGET
case ${VAGRANT_BUILD_TARGET} in
kvm)
  VAGRANT_BUILD_TARGET="source.qemu.debian12qemu"
  ;;
vbox)
  VAGRANT_BUILD_TARGET="source.virtualbox-iso.debian12vbox"
  ;;
*)
  echo "ERR: invalid architecture, must be one of kvm, vbox"
  exit 1
  ;;
esac

/bin/sed \
  -e "s#REPLACE_ME_SHA256SUM#${SHA256SUM}#" \
  -e "s#REPLACE_ME_DEBIAN12_NETINST#${NETINST_ISO}#" \
  -e "s#REPLACE_ME_BOXNAME#${VAGRANT_BOX_LOC}#" \
  -e "s#REPLACE_ME_BUILD_ARCH#${VAGRANT_BUILD_TARGET}#" \
  template/vagrant-debian-12-template.pkr.hcl >vagrant-debian-12.pkr.hcl

# -------------------------- job done

echo
echo "INFO: preparation complete, next run packer init vagrant-debian-12.pkr.hcl && packer validate vagrant-debian-12.pkr.hcl "
echo "INFO: followed by packer build vagrant-debian-12.pkr.hcl"
echo

# -------------------------- Create box

packer init vagrant-debian-12.pkr.hcl && packer validate vagrant-debian-12.pkr.hcl # && packer build vagrant-debian-12.pkr.hcl

if [ ! -f ${VAGRANT_BOX_LOC} ]; then
  echo "ERR: Vagrant box creation failed, check the logs"
  exit 1
fi

# -------------------------- Add box
BOX_NAME=$(basename "${VAGRANT_BOX_LOC}")
DESCRIPTION="Debian 12 base image."
VERSION=1.0.0

BOX_SHA256SUM=$(/usr/bin/sha256sum "${VAGRANT_BOX_LOC}" | cut -d' ' -f1)
/bin/cat <<EOF >"${VAGRANT_BOX_LOC}.json"
{
    "name": "debian-12",
    "description": "$DESCRIPTION",
    "versions": [{
        "version": "$VERSION",
        "providers": [{
            "name": "virtualbox",
            "url": "file:///${VAGRANT_BOX_LOC}",
            "checksum_type": "sha256",
            "checksum": "$BOX_SHA256SUM"
        }]
    }]
}
EOF

# create Vagrantfile
cat <<EOF >Vagrantfile
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  config.vm.box = "debian-12"
  config.vm.box_check_update = false

  # SSH configuration
  config.ssh.username = "vagrant"
  config.ssh.private_key_path = "${HOME}/.ssh/vagrant.id_rsa"

end
EOF

/bin/vagrant box add --clean "${VAGRANT_BOX_LOC}.json"
