# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

#INSTANCE_TYPE = "t1.large"
INSTANCE_TYPE = "t1.micro"
AWS_REGION = ENV["AWS_DEFAULT_REGION"] || "eu-west-1"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "precise64"
  config.vm.network :forwarded_port, host: 4567, guest: 80
  config.vm.provision :shell, :path => "bootstrap.sh"
end