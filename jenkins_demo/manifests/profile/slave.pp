class jenkins_demo::profile::slave {
  include ::wget # needed by jenkins
  include ::lsststack

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
    require   => [
      Host['jenkins-master'],
    ],
  }

  if $::operatingsystemmajrelease == '6' {
    # the version of git supplied with el6 is too old for
    # stash-pullrequest-builder
    ensure_packages(['devtoolset-3-git'])

    file_line { 'enable devtoolset-3':
      line    => '. /opt/rh/devtoolset-3/enable',
      path    => '/home/jenkins-slave/.bashrc',
      require => User['jenkins-slave'],
    }
  }

  # provides killall on el6 & el7 -- needed by stack-os-matrix
  ensure_packages(['psmisc'])
}
