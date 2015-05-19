Jenkins LSST Stack Demo
=======================

Prerequisites
-------------

* Vagrant 1.7.x
* `git` - needed to clone this repo


Vagrant plugins
---------------

These are required:

* vagrant-puppet-install
* vagrant-librarian-puppet '~> 0.9.0'
* vagrant-aws '~> 0.7.0'

Sandbox
-------
    export AWS_ACCESS_KEY_ID=<...>
    export AWS_SECRET_ACCESS_KEY=<...>
    export AWS_REGION=us-east-1

    git clone -b builder/aws https://github.com/jhoblitt/bento.git
    cd bento
    mkdir bin
    cd bin
    wget https://dl.bintray.com/mitchellh/packer/packer_0.7.5_linux_amd64.zip
    unzip packer_0.7.5_linux_amd64.zip
    cd ../packer

    # centos 6 x86_64 HVM https://aws.amazon.com/marketplace/pp/B00NQAYLWO
    sed -i -e "s/us-west-2/${AWS_REGION}/" centos-6.6-x86_64.json
    sed -i -e "s/ami-81d092b1/ami-c2a818aa/" centos-6.6-x86_64.json

    # centos 7 x86_64 HVM https://aws.amazon.com/marketplace/pp/B00O7WM7QW
    sed -i -e "s/us-west-2/${AWS_REGION}/" centos-7.1-x86_64.json
    sed -i -e "s/ami-c7d092f7/ami-96a818fe/" centos-7.1-x86_64.json

    # sanity check
    git diff
    ../bin/packer build --only=amazon-ebs centos-6.6-x86_64.json
==> Builds finished. The artifacts of successful builds are:
--> amazon-ebs: AMIs were created:

us-east-1: ami-92ccd2fa
--> amazon-ebs: 'aws' provider box: ../builds/aws/opscode_centos-6.6_chef-provisionerless.box

    ../bin/packer build --only=amazon-ebs centos-7.1-x86_64.json

==> Builds finished. The artifacts of successful builds are:
--> amazon-ebs: AMIs were created:

us-east-1: ami-feccd296
--> amazon-ebs: 'aws' provider box: ../builds/aws/opscode_centos-7.1_chef-provisionerless.box

    export CENTOS6_AMI=ami-92ccd2fa
    export CENTOS7_AMI=ami-feccd296
    export MASTER_AMI=$CENTOS7_AMI
    cd ..

    git clone git@github.com:jhoblitt/sandbox-jenkins-demo.git
    cd sandbox-jenkins-demo

    cd terraform
    make

    export TF_VAR_aws_access_key=$AWS_ACCESS_KEY_ID
    export TF_VAR_aws_secret_key=$AWS_SECRET_ACCESS_KEY
    export TF_VAR_aws_region=$AWS_REGION

    ./bin/terraform plan
    ./bin/terraform apply

Example output.

    ...
    Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

    The state of your infrastructure has been saved to the path
    below. This state is required to modify and destroy your
    infrastructure, so keep it safe. To inspect the complete state
    use the `terraform show` command.

    State path: terraform.tfstate

    Outputs:

      ELASTIC_IP                 = 52.6.202.20
      SECURITY_GROUP_ID_HTTP     = sg-3a163c5e
      SECURITY_GROUP_ID_INTERNAL = sg-05163c61
      SECURITY_GROUP_ID_SSH      = sg-39163c5d
      SUBNET_ID                  = subnet-30397947

Cut'n'paste the variable outputs into `terraform/aws.rb`

cat > aws.rb <<END
ELASTIC_IP                 = '52.6.202.20'
SECURITY_GROUP_ID_HTTP     = 'sg-3a163c5e'
SECURITY_GROUP_ID_INTERNAL = 'sg-05163c61'
SECURITY_GROUP_ID_SSH      = 'sg-39163c5d'
SUBNET_ID                  = 'subnet-30397947'
END


    vagrant plugin install vagrant-puppet-install
    vagrant plugin install vagrant-librarian-puppet --plugin-version '~> 0.9.0'
    vagrant plugin install vagrant-aws --plugin-version '~> 0.6.0'

    # sanity check
    vagrant plugin list

    export VAGRANT_DEFAULT_PROVIDER='aws'
    export VAGRANT_NO_PARALLEL='yes'
    vagrant up
