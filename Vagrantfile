# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

#INSTANCE_TYPE = "t1.large"
INSTANCE_TYPE = "t1.micro"
AWS_REGION = ENV["AWS_DEFAULT_REGION"] || "eu-west-1"
AWS_ZONE = "eu-west-1b"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.define "local" do |local|
    local.vm.box = "precise64"
    local.vm.network :forwarded_port, host: 4567, guest: 80
    local.vm.provision :shell, :path => "bootstrap.sh"
  end

  config.vm.define "aws" do |awsbox|
    awsbox.vm.box = "dummy"
    awsbox.vm.provision :shell, :path => "bootstrap.sh"

    awsbox.vm.provider :aws do |aws, override|
      aws.access_key_id = ENV["AWS_ACCESS_KEY_ID"]
      aws.secret_access_key = ENV["AWS_SECRET_ACCESS_KEY"]
      aws.keypair_name = ENV["AWS_KEYPAIR_NAME"]
      override.ssh.private_key_path = ENV["AWS_SSH_PRIVKEY"]
      override.ssh.username = "ubuntu"
      aws.region = AWS_REGION
      aws.availability_zone = AWS_ZONE
      aws.ami    = "ami-07cb2670"
      aws.instance_type = INSTANCE_TYPE
      aws.security_groups = ['Deploy']
      aws.tags = {"Name" => "Registry poc"}
    end
  end

end