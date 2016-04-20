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
    executors => 4,
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

  # packages requested by Dave Mills
  ensure_packages([
    'tk',
    'tk-devel',
    'swig',
    'ncurses-libs',
    'xterm',
    'xorg-x11-fonts-misc',
    'java-1.8.0-openjdk-devel',
    'boost-python',
    'boost-python-devel',
    'maven',
    'python-devel',
  ])
}
