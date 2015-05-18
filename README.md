LSST Stack build sandbox
========================

Prerequisites
-------------

* Vagrant 1.7.x
* `git` - needed to clone this repo

Suggested
---------

Only required if you intended to run VMs locally (parallels or VMWare Fusion
are also options but not presently supported)

* VirtualBox (used by Vagrant)

SQRE credentials
----------------

    cd ~
    git clone ~/Dropbox/Josh-Frossie-share/git/sqre.git .sqre
    chmod 0700 .sqre
    ls -lad .sqre
    export SQRE_SANDBOX_GROUP=sqre

### VirtualBox && Vagrant Installation

OSX
---

### Install VirtualBox

```shell
# based on:
# http://slaptijack.com/system-administration/os-x-cli-install-virtualbox/
wget http://download.virtualbox.org/virtualbox/4.3.20/VirtualBox-4.3.20-96996-OSX.dmg
hdiutil mount VirtualBox-4.3.20-96996-OSX.dmg
sudo installer -package /Volumes/VirtualBox/VirtualBox.pkg -target /
hdiutil unmount /Volumes/VirtualBox
rm VirtualBox-4.3.20-96996-OSX.dmg
```

```shell
# sanity check
$ which VirtualBox
/usr/bin/VirtualBox
```

### Install Vagrant

```shell
wget https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.2.dmg
hdiutil mount vagrant_1.7.2.dmg
sudo installer -package /Volumes/Vagrant/Vagrant.pkg -target /
hdiutil unmount /Volumes/Vagrant
rm vagrant_1.7.2.dmg
```

```shell
# sanity check
$ which vagrant
/usr/bin/vagrant
```
### How to accept the Xcode License from the CLI

This step can be skipped if you have already accepted the Xcode license or
installed an unmolested version of `git`/etc..

If you see a warning like the following:

```shell
$ git


Agreeing to the Xcode/iOS license requires admin privileges, please re-run as root via sudo.
```

Run this command:
```shell
sudo xcodebuild -license accept
```

Then verify that the license warning is gone:
```shell
# sanity check
$ git --version
git version 1.8.5.2 (Apple Git-48)
```

Fedora 21
---------

### Install VirtualBox

```shell
# http://www.if-not-true-then-false.com/2010/install-virtualbox-with-yum-on-fedora-centos-red-hat-rhel/
cd /etc/yum.repos.d/
sudo wget http://download.virtualbox.org/virtualbox/rpm/fedora/virtualbox.repo

sudo yum install -y binutils gcc make patch libgomp glibc-headers glibc-devel kernel-headers kernel-devel dkms
sudo yum install -y VirtualBox-4.3
sudo service vboxdrv setup
sudo usermod -a -G vboxusers $USER
```

```shell
# sanity check
$ which VirtualBox
/usr/bin/VirtualBox
$ lsmod | grep -i box
vboxpci                23256  0 
vboxnetadp             25670  0 
vboxnetflt             27605  0 
vboxdrv               397320  6 vboxnetadp,vboxnetflt,vboxpci
```

### Install Vagrant

```shell
sudo yum install -y https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.2_x86_64.rpm
```

Sanity check
```shell
/usr/bin/vagrant
```

Vagrant plugins
---------------

These are required:

* vagrant-hostmanager
* vagrant-puppet-install
* vagrant-librarian-puppet '~> 0.9.0'

Needed for DigitalOcean

* vagrant-digitalocean '~> 0.7.3'

Needed for AWS EC2

* vagrant-aws '~> 0.7.0'

Suggested for usage with virtualbox:

* vagrant-cachier

Sandbox
-------

    vagrant plugin install vagrant-hostmanager
    vagrant plugin install vagrant-puppet-install
    vagrant plugin install vagrant-librarian-puppet --plugin-version '~> 0.9.0'
    vagrant plugin install vagrant-cachier

    vagrant plugin install vagrant-digitalocean --plugin-version '~> 0.7.3'
    vagrant plugin install vagrant-aws --plugin-version '~> 0.6.0'

    # sanity check
    vagrant plugin list

    git clone git@github.com:lsst-sqre/sandbox-stackbuild.git
    cd sandbox-stackbuild
    vagrant up --provider=digital_ocean

Other useful commands
---------------------
    vagrant up --provider=virtual_box
    vagrant up --provider=digital_ocean
    vagrant up <hostname> --provider=digital_ocean
    vagrant status
    vagrant ssh
    vagrant ssh <hostname>
    vagrant halt  # restart with vagrant up
    vagrant halt <hostname>  # restart with vagrant up
    vagrant destroy -f
    vagrant destroy -f <hostname>
