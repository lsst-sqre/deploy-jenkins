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

  class { 'jenkins::slave':
    masterurl => 'http://jenkins-master:8080',
    executors => 1,
    labels    => downcase("${::operatingsystem}-${::operatingsystemmajrelease}"),
    # don't start slave before lsstsw build env is ready
    require   => [
      Lsststack::Lsstsw['build0'],
      Host['jenkins-master'],
    ],
  }

  # provides killall on el6 & el7 -- needed by stack-os-matrix
  ensure_packages(['psmisc'])
}
