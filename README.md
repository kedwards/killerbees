# Killerbees

# Host Requirements:

- [Vagrant](https://www.vagrantup.com/) - Development Environments Made Easy

- [Vai](https://github.com/cjsteel/vagrant-plugin-vai) - A Vagrant provisioning plugin to output a usable ]Ansible inventory to use outside Vagrant.

- [vbguest](https://github.com/dotless-de/vagrant-vbguest) -  A Vagrant plugin to keep your VirtualBox Guest Additions up to date

### inventory

```yml
# Generated by Vagrant

worker01 ansible_ssh_host=127.0.0.1 ansible_ssh_port=2203 ansible_ssh_private_key_file=/home/kedwards/dev/killerbees/vagrant/.vagrant/machines/worker01/virtualbox/private_key ansible_ssh_user=vagrant
worker02 ansible_ssh_host=127.0.0.1 ansible_ssh_port=2204 ansible_ssh_private_key_file=/home/kedwards/dev/killerbees/vagrant/.vagrant/machines/worker02/virtualbox/private_key ansible_ssh_user=vagrant
manager03 ansible_ssh_host=127.0.0.1 ansible_ssh_port=2202 ansible_ssh_private_key_file=/home/kedwards/dev/killerbees/vagrant/.vagrant/machines/manager03/virtualbox/private_key ansible_ssh_user=vagrant
proxy01 ansible_ssh_host=127.0.0.1 ansible_ssh_port=2222 ansible_ssh_private_key_file=/home/kedwards/dev/killerbees/vagrant/.vagrant/machines/proxy01/virtualbox/private_key ansible_ssh_user=vagrant
manager02 ansible_ssh_host=127.0.0.1 ansible_ssh_port=2201 ansible_ssh_private_key_file=/home/kedwards/dev/killerbees/vagrant/.vagrant/machines/manager02/virtualbox/private_key ansible_ssh_user=vagrant
manager01 ansible_ssh_host=127.0.0.1 ansible_ssh_port=2200 ansible_ssh_private_key_file=/home/kedwards/dev/killerbees/vagrant/.vagrant/machines/manager01/virtualbox/private_key ansible_ssh_user=vagrant

[proxy_nodes]
proxy01

[swarm_managers]
manager01
manager02
manager03

[gluster_nodes]
manager01
manager02
manager03

[swarm_workers]
worker01
worker02

[docker_nodes]
manager01
manager02
manager03
worker01
worker02

[docker:children]
proxy_nodes
docker_nodes
swarm_managers
swarm_workers
```

## Setup Docker Swarm with Ansible.

Ensure passwordless ssh is working:

```
$ ansible -i inventory.ini -u root -m ping all
client | SUCCESS => {
  "changed": false,
  "ping": "pong"
}
manager01| SUCCESS => {
  "changed": false,
  "ping": "pong"
}
worker02 | SUCCESS => {
  "changed": false,
  "ping": "pong"
}
worker01 | SUCCESS => {
  "changed": false,
  "ping": "pong"
}
```

## Deploy Docker Swarm

```
$ ansible-playbook -i inventory.ini -u root deploy-swarm.yml
PLAY RECAP

client               : ok=11   changed=3    unreachable=0    failed=0
manager01            : ok=18   changed=4    unreachable=0    failed=0
worker01             : ok=15   changed=1    unreachable=0    failed=0
worker02             : ok=15   changed=1    unreachable=0    failed=0
```

SSH to the Swarm Manager and List the Nodes:

```
$ docker node ls
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
0ead0jshzkpyrw7livudrzq9o *   manager01           Ready               Active              Leader              18.03.1-ce
iwyp6t3wcjdww0r797kwwkvvy     worker01            Ready               Active                                  18.03.1-ce
ytcc86ixi0kuuw5mq5xxqamt1     worker02            Ready               Active                                  18.03.1-ce
```

Create a Nginx Demo Service:

```
$ docker network create --driver overlay appnet
$ docker service create --name nginx --publish 80:80 --network appnet --replicas 6 nginx
$ docker service ls
ID                  NAME                MODE                REPLICAS            IMAGE               PORTS
k3vwvhmiqbfk        nginx               replicated          6/6                 nginx:latest        *:80->80/tcp

$ docker service ps nginx
ID                  NAME                IMAGE               NODE                DESIRED STATE       CURRENT STATE            ERROR               PORTS
tspsypgis3qe        nginx.1             nginx:latest        manager01           Running             Running 34 seconds ago
g2f0ytwb2jjg        nginx.2             nginx:latest        worker01            Running             Running 34 seconds ago
clcmew8bcvom        nginx.3             nginx:latest        manager01           Running             Running 34 seconds ago
q293r8zwu692        nginx.4             nginx:latest        worker02            Running             Running 34 seconds ago
sv7bqa5e08zw        nginx.5             nginx:latest        worker01            Running             Running 34 seconds ago
r7qg9nk0a9o2        nginx.6             nginx:latest        worker02            Running             Running 34 seconds ago
```

Test the Application:

```
$ curl -i http://192.168.1.10
HTTP/1.1 200 OK
Server: nginx/1.15.0
Date: Thu, 14 Jun 2018 10:01:34 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 05 Jun 2018 12:00:18 GMT
Connection: keep-alive
ETag: "5b167b52-264"
Accept-Ranges: bytes
```

## Delete the Swarm:

```
$ ansible-playbook -i inventory.ini -u root delete-swarm.yml

PLAY RECAP
manager01            : ok=2    changed=1    unreachable=0    failed=0
worker01             : ok=2    changed=1    unreachable=0    failed=0
worker02             : ok=2    changed=1    unreachable=0    failed=0
```

Ensure the Nodes is removed from the Swarm, SSH to your Swarm Manager:

```
$ docker node ls
Error response from daemon: This node is not a swarm manager. Use "docker swarm init" or "docker swarm join" to connect this node to swarm and try again.
```
