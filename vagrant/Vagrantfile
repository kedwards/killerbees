require 'yaml'

VAGRANTFILE_API_VERSION = "2"
VAGRANT_ROOT = File.dirname(File.expand_path(__FILE__))

# load configs
def load_config
  config = nil
  (['config.default.yml', 'config.yml']).each do |config_file|
    config_file = File.join(File.dirname(__FILE__), config_file)
    if File.exist?(config_file)
      config = YAML.load_file(config_file, aliases: true)
    end
  end

  if config.nil?
    puts "No configuration found"
    exit 1
  elsif config[config['use']].nil?
    puts "No configuration for #{config['use']}"
    exit 1
  end

  # install plugins
  # plugins are init and loaded in the order they are defined
  def install_plugins(plugins)
    plugin_status = false
    plugins.each do |plugin_name|
      unless Vagrant.has_plugin? plugin_name
        system("vagrant plugin install #{plugin_name}")
        plugin_status = true
        puts " #{plugin_name} Dependencies installed"
      end
    end
    if plugin_status === true
      exec "vagrant #{ARGV.join" "}"
    end
  end

  install_plugins(config['plugins'])
  return config[config['use']]
end  

# get provisioners
def get_provisioners(cfg)
  provisioner = false
  provisioner_grp_index = nil
  cfg.each_with_index do |grp, grp_index|
    if grp['type'] == 'provisioner'
      provisioner = true
      provisioner_grp_index = grp_index
      break
    end
  end
  return provisioner, provisioner_grp_index
end

cfg = load_config
provisioner, provisioner_grp_index = get_provisioners(cfg)

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.manage_guest = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = false
  config.ssh.insert_key = false
   
  ansible_groups = {}
  ansible_group = nil
  ansible_group_name = nil
  group_count = cfg.count
   
  cfg.each_with_index do |grp, grp_index|
    grp_num_nodes = nil

    if grp['name'].nil?
      puts "Error - each group requires a 'name' value, see config.sample.yml"
      exit 1
    end

    if not grp['nodes'].nil? and grp['nodes'] > 0
      if not grp['ansible_group'].nil?
        ansible_group = []
        ansible_group_name = grp['ansible_group']
      end
      
      vm_name_prefix = grp['name_prefix'] || 'box'
      vm_box = grp['box'] || 'ubuntu/bionic64'
      guest_ipaddr_prefix = grp['ip_addr_prefix'] || '10.10.56.'
      gui = grp['gui'] || false
      os_disk_size = grp['os_disk_size'] || '20GB'
      netmask = grp['netmask'] || "255.255.255.0"
      check_guest_additions = grp['check_guest_additions'] || false
      memory = grp['memory'] || 512
      cpus = grp['cpus'] || 1

      disks = grp['disks'].to_i
      disk_size = grp['disk_size'].to_i

      (1..grp['nodes']).each_with_index do |node, node_index|
        vm_name = "%s%02d" % [vm_name_prefix, node]
        guest_ipaddr = guest_ipaddr_prefix + (node + 1).to_s
        ansible_config_value = (grp['ansible_use'] == 'name') ? vm_name : guest_ipaddr

        # collect group information for ansible inventory provisioning
        # the last node will close the group
        if (grp['nodes'] - 1) == node_index
          ansible_group << ansible_config_value
          ansible_groups[ansible_group_name] = ansible_group
        else
          ansible_group << ansible_config_value
        end

        config.vm.define vm_name do |srv|
          srv.ssh.forward_agent = true
          srv.vm.box = vm_box
          srv.vm.hostname = vm_name
          srv.disksize.size = os_disk_size
          srv.vm.network "private_network", ip: guest_ipaddr, netmask: netmask

          srv.vm.provider :virtualbox do |vb, override|
            vb.name = vm_name
            vb.gui = gui
            vb.check_guest_additions = check_guest_additions

            # convienience shortcuts for memory and cpu
            vb.memory = memory
            vb.cpus = cpus

            if not grp['customize'].nil?
              (grp['customize']).each_with_index do |customize, customize_index|
                vb.customize ["modifyvm", :id, "#{customize['command']}", "#{customize['value']}"]
              end
            end

            (1..disks).each do |k|
              # Get disk path
              line = `VBoxManage list systemproperties | grep "Default machine folder"`
              vb_machine_folder = line.split(':')[1].strip()
              next_disk = File.join(vb_machine_folder, "#{vm_name}", "disk#{k}.vdi")

              unless File.exist?(next_disk)
                vb.customize ['createhd', '--filename', next_disk, '--size', disk_size * 1024]
              end
              vb.customize ['storageattach', :id, '--storagectl', grp['disk_type'], '--port', k+1, '--device', 0, '--type', 'hdd', '--medium', next_disk]
            end

            if not grp['usb'].nil?
              grp['usb'].each do |usb, index|
                vb.customize ["modifyvm", :id, "--usb", "on"]
                vb.customize ['usbfilter', 'add', "#{index}", '--target', :id, '--name', "#{usb['name']}", '--vendorid', "#{usb['vendorid']}", '--productid', "#{usb['productid']}"]
              end
            end
          end
          if not provisioner_grp_index.nil? and (provisioner_grp_index - 1) == grp_index and (grp['nodes'] - 1) == node_index
            cfg[provisioner_grp_index]['provisioners'].each do |p|
              case p['type']
              when 'hostsmanager'
                config.hostmanager.enabled = true
                config.hostmanager.manage_host = true
                config.hostmanager.manage_guest = true
                config.hostmanager.ignore_private_ip = false
                config.hostmanager.include_offline = false
              when 'vai'
                srv.vm.provision :vai do |vai|
                  if not p['path'].nil?
                    vai.inventory_dir = p['path']
                  end
                  if not p['filename'].nil?
                    vai.inventory_filename = p['filename']
                  end
                  if not ansible_groups.nil?
                    vai.groups = ansible_groups
                  end
                end
              when 'ansible'
                srv.vm.provision p['type'] do |a|
                  a.playbook = p['playbook']
                  a.config_file = p['config_file']
                  a.verbose = true
                  if not p['hosts'].nil?
                    a.limit = p['hosts']
                  end
                  if not p['inventory_path'].nil?
                    a.inventory_path = p['inventory_path']
                  end
                end
              when 'shell'
                srv.vm.provision p['type'], inline: p['script'], privileged: true
              end
            end
          end
        end
      end
    end
  end
end
