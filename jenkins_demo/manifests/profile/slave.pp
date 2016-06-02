class jenkins_demo::profile::slave {
  include ::wget # needed by jenkins
  include ::lsststack

  lsststack::lsstsw { 'build0':
    group             => 'jenkins-slave',
    manage_group      => true,
    lsstsw_ensure     => 'latest',
    buildbot_ensure   => 'latest',
    lsst_build_ensure => 'latest',
  }

  class { 'sudo':
    purge               => false,
    config_file_replace => false,
  }
  sudo::conf { 'jenkins-slave':
    content  => 'jenkins-slave ALL=(%jenkins-slave) NOPASSWD: ALL',
  }

  Class['::wget'] -> Class['::jenkins::slave']

  $platform = downcase("${::operatingsystem}-${::operatingsystemmajrelease}")
  class { 'jenkins::slave':
    masterurl  => 'http://jenkins-master:8080',
    slave_name => $::hostname,
    executors  => 1,
    labels     => "${::hostname} ${platform}",
    # don't start slave before lsstsw build env is ready
    require    => [
      Lsststack::Lsstsw['build0'],
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
