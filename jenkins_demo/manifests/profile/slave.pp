class jenkins_demo::profile::slave {
  include ::lsststack

  $platform = downcase("${::operatingsystem}-${::operatingsystemmajrelease}")
  class { 'jenkins::slave':
    masterurl  => 'http://jenkins-master:8080',
    slave_name => $::hostname,
    executors  => 1,
    labels     => "${::hostname} ${platform}",
    # don't start slave before lsstsw build env is ready
    require    => [
      Class['lsststack'],
      Host['jenkins-master'],
    ],
  }

  # provides killall on el6 & el7 -- needed by stack-os-matrix
  ensure_packages(['psmisc'])

  # virtualenv is needed by validate_drp
  class { 'python':
    version    => 'system',
    pip        => 'present',
    dev        => 'present',
    virtualenv => 'present',
  }
}
