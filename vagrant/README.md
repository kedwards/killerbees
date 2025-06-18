# Vagrant - Local Development Environment

This directory contains Vagrant configuration for setting up a complete Docker Swarm development environment locally. The Vagrant setup creates multiple VMs that simulate the full production architecture, making it perfect for development, testing, and learning.

## 🏗️ Environment Overview

The Vagrant environment creates a multi-machine setup featuring:

- **1 HAProxy Node**: Front-end load balancer with SSL offloading
- **3 Docker Swarm Manager Nodes**: High availability swarm cluster
- **3 Docker Swarm Worker Nodes** (optional): Additional compute capacity
- **Integrated networking**: Private network for inter-node communication
- **Automatic provisioning**: Integration with Ansible for service deployment

## 📋 Requirements

### Host System Requirements
- **RAM**: 8GB+ (VMs use 512MB each by default)
- **CPU**: 4+ cores recommended
- **Disk**: 20GB+ free space for VM storage
- **Virtualization**: VT-x/AMD-V enabled in BIOS

### Software Dependencies
- **[Vagrant](https://www.vagrantup.com/)**: VM provisioning tool
- **[VirtualBox](https://www.virtualbox.org/)**: Virtualization platform
- **[Ansible](https://www.ansible.com/)**: Configuration management (for provisioning)

### Required Vagrant Plugins
The following plugins will be automatically installed when you run `vagrant up`:
- **vagrant-disksize**: Allows resizing of VM disks
- **vai**: Generates Ansible inventory from Vagrant
- **vagrant-hostmanager**: Manages /etc/hosts files across VMs

## 🚀 Installation & Setup

### 1. Install Prerequisites

**For macOS with Homebrew:**
```bash
brew install vagrant virtualbox ansible
```

**For Ubuntu/Debian:**
```bash
# VirtualBox
sudo apt update
sudo apt install virtualbox

# Vagrant
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vagrant

# Ansible
sudo apt install ansible
```

### 2. Configure the Environment

Review and customize the configuration in `config.yml`:

```yaml
---
use: swarm  # Configuration set to use

vm: &vm-defaults
  box: 'kedwards/debian12'  # Base box (can be changed)
  memory: 512              # RAM per VM in MB
  cpus: 1                  # CPU cores per VM
  disks: 1                 # Number of additional disks
  disk_size: 10            # Size of additional disks in GB
  ip_addr_prefix: 192.168.56.  # IP range for VMs

swarm:
  - description: HA Proxy
    name_prefix: haproxy
    nodes: 1
    ansible_group: proxy_nodes
    
  - description: Swarm Managers  
    name_prefix: manager
    nodes: 3
    ip_addr_prefix: 192.168.56.1
    ansible_group: swarm_managers
    
  - description: Worker Nodes
    name_prefix: worker
    nodes: 3
    ip_addr_prefix: 192.168.56.2
    ansible_group: swarm_workers
```

## 🖥️ VM Management

### Start the Environment

```bash
# Start all VMs and provision with Ansible
vagrant up

# Start specific VMs only
vagrant up haproxy01 manager01 manager02
```

### Manage Individual VMs

```bash
# Check status of all VMs
vagrant status

# SSH into a specific VM
vagrant ssh manager01

# Stop all VMs
vagrant halt

# Stop specific VMs
vagrant halt worker01 worker02

# Restart VMs
vagrant reload

# Destroy all VMs
vagrant destroy -f
```

### Resource Management

```bash
# Show resource usage
vagrant status

# Suspend VMs (saves state)
vagrant suspend

# Resume suspended VMs
vagrant resume
```

## 🔧 Configuration Details

### Network Configuration

The Vagrant setup creates a private network with the following IP assignments:

| Node Type | Hostname | IP Address | Role |
|-----------|----------|------------|------|
| HAProxy | haproxy01 | 192.168.56.10 | Load Balancer |
| Manager | manager01 | 192.168.56.11 | Swarm Leader |
| Manager | manager02 | 192.168.56.12 | Swarm Manager |
| Manager | manager03 | 192.168.56.13 | Swarm Manager |
| Worker | worker01 | 192.168.56.21 | Swarm Worker |
| Worker | worker02 | 192.168.56.22 | Swarm Worker |
| Worker | worker03 | 192.168.56.23 | Swarm Worker |

### Storage Configuration

Each VM is configured with:
- **Primary disk**: 20GB (OS and applications)
- **Secondary disk**: 10GB (for GlusterFS volumes)
- **Disk type**: SATA (configurable to IDE/SCSI)

### Host Integration

Vagrant automatically:
- Updates your local `/etc/hosts` file with VM hostnames
- Manages VM `/etc/hosts` files for inter-node communication
- Generates Ansible inventory for provisioning

## 🔄 Provisioning Process

### Automatic Provisioning

When you run `vagrant up`, the following happens automatically:

1. **VM Creation**: All VMs are created with specified resources
2. **Network Setup**: Private network and hostname resolution configured
3. **Inventory Generation**: Ansible inventory created automatically
4. **Service Deployment**: Ansible playbooks run to install Docker Swarm infrastructure

### Manual Provisioning

You can also run provisioning manually:

```bash
# Re-run Ansible provisioning on all VMs
vagrant provision

# Run provisioning on specific VMs
vagrant provision manager01

# Run specific Ansible playbooks
cd ../ansible
ansible-playbook --inventory-file=inventory/hosts-vagrant playbooks/install.yml
```

## 🎯 Development Workflow

### Typical Development Session

1. **Start Environment**
   ```bash
   vagrant up
   ```

2. **Access Services**
   - Traefik: http://traefik.docker.local
   - Portainer: http://portainer.docker.local
   - HAProxy Stats: http://192.168.56.10/stats

3. **Deploy Test Applications**
   ```bash
   vagrant ssh manager01
   docker stack deploy --compose-file=test-app.yml testapp
   ```

4. **Development and Testing**
   - Make changes to your applications
   - Test in the swarm environment
   - Iterate and refine

5. **Cleanup**
   ```bash
   vagrant halt  # or vagrant destroy -f
   ```

### Testing Scenarios

The Vagrant environment is perfect for testing:

- **High Availability**: Kill manager nodes and verify swarm continues
- **Load Balancing**: Deploy multiple service replicas and test distribution
- **Storage**: Test persistent volumes with GlusterFS
- **Networking**: Test service discovery and inter-service communication
- **Scaling**: Add/remove worker nodes dynamically

## 🛠️ Customization Options

### Changing VM Resources

Edit `config.yml` to adjust resources:

```yaml
vm: &vm-defaults
  memory: 1024     # Increase RAM to 1GB
  cpus: 2          # Use 2 CPU cores
  disk_size: 20    # Larger storage disks
```

### Using Different Base Boxes

```yaml
vm: &vm-defaults
  box: 'ubuntu/focal64'  # Use Ubuntu 20.04
  # or
  box: 'generic/debian11'  # Use Debian 11
```

### Modifying Network Configuration

```yaml
vm: &vm-defaults
  ip_addr_prefix: 10.0.1.  # Different IP range
  netmask: "255.255.255.0"
```

### Adding Custom Provisioning

You can add custom shell provisioning:

```ruby
# In Vagrantfile, add to VM configuration
config.vm.provision "shell", inline: <<-SHELL
  # Custom setup commands
  echo "Custom provisioning step"
SHELL
```

## 🔍 Troubleshooting

### Common Issues

**VMs won't start:**
```bash
# Check VirtualBox status
VBoxManage list runningvms

# Restart VirtualBox service (Linux)
sudo systemctl restart vboxdrv

# Check available resources
vagrant status
```

**Network connectivity issues:**
```bash
# Recreate host network
vagrant reload

# Check VM network configuration
vagrant ssh manager01 -c "ip addr show"
```

**Ansible provisioning fails:**
```bash
# Run Ansible manually with verbose output
cd ../ansible
ansible-playbook -vvv --inventory-file=inventory/hosts-vagrant playbooks/install.yml
```

**Performance issues:**
- Increase VM memory allocation in `config.yml`
- Close other resource-intensive applications
- Consider reducing the number of worker nodes for development

### Log Files

Check these locations for troubleshooting:
- Vagrant logs: `vagrant up` output
- VM console logs: VirtualBox Manager → VM → Show
- Ansible logs: Displayed during provisioning
- Application logs: SSH into VMs and check service logs

## 🔗 Integration with Other Components

### Ansible Integration
- Inventory automatically generated in `../ansible/inventory/vagrant_ansible_inventory`
- Playbooks can be run directly against Vagrant VMs
- Configuration changes tested locally before production deployment

### Packer Integration
- Base boxes can be created with Packer
- Custom images tested in Vagrant environment
- Standardized base configuration across development and production

## 📚 Related Documentation

- [Main Project README](../README.md)
- [Ansible Automation](../ansible/README.md)
- [Packer Base Images](../packer/README.md)
- [Vagrant Documentation](https://www.vagrantup.com/docs)
- [VirtualBox Documentation](https://www.virtualbox.org/manual/)

## 💡 Tips and Best Practices

1. **Resource Management**: Start with fewer workers for development, scale as needed
2. **Snapshots**: Take VirtualBox snapshots before major changes
3. **Port Conflicts**: Ensure no other services use the same ports (2200-2299)
4. **Development Cycle**: Use `vagrant halt/up` rather than `destroy/up` for faster iteration
5. **Host Performance**: Close VMs when not in use to free system resources

---

**Note**: This Vagrant setup is optimized for development and testing. Production deployments should use dedicated infrastructure or cloud resources.

