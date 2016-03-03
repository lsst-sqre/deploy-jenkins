forge 'https://forgeapi.puppetlabs.com'

mod 'puppetlabs/stdlib'
mod 'camptocamp/augeas'
mod 'stahnma/epel'
mod 'jhoblitt/sysstat'

mod 'maestrodev/wget', '~> 1.7.0'
mod 'puppetlabs/firewall', '~> 1.5.0'
mod 'jfryman/nginx', '~> 0.2.7'
mod 'jfryman/selinux', '~> 0.2.3'
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
# pending the merger of https://github.com/jenkinsci/puppet-jenkins/pull/519
mod 'rtyler/jenkins',
  :git => 'https://github.com/jhoblitt/puppet-jenkins.git',
  :ref => '27c1bbf4b768ae5ae49835ee7266453e77909520'
mod 'lsst/lsststack',
  :git => 'https://github.com/lsst-sqre/puppet-lsststack.git',
  :ref => '9eaf2c4e22c2d5981423fd3145b23097caa778c5'

mod 'jhoblitt/ganglia', '~> 2.0'
mod 'mayflower/php', '~> 3.2'
# https://github.com/puppetlabs/puppetlabs-concat/pull/361
mod 'puppetlabs/concat',
  :git => 'https://github.com/puppetlabs/puppetlabs-concat.git',
  :ref => 'fd4f1e2d46a86f1659da420f4ce042882d38e021'

mod 'stankevich/python', '~> 1.11'

mod 'lsst/jenkins_demo', :path => './jenkins_demo'

# install ruby-devel & bundler for debugging inside VMs
mod 'puppetlabs/ruby'
