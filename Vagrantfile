Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"

  # CPU, Memory 설정
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 1
  end

  (1..3).each do |i|
    hostname = "server#{'%01d' % i}"
    config.vm.define "#{hostname}" do |node|
      node.vm.hostname = "#{hostname}"
      node.vm.network "private_network", ip: "192.168.56.#{100 + i}"
	  node.vm.provider "virtualbox" do |vb|
		vb.name = "server#{'%01d' % i}"
	  end
    end
  end

  shell_provision_configs = [
	{
	  "name" => "set-hosts",
	  "path" => "scripts/set-hosts.sh"
	},
	{
	  "name" => "set-user-key",
	  "path" => "scripts/set-user-key.sh"
	},
	{
	  "name" => "install-essential-tools",
	  "path" => "scripts/install-essential-tools.sh"
	},
	{
	  "name" => "install-docker",
	  "path" => "scripts/install-docker.sh"
	},
	{
	  "name" => "change-vagrant-passwd",
	  "path" => "scripts/change-vagrant-passwd.sh"
	}
  ] 

  shell_provision_configs.each do |cfg|
	config.vm.provision "shell" do |s|
	  s.name = cfg["name"]
	  s.path = cfg["path"]
	  s.privileged = cfg["privileged"] ? cfg["privileged"] : true
	  s.args = cfg["args"] ? cfg["args"] : []
	end
  end
end


