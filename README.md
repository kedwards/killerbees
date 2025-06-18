# Killer Bees - Docker Swarm Infrastructure Project

The **Killer Bees** project is a comprehensive infrastructure automation solution that demonstrates building and managing a Docker Swarm cluster with high availability, load balancing, and distributed storage. This project uses modern DevOps tools to create a production-ready container orchestration environment suitable for development labs and scalable to production use.

## 🏗️ Project Architecture

This project provides a complete Docker Swarm setup featuring:

- **3-node Docker Swarm cluster** with high availability
- **Layer 7 routing** with Traefik for automatic service discovery
- **Distributed file system** using GlusterFS for persistent container volumes
- **Load balancing** with HAProxy for SSL offloading and traffic distribution
- **Web UI management** with Portainer for Docker Swarm administration

## 📁 Project Structure

The Killer Bees project is organized into three main components:

### 🔧 [Ansible](./ansible/README.md)
Infrastructure automation and configuration management for the Docker Swarm cluster.
- Automated deployment of Docker Swarm, GlusterFS, Traefik, and HAProxy
- Service configuration and management playbooks
- Inventory management for different environments

### 📦 [Packer](./packer/README.md)
Base VM image creation for consistent infrastructure deployment.
- Automated Debian 12 base box creation for Vagrant
- Support for VirtualBox and KVM virtualization platforms
- Customizable preseed configurations for unattended installations

### 🖥️ [Vagrant](./vagrant/README.md)
Local development environment provisioning and testing.
- Multi-machine Vagrant setup for complete cluster simulation
- Automated VM provisioning with proper networking and storage
- Integration with Ansible for seamless development workflows

## 🚀 Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd killerbees
   ```

2. **Set up your environment**
   - Follow the setup instructions in each component's README
   - Install required dependencies (Ansible, Vagrant, Packer)

3. **Choose your deployment method**
   - **Development**: Use the [Vagrant setup](./vagrant/README.md) for local testing
   - **Production**: Use the [Ansible playbooks](./ansible/README.md) directly on your infrastructure
   - **Custom Images**: Use [Packer](./packer/README.md) to build custom base images

## 🛠️ Technologies Used

- **Docker & Docker Swarm**: Container orchestration and clustering
- **GlusterFS**: Distributed filesystem for persistent storage
- **Traefik**: Layer 7 reverse proxy with automatic service discovery
- **HAProxy**: Load balancer and SSL termination
- **Portainer**: Web-based Docker management interface
- **Ansible**: Infrastructure automation and configuration management
- **Vagrant**: Development environment provisioning
- **Packer**: Automated machine image creation

## 🎯 Use Cases

- **Development Labs**: Complete containerized application development environment
- **Learning Platform**: Hands-on experience with container orchestration concepts
- **Production Foundation**: Scalable base for production Docker Swarm deployments
- **High Availability Testing**: Test application behavior in a clustered environment

## 📚 Documentation

Each component has detailed documentation in its respective directory:

- **[Ansible Documentation](./ansible/README.md)** - Infrastructure automation and deployment
- **[Packer Documentation](./packer/README.md)** - Base image creation and customization
- **[Vagrant Documentation](./vagrant/README.md)** - Local development environment setup

## 🤝 Requirements

- Linux/macOS development environment
- Ansible CLI utilities
- Vagrant (for local development)
- VirtualBox or KVM (for virtualization)
- Sufficient resources for multi-VM deployment

## ⚡ Next Steps

1. Review the component-specific README files for detailed setup instructions
2. Choose your deployment strategy based on your use case
3. Follow the quick start guide for your chosen approach
4. Explore the example applications and deployment patterns

## 🔗 Related Resources

- [Docker Swarm Documentation](https://docs.docker.com/engine/swarm/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [GlusterFS Documentation](https://docs.gluster.org/)
- [Ansible Documentation](https://docs.ansible.com/)

---

**Note**: This project is designed for educational and development purposes. For production deployments, additional security hardening and operational considerations should be implemented.

