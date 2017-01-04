forge 'https://forgeapi.puppetlabs.com'

mod 'puppetlabs/stdlib'
mod 'camptocamp/augeas'
mod 'stahnma/epel'
mod 'jhoblitt/sysstat'

mod 'maestrodev/wget', '~> 1.7.0'
mod 'puppetlabs/firewall', '~> 1.5.0'
# https://github.com/jfryman/puppet-nginx/pull/778
# is required to work under puppet 4.4.1
mod 'jfryman/nginx',
  :git => 'https://github.com/jfryman/puppet-nginx.git',
  :ref => '56e1c591bf5bfd06c34782c66953b3bc4b10fafa'
# 0.3.1 does not include selinux module installation from a string
mod 'jfryman/selinux',
  :git => 'https://github.com/jfryman/puppet-selinux.git',
  :ref=> '940eb46fa020bec5d028518c548a89892c543977'
mod 'saz/timezone', '~> 3.3.0'
mod 'puppetlabs/ntp', '~> 3.3.0'
mod 'juniorsysadmin/irqbalance', '~> 1.0.4'
mod 'thias/tuned', '~> 1.0.2'

mod 'aco/yum_autoupdate',
  :git => 'https://github.com/jhoblitt/aco-yum_autoupdate.git',
  :ref => 'bugfix/operatingsystemmajrelease-is-a-string'

mod 'saz/sudo',
  :git => 'https://github.com/pbyrne413/puppet-sudo',
  :ref => '30feebf655c4966b96ae328c40c1a2dc144c2e66'
# unrelased slave groups
mod 'rtyler/jenkins',
  :git => 'https://github.com/jenkinsci/puppet-jenkins.git',
  :ref => '20f851ef712b04055682fe9728e3091a6386d5ca'
mod 'lsst/lsststack',
  :git => 'https://github.com/lsst-sqre/puppet-lsststack.git',
  :ref => '848eadfe15b6ab24604c39694940bb1addc5a712'

mod 'jhoblitt/ganglia', '~> 2.0'
mod 'mayflower/php', '~> 3.2'
# https://github.com/puppetlabs/puppetlabs-concat/pull/361
mod 'puppetlabs/concat',
  :git => 'https://github.com/puppetlabs/puppetlabs-concat.git',
  :ref => 'fd4f1e2d46a86f1659da420f4ce042882d38e021'

mod 'stankevich/python', '~> 1.12'

mod 'lsst/jenkins_demo', :path => './jenkins_demo'

# install ruby-devel & bundler for debugging inside VMs
mod 'puppetlabs/ruby', '~> 0.5.0'

mod 'puppetlabs/vcsrepo'
mod 'puppetlabs/gcc'
# 0.3.0 adds systemd fact
mod 'camptocamp/systemd', '~> 0.3'
mod 'jhoblitt/oauth2_proxy', '~> 1.2.0'
mod 'garethr/docker', '~> 5.3.0'
mod 'maestrodev/rvm', '~> 1.13.1'
mod 'puppet/archive', '~> 0.5'
