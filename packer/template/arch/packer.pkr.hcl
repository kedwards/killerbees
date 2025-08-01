packer {
  required_plugins {
    virtualbox = {
      source  = "github.com/hashicorp/virtualbox"
      version = ">= 1.0.0"
    }
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "~> 1"
    }
  }
}

variable "vm_name" {
  default = "arch-vagrant"
}

source "virtualbox-iso" "archvbox" {
  vm_name              = "archvbox"
  boot_command         = [
    "<enter><wait10>",
    "curl -o /tmp/install.sh http://{{ .HTTPIP }}:{{ .HTTPPort }}/arch-autoinstall.sh<enter><wait5>",
    "chmod +x /tmp/install.sh<enter><wait2>",
    "/tmp/install.sh<enter>"
  ]
  boot_wait            = "5s"
  disk_size            = "20480"
  guest_os_type        = "Linux_64"
  http_directory       = "http"
  iso_url              = "https://mirror.cpsc.ucalgary.ca/mirror/archlinux.org/iso/latest/archlinux-x86_64.iso"
  iso_checksum         = "sha256:0dbac20eddeef67d3b3e9c109a51b77140cf4ee33cc0b408181454f6c41d0a91"
  output_directory     = "output-virtualbox-iso-archvbox"
  shutdown_command     = "echo 'packer' | sudo -S shutdown -P now"
  ssh_timeout          = "20m"
  ssh_username         = "vagrant"
  ssh_password         = "vagrant"
  vboxmanage           = [
    ["modifyvm", "{{ .Name }}", "--memory", "4096"],
    ["modifyvm", "{{ .Name }}", "--cpus", "2"],
    ["modifyvm", "{{ .Name }}", "--firmware", "efi"],
    ["modifyvm", "{{ .Name }}", "--nat-localhostreachable1", "on"]
  ]
}

build {
  sources = ["source.virtualbox-iso.archvbox"]

  provisioner "shell" {
    inline = [
      "curl -fsSL https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub -o /home/vagrant/.ssh/authorized_keys",
      "chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys",
      "chmod 600 /home/vagrant/.ssh/authorized_keys",
      
      "sudo pacman --noconfirm -S virtualbox-guest-utils",
      "sudo systemctl enable vboxservice",
      
      "sudo ufw --force enable"
    ]
  }

  post-processor "vagrant" {
    keep_input_artifact = false
    output              = "arch-vagrant.box"
  }
}
