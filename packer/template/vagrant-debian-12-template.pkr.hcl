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
source "virtualbox-iso" "debian12vbox" {
  boot_command             = [
    "<esc><wait>",
    "install <wait>",
    " auto=true",
    " priority=critical",
    " preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg <wait>",
    "<enter><wait>"
  ]
  disk_size                = "20480"
  guest_additions_path     = "/home/vagrant/VBoxGuestAdditions.iso"
  guest_os_type            = "Debian_64"
  hard_drive_interface     = "sata"
  hard_drive_nonrotational = "true"
  hard_drive_discard       = "true"
  http_directory           = "http"
  iso_checksum             = "sha256:REPLACE_ME_SHA256SUM"
  iso_url                  = "file://REPLACE_ME_DEBIAN12_NETINST"
  output_directory         = "output-virtualbox-iso-debian12vbox"
  sata_port_count          = "10"
  shutdown_command         = "echo 'packer' | sudo -S shutdown -P now"
  ssh_agent_auth           = true
  ssh_timeout              = "6000s"
  ssh_username             = "vagrant"
  vboxmanage               = [
    ["modifyvm", "{{ .Name }}", "--memory", "2048"], 
    ["modifyvm", "{{ .Name }}", "--cpus", "2"],
    ["modifyvm", "{{.Name}}", "--nat-localhostreachable1", "on" ]

  ]
  vm_name                  = "debian12vbox"
}

# Reference: https://developer.hashicorp.com/packer/integrations/hashicorp/qemu/latest/components/builder/qemu
source "qemu" "debian12qemu" {
  iso_url           = "file://REPLACE_ME_DEBIAN12_NETINST"
  iso_checksum      = "sha256:REPLACE_ME_SHA256SUM"
  output_directory  = "output-qemu-debian12qemu"
  shutdown_command  = "echo 'packer' | sudo -S shutdown -P now"
  disk_size         = "20480"
  format            = "qcow2"
  accelerator       = "kvm"
  http_directory    = "http"
  ssh_username      = "vagrant"
  ssh_agent_auth    = true
  ssh_timeout       = "6000s"
  vm_name           = "debian12qemu"
  net_device        = "virtio-net"
  disk_interface    = "virtio-scsi"
  boot_command             = [
    "<esc><wait>",
    "install <wait>",
    " auto=true",
    " priority=critical",
    " preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg <wait>",
    "<enter><wait>"
  ]
  qemuargs          = [
    [ "-m", "1024M" ]
  ]
}

build {
  sources = [
    "REPLACE_ME_BUILD_ARCH"
  ]

  provisioner "ansible" {
    playbook_file = "../ansible/playbooks/vagrant-debian.yml"
    user          = "vagrant"
    # avoid "Failed to connect to the host via scp: bash: /usr/lib/sftp-server: No such file or directory"
    # by setting compatibility flags to work around openssh9 features
    extra_arguments = [ "--scp-extra-args", "'-O'" ]
  }

  post-processor "vagrant" {
    keep_input_artifact = false
    output              = "REPLACE_ME_BOXNAME"
  }
}
