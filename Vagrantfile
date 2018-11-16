# frozen_string_literal: true

required_plugins = %w[
  vagrant-puppet-install
  vagrant-aws
]
plugins_to_install = required_plugins.select do |plugin|
  not Vagrant.has_plugin? plugin
end
unless plugins_to_install.empty?
  puts "Installing plugins: #{plugins_to_install.join(' ')}"
  system "vagrant plugin install #{plugins_to_install.join(' ')}"
  exec "vagrant #{ARGV.join(' ')}"
end

TF_DIR = "#{__dir__}/tf"
tf_data = {}
Dir.chdir(TF_DIR) do
  output = JSON.parse(`./bin/terraform output -json`)
  output.each do |k, v|
    # install tf output values as constants
    value = v['value']
    Object.const_set(k.upcase, value)

    # create a sanitized hash
    tf_data[k] = value
  end
end

def gen_hostname(boxname)
  "jenkins-#{boxname}"
end

def ci_hostname(hostname, provider, role = nil)
  provider.user_data = <<~CC
    #cloud-config
    hostname: #{hostname}
    fqdn: #{hostname}.#{JENKINS_INTERNAL_DOMAIN}
    manage_etc_hosts: true
    write_files:
      - path: /etc/facter/facts.d/role.txt
        owner: root:root
        permissions: '0644'
        content: "role=#{role}"
  CC
end

def el7_nodes
  (1..8)
end

def ssh_private_key_path
  "#{__dir__}/jenkins_demo/templates/id_rsa"
end

def master_ami
  # us-east-1 centos 1805_01 (2018-06-12)
  ENV['MASTER_AMI'] || 'ami-9887c6e7'
end

def centos7_ami
  ENV['CENTOS7_AMI'] || master_ami
end

Vagrant.configure('2') do |config|
  config.vm.define 'master', primary: true do |define|
    hostname = gen_hostname('master')
    define.vm.hostname = hostname

    define.vm.provider :aws do |provider, _override|
      ci_hostname(hostname, provider, 'master')

      provider.ami = master_ami
      provider.private_ip_address = JENKINS_MASTER_INTERNAL_IP
      provider.elastic_ip = JENKINS_IP
      provider.security_groups = [
        SECURITY_GROUP_ID_INTERNAL,
        SECURITY_GROUP_ID_SSH,
        SECURITY_GROUP_ID_HTTP,
        SECURITY_GROUP_ID_SLAVEPORT,
      ]
      provider.instance_type = 'c5.xlarge'
      provider.tags = {
        'Name'     => hostname,
        'env_name' => ENV_NAME,
      }
      provider.block_device_mapping = [{
        'DeviceName'              => '/dev/sda1',
        # 200GiB is over kill but this is the size of the el7.1 ami in use
        'Ebs.VolumeSize'          => 200,
        'Ebs.VolumeType'          => 'gp2',
        'Ebs.DeleteOnTermination' => 'true',
      }]
    end
  end

  el7_nodes&.each do |agent_id|
    config.vm.define "el7-#{agent_id}" do |define|
      hostname = gen_hostname("el7-#{agent_id}")
      define.vm.hostname = hostname

      define.vm.provider :aws do |provider, _override|
        ci_hostname(hostname, provider, 'agent')

        provider.ami = centos7_ami
        provider.tags = {
          'Name'     => hostname,
          'env_name' => ENV_NAME,
        }
        provider.block_device_mapping = [{
          'DeviceName'              => '/dev/sda1',
          'Ebs.VolumeSize'          => 1500,
          'Ebs.VolumeType'          => 'gp2',
          'Ebs.DeleteOnTermination' => 'true',
        }]
      end
    end
  end

  config.vm.define 'snowflake-1' do |define|
    hostname = gen_hostname('snowflake-1')
    define.vm.hostname = hostname

    define.vm.provider :aws do |provider, _override|
      ci_hostname(hostname, provider, 'snowflake')

      provider.ami = centos7_ami
      provider.tags = {
        'Name'     => hostname,
        'env_name' => ENV_NAME,
      }
      provider.block_device_mapping = [{
        'DeviceName'              => '/dev/sda1',
        'Ebs.VolumeSize'          => 500,
        'Ebs.VolumeType'          => 'gp2',
        'Ebs.DeleteOnTermination' => 'true',
      }]
      provider.instance_type = 'm4.xlarge'
    end
  end

  # setup the remote repo needed to install a current version of puppet
  config.puppet_install.puppet_version = '5.5.6'

  config.vm.provision 'puppet', type: :puppet do |puppet|
    puppet.hiera_config_path = 'hiera.yaml'
    puppet.environment_path  = 'environments'
    puppet.environment       = 'jenkins'
    puppet.manifests_path    = 'environments/jenkins/manifests'
    puppet.manifest_file     = 'default.pp'
    # puppet does not allow uppercase variables
    puppet.facter            = tf_data

    puppet.options = [
      '--verbose',
      '--trace',
      '--report',
      '--show_diff',
      '--disable_warnings=deprecations',
    ]
  end

  # cleanup hiera data
  config.vm.provision 'shell', inline: 'rm -rf /tmp/vagrant-puppet/hieradata'

  config.vm.provider :aws do |provider, override|
    override.vm.box = 'aws'
    override.vm.box_url = 'https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box'
    # http://blog.damore.it/2015/01/aws-vagrant-no-host-ip-was-given-to.html
    override.nfs.functional = false
    override.vm.synced_folder '.', '/vagrant', disabled: true
    override.vm.synced_folder 'hieradata/', '/tmp/vagrant-puppet/hieradata'
    override.ssh.private_key_path = ssh_private_key_path
    override.ssh.username = 'centos'
    provider.keypair_name = ENV_NAME
    provider.access_key_id = ENV['AWS_ACCESS_KEY_ID']
    provider.secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
    provider.region = AWS_DEFAULT_REGION
    provider.availability_zone = "#{AWS_DEFAULT_REGION}c"
    provider.subnet_id = SUBNET_ID
    provider.associate_public_ip = true
    provider.security_groups = [
      SECURITY_GROUP_ID_INTERNAL,
      SECURITY_GROUP_ID_SSH,
    ]
    provider.instance_type = 'c5.2xlarge'
    provider.ebs_optimized = true
    provider.monitoring = true
    provider.instance_package_timeout = 36_600
  end

  if Vagrant.has_plugin?('vagrant-librarian-puppet')
    config.librarian_puppet.placeholder_filename = '.gitkeep'
    config.librarian_puppet.puppetfile_dir = 'environments/jenkins/modules'
    config.librarian_puppet.destructive = false
  end

  config.cache.disable! if Vagrant.has_plugin?('vagrant-cachier')
end

# -*- mode: ruby -*-
# vi: set ft=ruby :
