# registry-deploy-env

Provides configuration, UI templates and bootstraping for the Environment Registry.

This is a manual fork of UKGovLD/registry-deploy-poc

This provides vagrant and aws scripts to simplify creation and management of registry instances.

## Prerequisites 

Install vagrant: (make sure it is at least 1.4.1)

    http://downloads.vagrantup.com/

Install vagrant aws tools:

    vagrant plugin install vagrant-aws
    vagrant box add dummy https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box

Install aws python command line tools:

    sudo apt-get install python-pip
    sudo pip install awscli
    complete -C aws_completer aws

Install jq:

    http://stedolan.github.io/jq/download/

For local virtual machines you will also need VirtualBox:

    https://www.virtualbox.org/wiki/Downloads

and a Ubuntu box:

    vagrant box add precise64 http://files.vagrantup.com/precise64.box

For check/berkshelf:

    vagrant plugin install vagrant-berkshelf    

## Creating a local virtual machine instance

    vagrant up local

You can then log into the instance with:

    vagrant ssh local

The http port onto the local instance is mapped to port 4567 on your local machine so pointing a web browser at `http://localhost:4567/registry/` should show the launched registry instance.

Destroy it with:

    vagrant destroy local

## Amazon EC2 instances

### AWS credentials

To create an AWS instance you need an appropriate set of credentials.

First create a security group called `Deploy` which provides access to ssh, http and https.

Second ensure you have an installed key pair and a user who has access to that key pair.

Third create a credentials file which can be used to set the shell environment variables needed by the later scripts. This should look like:

	export AWS_ACCESS_KEY_ID=XXX
	export AWS_SECRET_ACCESS_KEY=YYY
	export AWS_DEFAULT_REGION=eu-west-1

	export AWS_KEYPAIR_NAME=keyname
	export AWS_SSH_PRIVKEY=/home/user/.ssh/keyname.pem

### Provision an instance

The AWS configuration is designed so that the run time registry information is kept on a separate EBS volume for ease of backup. This complicates the provisioning steps. 

First select or create an EBS volume to use. This might be created from a prior snapshot or might be a brand new volume. Then launch the instance with

    . mycredentials.cred
    vagrant up aws --provider=aws  --no-provision
    ./attach-volume.sh VOLUMEID
    vagrant provision aws

If the last step fails to rsync (warning about `mkdir -p /vagrant`) then can manually fix with:

    vagrant ssh aws
    # echo 'Defaults:ec2-user !requiretty' > /etc/sudoers.d/999-vagrant-cloud-init-requiretty && chmod 440 /etc/sudoers.d/999-vagrant-cloud-init-requiretty
    # exit
