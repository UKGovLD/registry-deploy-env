# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

INSTANCE_TYPE = "m1.large"
#INSTANCE_TYPE = "t1.micro"
AWS_REGION = ENV["AWS_DEFAULT_REGION"] || "eu-west-1"
AWS_ZONE = "eu-west-1b"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

   # install the chef client and chef solo
   #config.omnibus.chef_version = :latest
   
   # enable berkshelf
   #config.berkshelf.enabled = false

   # N.B. 
   config.vm.define "local" do |local|
        local.vm.box = "centos-6.5"
        local.vm.box_url = "https://github.com/2creatives/vagrant-centos/releases/download/v6.5.1/centos65-x86_64-20131205.box"
        #local.vm.provision :chef_solo do |chef|
        #    chef.roles_path   = "roles"
        #    chef.run_list     = ["role[fuseki-server]"]
        #end
        local.vm.provision :shell, :path => "bootstrap.sh"
        local.vm.network :forwarded_port, host: 4567, guest: 80
   end

  config.vm.define "aws" do |awsbox|
    awsbox.vm.box = "dummy"
    awsbox.vm.provision :shell, :path => "bootstrap.sh"

    # Fix sudoers bug for Amazon/CentOS linux 
    config.ssh.pty = true

    awsbox.vm.provider :aws do |aws, override|
      aws.access_key_id = ENV["AWS_ACCESS_KEY_ID"]
      aws.secret_access_key = ENV["AWS_SECRET_ACCESS_KEY"]
      aws.keypair_name = ENV["AWS_KEYPAIR_NAME"]
      override.ssh.private_key_path = ENV["AWS_SSH_PRIVKEY"]
      override.ssh.username = "ec2-user"
      aws.region = AWS_REGION
      aws.availability_zone = AWS_ZONE
      aws.ami    = "ami-5256b825"
      aws.instance_type = INSTANCE_TYPE
      aws.security_groups = ['Deploy']
      aws.tags = {"Name" => "Registry env pilot"}
      #aws.user_data = "#!/bin/bash\necho 'Defaults:ec2-user !requiretty' > /etc/sudoers.d/999-vagrant-cloud-init-requiretty && chmod 440 /etc/sudoers.d/999-vagrant-cloud-init-requiretty\n"
    end
  end

end