class jenkins_demo::profile::slave {
  include ::wget # needed by jenkins
  include ::lsststack

  lsststack::lsstsw { 'build0':
    group        => 'jenkins-slave',
    manage_group => false,
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
    ui_user   => 'admin',
    ui_pass   => 'b0da1e0bf3f79ff02624c2f716913808',
    executors => 1,
    labels    => downcase("${::operatingsystem}-${::operatingsystemmajrelease}"),
  }
}
