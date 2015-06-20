class jenkins_demo::profile::slave {
  include ::wget # needed by jenkins
  include ::lsststack

  lsststack::lsstsw { 'build0':
    group        => 'jenkins-slave',
    manage_group => true,
  }

  class { 'sudo':
    purge               => false,
    config_file_replace => false,
  }
  sudo::conf { 'jenkins-slave':
    content  => 'jenkins-slave ALL=(%jenkins-slave) NOPASSWD: ALL',
  }

  Class['::wget'] -> Class['::jenkins::slave']

  host { 'jenkins-master':
    ensure => 'present',
    ip     => '192.168.123.10',
  } ~>
  class { 'jenkins::slave':
    masterurl => 'http://jenkins-master:8080',
    executors => 1,
    labels    => downcase("${::operatingsystem}-${::operatingsystemmajrelease}"),
    # don't start slave before lsstsw build env is ready
    require   => Lsststack::Lsstsw['build0'],
  }
}
