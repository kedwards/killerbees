# Debian 12 Vagrant Base Box Builder

This script automates the creation of a **Debian 12** base box for [Vagrant](https://www.vagrantup.com/) using [Packer](https://www.packer.io/). It supports both **VirtualBox** and **KVM** as build targets and is intended for automated, non-interactive builds.

---

## 📋 Requirements

- Linux system with:
  - `bash`, `sed`, `sha256sum`, `date`, `ssh-keygen`
  - [`packer`](https://developer.hashicorp.com/packer/install)
  - [`vagrant`](https://developer.hashicorp.com/vagrant/downloads)
- Debian 12 Netinst ISO (e.g., `debian-12.11.0-amd64-netinst.iso`)
- The following directories and templates:
  - `template/preseed-debian-12-template.cfg`
  - `template/vagrant-debian-12-template.pkr.hcl`

---

## ⚙️ Inputs (via CLI flags)

| Flag              | Description                                                           | Default                                                  |
|-------------------|------------------------------------------------------------------------|----------------------------------------------------------|
| `--mirror`        | Debian mirror URL                                                      | `http://ftp.ca.debian.org`                               |
| `--mirror-dir`    | Mirror directory                                                       | `/debian`                                                |
| `--ssh-key`       | Path to SSH public key injected into VM                                | `$HOME/.ssh/vagrant.id_rsa.pub`                          |
| `--iso`           | Path to Debian Netinst ISO                                             | `$HOME/Downloads/debian-12.11.0-amd64-netinst.iso`       |
| `--box-output`    | Directory to store the generated `.box` file                           | `$HOME/vagrant/boxes`                                    |
| `--target`        | Virtualization backend: `vbox` or `kvm` (**required**)                 | _(none — must be explicitly specified)_                  |

---

## 📦 Outputs

- `http/preseed.cfg`: Custom preseed file for automated installation
- `vagrant-debian-12.pkr.hcl`: Generated Packer build config
- `debian-12-<timestamp>.box`: Final Vagrant box (in `box-output` directory)
- `debian-12-<timestamp>.box.json`: Metadata file for `vagrant box add`
- `Vagrantfile`: Sample file for local testing via `vagrant up`
- Box is automatically added to the local Vagrant environment

Timestamp format: `YYYYMMDDHHMM` (e.g., `debian-12-202506181745.box`)

---

## 🚀 Example Usage

### Build with VirtualBox

```bash
./build-debian12-box.sh \
  --mirror http://ftp.ca.debian.org \
  --mirror-dir /debian \
  --ssh-key ~/.ssh/vagrant.id_rsa.pub \
  --iso ~/Downloads/debian-12.11.0-amd64-netinst.iso \
  --box-output ~/vagrant/boxes \
  --target vbox
```

### Build with KVM

```bash
./build-debian12-box.sh \
  --target kvm \
  --iso ~/Downloads/debian-12.11.0-amd64-netinst.iso
```

## 🔐 SSH Key Notes

The script expects a pre-existing SSH key pair. You can generate one manually if needed:

```bash
ssh-keygen -t rsa -b 2048 -f ~/.ssh/vagrant.id_rsa -N ''
```

The public key (e.g., `vagrant.id_rsa.pub`) will be injected into the VM for passwordless SSH access.

## 🧪 Testing the Box

A Vagrantfile is generated automatically. To launch a VM from the box:

```bash
vagrant up
```

To remove the box:

```bash
vagrant box remove debian-12-<timestamp>
```

## ❓ FAQ
Why is SSH key creation skipped?

To ensure the script runs unattended and to avoid overwriting existing keys. You must provide a valid SSH key path via --ssh-key. This design supports CI/CD workflows and scripting.
Can I use this with other Debian versions?


This script is tailored for Debian 12 and may require template changes for other versions.
