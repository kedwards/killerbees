#!/usr/bin/env bash

script_dir=$(dirname "$0")
name=$1
version=$2
base=$3
description=${4:-"$name base image."}
owner=${5:-"kedwards"}/

if [ $# -lt 2 ]; then
  echo "Usage: $0 <name> <version> <base> [<description>] [<owner>]"
  exit 1
fi

box_dir=$script_dir/boxes/$name
mkdir -p "$box_dir"

if [[ ! -f "$HOME/.ssh/vagrant.id_rsa" ]]; then
  ssh-keygen -t rsa -C vagrant@localhost -f "$HOME/.ssh/vagrant.id_rsa" -N ''
fi

ssh-copy-id \
  -o PubkeyAuthentication=no \
  -i "$HOME/.ssh/vagrant.id_rsa.pub" \
  -p 2222 \
  vagrant@127.0.0.1

# create Vagrantfile
cat <<EOF >"$box_dir/Vagrantfile"
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  config.vm.box = "$owner${name}"
  config.vm.box_check_update = false

  # SSH configuration
  config.ssh.username = "vagrant"
  config.ssh.private_key_path = File.join(File.expand_path(File.dirname(__FILE__)), "vagrant.id_rsa")

end
EOF

# build box
cd "$box_dir" || exit 1
vagrant package \
  --base "$base" \
  --output "vagrant-$name-$version.box" \
  --vagrantfile "Vagrantfile" \
  --include "$HOME/.ssh/vagrant.id_rsa" \
  "kedwards/$name"

sha256sum=$(/usr/bin/sha256sum "vagrant-$name-$version.box" | cut -d' ' -f1)

cat <<EOF >"$name-$version.json"
{
    "name": "$owner$name",
    "description": "$description",
    "versions": [{
        "version": "$version",
        "providers": [{
            "name": "virtualbox",
            "url": "file:///$box_dir/vagrant-$name-$version.box",
            "checksum_type": "sha256",
            "checksum": "$sha256sum"
        }]
    }]
}
EOF

vagrant box add --clean "$name-$version.json"

rm -r Vagrantfile

vagrant init "$owner$name"
