packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "~> 1"
    }
  }
}

# Reference: https://developer.hashicorp.com/packer/integrations/hashicorp/virtualbox/latest/components/builder/iso
source "virtualbox-iso" "ubuntu25vbox" {
  boot_command = [
    "<esc><esc><esc>",
    "c<wait>",
    "set gfxpayload=keep<enter><wait>",
    "linux /casper/vmlinuz <wait>",
    "autoinstall <wait>",
    "ds=\"nocloud-net;s=http://{{.HTTPIP}}:{{.HTTPPort}}/\" <wait>",
    "---<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]

  boot_wait                = "5s"
  disk_size                = "20480"
  guest_additions_path     = "/home/vagrant/VBoxGuestAdditions.iso"
  guest_os_type            = "Ubuntu_64"
  hard_drive_interface     = "sata"
  hard_drive_nonrotational = "true"
  hard_drive_discard       = "true"
  http_directory           = "http"
  iso_checksum             = "sha256:b87366b62eddfbecb60e681ba83299c61884a0d97569abe797695c8861f5dea4"
  iso_url                  = "file:///home/kedwards/Downloads/ubuntu-25.04-desktop-amd64.iso"
  output_directory         = "output-virtualbox-iso-ubuntuvbox"
  sata_port_count          = "10"
  shutdown_command         = "echo 'packer' | sudo -S shutdown -P now"
  ssh_agent_auth           = true
  ssh_timeout              = "6000s"
  ssh_username             = "vagrant"
  ssh_password             = "vagrant"
  vboxmanage               = [
    ["modifyvm", "{{ .Name }}", "--memory", "2048"], 
    ["modifyvm", "{{ .Name }}", "--cpus", "2"],
    ["modifyvm", "{{.Name}}", "--nat-localhostreachable1", "on" ]

  ]
  vm_name                  = "ubuntuvbox"
}

build {
  sources = [
    "source.virtualbox-iso.ubuntu25vbox"
  ]

  provisioner "ansible" {
    playbook_file = "../../ansible/vagrant-ubuntu.yml"
    user          = "vagrant"
    # avoid "Failed to connect to the host via scp: bash: /usr/lib/sftp-server: No such file or directory"
    # by setting compatibility flags to work around openssh9 features
    extra_arguments = [ "--scp-extra-args", "'-O'" ]
  }

  post-processor "vagrant" {
    keep_input_artifact = false
    output              = "/home/kedwards/vagrant/boxes/ubuntu25-kevin-202507271213.box"
  }
}
